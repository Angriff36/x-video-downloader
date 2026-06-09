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

  /// Detect platform from URL.
  static String detectPlatform(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('youtube.com') || lower.contains('youtu.be')) {
      return 'YouTube';
    } else if (lower.contains('instagram.com')) {
      return 'Instagram';
    } else if (lower.contains('tiktok.com') || lower.contains('vm.tiktok')) {
      return 'TikTok';
    } else if (lower.contains('twitter.com') || lower.contains('x.com')) {
      return 'X/Twitter';
    } else if (lower.contains('vimeo.com')) {
      return 'Vimeo';
    } else if (lower.contains('dailymotion.com')) {
      return 'Dailymotion';
    } else if (lower.contains('facebook.com') || lower.contains('fb.watch')) {
      return 'Facebook';
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
