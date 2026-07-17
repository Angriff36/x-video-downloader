/// Represents a single download history entry stored in SQLite.
class DownloadRecord {
  final int? id;
  final String url;
  final String platform;
  final String title;
  final String filePath;
  final int fileSizeBytes;
  final String status; // 'completed', 'failed', 'deleted'
  final String? errorMessage;
  final DateTime downloadedAt;
  final String? thumbnailUrl;

  DownloadRecord({
    this.id,
    required this.url,
    required this.platform,
    required this.title,
    required this.filePath,
    required this.fileSizeBytes,
    required this.status,
    this.errorMessage,
    required this.downloadedAt,
    this.thumbnailUrl,
  });

  factory DownloadRecord.fromMap(Map<String, dynamic> map) {
    return DownloadRecord(
      id: map['id'] as int?,
      url: map['url'] as String,
      platform: map['platform'] as String,
      title: map['title'] as String,
      filePath: map['filePath'] as String,
      fileSizeBytes: map['fileSizeBytes'] as int,
      status: map['status'] as String,
      errorMessage: map['errorMessage'] as String?,
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(map['downloadedAt'] as int),
      thumbnailUrl: map['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'platform': platform,
      'title': title,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      'status': status,
      'errorMessage': errorMessage,
      'downloadedAt': downloadedAt.millisecondsSinceEpoch,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  /// Ordered domain-substring → platform label pairs.
  /// Order matters: keep more specific entries before generic ones
  /// (e.g. 'vm.tiktok' vs 'x.com' substring quirks).
  static const List<MapEntry<String, String>> _platformDomains = [
    MapEntry('youtube.com', 'YouTube'),
    MapEntry('youtu.be', 'YouTube'),
    MapEntry('instagram.com', 'Instagram'),
    MapEntry('tiktok.com', 'TikTok'),
    MapEntry('vm.tiktok', 'TikTok'),
    MapEntry('douyin.com', 'Douyin'),
    // Before x.com: 'xnxx.com' contains the substring 'x.com'.
    MapEntry('xnxx.com', 'XNXX'),
    MapEntry('twitter.com', 'X/Twitter'),
    MapEntry('x.com', 'X/Twitter'),
    MapEntry('vimeo.com', 'Vimeo'),
    MapEntry('dailymotion.com', 'Dailymotion'),
    MapEntry('facebook.com', 'Facebook'),
    MapEntry('fb.watch', 'Facebook'),
    MapEntry('reddit.com', 'Reddit'),
    MapEntry('redd.it', 'Reddit'),
    MapEntry('espn.com', 'ESPN'),
    MapEntry('pinterest.com', 'Pinterest'),
    MapEntry('pin.it', 'Pinterest'),
    MapEntry('imdb.com', 'IMDb'),
    MapEntry('imgur.com', 'Imgur'),
    MapEntry('snapchat.com', 'Snapchat'),
    MapEntry('likee.video', 'Likee'),
    MapEntry('linkedin.com', 'LinkedIn'),
    MapEntry('tumblr.com', 'Tumblr'),
    MapEntry('t.me', 'Telegram'),
    MapEntry('bitchute.com', 'BitChute'),
    MapEntry('9gag.com', '9GAG'),
    MapEntry('ok.ru', 'OK.ru'),
    MapEntry('rumble.com', 'Rumble'),
    MapEntry('streamable.com', 'Streamable'),
    MapEntry('ted.com', 'TED'),
    MapEntry('sohu.com', 'Sohu'),
    MapEntry('xvideos.com', 'XVideos'),
    MapEntry('xiaohongshu.com', 'Xiaohongshu'),
    MapEntry('xhslink.com', 'Xiaohongshu'),
    MapEntry('ixigua.com', 'Ixigua'),
    MapEntry('weibo.com', 'Weibo'),
    MapEntry('weibo.cn', 'Weibo'),
    MapEntry('meipai.com', 'Meipai'),
    MapEntry('sina.com.cn', 'Sina'),
    MapEntry('vk.com', 'VK'),
    MapEntry('vkvideo.ru', 'VK'),
    MapEntry('bilibili.com', 'Bilibili'),
    MapEntry('b23.tv', 'Bilibili'),
    MapEntry('soundcloud.com', 'SoundCloud'),
    MapEntry('mixcloud.com', 'Mixcloud'),
    MapEntry('zingmp3.vn', 'Zing MP3'),
    MapEntry('bandcamp.com', 'Bandcamp'),
  ];

  /// Detect platform from URL.
  static String detectPlatform(String url) {
    final lower = url.toLowerCase();
    for (final entry in _platformDomains) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return 'Other';
  }

  /// Format file size to human-readable string.
  String get fileSizeText {
    if (fileSizeBytes <= 0) return 'Unknown';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = fileSizeBytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
