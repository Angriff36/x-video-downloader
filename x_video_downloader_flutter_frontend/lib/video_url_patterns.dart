/// Shared URL detection for clipboard sniffing, share-intents, and batch
/// import. The backend passes any URL to yt-dlp, so this list is only about
/// when to proactively offer a download — manual entry accepts anything.
final videoUrlPattern = RegExp(
  r'(https?://(?:'
  // Path-specific patterns for the big platforms (avoids false positives
  // like profile pages).
  r'(?:www\.)?(?:x\.com|twitter\.com)/\w+/status/\d+'
  r'|(?:www\.|m\.)?(?:youtube\.com/(?:watch\?v=|shorts/|embed/)|youtu\.be/)'
  r'|(?:www\.)?(?:instagram\.com/(?:reel|p|tv)/)'
  r'|(?:www\.|vm\.|vt\.)?(?:tiktok\.com/)'
  r'|(?:www\.|m\.)?(?:facebook\.com/(?:watch|reel|share|videos/)|fb\.watch/)'
  r'|(?:www\.)?(?:vimeo\.com/\d+)'
  r'|(?:www\.|old\.)?(?:reddit\.com/r/[^/]+/comments/|redd\.it/)'
  r'|(?:www\.)?(?:dailymotion\.com/video/)'
  // Domain-level patterns for the rest — copying a link from these sites
  // almost always means a media page.
  r'|(?:www\.|m\.)?(?:'
  r'douyin\.com'
  r'|espn\.com'
  r'|pinterest\.com/pin|pin\.it'
  r'|imdb\.com'
  r'|imgur\.com'
  r'|snapchat\.com'
  r'|likee\.video'
  r'|linkedin\.com/posts'
  r'|tumblr\.com'
  r'|t\.me'
  r'|bitchute\.com'
  r'|9gag\.com'
  r'|ok\.ru'
  r'|rumble\.com'
  r'|streamable\.com'
  r'|ted\.com/talks'
  r'|tv\.sohu\.com'
  r'|xvideos\.com'
  r'|xnxx\.com'
  r'|xiaohongshu\.com|xhslink\.com'
  r'|ixigua\.com'
  r'|weibo\.(?:com|cn)'
  r'|meipai\.com'
  r'|video\.sina\.com\.cn'
  r'|vk\.com|vkvideo\.ru'
  r'|bilibili\.com|b23\.tv'
  r'|soundcloud\.com'
  r'|mixcloud\.com'
  r'|zingmp3\.vn'
  r'|bandcamp\.com'
  r')/'
  r')[^\s<>"{}|\\^`\[\]]*)',
  caseSensitive: false,
);
