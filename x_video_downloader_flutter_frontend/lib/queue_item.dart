/// Represents a single item in the download queue with full lifecycle state.
class QueueItem {
  final int? id;
  final String url;
  final String platform;
  final String title;
  final String? thumbnailUrl;

  // Download state
  QueueItemStatus status;
  double progress; // 0.0 to 1.0
  String? filePath;
  int fileSizeBytes;
  String? errorMessage;
  String? errorCode;
  bool retryable;

  // Retry tracking
  int retryCount;
  int maxRetries;

  // Concurrency control
  final int? videoIndex; // For media group items, the index in the group

  // Format selection
  final String? formatId; // yt-dlp format_id for quality selection
  final String? formatLabel; // Human-readable label for display (e.g. "1080p")

  // Subtitle options
  final String? subtitleLang; // Language code for subtitles (e.g. 'en')
  final String? subtitleFormat; // Subtitle format: 'srt', 'vtt', 'ass'
  final bool embedSubtitles; // Whether to embed subtitles in MP4 container
  final bool downloadSidecarSubtitles; // Whether to download subtitles as separate file

  // Timestamps
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? completedAt;

  // Pause tracking
  int downloadedBytes; // Bytes downloaded so far (for resume)

  // Speed tracking
  double speedBps; // Bytes per second (calculated on client side)
  int _lastSpeedBytes;
  DateTime? _lastSpeedTime;

  QueueItem({
    this.id,
    required this.url,
    required this.platform,
    required this.title,
    this.thumbnailUrl,
    this.status = QueueItemStatus.queued,
    this.progress = 0.0,
    this.filePath,
    this.fileSizeBytes = 0,
    this.errorMessage,
    this.errorCode,
    this.retryable = false,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.videoIndex,
    this.formatId,
    this.formatLabel,
    this.subtitleLang,
    this.subtitleFormat,
    this.embedSubtitles = false,
    this.downloadSidecarSubtitles = false,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.downloadedBytes = 0,
    this.speedBps = 0.0,
  }) : _lastSpeedBytes = 0, _lastSpeedTime = null;

  /// Update speed calculation based on current download progress.
  void updateSpeed(int currentBytes) {
    final now = DateTime.now();
    if (_lastSpeedTime != null && startedAt != null) {
      final elapsed = now.difference(_lastSpeedTime!).inMilliseconds;
      if (elapsed > 0) {
        final bytesDiff = currentBytes - _lastSpeedBytes;
        speedBps = (bytesDiff / elapsed) * 1000; // bytes per second
      }
    }
    _lastSpeedBytes = currentBytes;
    _lastSpeedTime = now;
  }

  /// Human-readable speed string.
  String get speedText {
    if (speedBps <= 0) return '';
    if (speedBps >= 1048576) {
      return '${(speedBps / 1048576).toStringAsFixed(1)} MB/s';
    } else if (speedBps >= 1024) {
      return '${(speedBps / 1024).toStringAsFixed(0)} KB/s';
    }
    return '${speedBps.toStringAsFixed(0)} B/s';
  }

  /// Estimated time remaining based on current speed.
  String get etaText {
    if (speedBps <= 0 || fileSizeBytes <= 0 || downloadedBytes <= 0) return '';
    final remaining = fileSizeBytes - downloadedBytes;
    if (remaining <= 0) return '';
    final seconds = remaining / speedBps;
    if (seconds < 60) return '${seconds.toStringAsFixed(0)}s left';
    if (seconds < 3600) return '${(seconds / 60).toStringAsFixed(0)}m left';
    return '${(seconds / 3600).toStringAsFixed(1)}h left';
  }

  factory QueueItem.fromMap(Map<String, dynamic> map) {
    return QueueItem(
      id: map['id'] as int?,
      url: map['url'] as String,
      platform: map['platform'] as String,
      title: map['title'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      status: QueueItemStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String),
        orElse: () => QueueItemStatus.queued,
      ),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      filePath: map['filePath'] as String?,
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      errorMessage: map['errorMessage'] as String?,
      errorCode: map['errorCode'] as String?,
      retryable: (map['retryable'] as num?)?.toInt() == 1,
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      maxRetries: (map['maxRetries'] as num?)?.toInt() ?? 3,
      videoIndex: map['videoIndex'] as int?,
      formatId: map['formatId'] as String?,
      formatLabel: map['formatLabel'] as String?,
      subtitleLang: map['subtitleLang'] as String?,
      subtitleFormat: map['subtitleFormat'] as String?,
      embedSubtitles: (map['embedSubtitles'] as num?)?.toInt() == 1,
      downloadSidecarSubtitles:
          (map['downloadSidecarSubtitles'] as num?)?.toInt() == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      startedAt: map['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startedAt'] as int)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      downloadedBytes: (map['downloadedBytes'] as num?)?.toInt() ?? 0,
      speedBps: (map['speedBps'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'url': url,
      'platform': platform,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'status': status.name,
      'progress': progress,
      'filePath': filePath,
      'fileSizeBytes': fileSizeBytes,
      'errorMessage': errorMessage,
      'errorCode': errorCode,
      'retryable': retryable ? 1 : 0,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'videoIndex': videoIndex,
      'formatId': formatId,
      'formatLabel': formatLabel,
      'subtitleLang': subtitleLang,
      'subtitleFormat': subtitleFormat,
      'embedSubtitles': embedSubtitles ? 1 : 0,
      'downloadSidecarSubtitles': downloadSidecarSubtitles ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'downloadedBytes': downloadedBytes,
      'speedBps': speedBps,
    };
  }

  /// Whether this item can be retried.
  bool get canRetry => retryable && retryCount < maxRetries;

  /// Whether this item is in an active state (downloading or paused).
  bool get isActive =>
      status == QueueItemStatus.downloading || status == QueueItemStatus.paused;

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

  QueueItem copyWith({
    int? id,
    String? url,
    String? platform,
    String? title,
    String? thumbnailUrl,
    QueueItemStatus? status,
    double? progress,
    String? filePath,
    int? fileSizeBytes,
    String? errorMessage,
    String? errorCode,
    bool? retryable,
    int? retryCount,
    int? maxRetries,
    int? videoIndex,
    String? formatId,
    String? formatLabel,
    String? subtitleLang,
    String? subtitleFormat,
    bool? embedSubtitles,
    bool? downloadSidecarSubtitles,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? downloadedBytes,
    double? speedBps,
  }) {
    return QueueItem(
      id: id ?? this.id,
      url: url ?? this.url,
      platform: platform ?? this.platform,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      retryable: retryable ?? this.retryable,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      videoIndex: videoIndex ?? this.videoIndex,
      formatId: formatId ?? this.formatId,
      formatLabel: formatLabel ?? this.formatLabel,
      subtitleLang: subtitleLang ?? this.subtitleLang,
      subtitleFormat: subtitleFormat ?? this.subtitleFormat,
      embedSubtitles: embedSubtitles ?? this.embedSubtitles,
      downloadSidecarSubtitles:
          downloadSidecarSubtitles ?? this.downloadSidecarSubtitles,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      speedBps: speedBps ?? this.speedBps,
    );
  }
}

/// Status lifecycle for a queue item.
enum QueueItemStatus {
  queued, // Waiting to be downloaded
  downloading, // Actively downloading
  paused, // User paused the download
  completed, // Successfully finished
  failed, // Download failed
  cancelled, // User cancelled
}
