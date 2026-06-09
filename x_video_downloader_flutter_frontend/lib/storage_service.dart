import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'download_database.dart';
import 'download_record.dart';

/// Auto-cleanup rule: delete downloads after a specified number of days.
enum CleanupRule {
  disabled('Never', 0),
  after7('After 7 days', 7),
  after14('After 14 days', 14),
  after30('After 30 days', 30),
  after60('After 60 days', 60),
  after90('After 90 days', 90);

  final String label;
  final int days;
  const CleanupRule(this.label, this.days);
}

/// Storage breakdown by platform.
class PlatformStorageInfo {
  final String platform;
  final int totalBytes;
  final int fileCount;
  final int completedCount;

  const PlatformStorageInfo({
    required this.platform,
    required this.totalBytes,
    required this.fileCount,
    required this.completedCount,
  });
}

/// Information about a single large file for the "largest files" list.
class LargeFileInfo {
  final int id;
  final String title;
  final String platform;
  final String filePath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final String status;

  const LargeFileInfo({
    required this.id,
    required this.title,
    required this.platform,
    required this.filePath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    required this.status,
  });
}

/// Overall storage summary.
class StorageSummary {
  final int totalUsedBytes;
  final int completedBytes;
  final int failedBytes;
  final int completedCount;
  final int failedCount;
  final int deletedCount;
  final List<PlatformStorageInfo> platformBreakdown;
  final List<LargeFileInfo> largestFiles;
  final int filesOnDisk;
  final int orphanedBytes;

  const StorageSummary({
    required this.totalUsedBytes,
    required this.completedBytes,
    required this.failedBytes,
    required this.completedCount,
    required this.failedCount,
    required this.deletedCount,
    required this.platformBreakdown,
    required this.largestFiles,
    required this.filesOnDisk,
    required this.orphanedBytes,
  });
}

/// Result of a cleanup operation.
class CleanupResult {
  final int filesDeleted;
  final int bytesFreed;
  final List<String> errors;

  const CleanupResult({
    required this.filesDeleted,
    required this.bytesFreed,
    required this.errors,
  });
}

int _sqlInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ?? 0;
}

/// Service for calculating storage usage and performing cleanup operations.
class StorageService {
  static const _keyCleanupRule = 'auto_cleanup_rule';
  static const _keyCleanupFailed = 'auto_cleanup_failed';
  static const _keyLastCleanup = 'last_auto_cleanup';

  final DownloadDatabase _db = DownloadDatabase();

  /// Get a comprehensive storage summary.
  Future<StorageSummary> getStorageSummary() async {
    final db = await _db.database;

    // Overall stats
    final stats = await _getOverallStats(db);

    // Platform breakdown
    final platformBreakdown = await _getPlatformBreakdown(db);

    // Largest files (top 20)
    final largestFiles = await _getLargestFiles(db);

    // Check which files actually exist on disk
    final (filesOnDisk, orphanedBytes) = await _checkFilesOnDisk(db);

    return StorageSummary(
      totalUsedBytes: stats['totalBytes'] as int,
      completedBytes: stats['completedBytes'] as int,
      failedBytes: stats['failedBytes'] as int,
      completedCount: stats['completedCount'] as int,
      failedCount: stats['failedCount'] as int,
      deletedCount: stats['deletedCount'] as int,
      platformBreakdown: platformBreakdown,
      largestFiles: largestFiles,
      filesOnDisk: filesOnDisk,
      orphanedBytes: orphanedBytes,
    );
  }

