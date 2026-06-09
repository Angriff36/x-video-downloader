from fastapi import FastAPI, Query, UploadFile, File, Request
from fastapi.responses import FileResponse, JSONResponse, StreamingResponse, Response
import yt_dlp
import os
import re
import time
import uuid
import threading
import logging
import functools
import json
import hashlib
from collections import OrderedDict
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional
from datetime import datetime
import urllib.error
import urllib.parse
import urllib.request
import io

app = FastAPI()

OUTPUT_DIR = "/tmp/downloads"
os.makedirs(OUTPUT_DIR, exist_ok=True)

COOKIES_FILE = "youtube_cookies.txt"

# In-memory store for batch download progress
_batch_jobs: dict = {}

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
logger = logging.getLogger(__name__)

# --- Metadata Cache (LRU with TTL) ---

class MetadataCache:
    """LRU cache for video metadata with TTL-based expiration.
    Reduces redundant yt-dlp extraction calls for previously probed URLs."""

    def __init__(self, max_size: int = 200, ttl_seconds: int = 1800):
        self._cache: OrderedDict[str, dict] = OrderedDict()
        self._max_size = max_size
        self._ttl = ttl_seconds
        self._lock = threading.Lock()

    def _make_key(self, url: str) -> str:
        return hashlib.sha256(url.strip().encode()).hexdigest()[:32]

    def get(self, url: str) -> Optional[dict]:
        key = self._make_key(url)
        with self._lock:
            if key in self._cache:
                entry = self._cache[key]
                if time.time() - entry['_cached_at'] < self._ttl:
                    self._cache.move_to_end(key)
                    return entry['data']
                else:
                    del self._cache[key]
        return None

    def put(self, url: str, data: dict) -> None:
        key = self._make_key(url)
        with self._lock:
            if key in self._cache:
                self._cache.move_to_end(key)
            self._cache[key] = {'data': data, '_cached_at': time.time()}
            while len(self._cache) > self._max_size:
                self._cache.popitem(last=False)

    def invalidate(self, url: str) -> None:
        key = self._make_key(url)
        with self._lock:
            self._cache.pop(key, None)

    @property
    def size(self) -> int:
        with self._lock:
            return len(self._cache)

_metadata_cache = MetadataCache(max_size=200, ttl_seconds=1800)


# --- Download Speed Throttler ---

class SpeedThrottler:
    """Token-bucket rate limiter for controlling download bandwidth."""

    def __init__(self, rate_bytes_per_sec: Optional[int] = None):
        self._rate = rate_bytes_per_sec
        self._lock = threading.Lock()
        self._tokens = 0.0
        self._last_refill = time.monotonic()

    @property
    def rate(self) -> Optional[int]:
        return self._rate

    @rate.setter
    def rate(self, value: Optional[int]):
        with self._lock:
            self._rate = value

    def throttle(self, chunk_size: int) -> float:
        """Return how long to sleep after sending chunk_size bytes.
        Returns 0 if no throttling is active."""
        if self._rate is None or self._rate <= 0:
            return 0.0
        with self._lock:
            now = time.monotonic()
            elapsed = now - self._last_refill
            self._tokens = min(self._rate, self._tokens + elapsed * self._rate)
            self._last_refill = now
            self._tokens -= chunk_size
            if self._tokens < 0:
                return -self._tokens / self._rate
        return 0.0

# Global throttler — can be adjusted via API
_speed_throttler = SpeedThrottler()


# --- Active download tracking ---

_active_downloads: dict[str, dict] = {}
_active_downloads_lock = threading.Lock()


# --- Error categorization ---

class ErrorCode:
    """Structured error codes for the API."""
    # Client errors
    INVALID_URL = "invalid_url"
    UNSUPPORTED_PLATFORM = "unsupported_platform"
    MISSING_PARAMS = "missing_params"
    VIDEO_UNAVAILABLE = "video_unavailable"
    GEO_BLOCKED = "geo_blocked"
    AUTH_REQUIRED = "auth_required"
    PRIVATE_VIDEO = "private_video"
    LIVE_STREAM = "live_stream"
    NO_FORMATS = "no_formats"

    # Server / transient errors
    EXTRACTION_FAILED = "extraction_failed"
    DOWNLOAD_FAILED = "download_failed"
    FFMPEG_FAILED = "ffmpeg_failed"
    NETWORK_TIMEOUT = "network_timeout"
    SERVER_ERROR = "server_error"

    # Batch-specific
    JOB_NOT_FOUND = "job_not_found"
    JOB_NOT_COMPLETE = "job_not_complete"
    INVALID_INDICES = "invalid_indices"


# HTTP status code mapping for each error code
_ERROR_STATUS_MAP = {
    ErrorCode.INVALID_URL: 400,
    ErrorCode.UNSUPPORTED_PLATFORM: 400,
    ErrorCode.MISSING_PARAMS: 400,
    ErrorCode.VIDEO_UNAVAILABLE: 404,
    ErrorCode.GEO_BLOCKED: 403,
    ErrorCode.AUTH_REQUIRED: 403,
    ErrorCode.PRIVATE_VIDEO: 403,
    ErrorCode.LIVE_STREAM: 400,
    ErrorCode.NO_FORMATS: 404,
    ErrorCode.EXTRACTION_FAILED: 500,
    ErrorCode.DOWNLOAD_FAILED: 500,
    ErrorCode.FFMPEG_FAILED: 500,
    ErrorCode.NETWORK_TIMEOUT: 504,
    ErrorCode.SERVER_ERROR: 500,
    ErrorCode.JOB_NOT_FOUND: 404,
    ErrorCode.JOB_NOT_COMPLETE: 409,
    ErrorCode.INVALID_INDICES: 400,
}

# User-friendly messages (safe to show in frontend)
_USER_MESSAGES = {
    ErrorCode.INVALID_URL: "The URL you provided is not valid. Please check and try again.",
    ErrorCode.UNSUPPORTED_PLATFORM: "This platform is not supported. We support YouTube, X/Twitter, Instagram, TikTok, Vimeo, and more.",
    ErrorCode.MISSING_PARAMS: "Required information is missing. Please provide a valid URL.",
    ErrorCode.VIDEO_UNAVAILABLE: "This video is no longer available or has been removed.",
    ErrorCode.GEO_BLOCKED: "This video is not available in your region.",
    ErrorCode.AUTH_REQUIRED: "This video requires authentication. Try uploading cookies in Settings.",
    ErrorCode.PRIVATE_VIDEO: "This video is private and cannot be downloaded.",
    ErrorCode.LIVE_STREAM: "Live streams cannot be downloaded. Wait until the stream ends.",
    ErrorCode.NO_FORMATS: "No downloadable formats found for this video.",
    ErrorCode.EXTRACTION_FAILED: "Could not extract video information. The site may have changed or the video may be protected.",
    ErrorCode.DOWNLOAD_FAILED: "The download failed. This may be a temporary issue — please try again.",
    ErrorCode.FFMPEG_FAILED: "Video processing failed. The file format may not be supported.",
    ErrorCode.NETWORK_TIMEOUT: "The request timed out. Please check your connection and try again.",
    ErrorCode.SERVER_ERROR: "Something went wrong on our end. Please try again later.",
    ErrorCode.JOB_NOT_FOUND: "The download job could not be found. It may have expired.",
    ErrorCode.JOB_NOT_COMPLETE: "The download is still in progress. Please wait.",
    ErrorCode.INVALID_INDICES: "Invalid selection. Please select valid video indices.",
}

# Set of error codes that are retryable (transient failures)
RETRYABLE_ERRORS = {
    ErrorCode.NETWORK_TIMEOUT,
    ErrorCode.DOWNLOAD_FAILED,
    ErrorCode.EXTRACTION_FAILED,
    ErrorCode.SERVER_ERROR,
}


def _classify_error(error: Exception) -> tuple[str, str]:
    """Classify an exception into an error code and raw message.

    Pattern-matches against known yt-dlp error strings to produce
    structured, user-friendly error codes.
    """
    msg = str(error).lower()
    error_type = type(error).__name__

    # yt-dlp specific patterns
    if "sign in to confirm" in msg or "bot" in msg:
        return ErrorCode.AUTH_REQUIRED, str(error)
    if "private" in msg and "video" in msg:
        return ErrorCode.PRIVATE_VIDEO, str(error)
    if "geo" in msg or "country" in msg or "region" in msg or "not available in your country" in msg:
        return ErrorCode.GEO_BLOCKED, str(error)
    if "live" in msg and ("stream" in msg or "broadcast" in msg):
        return ErrorCode.LIVE_STREAM, str(error)
    if "no video formats" in msg or "requested format not available" in msg:
        return ErrorCode.NO_FORMATS, str(error)
    if "unable to extract" in msg or "extract_info" in msg.lower():
        return ErrorCode.EXTRACTION_FAILED, str(error)
    if "video unavailable" in msg or "does not exist" in msg or "been removed" in msg:
        return ErrorCode.VIDEO_UNAVAILABLE, str(error)
    if "unsupported url" in msg or "no suitable extractor" in msg or "unrecognized" in msg:
        return ErrorCode.UNSUPPORTED_PLATFORM, str(error)

    # Network / timeout patterns
    if "timeout" in msg or "timed out" in msg:
        return ErrorCode.NETWORK_TIMEOUT, str(error)
    if "connection" in msg and ("refused" in msg or "reset" in msg or "failed" in msg):
        return ErrorCode.NETWORK_TIMEOUT, str(error)

    # ffmpeg patterns
    if "ffmpeg" in msg or "ffprobe" in msg:
        return ErrorCode.FFMPEG_FAILED, str(error)

    # Download failure patterns
    if "download" in msg and ("error" in msg or "fail" in msg):
        return ErrorCode.DOWNLOAD_FAILED, str(error)

    # KeyError / AttributeError from yt-dlp (known issue with some extractors)
    if error_type in ("KeyError", "AttributeError", "IndexError"):
        return ErrorCode.EXTRACTION_FAILED, str(error)

    return ErrorCode.SERVER_ERROR, str(error)


# --- Filename Template Engine ---

# Default template: just the title + platform for clean organization
DEFAULT_FILENAME_TEMPLATE = "{title}"

# Characters forbidden in filenames across Windows/Mac/Linux
_FILENAME_FORBIDDEN = re.compile(r'[<>:"/\\|?*\x00-\x1f]')


def _detect_platform_name(url: str) -> str:
    """Extract a short platform name from the URL."""
    lower = url.lower()
    if "youtube.com" in lower or "youtu.be" in lower:
        return "YouTube"
    if "instagram.com" in lower:
        return "Instagram"
    if "tiktok.com" in lower or "vm.tiktok" in lower:
        return "TikTok"
    if "twitter.com" in lower or "x.com" in lower:
        return "X"
    if "vimeo.com" in lower:
        return "Vimeo"
    if "dailymotion.com" in lower:
        return "Dailymotion"
    if "facebook.com" in lower or "fb.watch" in lower:
        return "Facebook"
    if "reddit.com" in lower:
        return "Reddit"
    return "Other"


