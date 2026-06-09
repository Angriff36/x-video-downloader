/// Data models for download analytics computed from local download history.
class DownloadAnalytics {
  final int totalDownloads;
  final int completedDownloads;
  final int failedDownloads;
  final double successRate;
  final int totalBytesDownloaded;
  final double averageSpeedBps;
  final List<PlatformStats> platformStats;
  final List<DailyCount> dailyCounts;
  final List<DailyBandwidth> dailyBandwidth;
  final DateTime? firstDownloadDate;
  final DateTime? lastDownloadDate;

  DownloadAnalytics({
    required this.totalDownloads,
    required this.completedDownloads,
    required this.failedDownloads,
    required this.successRate,
    required this.totalBytesDownloaded,
    required this.averageSpeedBps,
    required this.platformStats,
    required this.dailyCounts,
    required this.dailyBandwidth,
    this.firstDownloadDate,
    this.lastDownloadDate,
  });

  /// Human-readable total bandwidth.
  String get totalBandwidthText => _formatBytes(totalBytesDownloaded);

  /// Human-readable average speed.
  String get averageSpeedText => _formatSpeed(averageSpeedBps);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  static String _formatSpeed(double bps) {
    if (bps <= 0) return 'N/A';
    if (bps >= 1048576) {
      return '${(bps / 1048576).toStringAsFixed(1)} MB/s';
    } else if (bps >= 1024) {
      return '${(bps / 1024).toStringAsFixed(0)} KB/s';
    }
    return '${bps.toStringAsFixed(0)} B/s';
  }
}

/// Statistics for a single platform.
class PlatformStats {
  final String platform;
  final int downloadCount;
  final int successCount;
  final int totalBytes;
  final double successRate;

  PlatformStats({
    required this.platform,
    required this.downloadCount,
    required this.successCount,
    required this.totalBytes,
    required this.successRate,
  });

  String get totalBytesText {
    if (totalBytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = totalBytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}

/// Download count for a single day.
class DailyCount {
  final DateTime date;
  final int completed;
  final int failed;

  DailyCount({required this.date, required this.completed, required this.failed});

  int get total => completed + failed;
}

/// Bandwidth consumed for a single day.
class DailyBandwidth {
  final DateTime date;
  final int bytes;

  DailyBandwidth({required this.date, required this.bytes});

  String get bytesText {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