  Future<Map<String, int>> _getOverallStats(dynamic db) async {
    final results = await db.rawQuery('''
      SELECT
        COALESCE(SUM(fileSizeBytes), 0) as totalBytes,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN fileSizeBytes ELSE 0 END), 0) as completedBytes,
        COALESCE(SUM(CASE WHEN status = 'failed' THEN fileSizeBytes ELSE 0 END), 0) as failedBytes,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completedCount,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failedCount,
        SUM(CASE WHEN status = 'deleted' THEN 1 ELSE 0 END) as deletedCount
      FROM downloads
    ''');
    final row = results.first;
    return {
      'totalBytes': _sqlInt(row['totalBytes']),
      'completedBytes': _sqlInt(row['completedBytes']),
      'failedBytes': _sqlInt(row['failedBytes']),
      'completedCount': _sqlInt(row['completedCount']),
      'failedCount': _sqlInt(row['failedCount']),
      'deletedCount': _sqlInt(row['deletedCount']),
    };
  }

  Future<List<PlatformStorageInfo>> _getPlatformBreakdown(dynamic db) async {
    final results = await db.rawQuery('''
      SELECT
        platform,
        COUNT(*) as fileCount,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completedCount,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN fileSizeBytes ELSE 0 END), 0) as totalBytes
      FROM downloads
      GROUP BY platform
      ORDER BY totalBytes DESC
    ''');
    return results.map((r) => PlatformStorageInfo(
      platform: r['platform'] as String,
      totalBytes: _sqlInt(r['totalBytes']),
      fileCount: _sqlInt(r['fileCount']),
      completedCount: _sqlInt(r['completedCount']),
    )).toList();
  }

  Future<List<LargeFileInfo>> _getLargestFiles(dynamic db) async {
    final results = await db.rawQuery('''
      SELECT id, title, platform, filePath, fileSizeBytes, downloadedAt, status
      FROM downloads
      WHERE status IN ('completed', 'failed')
      ORDER BY fileSizeBytes DESC
      LIMIT 20
    ''');
    return results.map((r) => LargeFileInfo(
      id: r['id'] as int,
      title: r['title'] as String,
      platform: r['platform'] as String,
      filePath: r['filePath'] as String,
      fileSizeBytes: r['fileSizeBytes'] as int,
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(r['downloadedAt'] as int),
      status: r['status'] as String,
    )).toList();
  }

  Future<(int, int)> _checkFilesOnDisk(dynamic db) async {
    final results = await db.rawQuery(
      "SELECT filePath, fileSizeBytes FROM downloads WHERE status = 'completed'",
    );
    int filesOnDisk = 0;
    int orphanedBytes = 0;
    for (final row in results) {
      final path = row['filePath'] as String;
      final file = File(path);
      if (await file.exists()) {
        filesOnDisk++;
      } else {
        orphanedBytes += _sqlInt(row['fileSizeBytes']);
      }
    }
    return (filesOnDisk, orphanedBytes);
  }

  /// Delete files for a list of download record IDs.
  /// Returns the number of files deleted and bytes freed.
  Future<CleanupResult> deleteFiles(List<int> ids) async {
    int filesDeleted = 0;
    int bytesFreed = 0;
    final errors = <String>[];

    for (final id in ids) {
      // Get the specific record
      final db = await _db.database;
      final results = await db.query(
        'downloads',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) continue;

      final record = DownloadRecord.fromMap(results.first);

      // Try to delete the actual file
      if (record.status == 'completed') {
        final file = File(record.filePath);
        try {
          if (await file.exists()) {
            await file.delete();
            bytesFreed += record.fileSizeBytes;
          }
        } catch (e) {
          errors.add('Failed to delete ${record.title}: $e');
        }
      }

      // Mark as deleted in database
      await _db.updateStatus(id, 'deleted');
      filesDeleted++;
    }

    return CleanupResult(
      filesDeleted: filesDeleted,
      bytesFreed: bytesFreed,
      errors: errors,
    );
  }

  /// Clean up failed downloads (no files on disk, just database records).
  Future<CleanupResult> cleanupFailedDownloads() async {
    final db = await _db.database;
    final results = await db.query(
      'downloads',
      where: "status = 'failed'",
    );

    int deleted = 0;
    int bytesFreed = 0;
    for (final row in results) {
      await db.delete('downloads', where: 'id = ?', whereArgs: [row['id']]);
      deleted++;
    }

    return CleanupResult(
      filesDeleted: deleted,
      bytesFreed: bytesFreed,
      errors: [],
    );
  }