def _sanitize_filename(name: str, max_length: int = 200) -> str:
    """Sanitize a string for use as a filename component.

    - Strips forbidden characters (<>:"/\\|?* and control chars)
    - Collapses multiple spaces/dots into one
    - Truncates to max_length
    - Falls back to 'untitled' if empty
    """
    name = _FILENAME_FORBIDDEN.sub('', name)
    name = re.sub(r'\s+', ' ', name).strip()
    name = re.sub(r'\.{2,}', '.', name)
    # Remove leading/trailing dots and spaces
    name = name.strip('. ')
    if not name:
        return 'untitled'
    return name[:max_length]


def _detect_instagram_content_type(url: str) -> str:
    """Detect the type of Instagram content from the URL.

    Returns: 'post', 'reel', 'story', 'igtv', 'carousel', or 'unknown'
    """
    lower = url.lower()
    # Remove query parameters for cleaner matching
    clean_url = lower.split('?')[0].split('/')

    if 'stories' in clean_url:
        return 'story'
    elif 'reel' in clean_url or '/reel/' in lower:
        return 'reel'
    elif 'tv' in clean_url or '/igtv/' in lower:
        return 'igtv'
    elif 'p' in clean_url or '/p/' in lower:
        # Regular posts could be carousels - will be detected during extraction
        return 'post'
    return 'unknown'


def _normalize_instagram_url(url: str) -> str:
    """Normalize Instagram URLs to ensure proper extraction.

    Handles various Instagram URL formats:
    - Regular posts: instagram.com/p/shortcode/
    - Reels: instagram.com/reel/shortcode/
    - Stories: instagram.com/stories/username/id
    - IGTV: instagram.com/tv/shortcode/
    """
    url = url.strip()

    # Ensure https
    if not url.lower().startswith('https://'):
        if url.lower().startswith('http://'):
            url = url.replace('http://', 'https://', 1)
        else:
            url = 'https://' + url

    # Remove trailing query params that can cause issues (like ?igsh=...)
    # but keep the path intact
    return url


def _normalize_tiktok_url(url: str) -> str:
    """Normalize TikTok URLs to ensure proper extraction.

    Handles various TikTok URL formats:
    - Full URLs: tiktok.com/@username/video/1234567890
    - Short URLs: vm.tiktok.com/Zxxxx
    - Embed URLs: tiktok.com/embed/v2/1234567890
    """
    url = url.strip()
    lower = url.lower()

    # Ensure https
    if not lower.startswith('https://'):
        if lower.startswith('http://'):
            url = url.replace('http://', 'https://', 1)
        else:
            url = 'https://' + url
        lower = url.lower()

    # Handle vm.tiktok.com short links - they should be resolved by yt-dlp
    # but we can ensure they're properly formatted
    if 'vm.tiktok.com' in lower or 'vt.tiktok.com' in lower:
        # Short links are fine as-is, yt-dlp will resolve them
        return url

    # Ensure www. for consistency
    if 'tiktok.com' in lower and not url.startswith('https://www.'):
        url = re.sub(r'tiktok\.com', r'www.tiktok.com', url, flags=re.IGNORECASE)

    return url


def _detect_tiktok_content_type(url: str) -> str:
    """Detect the type of TikTok content from the URL.

    Returns: 'video', 'story', 'live', or 'unknown'
    """
    lower = url.lower()
    clean_url = lower.split('?')[0].split('/')

    if 'live' in clean_url:
        return 'live'
    elif 'story' in clean_url:
        return 'story'
    elif 'video' in clean_url or '/v/' in lower or '/@' in lower:
        return 'video'
    return 'unknown'


# --- Custom Platform Extractors (bypass yt-dlp) ---

def _extract_tiktok(url: str) -> dict | None:
    """Extract TikTok video info directly from the embed page, bypassing yt-dlp."""
    import requests as _req
    try:
        # Extract video ID from URL
        video_id = None
        m = re.search(r'/video/(\d+)', url)
        if m:
            video_id = m.group(1)
        else:
            # Try short URL resolution
            resp = _req.head(url, allow_redirects=True, timeout=10,
                             headers={'User-Agent': 'Mozilla/5.0 (Linux; Android 13) Chrome/115.0.0.0 Mobile'})
            resolved = resp.url
            m2 = re.search(r'/video/(\d+)', resolved)
            if m2:
                video_id = m2.group(1)
        if not video_id:
            logger.warning(f"[TikTok] Could not extract video ID from {url}")
            return None

        # Fetch the embed page which has video data in the HTML
        embed_url = f"https://www.tiktok.com/embed/v2/{video_id}"
        resp = _req.get(embed_url, timeout=15, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml',
            'Accept-Language': 'en-US,en;q=0.9',
        })
        resp.raise_for_status()
        html = resp.text

        # Extract video URL from og:video meta tag
        video_url = None
        og_match = re.search(r'<meta\s+property="og:video(?:\:url)?"[^>]*content="([^"]+)"', html)
        if og_match:
            video_url = og_match.group(1).replace('&amp;', '&')

        # Also try to extract from JSON data embedded in the page
        if not video_url:
            json_match = re.search(r'"playAddr":"([^"]+)"', html)
            if json_match:
                video_url = json_match.group(1).replace('\\u002F', '/').replace('&amp;', '&')

        # Extract title
        title = "TikTok Video"
        title_match = re.search(r'<meta\s+property="og:title"[^>]*content="([^"]+)"', html)
        if title_match:
            title = title_match.group(1)

        # Extract thumbnail
        thumbnail = None
        thumb_match = re.search(r'<meta\s+property="og:image"[^>]*content="([^"]+)"', html)
        if thumb_match:
            thumbnail = thumb_match.group(1).replace('&amp;', '&')

        if not video_url:
            logger.warning(f"[TikTok] No video URL found in embed page for {video_id}")
            return None

        return {
            'title': title,
            'video_url': video_url,
            'thumbnail': thumbnail,
            'platform': 'TikTok',
            'video_id': video_id,
            'duration': None,
        }
    except Exception as e:
        logger.error(f"[TikTok] Custom extraction failed: {e}")
        return None


def _extract_instagram(url: str) -> dict | None:
    """Extract Instagram media info directly from the page, bypassing yt-dlp."""
    import requests as _req
    try:
        # Clean URL - remove query params
        clean_url = url.split('?')[0]
        if not clean_url.endswith('/'):
            clean_url += '/'

        headers = {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'X-IG-App-ID': '936619743392459',
            'Referer': 'https://www.instagram.com/',
        }

        # Try fetching the page with __a=1 for JSON response
        api_url = f"{clean_url}?__a=1&__d=dis"
        resp = _req.get(api_url, timeout=15, headers=headers)

        # If we got JSON, parse it
        if resp.status_code == 200 and 'application/json' in resp.headers.get('content-type', ''):
            data = resp.json()
            items = data.get('items', [])
            if items:
                item = items[0]
                video_url = None
                # Check for video versions
                video_versions = item.get('video_versions', [])
                if video_versions:
                    video_url = video_versions[0].get('url')
                # Check for carousel
                carousel = item.get('carousel_media', [])
                title = item.get('caption', {}).get('text', '') if item.get('caption') else ''
                if not title:
                    title = f"Instagram {_detect_instagram_content_type(url)}"
                thumbnail = None
                image_versions = item.get('image_versions2', {}).get('candidates', [])
                if image_versions:
                    thumbnail = image_versions[0].get('url')

                return {
                    'title': title[:200],
                    'video_url': video_url,
                    'thumbnail': thumbnail,
                    'platform': 'Instagram',
                    'video_id': item.get('code', ''),
                    'duration': item.get('video_duration'),
                    'carousel_count': len(carousel) if carousel else (1 if video_url else 0),
                    'carousel': carousel,
                }

        # Fallback: fetch the HTML page and extract og:video
        resp = _req.get(clean_url, timeout=15, headers=headers)
        resp.raise_for_status()
        html = resp.text

        video_url = None
        og_match = re.search(r'<meta\s+property="og:video(?:\:url)?"[^>]*content="([^"]+)"', html)
        if og_match:
            video_url = og_match.group(1).replace('&amp;', '&')

        title = "Instagram Post"
        title_match = re.search(r'<meta\s+property="og:title"[^>]*content="([^"]+)"', html)
        if title_match:
            title = title_match.group(1)

        thumbnail = None
        thumb_match = re.search(r'<meta\s+property="og:image"[^>]*content="([^"]+)"', html)
        if thumb_match:
            thumbnail = thumb_match.group(1).replace('&amp;', '&')

        if not video_url:
            logger.warning(f"[Instagram] No video URL found for {url}")
            return None

        return {
            'title': title,
            'video_url': video_url,
            'thumbnail': thumbnail,
            'platform': 'Instagram',
            'video_id': '',
            'duration': None,
        }
    except Exception as e:
        logger.error(f"[Instagram] Custom extraction failed: {e}")
        return None



    template: str,
    info: dict,
    url: str,
    format_id: str | None = None,
    ext: str = "mp4",
    quality_label: str | None = None,
    index: int | None = None,
) -> str:
    """Resolve a filename template using video metadata.

    Supported placeholders:
        {title}      - Video title (sanitized)
        {platform}   - Platform name (YouTube, Instagram, etc.)
        {uploader}   - Channel/uploader name
        {date}       - Upload date as YYYY-MM-DD
        {year}       - Upload year
        {month}      - Upload month (zero-padded)
        {day}        - Upload day (zero-padded)
        {id}         - Video ID from the platform
        {quality}    - Resolution/quality label (e.g. 1080p, 720p)
        {ext}        - File extension (mp4, m4a, etc.)
        {index}      - Index within a media group (1-based)
    """
    platform = _detect_platform_name(url)
    title = info.get('title', 'Untitled Video')
    uploader = info.get('uploader') or info.get('channel') or info.get('creator') or 'Unknown'

    # Parse upload date — yt-dlp returns YYYYMMDD string
    upload_date_raw = info.get('upload_date', '')
    try:
        if upload_date_raw and len(upload_date_raw) == 8:
            dt = datetime.strptime(upload_date_raw, '%Y%m%d')
            date_str = dt.strftime('%Y-%m-%d')
            year_str = dt.strftime('%Y')
            month_str = dt.strftime('%m')
            day_str = dt.strftime('%d')
        else:
            dt = None
            date_str = year_str = month_str = day_str = 'unknown'
    except (ValueError, TypeError):
        date_str = year_str = month_str = day_str = 'unknown'

    video_id = info.get('id', 'unknown')

    # Quality label
    if quality_label:
        quality = quality_label
    elif format_id:
        # Try to infer from format info
        height = info.get('height')
        quality = f"{height}p" if height else "best"
    else:
        quality = "best"

    # Index (1-based for user-friendliness)
    index_str = str(index + 1) if index is not None else ""

    # Build replacement map
    replacements = {
        'title': _sanitize_filename(title),
        'platform': _sanitize_filename(platform),
        'uploader': _sanitize_filename(uploader),
        'date': date_str,
        'year': year_str,
        'month': month_str,
        'day': day_str,
        'id': _sanitize_filename(video_id),
        'quality': _sanitize_filename(quality),
        'ext': ext,
        'index': index_str,
    }

    # Replace placeholders
    result = template
    for key, value in replacements.items():
        result = result.replace(f'{{{key}}}', value)

    # Clean up any leftover empty braces or double separators
    result = re.sub(r'\{[^}]*\}', '', result)  # Remove unresolved placeholders
    result = re.sub(r'_{2,}', '_', result)      # Collapse multiple underscores
    result = re.sub(r'-{2,}', '-', result)       # Collapse multiple dashes
    result = result.strip('_- .')

    # Final sanitization of the whole filename
    result = _sanitize_filename(result, max_length=240)

    if not result:
        result = f"video_{int(time.time())}"

    return result


