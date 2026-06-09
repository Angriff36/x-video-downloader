@echo off
echo ====================================
echo YouTube Playlist Batch Downloader
echo ====================================
echo.
echo Current progress:
cd /d "%~dp0"
for /f %%A in ('dir /b "*.mp4" 2^>nul ^| find /c /v ""') do set count=%%A
echo Downloaded: %count% out of 327 videos
echo.
echo Starting batch download (10 videos with 30s delays)...
echo Press Ctrl+C to stop
echo.

yt-dlp --cookies youtube_cookies.txt -f "bv*+ba/best[ext=mp4]/best" --merge-output-format mp4 -o "%%(playlist_index)s - %%(title)s.%%(ext)s" --ignore-errors --continue --no-overwrites --sleep-interval 30 --max-sleep-interval 40 --min-sleep-interval 20 --extractor-retries 5 --playlist-items 1-327 "https://www.youtube.com/watch?v=JjTjwtCLAVw&list=PLlwlx6JtpFj0PUS59Mf0uwdbwg3j_y9cJ"

echo.
echo Batch complete! Run this script again in 30-60 minutes to continue.
pause