  /// Clean up old downloads based on age threshold.
  Future<CleanupResult> cleanupOldDownloads(int olderThanDays) async {
    final db = await _db.database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: olderThanDays))
        .millisecondsSinceEpoch;

    final results = await db.query(
      'downloads',
      where: "downloadedAt < ? AND status = 'completed'",
      whereArgs: [cutoff],
    );

    int filesDeleted = 0;
    int bytesFreed = 0;
    final errors = <String>[];

    for (final row in results) {
      final record = DownloadRecord.fromMap(row);
      final file = File(record.filePath);
      try {
        if (await file.exists()) {
          await file.delete();
          bytesFreed += record.fileSizeBytes;
        }
      } catch (e) {
        errors.add('Failed to delete ${record.title}: $e');
      }
      await _db.updateStatus(record.id!, 'deleted');
      filesDeleted++;
    }

    return CleanupResult(
      filesDeleted: filesDeleted,
      bytesFreed: bytesFreed,
      errors: errors,
    );
  }

  /// Clean up orphaned records (files no longer on disk).
  Future<CleanupResult> cleanupOrphanedRecords() async {
    final db = await _db.database;
    final results = await db.query(
      'downloads',
      where: "status = 'completed'",
    );

    int filesDeleted = 0;
    int bytesFreed = 0;

    for (final row in results) {
      final record = DownloadRecord.fromMap(row);
      final file = File(record.filePath);
      if (!await file.exists()) {
        await _db.updateStatus(record.id!, 'deleted');
        bytesFreed += record.fileSizeBytes;
        filesDeleted++;
      }
    }

    return CleanupResult(
      filesDeleted: filesDeleted,
      bytesFreed: bytesFreed,
      errors: [],
    );
  }

  // --- Auto-cleanup settings ---

  Future<CleanupRule> getCleanupRule() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyCleanupRule);
    if (saved != null) {
      return CleanupRule.values.firstWhere(
        (r) => r.name == saved,
        orElse: () => CleanupRule.disabled,
      );
    }
    return CleanupRule.disabled;
  }

  Future<void> setCleanupRule(CleanupRule rule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCleanupRule, rule.name);
  }

  Future<bool> getCleanupFailedEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCleanupFailed) ?? false;
  }

  Future<void> setCleanupFailedEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCleanupFailed, enabled);
  }

  DateTime? getLastCleanupTime() {
    // Lightweight sync check via cached prefs
    return null; // Will be updated after cleanup runs
  }

  Future<void> recordCleanupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastCleanup, DateTime.now().millisecondsSinceEpoch);
  }

  /// Run auto-cleanup based on current settings.
  /// Call this on app startup or periodically.
  Future<CleanupResult?> runAutoCleanup() async {
    final rule = await getCleanupRule();
    if (rule == CleanupRule.disabled) return null;

    // Check if cleanup ran recently (within last hour)
    final prefs = await SharedPreferences.getInstance();
    final lastCleanup = prefs.getInt(_keyLastCleanup);
    if (lastCleanup != null) {
      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastCleanup);
      if (DateTime.now().difference(lastTime).inHours < 1) {
        return null; // Already ran recently
      }
    }

    final results = <CleanupResult>[];

    // Age-based cleanup
    final ageResult = await cleanupOldDownloads(rule.days);
    results.add(ageResult);

    // Optionally clean failed downloads
    if (await getCleanupFailedEnabled()) {
      final failedResult = await cleanupFailedDownloads();
      results.add(failedResult);
    }

    await recordCleanupTime();

    return CleanupResult(
      filesDeleted: results.fold(0, (sum, r) => sum + r.filesDeleted),
      bytesFreed: results.fold(0, (sum, r) => sum + r.bytesFreed),
      errors: results.expand((r) => r.errors).toList(),
    );
  }

  /// Format bytes to human-readable string.
  static String formatBytes(int bytes) {
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
}
