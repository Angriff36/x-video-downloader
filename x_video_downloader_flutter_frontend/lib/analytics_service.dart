import 'download_analytics.dart';
import 'download_database.dart';

/// Service that computes analytics from the local download database.
class AnalyticsService {
  final DownloadDatabase _db = DownloadDatabase();

  /// Compute full analytics snapshot from the database.
  Future<DownloadAnalytics> computeAnalytics({int days = 30}) async {
    final counts = await _db.getAnalyticsCounts();
    final totalBytes = await _db.getTotalBytesDownloaded();
    final avgSpeed = await _db.getAverageSpeed();
    final platformRows = await _db.getDownloadsByPlatform();
    final dailyCountRows = await _db.getDailyCounts(days: days);
    final dailyBandwidthRows = await _db.getDailyBandwidth(days: days);
    final dateRange = await _db.getDownloadDateRange();

    final totalDownloads = counts['total'] ?? 0;
    final completedDownloads = counts['completed'] ?? 0;
    final failedDownloads = counts['failed'] ?? 0;
    final successRate = totalDownloads > 0
        ? completedDownloads / totalDownloads
        : 0.0;

    final platformStats = platformRows.map((row) {
      final count = row['count'] as int;
      final successCount = row['success_count'] as int;
      return PlatformStats(
        platform: row['platform'] as String,
        downloadCount: count,
        successCount: successCount,
        totalBytes: row['total_bytes'] as int,
        successRate: count > 0 ? successCount / count : 0.0,
      );
    }).toList();

    final dailyCounts = dailyCountRows.map((row) {
      final dayEpoch = row['day_epoch'] as int;
      return DailyCount(
        date: DateTime.fromMillisecondsSinceEpoch(dayEpoch * 86400000),
        completed: row['completed'] as int,
        failed: row['failed'] as int,
      );
    }).toList();

    final dailyBandwidth = dailyBandwidthRows.map((row) {
      final dayEpoch = row['day_epoch'] as int;
      return DailyBandwidth(
        date: DateTime.fromMillisecondsSinceEpoch(dayEpoch * 86400000),
        bytes: row['bytes'] as int,
      );
    }).toList();

    return DownloadAnalytics(
      totalDownloads: totalDownloads,
      completedDownloads: completedDownloads,
      failedDownloads: failedDownloads,
      successRate: successRate,
      totalBytesDownloaded: totalBytes,
      averageSpeedBps: avgSpeed,
      platformStats: platformStats,
      dailyCounts: dailyCounts,
      dailyBandwidth: dailyBandwidth,
      firstDownloadDate: dateRange['first'] != null
          ? DateTime.fromMillisecondsSinceEpoch(dateRange['first']!)
          : null,
      lastDownloadDate: dateRange['last'] != null
          ? DateTime.fromMillisecondsSinceEpoch(dateRange['last']!)
          : null,
    );
  }
}