def _error_response(error_code: str, raw_message: str | None = None, status_override: int | None = None) -> JSONResponse:
    """Build a structured JSON error response with proper HTTP status code."""
    http_status = status_override or _ERROR_STATUS_MAP.get(error_code, 500)
    user_message = _USER_MESSAGES.get(error_code, "An unexpected error occurred.")
    retryable = error_code in RETRYABLE_ERRORS

    content = {
        "error": user_message,
        "error_code": error_code,
        "retryable": retryable,
    }
    # Include raw debug info only in non-production scenarios
    if raw_message and os.environ.get("DEBUG"):
        content["debug"] = raw_message

    logger.warning(f"Error [{error_code}] (HTTP {http_status}): {raw_message or user_message}")
    return JSONResponse(content=content, status_code=http_status)


# --- Retry logic with exponential backoff ---

def _retry_with_backoff(max_retries: int = 2, base_delay: float = 1.0, max_delay: float = 8.0):
    """Decorator that retries a function on transient failures with exponential backoff.

    Only retries on errors classified as retryable (network timeout, download failed,
    extraction failed). Non-retryable errors propagate immediately.
    """
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            last_error_code = None
            last_raw = None
            for attempt in range(max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    error_code, raw_msg = _classify_error(e)
                    if error_code not in RETRYABLE_ERRORS or attempt == max_retries:
                        raise
                    last_error_code = error_code
                    last_raw = raw_msg
                    delay = min(base_delay * (2 ** attempt), max_delay)
                    logger.info(f"Retryable error [{error_code}] on attempt {attempt + 1}/{max_retries + 1}, retrying in {delay:.1f}s: {raw_msg}")
                    time.sleep(delay)
            # Should not reach here, but safety net
            raise Exception(last_raw or "Max retries exceeded")
        return wrapper
    return decorator


def _get_headers(url: str) -> dict:
    """Return appropriate HTTP headers for the given URL."""
    lower_url = url.lower()
    if "x.com" in lower_url or "twitter.com" in lower_url:
        referer = "https://x.com/"
    elif "instagram.com" in lower_url:
        referer = "https://www.instagram.com/"
    elif "tiktok.com" in lower_url:
        referer = "https://www.tiktok.com/"
    else:
        referer = "https://www.youtube.com/"

    if "x.com" in lower_url or "twitter.com" in lower_url or "vimeo.com" in lower_url:
        user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    elif "instagram.com" in lower_url:
        # Instagram requires specific headers for better compatibility
        user_agent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
    else:
        user_agent = "Mozilla/5.0 (Linux; Android 13; Pixel 7 Pro Build/TQ2A.230505.002) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Mobile Safari/537.36"

    headers = {
        'User-Agent': user_agent,
        'Referer': referer,
        'Accept-Language': 'en-US,en;q=0.9',
    }

    # Add Instagram-specific headers
    if "instagram.com" in lower_url:
        headers.update({
            'X-IG-App-ID': '936619743392459',  # Public Instagram app ID
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': '*/*',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'same-origin',
        })

    return headers


def _apply_auth_to_opts(ydl_opts: dict, request: Request, url: str) -> dict:
    """Apply authentication from request headers to yt-dlp options.

    Checks for X-Auth-Token header and applies it to the appropriate platform.
    Also applies cookies from the uploaded cookie file if it exists.
    """
    # Apply uploaded cookies if the file exists
    if os.path.exists(COOKIES_FILE):
        ydl_opts['cookiefile'] = COOKIES_FILE

    # Check for client-provided auth token
    auth_token = request.headers.get('x-auth-token')
    if not auth_token:
        return ydl_opts

    # Add bearer token to headers for platforms that support it
    headers = ydl_opts.get('http_headers', {})
    headers['Authorization'] = f'Bearer {auth_token}'
    ydl_opts['http_headers'] = headers

    # Platform-specific cookie injection
    # For Twitter/X, the OAuth token can be used as a cookie
    if "x.com" in url or "twitter.com" in url:
        ydl_opts['http_headers']['Cookie'] = f'auth_token={auth_token}'
    elif "instagram.com" in url:
        # Instagram requires multiple cookies for proper authentication
        # sessionid is the primary auth cookie
        ydl_opts['http_headers']['Cookie'] = f'sessionid={auth_token}'
        # Add Instagram-specific extractor options when auth is present
        ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
        ydl_opts['extractor_args']['instagram'] = [
            'player_client=android',
        ]
    elif "tiktok.com" in url:
        ydl_opts['http_headers']['Cookie'] = f'sessionid={auth_token}'

    return ydl_opts


def _build_content_disposition(filename: str) -> str:
    safe = filename.replace('\\', '_').replace('/', '_').replace('"', "'")
    ascii_fallback = safe.encode('ascii', 'ignore').decode('ascii').strip()
    if not ascii_fallback:
        ascii_fallback = 'download.mp4'
    encoded = urllib.parse.quote(safe, safe='')
    return f'attachment; filename="{ascii_fallback}"; filename*=UTF-8\'\'{encoded}'


def _choose_direct_format(info: dict, requested_format_id: Optional[str]) -> dict | None:
    """Choose a single media URL that can be streamed without server-side merging."""
    formats = info.get('formats') or []
    if requested_format_id:
        for item in formats:
            if item.get('format_id') == requested_format_id and item.get('url'):
                acodec = item.get('acodec')
                vcodec = item.get('vcodec')
                if acodec and acodec != 'none' and vcodec and vcodec != 'none':
                    return item

    progressive = [
        item for item in formats
        if item.get('url')
        and item.get('vcodec') not in (None, 'none')
        and item.get('acodec') not in (None, 'none')
    ]
    if progressive:
        progressive.sort(
            key=lambda item: (
                item.get('height') or 0,
                item.get('tbr') or 0,
                item.get('filesize') or item.get('filesize_approx') or 0,
            ),
            reverse=True,
        )
        return progressive[0]

    if requested_format_id:
        for item in formats:
            if item.get('format_id') == requested_format_id and item.get('url'):
                return item

    return info if info.get('url') else None


def _stream_remote_media(media_url: str, headers: dict, chunk_size: int = 65536):
    req = urllib.request.Request(media_url, headers=headers)
    with urllib.request.urlopen(req, timeout=60) as upstream:
        while True:
            chunk = upstream.read(chunk_size)
            if not chunk:
                break
            yield chunk


def _stream_from_requests(resp, chunk_size: int = 65536):
    """Stream from a requests.Response object."""
    try:
        for chunk in resp.iter_content(chunk_size=chunk_size):
            if chunk:
                yield chunk
    finally:
        resp.close()


def _direct_stream_response(
    url: str,
    request: Request,
    format_id: Optional[str],
    filename_template: Optional[str],
) -> StreamingResponse | None:
    lower_url = url.lower()
    if "x.com" in lower_url or "twitter.com" in lower_url:
        return None

    template = filename_template or DEFAULT_FILENAME_TEMPLATE
    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'skip_download': True,
        'format': format_id or 'best[ext=mp4][vcodec!=none][acodec!=none]/best[vcodec!=none][acodec!=none]/best',
        'http_headers': _get_headers(url),
        'socket_timeout': 30,
        'noplaylist': True,
    }
    if "dailymotion.com" in url:
        ydl_opts['force_generic_extractor'] = True
    elif "tiktok.com" in url or "vm.tiktok.com" in url:
        ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
        ydl_opts['extractor_args']['tiktok'] = [
            'player_client=android',
        ]
    if request:
        _apply_auth_to_opts(ydl_opts, request, url)

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)

    if not info:
        return None

    selected = _choose_direct_format(info, format_id)
    if not selected or not selected.get('url'):
        return None

    ext = selected.get('ext') or info.get('ext') or 'mp4'
    media_type = 'audio/mpeg' if ext == 'mp3' else 'video/mp4'
    base_name = _resolve_filename_template(template, info, url, format_id=format_id, ext=ext)
    filename = f"{base_name}.{ext}"

    stream_headers = dict(_get_headers(url))
    stream_headers.update(selected.get('http_headers') or {})

    response_headers = {
        'Content-Disposition': _build_content_disposition(filename),
        'X-Accel-Buffering': 'no',
    }

    return StreamingResponse(
        _stream_remote_media(selected['url'], stream_headers),
        media_type=media_type,
        headers=response_headers,
    )


@app.post("/upload-cookies")
async def upload_cookies(file: UploadFile = File(...)):
    with open(COOKIES_FILE, "wb") as f:
        f.write(await file.read())
    return {"status": "cookies uploaded"}


@app.get("/probe")
def probe_url(request: Request, url: str = Query(...)):
    """Probe a URL to detect media groups (threads, albums, multi-media posts).
    Returns a list of available videos with metadata.
    Uses server-side metadata cache to avoid redundant yt-dlp calls."""
    if not url or not url.strip():
        return _error_response(ErrorCode.MISSING_PARAMS)

    # Basic URL validation
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return _error_response(ErrorCode.INVALID_URL)

    # Normalize URLs for better extraction
    if "instagram.com" in url.lower():
        url = _normalize_instagram_url(url)
    elif "tiktok.com" in url.lower():
        url = _normalize_tiktok_url(url)

    # Check metadata cache first
    cached = _metadata_cache.get(url)
    if cached is not None:
        logger.info(f"Metadata cache hit for: {url[:80]}")
        cached['cached'] = True
        return cached

    try:
        # --- Custom extractors for TikTok/Instagram (bypass yt-dlp) ---
        is_tiktok = "tiktok.com" in url.lower() or "vm.tiktok.com" in url.lower()
        is_instagram = "instagram.com" in url.lower()

        if is_tiktok:
            extracted = _extract_tiktok(url)
            if extracted:
                result = {
                    'is_group': False,
                    'group_title': extracted.get('title', ''),
                    'count': 1,
                    'videos': [{
                        'index': 0,
                        'title': extracted.get('title', 'TikTok Video'),
                        'url': url,
                        'duration': extracted.get('duration'),
                        'thumbnail': extracted.get('thumbnail'),
                        'id': extracted.get('video_id', ''),
                        'direct_url': extracted.get('video_url'),
                    }],
                    'cached': False,
                    'platform': 'TikTok',
                    'content_type': _detect_tiktok_content_type(url),
                }
                _metadata_cache.put(url, result)
                return result

        if is_instagram:
            extracted = _extract_instagram(url)
            if extracted:
                carousel = extracted.get('carousel', [])
                if carousel and len(carousel) > 1:
                    videos = []
                    for i, media in enumerate(carousel):
                        vid_versions = media.get('video_versions', [])
                        vid_url = vid_versions[0].get('url') if vid_versions else None
                        img_versions = media.get('image_versions2', {}).get('candidates', [])
                        thumb = img_versions[0].get('url') if img_versions else extracted.get('thumbnail')
                        videos.append({
                            'index': i,
                            'title': f"{extracted.get('title', 'Instagram Post')} ({i+1}/{len(carousel)})",
                            'url': url,
                            'duration': media.get('video_duration'),
                            'thumbnail': thumb,
                            'id': media.get('code', str(i)),
                            'direct_url': vid_url,
                        })
                    result = {
                        'is_group': True,
                        'group_title': extracted.get('title', 'Instagram Carousel'),
                        'count': len(videos),
                        'videos': videos,
                        'cached': False,
                        'platform': 'Instagram',
                        'content_type': 'carousel',
                    }
                else:
                    result = {
                        'is_group': False,
                        'group_title': extracted.get('title', ''),
                        'count': 1,
                        'videos': [{
                            'index': 0,
                            'title': extracted.get('title', 'Instagram Post'),
                            'url': url,
                            'duration': extracted.get('duration'),
                            'thumbnail': extracted.get('thumbnail'),
                            'id': extracted.get('video_id', ''),
                            'direct_url': extracted.get('video_url'),
                        }],
                        'cached': False,
                        'platform': 'Instagram',
                        'content_type': _detect_instagram_content_type(url),
                    }
                _metadata_cache.put(url, result)
                return result

        # --- Fallback to yt-dlp for all other platforms ---
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'extract_flat': 'in_playlist',
            'http_headers': _get_headers(url),
            'socket_timeout': 30,
        }

        _apply_auth_to_opts(ydl_opts, request, url)

        # Platform-specific extractor options
        if "dailymotion.com" in url:
            ydl_opts['force_generic_extractor'] = True
        elif "instagram.com" in url:
            # Instagram-specific options for better carousel and story detection
            ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
            ydl_opts['extractor_args']['instagram'] = [
                'player_client=android',
                'format_sort',  # Prefer MP4 formats
            ]
        elif "tiktok.com" in url or "vm.tiktok.com" in url:
            # TikTok-specific options for better extraction
            ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
            ydl_opts['extractor_args']['tiktok'] = [
                'player_client=android',
            ]

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)

        if info is None:
            return _error_response(ErrorCode.EXTRACTION_FAILED, "Could not extract info from URL")

        # Check if this is a playlist/album/thread with multiple entries
        entries = info.get('entries')
        if entries:
            videos = []
            for i, entry in enumerate(entries):
                if entry is None:
                    continue
                video = {
                    'index': i,
                    'title': entry.get('title', f'Video {i + 1}'),
                    'url': entry.get('url') or entry.get('webpage_url') or url,
                    'duration': entry.get('duration'),
                    'thumbnail': entry.get('thumbnail'),
                    'id': entry.get('id', ''),
                }
                videos.append(video)

            if not videos:
                return _error_response(ErrorCode.NO_FORMATS, "No videos found in group")

            result = {
                'is_group': True,
                'group_title': info.get('title', 'Media Group'),
                'count': len(videos),
                'videos': videos,
                'cached': False,
            }

            # Add platform-specific metadata
            if "instagram.com" in url.lower():
                content_type = _detect_instagram_content_type(url)
                result['content_type'] = content_type
                result['platform'] = 'Instagram'
            elif "tiktok.com" in url.lower() or "vm.tiktok.com" in url.lower():
                content_type = _detect_tiktok_content_type(url)
                result['content_type'] = content_type
                result['platform'] = 'TikTok'
        else:
            # Single video
            result = {
                'is_group': False,
                'group_title': info.get('title', ''),
                'count': 1,
                'videos': [{
                    'index': 0,
                    'title': info.get('title', 'Video'),
                    'url': url,
                    'duration': info.get('duration'),
                    'thumbnail': info.get('thumbnail'),
                    'id': info.get('id', ''),
                }],
                'cached': False,
            }

            # Add platform-specific metadata
            if "instagram.com" in url.lower():
                content_type = _detect_instagram_content_type(url)
                result['content_type'] = content_type
                result['platform'] = 'Instagram'
            elif "tiktok.com" in url.lower() or "vm.tiktok.com" in url.lower():
                content_type = _detect_tiktok_content_type(url)
                result['content_type'] = content_type
                result['platform'] = 'TikTok'

        # Cache the result
        _metadata_cache.put(url, result)
        return result

    except Exception as e:
        error_code, raw_msg = _classify_error(e)
        return _error_response(error_code, raw_msg)


@app.get("/formats")
def list_formats(request: Request, url: str = Query(...)):
    """List all available formats/qualities for a video URL.
    Returns video-only, audio-only, and combined formats with resolution,
    codec, file size estimates, and format notes."""
    if not url or not url.strip():
        return _error_response(ErrorCode.MISSING_PARAMS)
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return _error_response(ErrorCode.INVALID_URL)

    # Normalize URLs
    if "instagram.com" in url.lower():
        url = _normalize_instagram_url(url)
    elif "tiktok.com" in url.lower():
        url = _normalize_tiktok_url(url)

    try:
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'http_headers': _get_headers(url),
            'socket_timeout': 30,
        }

        _apply_auth_to_opts(ydl_opts, request, url)

        # Platform-specific extractor options
        if "dailymotion.com" in url:
            ydl_opts['force_generic_extractor'] = True
        elif "instagram.com" in url:
            ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
            ydl_opts['extractor_args']['instagram'] = [
                'player_client=android',
            ]
        elif "tiktok.com" in url or "vm.tiktok.com" in url:
            ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
            ydl_opts['extractor_args']['tiktok'] = [
                'player_client=android',
            ]

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)

        if info is None:
            return _error_response(ErrorCode.EXTRACTION_FAILED, "Could not extract info")

        title = info.get('title', 'Video')
        thumbnail = info.get('thumbnail')
        duration = info.get('duration')

        raw_formats = info.get('formats', [])
        if not raw_formats:
            return _error_response(ErrorCode.NO_FORMATS, "No formats found")

        # Build deduplicated format list, prioritizing combined formats
        formats = []
        seen_keys = set()

        for f in raw_formats:
            format_id = f.get('format_id', '')
            ext = f.get('ext', '')
            if not format_id or not ext:
                continue

            height = f.get('height')
            width = f.get('width')
            vcodec = f.get('vcodec', 'none')
            acodec = f.get('acodec', 'none')
            has_video = vcodec != 'none' and vcodec is not None
            has_audio = acodec != 'none' and acodec is not None
            filesize = f.get('filesize') or f.get('filesize_approx')
            tbr = f.get('tbr')
            vbr = f.get('vbr')
            abr = f.get('abr')
            fps = f.get('fps')
            format_note = f.get('format_note', '')

            # Skip duplicates with same quality+codec combo
            if has_video and has_audio:
                key = f"combined_{height}_{ext}_{vcodec}_{acodec}"
            elif has_video:
                key = f"video_{height}_{ext}_{vcodec}"
            elif has_audio:
                key = f"audio_{ext}_{acodec}_{tbr}"
            else:
                continue

            if key in seen_keys:
                continue
            seen_keys.add(key)

            # Build resolution label
            if has_video and height:
                resolution = f"{height}p"
                if fps and fps > 30:
                    resolution += f" {int(fps)}fps"
            elif has_audio and not has_video:
                resolution = "Audio only"
            else:
                resolution = "Unknown"

            # Build format label
            if has_video and has_audio:
                format_type = "video+audio"
            elif has_video:
                format_type = "video"
            elif has_audio:
                format_type = "audio"
            else:
                continue

            # Estimate file size from tbr if not available
            estimated_size = None
            if filesize:
                estimated_size = filesize
            elif tbr and duration:
                estimated_size = int(tbr * 1024 / 8 * duration)

            # Build yt-dlp format string for this option
            if has_video and has_audio:
                yt_format = format_id
            elif has_video:
                yt_format = f"{format_id}+bestaudio/best"
            elif has_audio:
                yt_format = format_id

            formats.append({
                'format_id': format_id,
                'ext': ext,
                'resolution': resolution,
                'height': height,
                'width': width,
                'fps': fps,
                'format_type': format_type,
                'vcodec': vcodec if has_video else None,
                'acodec': acodec if has_audio else None,
                'filesize': estimated_size,
                'tbr': tbr,
                'vbr': vbr,
                'abr': abr,
                'format_note': format_note,
                'yt_format': yt_format,
            })

        # Sort: combined first (by height desc), then video-only, then audio-only (by tbr desc)
        def _sort_key(f):
            type_order = {'video+audio': 0, 'video': 1, 'audio': 2}
            return (
                type_order.get(f['format_type'], 3),
                -(f.get('height') or 0),
                -(f.get('tbr') or 0),
            )

        formats.sort(key=_sort_key)

        return {
            'title': title,
            'thumbnail': thumbnail,
            'duration': duration,
            'formats': formats,
        }

    except Exception as e:
        error_code, raw_msg = _classify_error(e)
        return _error_response(error_code, raw_msg)


@app.get("/download")
def download_video(
    request: Request,
    url: str = Query(...),
    format_id: Optional[str] = Query(None),
    filename_template: Optional[str] = Query(None),
    subtitle_lang: Optional[str] = Query(None),
    subtitle_format: Optional[str] = Query(None),
    embed_subtitles: bool = Query(False),
):
    if not url or not url.strip():
        return _error_response(ErrorCode.MISSING_PARAMS)
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return _error_response(ErrorCode.INVALID_URL)

    # Normalize URLs
    if "instagram.com" in url.lower():
        url = _normalize_instagram_url(url)
    elif "tiktok.com" in url.lower():
        url = _normalize_tiktok_url(url)

    try:
        # Custom download for TikTok/Instagram using direct URL
        is_tiktok = "tiktok.com" in url.lower() or "vm.tiktok.com" in url.lower()
        is_instagram = "instagram.com" in url.lower()

        if is_tiktok or is_instagram:
            extracted = None
            if is_tiktok:
                extracted = _extract_tiktok(url)
            elif is_instagram:
                extracted = _extract_instagram(url)

            if extracted and extracted.get('video_url'):
                import requests as _req
                video_url = extracted['video_url']
                title = extracted.get('title', 'video')
                safe_name = _sanitize_filename(title, max_length=150)
                filename = f"{safe_name}.mp4"

                stream_resp = _req.get(video_url, stream=True, timeout=30, headers={
                    'User-Agent': 'Mozilla/5.0 (Linux; Android 13) Chrome/115.0.0.0 Mobile',
                    'Referer': 'https://www.tiktok.com/' if is_tiktok else 'https://www.instagram.com/',
                })
                stream_resp.raise_for_status()

                return StreamingResponse(
                    _stream_from_requests(stream_resp),
                    media_type='video/mp4',
                    headers={
                        'Content-Disposition': _build_content_disposition(filename),
                        'X-Accel-Buffering': 'no',
                    },
                )

        if not subtitle_lang and not embed_subtitles:
            direct_response = _direct_stream_response(
                url,
                request=request,
                format_id=format_id,
                filename_template=filename_template,
            )
            if direct_response is not None:
                return direct_response
        return _download_with_retry(
            url,
            request=request,
            format_id=format_id,
            filename_template=filename_template,
            subtitle_lang=subtitle_lang,
            subtitle_format=subtitle_format,
            embed_subtitles=embed_subtitles,
        )
    except Exception as e:
        error_code, raw_msg = _classify_error(e)
        return _error_response(error_code, raw_msg)


@_retry_with_backoff(max_retries=2, base_delay=1.0, max_delay=8.0)
def _download_with_retry(
    url: str,
    request: Request = None,
    format_id: Optional[str] = None,
    filename_template: Optional[str] = None,
    subtitle_lang: Optional[str] = None,
    subtitle_format: Optional[str] = None,
    embed_subtitles: bool = False,
) -> FileResponse:
    # Determine the format string and output extension
    if format_id:
        is_audio_only = 'audio' in format_id.lower() or format_id.startswith('a')
        if is_audio_only:
            ext = 'mp3' if 'mp3' in format_id.lower() else 'm4a'
            fmt_string = format_id
            merge_format = ext
        else:
            ext = 'mp4'
            fmt_string = f"{format_id}+bestaudio/{format_id}/best"
            merge_format = 'mp4'
    else:
        ext = 'mp4'
        fmt_string = 'bestvideo+bestaudio/best'
        merge_format = 'mp4'

    # Extract metadata first for filename template resolution
    template = filename_template or DEFAULT_FILENAME_TEMPLATE
    info = None
    try:
        probe_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'http_headers': _get_headers(url),
            'socket_timeout': 15,
        }
        if request:
            _apply_auth_to_opts(probe_opts, request, url)
        # Platform-specific extractor options
        if "dailymotion.com" in url:
            probe_opts['force_generic_extractor'] = True
        elif "instagram.com" in url:
            probe_opts['extractor_args'] = probe_opts.get('extractor_args', {})
            probe_opts['extractor_args']['instagram'] = [
                'player_client=android',
            ]
        elif "tiktok.com" in url or "vm.tiktok.com" in url:
            probe_opts['extractor_args'] = probe_opts.get('extractor_args', {})
            probe_opts['extractor_args']['tiktok'] = [
                'player_client=android',
            ]
        with yt_dlp.YoutubeDL(probe_opts) as ydl:
            info = ydl.extract_info(url, download=False)
    except Exception:
        pass  # Non-fatal: fallback to default filename

    # Resolve filename from template
    if info:
        # Determine quality label for template
        quality_label = None
        if format_id and info.get('formats'):
            for f in info['formats']:
                if f.get('format_id') == format_id:
                    height = f.get('height')
                    if height:
                        quality_label = f"{height}p"
                    break
        base_name = _resolve_filename_template(
            template, info, url,
            format_id=format_id,
            ext=ext,
            quality_label=quality_label,
        )
    else:
        base_name = f"video_{int(time.time())}"

    filename = f"{base_name}.{ext}"
    output_path = os.path.join(OUTPUT_DIR, filename)

    # Ensure unique filename — append counter if file exists
    counter = 1
    original_output = output_path
    while os.path.exists(output_path):
        filename = f"{base_name}_{counter}.{ext}"
        output_path = os.path.join(OUTPUT_DIR, filename)
        counter += 1

    ydl_opts = {
        'outtmpl': output_path,
        'format': fmt_string,
        'merge_output_format': merge_format,
        'ffmpeg_location': '/usr/bin/ffmpeg',
        'noplaylist': True,
        'quiet': True,
        'postprocessors': [{
            'key': 'FFmpegVideoConvertor',
            'preferedformat': merge_format,
        }],
        'extractor_args': {
            'youtube': ['player_client=android'],
        },
        'mark_watched': False,
        'http_headers': _get_headers(url),
        'socket_timeout': 60,
        'retries': 3,
    }

    # Add platform-specific extractor options
    if "instagram.com" in url:
        ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
        ydl_opts['extractor_args']['instagram'] = [
            'player_client=android',
        ]
    elif "tiktok.com" in url or "vm.tiktok.com" in url:
        ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
        ydl_opts['extractor_args']['tiktok'] = [
            'player_client=android',
        ]

    # Subtitle embedding: download subtitles and embed in MP4 via FFmpeg
    subtitle_file = None
    if subtitle_lang and embed_subtitles and ext == 'mp4':
        try:
            sub_lang = subtitle_lang.split(',')[0]  # Use first language if multiple
            sub_format = subtitle_format or 'srt'

            sub_info_opts = {
                'quiet': True,
                'no_warnings': True,
                'skip_download': True,
                'http_headers': _get_headers(url),
                'socket_timeout': 30,
            }
            if request:
                _apply_auth_to_opts(sub_info_opts, request, url)

            with yt_dlp.YoutubeDL(sub_info_opts) as sub_ydl:
                sub_info = sub_ydl.extract_info(url, download=False)

            if sub_info:
                subtitle_url = None
                # Try manual subs first, then auto
                for sub_dict_key in ('subtitles', 'automatic_captions'):
                    subs = sub_info.get(sub_dict_key, {})
                    lang_subs = subs.get(sub_lang, [])
                    for s in lang_subs:
                        if s.get('ext') == 'vtt':
                            subtitle_url = s.get('url')
                            break
                    if not subtitle_url and lang_subs:
                        subtitle_url = lang_subs[0].get('url')
                    if subtitle_url:
                        break

                if subtitle_url:
                    # Download subtitle content
                    sub_req = urllib.request.Request(
                        subtitle_url,
                        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
                    )
                    with urllib.request.urlopen(sub_req, timeout=15) as sub_resp:
                        raw_sub = sub_resp.read().decode('utf-8')

                    # Convert to SRT for FFmpeg embedding compatibility
                    if raw_sub.strip().startswith('WEBVTT'):
                        sub_content = _convert_vtt_to_srt(raw_sub)
                    else:
                        sub_content = raw_sub

                    # Save subtitle to temp file
                    subtitle_file = os.path.join(OUTPUT_DIR, f"{base_name}.{sub_lang}.srt")
                    with open(subtitle_file, 'w', encoding='utf-8') as sf:
                        sf.write(sub_content)

        except Exception as e:
            logger.warning(f"Failed to fetch subtitles for embedding: {e}")
            subtitle_file = None

    if "dailymotion.com" in url:
        ydl_opts['force_generic_extractor'] = True

    if request:
        _apply_auth_to_opts(ydl_opts, request, url)

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([url])

    # Embed subtitles into MP4 if subtitle file was downloaded
    if subtitle_file and os.path.exists(subtitle_file) and os.path.exists(output_path):
        try:
            import subprocess
            embedded_output = os.path.join(OUTPUT_DIR, f"{base_name}_embedded.{ext}")
            cmd = [
                '/usr/bin/ffmpeg', '-i', output_path,
                '-i', subtitle_file,
                '-c', 'copy',
                '-c:s', 'mov_text',
                '-metadata:s:s:0', f'language={sub_lang}',
                embedded_output,
            ]
            result = subprocess.run(cmd, capture_output=True, timeout=120)
            if result.returncode == 0 and os.path.exists(embedded_output):
                # Replace original with embedded version
                os.remove(output_path)
                os.rename(embedded_output, output_path)
                logger.info(f"Subtitles embedded successfully for: {filename}")
            else:
                logger.warning(f"FFmpeg subtitle embedding failed: {result.stderr.decode()[:200]}")
            # Clean up temp subtitle file
            if os.path.exists(subtitle_file):
                os.remove(subtitle_file)
        except Exception as e:
            logger.warning(f"Subtitle embedding error: {e}")
            # Clean up temp files
            if subtitle_file and os.path.exists(subtitle_file):
                os.remove(subtitle_file)
            embedded_output = os.path.join(OUTPUT_DIR, f"{base_name}_embedded.{ext}")
            if os.path.exists(embedded_output):
                os.remove(embedded_output)

    media_type = 'audio/mpeg' if ext == 'mp3' else 'video/mp4'
    return FileResponse(
        path=output_path,
        media_type=media_type,
        headers={'Content-Disposition': _build_content_disposition(filename)},
    )


@app.get("/download-index")
def download_video_by_index(
    request: Request,
    url: str = Query(...),
    index: int = Query(...),
    format_id: Optional[str] = Query(None),
    filename_template: Optional[str] = Query(None),
):
    """Download a specific video from a media group by its index position."""
    if not url or not url.strip():
        return _error_response(ErrorCode.MISSING_PARAMS)
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return _error_response(ErrorCode.INVALID_URL)

    # Normalize URLs
    if "instagram.com" in url.lower():
        url = _normalize_instagram_url(url)
    elif "tiktok.com" in url.lower():
        url = _normalize_tiktok_url(url)

    try:
        return _download_index_with_retry(
            url, index,
            request=request,
            format_id=format_id,
            filename_template=filename_template,
        )
    except Exception as e:
        error_code, raw_msg = _classify_error(e)
        return _error_response(error_code, raw_msg)


@_retry_with_backoff(max_retries=2, base_delay=1.0, max_delay=8.0)
def _download_index_with_retry(
    url: str,
    index: int,
    request: Request = None,
    format_id: Optional[str] = None,
    filename_template: Optional[str] = None,
) -> FileResponse:
    # Determine format and extension
    if format_id:
        ext = 'mp4'
        fmt_string = f"{format_id}+bestaudio/{format_id}/best"
        merge_format = 'mp4'
    else:
        ext = 'mp4'
        fmt_string = 'bestvideo+bestaudio/best'
        merge_format = 'mp4'

    # Extract metadata for filename template
    template = filename_template or DEFAULT_FILENAME_TEMPLATE
    info = None
    try:
        probe_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'http_headers': _get_headers(url),
            'socket_timeout': 15,
            'playlist_items': str(index + 1),
        }
        if request:
            _apply_auth_to_opts(probe_opts, request, url)
        # Platform-specific extractor options
        if "dailymotion.com" in url:
            probe_opts['force_generic_extractor'] = True
        elif "instagram.com" in url:
            probe_opts['extractor_args'] = probe_opts.get('extractor_args', {})
            probe_opts['extractor_args']['instagram'] = [
                'player_client=android',
            ]
        elif "tiktok.com" in url or "vm.tiktok.com" in url:
            probe_opts['extractor_args'] = probe_opts.get('extractor_args', {})
            probe_opts['extractor_args']['tiktok'] = [
                'player_client=android',
            ]
        with yt_dlp.YoutubeDL(probe_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            # Get the specific entry from playlist
            if info and info.get('entries'):
                entries = [e for e in info['entries'] if e is not None]
                if entries:
                    info = entries[0]
    except Exception:
        pass

    # Resolve filename
    if info:
        quality_label = None
        if format_id and info.get('formats'):
            for f in info['formats']:
                if f.get('format_id') == format_id:
                    height = f.get('height')
                    if height:
                        quality_label = f"{height}p"
                    break
        base_name = _resolve_filename_template(
            template, info, url,
            format_id=format_id,
            ext=ext,
            quality_label=quality_label,
            index=index,
        )
    else:
        base_name = f"video_{int(time.time())}_{index}"

    filename = f"{base_name}.{ext}"
    output_path = os.path.join(OUTPUT_DIR, filename)

    # Ensure unique filename
    counter = 1
    while os.path.exists(output_path):
        filename = f"{base_name}_{counter}.{ext}"
        output_path = os.path.join(OUTPUT_DIR, filename)
        counter += 1

    ydl_opts = {
        'outtmpl': output_path,
        'format': fmt_string,
        'merge_output_format': merge_format,
        'ffmpeg_location': '/usr/bin/ffmpeg',
        'quiet': True,
        'postprocessors': [{
            'key': 'FFmpegVideoConvertor',
            'preferedformat': merge_format,
        }],
        'extractor_args': {
            'youtube': ['player_client=android'],
        },
        'mark_watched': False,
        'http_headers': _get_headers(url),
        'playlist_items': str(index + 1),
        'socket_timeout': 60,
        'retries': 3,
    }

    # Platform-specific options
    if "dailymotion.com" in url:
        ydl_opts['force_generic_extractor'] = True
    elif "instagram.com" in url:
        ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
        ydl_opts['extractor_args']['instagram'] = [
            'player_client=android',
        ]
    elif "tiktok.com" in url or "vm.tiktok.com" in url:
        ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
        ydl_opts['extractor_args']['tiktok'] = [
            'player_client=android',
        ]

    if request:
        _apply_auth_to_opts(ydl_opts, request, url)

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([url])

    media_type = 'audio/mpeg' if ext == 'mp3' else 'video/mp4'
    return FileResponse(
        path=output_path,
        media_type=media_type,
        headers={'Content-Disposition': _build_content_disposition(filename)},
    )


def _run_batch_download(job_id: str, url: str, indices: list[int], max_concurrent: int = 1, filename_template: str | None = None):
    """Background worker to download multiple videos from a group.
    Supports concurrent downloads with per-item retry and exponential backoff."""
    job = _batch_jobs[job_id]
    template = filename_template or DEFAULT_FILENAME_TEMPLATE

    def _download_single(idx: int, item_num: int) -> dict:
        """Download a single video by index. Returns result dict."""
        ext = 'mp4'
        base_name = f"video_{int(time.time())}_{idx}"

        # Try to resolve template from metadata
        try:
            probe_opts = {
                'quiet': True,
                'no_warnings': True,
                'skip_download': True,
                'http_headers': _get_headers(url),
                'socket_timeout': 15,
                'playlist_items': str(idx + 1),
            }
            if "dailymotion.com" in url:
                probe_opts['force_generic_extractor'] = True
            with yt_dlp.YoutubeDL(probe_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                if info and info.get('entries'):
                    entries = [e for e in info['entries'] if e is not None]
                    if entries:
                        info = entries[0]
                if info:
                    base_name = _resolve_filename_template(
                        template, info, url, ext=ext, index=idx,
                    )
        except Exception:
            pass

        filename = f"{base_name}.{ext}"
        output_path = os.path.join(OUTPUT_DIR, filename)

        # Ensure unique filename
        counter = 1
        while os.path.exists(output_path):
            filename = f"{base_name}_{counter}.{ext}"
            output_path = os.path.join(OUTPUT_DIR, filename)
            counter += 1

        job['status'] = f'downloading_{idx}'

        last_error_code = None
        last_raw = None

        for attempt in range(3):
            try:
                ydl_opts = {
                    'outtmpl': output_path,
                    'format': 'bestvideo+bestaudio/best',
                    'merge_output_format': 'mp4',
                    'ffmpeg_location': '/usr/bin/ffmpeg',
                    'quiet': True,
                    'postprocessors': [{
                        'key': 'FFmpegVideoConvertor',
                        'preferedformat': 'mp4',
                    }],
                    'extractor_args': {
                        'youtube': ['player_client=android'],
                    },
                    'mark_watched': False,
                    'http_headers': _get_headers(url),
                    'playlist_items': str(idx + 1),
                    'socket_timeout': 60,
                    'retries': 3,
                }

                if "dailymotion.com" in url:
                    ydl_opts['force_generic_extractor'] = True
                elif "tiktok.com" in url or "vm.tiktok.com" in url:
                    ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
                    ydl_opts['extractor_args']['tiktok'] = [
                        'player_client=android',
                    ]

                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    ydl.download([url])

                return {'success': True, 'index': idx, 'filename': filename, 'path': output_path}
            except Exception as e:
                error_code, raw_msg = _classify_error(e)
                last_error_code = error_code
                last_raw = raw_msg
                if error_code not in RETRYABLE_ERRORS:
                    break
                if attempt < 2:
                    delay = min(1.0 * (2 ** attempt), 8.0)
                    logger.info(f"Batch item {idx} retry {attempt + 1}/3 after {delay:.1f}s: {raw_msg}")
                    time.sleep(delay)

        error_code = last_error_code or ErrorCode.DOWNLOAD_FAILED
        user_msg = _USER_MESSAGES.get(error_code, last_raw or "Download failed")
        return {
            'success': False,
            'index': idx,
            'error': user_msg,
            'error_code': error_code,
            'retryable': error_code in RETRYABLE_ERRORS,
        }

    if max_concurrent <= 1:
        # Sequential (original behavior)
        for i, idx in enumerate(indices):
            job['current'] = i
            job['current_index'] = idx
            result = _download_single(idx, i)
            if result['success']:
                job['completed'].append(result)
            else:
                job['failed'].append(result)
    else:
        # Concurrent downloads using thread pool
        with ThreadPoolExecutor(max_workers=max_concurrent) as executor:
            futures = {
                executor.submit(_download_single, idx, i): i
                for i, idx in enumerate(indices)
            }
            for future in as_completed(futures):
                i = futures[future]
                try:
                    result = future.result()
                    if result['success']:
                        job['completed'].append(result)
                    else:
                        job['failed'].append(result)
                    job['current'] = max(
                        job['current'],
                        len(job['completed']) + len(job['failed']),
                    )
                except Exception as e:
                    error_code, raw_msg = _classify_error(e)
                    user_msg = _USER_MESSAGES.get(error_code, str(e))
                    job['failed'].append({
                        'index': indices[i],
                        'error': user_msg,
                        'error_code': error_code,
                        'retryable': error_code in RETRYABLE_ERRORS,
                    })

    job['status'] = 'done'


@app.post("/download-batch")
def start_batch_download(
    url: str = Query(...),
    indices: str = Query(...),
    max_concurrent: int = Query(1, description="Max concurrent downloads (1-4)"),
    filename_template: Optional[str] = Query(None, description="Custom filename template"),
):
    """Start a batch download job. indices is a comma-separated list of video indices.
    max_concurrent controls parallel download threads (default 1 = sequential).
    filename_template applies a custom naming template to each downloaded file."""
    if not url or not url.strip():
        return _error_response(ErrorCode.MISSING_PARAMS)
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return _error_response(ErrorCode.INVALID_URL)

    try:
        idx_list = [int(i.strip()) for i in indices.split(',') if i.strip()]
    except ValueError:
        return _error_response(ErrorCode.INVALID_INDICES, "Invalid indices format. Use comma-separated integers.")

    if not idx_list:
        return _error_response(ErrorCode.INVALID_INDICES, "No indices provided")

    max_concurrent = max(1, min(4, max_concurrent))

    job_id = str(uuid.uuid4())
    _batch_jobs[job_id] = {
        'url': url,
        'indices': idx_list,
        'status': 'started',
        'current': 0,
        'current_index': idx_list[0],
        'completed': [],
        'failed': [],
        'max_concurrent': max_concurrent,
    }

    thread = threading.Thread(
        target=_run_batch_download,
        args=(job_id, url, idx_list, max_concurrent, filename_template),
        daemon=True,
    )
    thread.start()

    return {'job_id': job_id, 'total': len(idx_list), 'max_concurrent': max_concurrent}


@app.get("/batch-status")
def get_batch_status(job_id: str = Query(...)):
    """Get the status of a batch download job."""
    job = _batch_jobs.get(job_id)
    if not job:
        return _error_response(ErrorCode.JOB_NOT_FOUND)

    return {
        'job_id': job_id,
        'status': job['status'],
        'total': len(job['indices']),
        'current': job['current'] + 1 if job['status'] != 'done' else len(job['indices']),
        'current_index': job['current_index'],
        'completed': len(job['completed']),
        'failed': len(job['failed']),
        'completed_files': job['completed'],
        'failed_files': job['failed'],
    }


@app.get("/batch-download-file")
def download_batch_file(job_id: str = Query(...)):
    """Download all completed files from a batch job as a zip archive."""
    import zipfile
    import io

    job = _batch_jobs.get(job_id)
    if not job:
        return _error_response(ErrorCode.JOB_NOT_FOUND)

    if job['status'] != 'done':
        return _error_response(ErrorCode.JOB_NOT_COMPLETE)

    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for item in job['completed']:
            if os.path.exists(item['path']):
                zipf.write(item['path'], item['filename'])

    zip_buffer.seek(0)

    return StreamingResponse(
        iter([zip_buffer.getvalue()]),
        media_type='application/zip',
        headers={'Content-Disposition': f'attachment; filename="batch_{job_id[:8]}.zip"'},
    )


# --- Streaming download with speed tracking and throttling ---

def _throttled_file_stream(file_path: str, download_id: str, chunk_size: int = 65536):
    """Stream a file with optional speed throttling and progress tracking."""
    try:
        file_size = os.path.getsize(file_path)
        with _active_downloads_lock:
            _active_downloads[download_id]['total_bytes'] = file_size
            _active_downloads[download_id]['started_at'] = time.time()

        bytes_sent = 0
        with open(file_path, 'rb') as f:
            while True:
                chunk = f.read(chunk_size)
                if not chunk:
                    break
                yield chunk
                bytes_sent += len(chunk)

                # Apply throttling if configured
                sleep_time = _speed_throttler.throttle(len(chunk))
                if sleep_time > 0:
                    time.sleep(sleep_time)

                # Update tracking
                with _active_downloads_lock:
                    _active_downloads[download_id]['bytes_sent'] = bytes_sent
                    elapsed = time.time() - _active_downloads[download_id]['started_at']
                    _active_downloads[download_id]['speed_bps'] = (
                        bytes_sent / elapsed if elapsed > 0 else 0
                    )

    except Exception as e:
        logger.error(f"Stream error for {download_id}: {e}")
    finally:
        with _active_downloads_lock:
            if download_id in _active_downloads:
                _active_downloads[download_id]['finished_at'] = time.time()
                _active_downloads[download_id]['status'] = 'completed'


@app.get("/download-stream")
def download_video_stream(
    request: Request,
    url: str = Query(...),
    filename_template: Optional[str] = Query(None),
):
    """Download a video with streaming response, speed tracking, and optional throttling.
    Returns the video file as a streaming response with X- headers for progress tracking."""
    if not url or not url.strip():
        return _error_response(ErrorCode.MISSING_PARAMS)
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return _error_response(ErrorCode.INVALID_URL)

    try:
        # Extract metadata for filename template
        template = filename_template or DEFAULT_FILENAME_TEMPLATE
        ext = 'mp4'
        base_name = f"video_{int(time.time())}"
        try:
            probe_opts = {
                'quiet': True,
                'no_warnings': True,
                'skip_download': True,
                'http_headers': _get_headers(url),
                'socket_timeout': 15,
            }
            if "dailymotion.com" in url:
                probe_opts['force_generic_extractor'] = True
            _apply_auth_to_opts(probe_opts, request, url)
            with yt_dlp.YoutubeDL(probe_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                if info:
                    base_name = _resolve_filename_template(template, info, url, ext=ext)
        except Exception:
            pass

        filename = f"{base_name}.{ext}"
        output_path = os.path.join(OUTPUT_DIR, filename)

        # Ensure unique filename
        counter = 1
        while os.path.exists(output_path):
            filename = f"{base_name}_{counter}.{ext}"
            output_path = os.path.join(OUTPUT_DIR, filename)
            counter += 1

        ydl_opts = {
            'outtmpl': output_path,
            'format': 'bestvideo+bestaudio/best',
            'merge_output_format': 'mp4',
            'ffmpeg_location': '/usr/bin/ffmpeg',
            'noplaylist': True,
            'quiet': True,
            'postprocessors': [{
                'key': 'FFmpegVideoConvertor',
                'preferedformat': 'mp4',
            }],
            'extractor_args': {
                'youtube': ['player_client=android'],
            },
            'mark_watched': False,
            'http_headers': _get_headers(url),
            'socket_timeout': 60,
            'retries': 3,
        }

        if "dailymotion.com" in url:
            ydl_opts['force_generic_extractor'] = True
        elif "tiktok.com" in url or "vm.tiktok.com" in url:
            ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
            ydl_opts['extractor_args']['tiktok'] = [
                'player_client=android',
            ]

        _apply_auth_to_opts(ydl_opts, request, url)

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])

        if not os.path.exists(output_path):
            return _error_response(ErrorCode.DOWNLOAD_FAILED, "Downloaded file not found")

        file_size = os.path.getsize(output_path)
        download_id = str(uuid.uuid4())

        with _active_downloads_lock:
            _active_downloads[download_id] = {
                'id': download_id,
                'url': url,
                'filename': filename,
                'total_bytes': file_size,
                'bytes_sent': 0,
                'speed_bps': 0,
                'started_at': None,
                'finished_at': None,
                'status': 'streaming',
            }

        return StreamingResponse(
            _throttled_file_stream(output_path, download_id),
            media_type='video/mp4',
            headers={
                'Content-Disposition': _build_content_disposition(filename),
                'Content-Length': str(file_size),
                'X-Download-Id': download_id,
                'X-File-Size': str(file_size),
            },
        )
    except Exception as e:
        error_code, raw_msg = _classify_error(e)
        return _error_response(error_code, raw_msg)


# --- Speed Throttle Control ---

@app.get("/throttle")
def get_throttle_settings():
    """Get current download speed throttle settings."""
    rate = _speed_throttler.rate
    return {
        'enabled': rate is not None and rate > 0,
        'rate_bytes_per_sec': rate,
        'rate_human': f"{rate / 1024 / 1024:.1f} MB/s" if rate and rate >= 1048576
            else f"{rate / 1024:.0f} KB/s" if rate and rate >= 1024
            else f"{rate} B/s" if rate else "unlimited",
    }


@app.post("/throttle")
def set_throttle_settings(rate_bytes_per_sec: Optional[int] = Query(None)):
    """Set download speed throttle. Set to null/0 to disable.
    Examples: 1048576 = 1 MB/s, 5242880 = 5 MB/s, 0 = unlimited."""
    if rate_bytes_per_sec is None or rate_bytes_per_sec <= 0:
        _speed_throttler.rate = None
        return {'status': 'throttle_disabled', 'rate_bytes_per_sec': None}
    else:
        _speed_throttler.rate = rate_bytes_per_sec
        return {
            'status': 'throttle_set',
            'rate_bytes_per_sec': rate_bytes_per_sec,
        }


# --- Cache Stats ---

@app.get("/cache-stats")
def get_cache_stats():
    """Get metadata cache statistics."""
    return {
        'cache_size': _metadata_cache.size,
        'max_size': 200,
        'ttl_seconds': 1800,
    }


@app.post("/cache-clear")
def clear_cache():
    """Clear all cached metadata."""
    global _metadata_cache
    old_size = _metadata_cache.size
    _metadata_cache = MetadataCache(max_size=200, ttl_seconds=1800)
    return {'status': 'cache_cleared', 'previous_size': old_size}


# --- Thumbnail Proxy with Caching ---

_THUMBNAIL_DIR = "/tmp/thumbnails"
os.makedirs(_THUMBNAIL_DIR, exist_ok=True)
_thumbnail_cache_lock = threading.Lock()


def _thumbnail_cache_path(url: str, size: int) -> str:
    """Generate a deterministic file path for a cached thumbnail."""
    key = hashlib.sha256(f"{url}:{size}".encode()).hexdigest()[:24]
    return os.path.join(_THUMBNAIL_DIR, f"{key}.jpg")


@app.get("/thumbnail")
def get_thumbnail(
    request: Request,
    url: str = Query(..., description="Thumbnail URL to proxy"),
    size: int = Query(320, description="Target width in pixels (max 640)"),
):
    """Proxy and optionally resize a thumbnail image.
    Caches thumbnails locally to reduce bandwidth on repeat requests.
    Falls back to platform-specific thumbnail URLs if the direct URL fails."""
    if not url or not url.strip():
        return _error_response(ErrorCode.MISSING_PARAMS)

    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return _error_response(ErrorCode.INVALID_URL)

    size = max(64, min(640, size))

    cache_path = _thumbnail_cache_path(url, size)

    # Check cache first
    with _thumbnail_cache_lock:
        if os.path.exists(cache_path):
            try:
                stat = os.stat(cache_path)
                # Cache thumbnails for 24 hours
                if time.time() - stat.st_mtime < 86400:
                    return FileResponse(
                        cache_path,
                        media_type='image/jpeg',
                        headers={
                            'Cache-Control': 'public, max-age=86400',
                            'X-Cache': 'HIT',
                        },
                    )
                else:
                    os.remove(cache_path)
            except OSError:
                pass

    # Fetch the thumbnail
    try:
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'image/*,*/*',
        })
        with urllib.request.urlopen(req, timeout=10) as resp:
            image_data = resp.read()

        if not image_data or len(image_data) < 100:
            return _error_response(ErrorCode.DOWNLOAD_FAILED, "Empty thumbnail response")

        # Try to resize using PIL/Pillow if available, otherwise serve original
        try:
            from PIL import Image
            img = Image.open(io.BytesIO(image_data))
            img = img.convert('RGB')

            # Resize maintaining aspect ratio
            w, h = img.size
            if w > size:
                new_h = int(h * size / w)
                img = img.resize((size, new_h), Image.LANCZOS)

            buf = io.BytesIO()
            img.save(buf, format='JPEG', quality=80)
            image_data = buf.getvalue()
        except ImportError:
            logger.debug("Pillow not available, serving original thumbnail")
        except Exception as e:
            logger.debug(f"Thumbnail resize failed, serving original: {e}")

        # Cache the result
        try:
            with _thumbnail_cache_lock:
                with open(cache_path, 'wb') as f:
                    f.write(image_data)
        except OSError as e:
            logger.warning(f"Failed to cache thumbnail: {e}")

        return Response(
            content=image_data,
            media_type='image/jpeg',
            headers={
                'Cache-Control': 'public, max-age=86400',
                'X-Cache': 'MISS',
            },
        )

    except Exception as e:
        error_code, raw_msg = _classify_error(e)
        return _error_response(error_code, raw_msg)


# --- Active Download Stats ---

@app.get("/download-stats")
def get_download_stats(download_id: Optional[str] = Query(None)):
    """Get real-time download speed and progress for active downloads.
    If download_id is provided, returns stats for that specific download."""
    with _active_downloads_lock:
        if download_id:
            dl = _active_downloads.get(download_id)
            if not dl:
                return _error_response(ErrorCode.JOB_NOT_FOUND)
            return dl
        return {
            'active_count': len([
                d for d in _active_downloads.values()
                if d['status'] == 'streaming'
            ]),
            'downloads': list(_active_downloads.values()),
        }


# --- Subtitle Support ---

def _convert_vtt_to_srt(vtt_content: str) -> str:
    """Convert WebVTT subtitle content to SRT format."""
    lines = vtt_content.strip().split('\n')
    srt_lines = []
    index = 1
    i = 0

    # Skip WEBVTT header and any metadata
    while i < len(lines) and not re.match(r'\d{2}:\d{2}', lines[i]):
        i += 1

    while i < len(lines):
        line = lines[i].strip()

        # Look for timestamp line
        if '-->' in line:
            # Convert VTT timestamp (HH:MM:SS.mmm) to SRT (HH:MM:SS,mmm)
            timestamp_line = line.replace('.', ',')
            srt_lines.append(str(index))
            srt_lines.append(timestamp_line)
            index += 1
            i += 1

            # Collect subtitle text until next blank line or timestamp
            text_lines = []
            while i < len(lines):
                sub_line = lines[i].strip()
                if not sub_line or '-->' in sub_line:
                    break
                # Strip VTT formatting tags
                clean = re.sub(r'<[^>]+>', '', sub_line)
                if clean:
                    text_lines.append(clean)
                i += 1

            srt_lines.extend(text_lines)
            srt_lines.append('')  # Blank line separator
        else:
            i += 1

    return '\n'.join(srt_lines)


def _convert_vtt_to_ass(vtt_content: str, title: str = "Subtitles") -> str:
    """Convert WebVTT subtitle content to ASS/SSA format."""
    lines = vtt_content.strip().split('\n')

    # Parse subtitle entries
    entries = []
    i = 0
    while i < len(lines) and not re.match(r'\d{2}:\d{2}', lines[i]):
        i += 1

    while i < len(lines):
        line = lines[i].strip()
        if '-->' in line:
            parts = line.split('-->')
            start_str = parts[0].strip().split(' ')[0]
            end_str = parts[1].strip().split(' ')[0]
            i += 1

            text_lines = []
            while i < len(lines):
                sub_line = lines[i].strip()
                if not sub_line or '-->' in sub_line:
                    break
                clean = re.sub(r'<[^>]+>', '', sub_line)
                if clean:
                    text_lines.append(clean)
                i += 1

            if text_lines:
                text = '\\N'.join(text_lines)
                entries.append((start_str, end_str, text))
        else:
            i += 1

    def _vtt_to_ass_ts(ts: str) -> str:
        """Convert VTT timestamp (HH:MM:SS.mmm) to ASS (H:MM:SS.cc)."""
        ts = ts.strip()
        # Handle MM:SS.mmm or HH:MM:SS.mmm
        parts = ts.split(':')
        if len(parts) == 2:
            h, rest = '0', ts
        else:
            h, rest = parts[0], ':'.join(parts[1:])
        m_and_s = rest.split(':')
        m = m_and_s[0]
        s_parts = m_and_s[1].split('.')
        s = s_parts[0]
        ms = s_parts[1] if len(s_parts) > 1 else '000'
        cs = str(int(ms[:2])).zfill(2) if len(ms) >= 2 else '00'
        return f"{h}:{m}:{s}.{cs}"

    ass_header = f"""[Script Info]
Title: {title}
ScriptType: v4.00+
WrapStyle: 0
PlayResX: 384
PlayResY: 288
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,16,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,2,1,2,10,10,10,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    ass_events = []
    for start, end, text in entries:
        ass_start = _vtt_to_ass_ts(start)
        ass_end = _vtt_to_ass_ts(end)
        ass_events.append(f"Dialogue: 0,{ass_start},{ass_end},Default,,0,0,0,,{text}")

    return ass_header + '\n'.join(ass_events) + '\n'


def _format_vtt_timestamp(hours: int, minutes: int, seconds: int, ms: int) -> str:
    """Format a timestamp for VTT format: HH:MM:SS.mmm"""
    return f"{hours:02d}:{minutes:02d}:{seconds:02d}.{ms:03d}"


def _convert_srt_to_vtt(srt_content: str) -> str:
    """Convert SRT subtitle content to WebVTT format."""
    lines = srt_content.strip().split('\n')
    vtt_lines = ['WEBVTT\n']

    i = 0
    while i < len(lines):
        line = lines[i].strip()
        # Look for timestamp line
        if '-->' in line:
            # Convert SRT timestamp (HH:MM:SS,mmm) to VTT (HH:MM:SS.mmm)
            timestamp_line = line.replace(',', '.')
            vtt_lines.append(timestamp_line)
            i += 1

            # Collect subtitle text
            while i < len(lines):
                sub_line = lines[i].strip()
                if not sub_line:
                    break
                vtt_lines.append(sub_line)
                i += 1
            vtt_lines.append('')
        else:
            i += 1

    return '\n'.join(vtt_lines)


@app.get("/subtitles")
def list_subtitles(request: Request, url: str = Query(...)):
    """List available subtitles/captions for a video.
    Returns available languages with their names and automatic/generated status."""
    if not url or not url.strip():
        return _error_response(ErrorCode.MISSING_PARAMS)
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return _error_response(ErrorCode.INVALID_URL)

    try:
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'listsubtitles': True,
            'http_headers': _get_headers(url),
            'socket_timeout': 30,
        }

        _apply_auth_to_opts(ydl_opts, request, url)

        if "dailymotion.com" in url:
            ydl_opts['force_generic_extractor'] = True
        elif "tiktok.com" in url or "vm.tiktok.com" in url:
            ydl_opts['extractor_args'] = ydl_opts.get('extractor_args', {})
            ydl_opts['extractor_args']['tiktok'] = [
                'player_client=android',
            ]

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)

        if info is None:
            return _error_response(ErrorCode.EXTRACTION_FAILED, "Could not extract info")

        subtitles = []
        seen_langs = set()

        # Manual subtitles (user-uploaded or creator-provided)
        manual_subs = info.get('subtitles', {})
        for lang_code, sub_list in manual_subs.items():
            if not sub_list:
                continue
            for sub in sub_list:
                key = f"{lang_code}_{sub.get('ext', 'vtt')}"
                if key in seen_langs:
                    continue
                seen_langs.add(key)
                subtitles.append({
                    'language': lang_code,
                    'name': sub.get('name', lang_code),
                    'ext': sub.get('ext', 'vtt'),
                    'url': sub.get('url', ''),
                    'auto_generated': False,
                })

        # Automatic captions (auto-translated)
        auto_subs = info.get('automatic_captions', {})
        for lang_code, sub_list in auto_subs.items():
            if not sub_list:
                continue
            for sub in sub_list:
                key = f"{lang_code}_{sub.get('ext', 'vtt')}_auto"
                if key in seen_langs:
                    continue
                seen_langs.add(key)
                subtitles.append({
                    'language': lang_code,
                    'name': sub.get('name', f"{lang_code} (auto-generated)"),
                    'ext': sub.get('ext', 'vtt'),
                    'url': sub.get('url', ''),
                    'auto_generated': True,
                })

        # Determine which languages are available (deduplicated)
        available_languages = sorted(set(
            s['language'] for s in subtitles
        ), key=lambda x: (x != 'en', x))

        return {
            'subtitles': subtitles,
            'available_languages': available_languages,
            'count': len(subtitles),
        }

    except Exception as e:
        error_code, raw_msg = _classify_error(e)
        return _error_response(error_code, raw_msg)


@app.get("/download-subtitles")
def download_subtitles(
    request: Request,
    url: str = Query(...),
    lang: str = Query('en'),
    format: str = Query('srt'),
    auto_generated: bool = Query(False),
):
    """Download subtitles for a video in the specified format.
    Supported formats: srt, vtt, ass.
    Uses yt-dlp to extract subtitles and converts to requested format."""
    if not url or not url.strip():
        return _error_response(ErrorCode.MISSING_PARAMS)
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return _error_response(ErrorCode.INVALID_URL)

    format = format.lower().strip()
    if format not in ('srt', 'vtt', 'ass'):
        return _error_response(ErrorCode.INVALID_URL, f"Unsupported subtitle format: {format}. Use srt, vtt, or ass.")

    try:
        # Use yt-dlp to download subtitles
        sub_langs = lang
        if auto_generated:
            sub_langs = f"{lang}"

        sub_opts = {
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'writesubtitles': not auto_generated,
            'writeautomaticsub': auto_generated,
            'subtitleslangs': [lang],
            'subtitlesformat': 'vtt',  # Always get VTT first, then convert
            'http_headers': _get_headers(url),
            'socket_timeout': 30,
        }

        _apply_auth_to_opts(sub_opts, request, url)

        if "dailymotion.com" in url:
            sub_opts['force_generic_extractor'] = True
        elif "tiktok.com" in url or "vm.tiktok.com" in url:
            sub_opts['extractor_args'] = sub_opts.get('extractor_args', {})
            sub_opts['extractor_args']['tiktok'] = [
                'player_client=android',
            ]

        # Use yt-dlp to extract subtitle URLs
        with yt_dlp.YoutubeDL(sub_opts) as ydl:
            info = ydl.extract_info(url, download=False)

        if info is None:
            return _error_response(ErrorCode.EXTRACTION_FAILED, "Could not extract video info")

        # Find the subtitle URL from the info dict
        subtitle_url = None
        if auto_generated:
            auto_subs = info.get('automatic_captions', {})
            lang_subs = auto_subs.get(lang, [])
            # Prefer vtt format
            for sub in lang_subs:
                if sub.get('ext') == 'vtt':
                    subtitle_url = sub.get('url')
                    break
            if not subtitle_url and lang_subs:
                subtitle_url = lang_subs[0].get('url')
        else:
            manual_subs = info.get('subtitles', {})
            lang_subs = manual_subs.get(lang, [])
            for sub in lang_subs:
                if sub.get('ext') == 'vtt':
                    subtitle_url = sub.get('url')
                    break
            if not subtitle_url and lang_subs:
                subtitle_url = lang_subs[0].get('url')

        if not subtitle_url:
            return _error_response(
                ErrorCode.NO_FORMATS,
                f"No {'auto-generated ' if auto_generated else ''}subtitles found for language '{lang}'"
            )

        # Download the subtitle content
        req = urllib.request.Request(
            subtitle_url,
            headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept-Language': 'en-US,en;q=0.9',
            }
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            raw_content = resp.read().decode('utf-8')

        # Convert to requested format
        title = info.get('title', 'video')
        if format == 'srt':
            if raw_content.strip().startswith('WEBVTT'):
                content = _convert_vtt_to_srt(raw_content)
            else:
                content = raw_content
            media_type = 'text/plain'
            ext = 'srt'
        elif format == 'vtt':
            if raw_content.strip().startswith('WEBVTT'):
                content = raw_content
            else:
                content = _convert_srt_to_vtt(raw_content)
            media_type = 'text/vtt'
            ext = 'vtt'
        elif format == 'ass':
            if raw_content.strip().startswith('WEBVTT'):
                content = _convert_vtt_to_ass(raw_content, title)
            else:
                # Convert SRT -> VTT -> ASS
                vtt = _convert_srt_to_vtt(raw_content)
                content = _convert_vtt_to_ass(vtt, title)
            media_type = 'text/plain'
            ext = 'ass'
        else:
            content = raw_content
            media_type = 'text/plain'
            ext = 'vtt'

        safe_title = _sanitize_filename(title, max_length=100)
        filename = f"{safe_title}.{lang}.{ext}"

        return Response(
            content=content.encode('utf-8'),
            media_type=media_type,
            headers={
                'Content-Disposition': _build_content_disposition(filename),
            },
        )

    except Exception as e:
        error_code, raw_msg = _classify_error(e)
        return _error_response(error_code, raw_msg)

