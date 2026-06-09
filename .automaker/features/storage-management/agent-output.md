CogniLayer v4 active — persistent memory is on. Type /cognihelp for available commands.

Let me assess the current state and get the storage management feature implemented properly.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Explore current codebase state and existing files",
      "status": "in_progress",
      "activeForm": "Exploring current codebase state"
    },
    {
      "content": "Implement StorageService for storage calculations",
      "status": "pending",
      "activeForm": "Implementing StorageService"
    },
    {
      "content": "Implement StorageManagementScreen UI",
      "status": "pending",
      "activeForm": "Implementing StorageManagementScreen UI"
    },
    {
      "content": "Add cleanup rules and auto-cleanup functionality",
      "status": "pending",
      "activeForm": "Adding cleanup rules and auto-cleanup"
    },
    {
      "content": "Integrate storage screen into app navigation",
      "status": "pending",
      "activeForm": "Integrating into app navigation"
    },
    {
      "content": "Verify implementation compiles and works",
      "status": "pending",
      "activeForm": "Verifying implementation"
    }
  ]
}

🔧 Tool: Task
Input: {
  "description": "Explore Flutter frontend codebase",
  "subagent_type": "Explore",
  "model": "haiku",
  "prompt": "Explore the Flutter frontend codebase at C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend. I need:\n\n1. The complete file structure (all .dart files)\n2. The content of pubspec.yaml to understand dependencies\n3. The content of lib/main.dart\n4. Any existing models, services, or screens related to downloads or storage\n5. The theme files (app_theme.dart, theme_provider.dart, theme_settings_screen.dart)\n6. Any existing database/storage related code\n\nReturn a comprehensive summary of all files and their contents. Include file paths and key classes/functions."
}

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && find . -name \"*.dart\" -type f | sort",
  "description": "List all Dart files in the Flutter project"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\pubspec.yaml"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\app_theme.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\theme_provider.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\theme_settings_screen.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_record.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart",
  "limit": 100
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\scheduled_download.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\format_option.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\filename_template.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\network_monitor.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart",
  "limit": 50
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_history_screen.dart",
  "limit": 50
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\batch_import_screen.dart",
  "limit": 50
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_analytics_screen.dart",
  "limit": 50
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\filename_template_settings_screen.dart",
  "limit": 50
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\models\\download_record.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart"
}
Now let me read the remaining key files.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_record.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\app_theme.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\theme_provider.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\pubspec.yaml"
}
Good. Now I have a thorough understanding of the codebase. Let me implement the storage management feature. I need to create:

1. A `StorageService` for storage calculations and cleanup logic
2. A `StorageManagementScreen` for the UI
3. Integration into `main.dart` navigation

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring current codebase state",
      "content": "Explore current codebase state and existing files",
      "status": "completed"
    },
    {
      "activeForm": "Creating StorageService",
      "content": "Create StorageService for storage calculations and cleanup",
      "status": "in_progress"
    },
    {
      "activeForm": "Implementing StorageManagementScreen UI",
      "content": "Implement StorageManagementScreen UI",
      "status": "pending"
    },
    {
      "activeForm": "Adding cleanup rules and auto-cleanup",
      "content": "Add cleanup rules and auto-cleanup functionality",
      "status": "pending"
    },
    {
      "activeForm": "Integrating into app navigation",
      "content": "Integrate storage screen into app navigation in main.dart",
      "status": "pending"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "pending"
    }
  ]
}

🔧 Tool: Write
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\storage_service.dart",
  "content": "import 'dart:io';\nimport 'package:path_provider/path_provider.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\nimport 'download_database.dart';\nimport 'download_record.dart';\n\n/// Auto-cleanup rule: delete downloads after a specified number of days.\nenum CleanupRule {\n  disabled('Never', 0),\n  after7('After 7 days', 7),\n  after14('After 14 days', 14),\n  after30('After 30 days', 30),\n  after60('After 60 days', 60),\n  after90('After 90 days', 90);\n\n  final String label;\n  final int days;\n  const CleanupRule(this.label, this.days);\n}\n\n/// Storage breakdown by platform.\nclass PlatformStorageInfo {\n  final String platform;\n  final int totalBytes;\n  final int fileCount;\n  final int completedCount;\n\n  const PlatformStorageInfo({\n    required this.platform,\n    required this.totalBytes,\n    required this.fileCount,\n    required this.completedCount,\n  });\n}\n\n/// Information about a single large file for the \"largest files\" list.\nclass LargeFileInfo {\n  final int id;\n  final String title;\n  final String platform;\n  final String filePath;\n  final int fileSizeBytes;\n  final DateTime downloadedAt;\n  final String status;\n\n  const LargeFileInfo({\n    required this.id,\n    required this.title,\n    required this.platform,\n    required this.filePath,\n    required this.fileSizeBytes,\n    required this.downloadedAt,\n    required this.status,\n  });\n}\n\n/// Overall storage summary.\nclass StorageSummary {\n  final int totalUsedBytes;\n  final int completedBytes;\n  final int failedBytes;\n  final int completedCount;\n  final int failedCount;\n  final int deletedCount;\n  final List<PlatformStorageInfo> platformBreakdown;\n  final List<LargeFileInfo> largestFiles;\n  final int filesOnDisk;\n  final int orphanedBytes;\n\n  const StorageSummary({\n    required this.totalUsedBytes,\n    required this.completedBytes,\n    required this.failedBytes,\n    required this.completedCount,\n    required this.failedCount,\n    required this.deletedCount,\n    required this.platformBreakdown,\n    required this.largestFiles,\n    required this.filesOnDisk,\n    required this.orphanedBytes,\n  });\n}\n\n/// Result of a cleanup operation.\nclass CleanupResult {\n  final int filesDeleted;\n  final int bytesFreed;\n  final List<String> errors;\n\n  const CleanupResult({\n    required this.filesDeleted,\n    required this.bytesFreed,\n    required this.errors,\n  });\n}\n\n/// Service for calculating storage usage and performing cleanup operations.\nclass StorageService {\n  static const _keyCleanupRule = 'auto_cleanup_rule';\n  static const _keyCleanupFailed = 'auto_cleanup_failed';\n  static const _keyLastCleanup = 'last_auto_cleanup';\n\n  final DownloadDatabase _db = DownloadDatabase();\n\n  /// Get a comprehensive storage summary.\n  Future<StorageSummary> getStorageSummary() async {\n    final db = await _db.database;\n\n    // Overall stats\n    final stats = await _getOverallStats(db);\n\n    // Platform breakdown\n    final platformBreakdown = await _getPlatformBreakdown(db);\n\n    // Largest files (top 20)\n    final largestFiles = await _getLargestFiles(db);\n\n    // Check which files actually exist on disk\n    final (filesOnDisk, orphanedBytes) = await _checkFilesOnDisk(db);\n\n    return StorageSummary(\n      totalUsedBytes: stats['totalBytes'] as int,\n      completedBytes: stats['completedBytes'] as int,\n      failedBytes: stats['failedBytes'] as int,\n      completedCount: stats['completedCount'] as int,\n      failedCount: stats['failedCount'] as int,\n      deletedCount: stats['deletedCount'] as int,\n      platformBreakdown: platformBreakdown,\n      largestFiles: largestFiles,\n      filesOnDisk: filesOnDisk,\n      orphanedBytes: orphanedBytes,\n    );\n  }\n\n  Future<Map<String, int>> _getOverallStats(dynamic db) async {\n    final results = await db.rawQuery('''\n      SELECT\n        COALESCE(SUM(fileSizeBytes), 0) as totalBytes,\n        COALESCE(SUM(CASE WHEN status = 'completed' THEN fileSizeBytes ELSE 0 END), 0) as completedBytes,\n        COALESCE(SUM(CASE WHEN status = 'failed' THEN fileSizeBytes ELSE 0 END), 0) as failedBytes,\n        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completedCount,\n        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failedCount,\n        SUM(CASE WHEN status = 'deleted' THEN 1 ELSE 0 END) as deletedCount\n      FROM downloads\n    ''');\n    final row = results.first;\n    return {\n      'totalBytes': row['totalBytes'] as int,\n      'completedBytes': row['completedBytes'] as int,\n      'failedBytes': row['failedBytes'] as int,\n      'completedCount': (row['completedCount'] as num?)?.toInt() ?? 0,\n      'failedCount': (row['failedCount'] as num?)?.toInt() ?? 0,\n      'deletedCount': (row['deletedCount'] as num?)?.toInt() ?? 0,\n    };\n  }\n\n  Future<List<PlatformStorageInfo>> _getPlatformBreakdown(dynamic db) async {\n    final results = await db.rawQuery('''\n      SELECT\n        platform,\n        COUNT(*) as fileCount,\n        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completedCount,\n        COALESCE(SUM(CASE WHEN status = 'completed' THEN fileSizeBytes ELSE 0 END), 0) as totalBytes\n      FROM downloads\n      GROUP BY platform\n      ORDER BY totalBytes DESC\n    ''');\n    return results.map((r) => PlatformStorageInfo(\n      platform: r['platform'] as String,\n      totalBytes: r['totalBytes'] as int,\n      fileCount: r['fileCount'] as int,\n      completedCount: (r['completedCount'] as num?)?.toInt() ?? 0,\n    )).toList();\n  }\n\n  Future<List<LargeFileInfo>> _getLargestFiles(dynamic db) async {\n    final results = await db.rawQuery('''\n      SELECT id, title, platform, filePath, fileSizeBytes, downloadedAt, status\n      FROM downloads\n      WHERE status IN ('completed', 'failed')\n      ORDER BY fileSizeBytes DESC\n      LIMIT 20\n    ''');\n    return results.map((r) => LargeFileInfo(\n      id: r['id'] as int,\n      title: r['title'] as String,\n      platform: r['platform'] as String,\n      filePath: r['filePath'] as String,\n      fileSizeBytes: r['fileSizeBytes'] as int,\n      downloadedAt: DateTime.fromMillisecondsSinceEpoch(r['downloadedAt'] as int),\n      status: r['status'] as String,\n    )).toList();\n  }\n\n  Future<(int, int)> _checkFilesOnDisk(dynamic db) async {\n    final results = await db.rawQuery(\n      \"SELECT filePath, fileSizeBytes FROM downloads WHERE status = 'completed'\",\n    );\n    int filesOnDisk = 0;\n    int orphanedBytes = 0;\n    for (final row in results) {\n      final path = row['filePath'] as String;\n      final file = File(path);\n      if (await file.exists()) {\n        filesOnDisk++;\n      } else {\n        orphanedBytes += row['fileSizeBytes'] as int;\n      }\n    }\n    return (filesOnDisk, orphanedBytes);\n  }\n\n  /// Delete files for a list of download record IDs.\n  /// Returns the number of files deleted and bytes freed.\n  Future<CleanupResult> deleteFiles(List<int> ids) async {\n    int filesDeleted = 0;\n    int bytesFreed = 0;\n    final errors = <String>[];\n\n    for (final id in ids) {\n      final records = await _db.getAllRecords(limit: 1);\n      // Get the specific record\n      final db = await _db.database;\n      final results = await db.query(\n        'downloads',\n        where: 'id = ?',\n        whereArgs: [id],\n      );\n      if (results.isEmpty) continue;\n\n      final record = DownloadRecord.fromMap(results.first);\n\n      // Try to delete the actual file\n      if (record.status == 'completed') {\n        final file = File(record.filePath);\n        try {\n          if (await file.exists()) {\n            await file.delete();\n            bytesFreed += record.fileSizeBytes;\n          }\n        } catch (e) {\n          errors.add('Failed to delete ${record.title}: $e');\n        }\n      }\n\n      // Mark as deleted in database\n      await _db.updateStatus(id, 'deleted');\n      filesDeleted++;\n    }\n\n    return CleanupResult(\n      filesDeleted: filesDeleted,\n      bytesFreed: bytesFreed,\n      errors: errors,\n    );\n  }\n\n  /// Clean up failed downloads (no files on disk, just database records).\n  Future<CleanupResult> cleanupFailedDownloads() async {\n    final db = await _db.database;\n    final results = await db.query(\n      'downloads',\n      where: \"status = 'failed'\",\n    );\n\n    int deleted = 0;\n    int bytesFreed = 0;\n    for (final row in results) {\n      await db.delete('downloads', where: 'id = ?', whereArgs: [row['id']]);\n      deleted++;\n    }\n\n    return CleanupResult(\n      filesDeleted: deleted,\n      bytesFreed: bytesFreed,\n      errors: [],\n    );\n  }\n\n  /// Clean up old downloads based on age threshold.\n  Future<CleanupResult> cleanupOldDownloads(int olderThanDays) async {\n    final db = await _db.database;\n    final cutoff = DateTime.now()\n        .subtract(Duration(days: olderThanDays))\n        .millisecondsSinceEpoch;\n\n    final results = await db.query(\n      'downloads',\n      where: \"downloadedAt < ? AND status = 'completed'\",\n      whereArgs: [cutoff],\n    );\n\n    int filesDeleted = 0;\n    int bytesFreed = 0;\n    final errors = <String>[];\n\n    for (final row in results) {\n      final record = DownloadRecord.fromMap(row);\n      final file = File(record.filePath);\n      try {\n        if (await file.exists()) {\n          await file.delete();\n          bytesFreed += record.fileSizeBytes;\n        }\n      } catch (e) {\n        errors.add('Failed to delete ${record.title}: $e');\n      }\n      await _db.updateStatus(record.id!, 'deleted');\n      filesDeleted++;\n    }\n\n    return CleanupResult(\n      filesDeleted: filesDeleted,\n      bytesFreed: bytesFreed,\n      errors: errors,\n    );\n  }\n\n  /// Clean up orphaned records (files no longer on disk).\n  Future<CleanupResult> cleanupOrphanedRecords() async {\n    final db = await _db.database;\n    final results = await db.query(\n      'downloads',\n      where: \"status = 'completed'\",\n    );\n\n    int filesDeleted = 0;\n    int bytesFreed = 0;\n\n    for (final row in results) {\n      final record = DownloadRecord.fromMap(row);\n      final file = File(record.filePath);\n      if (!await file.exists()) {\n        await _db.updateStatus(record.id!, 'deleted');\n        bytesFreed += record.fileSizeBytes;\n        filesDeleted++;\n      }\n    }\n\n    return CleanupResult(\n      filesDeleted: filesDeleted,\n      bytesFreed: bytesFreed,\n      errors: [],\n    );\n  }\n\n  // --- Auto-cleanup settings ---\n\n  Future<CleanupRule> getCleanupRule() async {\n    final prefs = await SharedPreferences.getInstance();\n    final saved = prefs.getString(_keyCleanupRule);\n    if (saved != null) {\n      return CleanupRule.values.firstWhere(\n        (r) => r.name == saved,\n        orElse: () => CleanupRule.disabled,\n      );\n    }\n    return CleanupRule.disabled;\n  }\n\n  Future<void> setCleanupRule(CleanupRule rule) async {\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.setString(_keyCleanupRule, rule.name);\n  }\n\n  Future<bool> getCleanupFailedEnabled() async {\n    final prefs = await SharedPreferences.getInstance();\n    return prefs.getBool(_keyCleanupFailed) ?? false;\n  }\n\n  Future<void> setCleanupFailedEnabled(bool enabled) async {\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.setBool(_keyCleanupFailed, enabled);\n  }\n\n  DateTime? getLastCleanupTime() {\n    // Lightweight sync check via cached prefs\n    return null; // Will be updated after cleanup runs\n  }\n\n  Future<void> recordCleanupTime() async {\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.setInt(_keyLastCleanup, DateTime.now().millisecondsSinceEpoch);\n  }\n\n  /// Run auto-cleanup based on current settings.\n  /// Call this on app startup or periodically.\n  Future<CleanupResult?> runAutoCleanup() async {\n    final rule = await getCleanupRule();\n    if (rule == CleanupRule.disabled) return null;\n\n    // Check if cleanup ran recently (within last hour)\n    final prefs = await SharedPreferences.getInstance();\n    final lastCleanup = prefs.getInt(_keyLastCleanup);\n    if (lastCleanup != null) {\n      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastCleanup);\n      if (DateTime.now().difference(lastTime).inHours < 1) {\n        return null; // Already ran recently\n      }\n    }\n\n    final results = <CleanupResult>[];\n\n    // Age-based cleanup\n    final ageResult = await cleanupOldDownloads(rule.days);\n    results.add(ageResult);\n\n    // Optionally clean failed downloads\n    if (await getCleanupFailedEnabled()) {\n      final failedResult = await cleanupFailedDownloads();\n      results.add(failedResult);\n    }\n\n    await recordCleanupTime();\n\n    return CleanupResult(\n      filesDeleted: results.fold(0, (sum, r) => sum + r.filesDeleted),\n      bytesFreed: results.fold(0, (sum, r) => sum + r.bytesFreed),\n      errors: results.expand((r) => r.errors).toList(),\n    );\n  }\n\n  /// Format bytes to human-readable string.\n  static String formatBytes(int bytes) {\n    if (bytes <= 0) return '0 B';\n    const units = ['B', 'KB', 'MB', 'GB', 'TB'];\n    double size = bytes.toDouble();\n    int unitIndex = 0;\n    while (size >= 1024 && unitIndex < units.length - 1) {\n      size /= 1024;\n      unitIndex++;\n    }\n    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';\n  }\n}\n"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring current codebase state",
      "content": "Explore current codebase state and existing files",
      "status": "completed"
    },
    {
      "activeForm": "Creating StorageService",
      "content": "Create StorageService for storage calculations and cleanup",
      "status": "completed"
    },
    {
      "activeForm": "Implementing StorageManagementScreen UI",
      "content": "Implement StorageManagementScreen UI",
      "status": "in_progress"
    },
    {
      "activeForm": "Adding cleanup rules and auto-cleanup",
      "content": "Add cleanup rules and auto-cleanup functionality",
      "status": "pending"
    },
    {
      "activeForm": "Integrating into app navigation",
      "content": "Integrate storage screen into app navigation in main.dart",
      "status": "pending"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "pending"
    }
  ]
}
Now let me create the storage management screen with the full UI.

🔧 Tool: Write
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\storage_management_screen.dart",
  "content": "import 'dart:io';\nimport 'package:flutter/material.dart';\nimport 'package:fl_chart/fl_chart.dart';\nimport 'storage_service.dart';\n\n/// Screen for viewing storage usage, breakdown, and managing cleanup.\nclass StorageManagementScreen extends StatefulWidget {\n  const StorageManagementScreen({super.key});\n\n  @override\n  State<StorageManagementScreen> createState() => _StorageManagementScreenState();\n}\n\nclass _StorageManagementScreenState extends State<StorageManagementScreen> {\n  final StorageService _storageService = StorageService();\n\n  StorageSummary? _summary;\n  bool _isLoading = true;\n  bool _isCleaning = false;\n  CleanupRule _cleanupRule = CleanupRule.disabled;\n  bool _cleanupFailed = false;\n\n  @override\n  void initState() {\n    super.initState();\n    _loadData();\n  }\n\n  Future<void> _loadData() async {\n    setState(() => _isLoading = true);\n    try {\n      final results = await Future.wait([\n        _storageService.getStorageSummary(),\n        _storageService.getCleanupRule(),\n        _storageService.getCleanupFailedEnabled(),\n      ]);\n      if (mounted) {\n        setState(() {\n          _summary = results[0] as StorageSummary;\n          _cleanupRule = results[1] as CleanupRule;\n          _cleanupFailed = results[2] as bool;\n          _isLoading = false;\n        });\n      }\n    } catch (e) {\n      if (mounted) {\n        setState(() => _isLoading = false);\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(content: Text('Error loading storage info: $e')),\n        );\n      }\n    }\n  }\n\n  Future<void> _performCleanup(Future<CleanupResult> Function() action) async {\n    setState(() => _isCleaning = true);\n    try {\n      final result = await action();\n      if (mounted) {\n        final msg = StringBuffer();\n        msg.write('Cleaned up ${result.filesDeleted} item${result.filesDeleted != 1 ? 's' : ''}');\n        if (result.bytesFreed > 0) {\n          msg.write(', freed ${StorageService.formatBytes(result.bytesFreed)}');\n        }\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(content: Text(msg.toString())),\n        );\n        await _loadData();\n      }\n    } catch (e) {\n      if (mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(content: Text('Cleanup error: $e')),\n        );\n      }\n    } finally {\n      if (mounted) setState(() => _isCleaning = false);\n    }\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final theme = Theme.of(context);\n    final colorScheme = theme.colorScheme;\n\n    return Scaffold(\n      appBar: AppBar(\n        title: const Text('Storage Management'),\n        actions: [\n          IconButton(\n            icon: const Icon(Icons.refresh),\n            tooltip: 'Refresh',\n            onPressed: _isLoading ? null : _loadData,\n          ),\n        ],\n      ),\n      body: _isLoading\n          ? const Center(child: CircularProgressIndicator())\n          : RefreshIndicator(\n              onRefresh: _loadData,\n              child: ListView(\n                padding: const EdgeInsets.all(16),\n                children: [\n                  _buildOverviewCard(theme, colorScheme),\n                  const SizedBox(height: 16),\n                  _buildPlatformBreakdownCard(theme, colorScheme),\n                  const SizedBox(height: 16),\n                  _buildLargestFilesCard(theme, colorScheme),\n                  const SizedBox(height: 16),\n                  _buildCleanupActionsCard(theme, colorScheme),\n                  const SizedBox(height: 16),\n                  _buildAutoCleanupCard(theme, colorScheme),\n                  const SizedBox(height: 32),\n                ],\n              ),\n            ),\n    );\n  }\n\n  Widget _buildOverviewCard(ThemeData theme, ColorScheme colorScheme) {\n    final summary = _summary!;\n    final total = summary.totalUsedBytes;\n    final completedPct = total > 0 ? summary.completedBytes / total : 0.0;\n    final failedPct = total > 0 ? summary.failedBytes / total : 0.0;\n\n    return Card(\n      child: Padding(\n        padding: const EdgeInsets.all(16),\n        child: Column(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            Row(\n              children: [\n                Icon(Icons.storage, color: colorScheme.primary),\n                const SizedBox(width: 8),\n                Text(\n                  'Storage Overview',\n                  style: theme.textTheme.titleMedium?.copyWith(\n                    fontWeight: FontWeight.bold,\n                  ),\n                ),\n              ],\n            ),\n            const SizedBox(height: 16),\n            // Total usage\n            Center(\n              child: Column(\n                children: [\n                  Text(\n                    StorageService.formatBytes(total),\n                    style: theme.textTheme.headlineMedium?.copyWith(\n                      fontWeight: FontWeight.bold,\n                      color: colorScheme.primary,\n                    ),\n                  ),\n                  const SizedBox(height: 4),\n                  Text(\n                    'Total space used by downloads',\n                    style: theme.textTheme.bodySmall?.copyWith(\n                      color: colorScheme.onSurfaceVariant,\n                    ),\n                  ),\n                ],\n              ),\n            ),\n            const SizedBox(height: 16),\n            // Usage bar\n            ClipRRect(\n              borderRadius: BorderRadius.circular(4),\n              child: SizedBox(\n                height: 12,\n                child: LinearProgressIndicator(\n                  value: 1.0,\n                  backgroundColor: colorScheme.surfaceContainerHighest,\n                  valueColor: AlwaysStoppedAnimation<Color>(\n                    completedPct > 0\n                        ? colorScheme.primary\n                        : colorScheme.surfaceContainerHighest,\n                  ),\n                ),\n              ),\n            ),\n            const SizedBox(height: 12),\n            // Stats row\n            Row(\n              mainAxisAlignment: MainAxisAlignment.spaceAround,\n              children: [\n                _buildStatColumn(\n                  '${summary.completedCount}',\n                  'Completed',\n                  colorScheme.primary,\n                  Icons.check_circle_outline,\n                ),\n                _buildStatColumn(\n                  '${summary.failedCount}',\n                  'Failed',\n                  colorScheme.error,\n                  Icons.error_outline,\n                ),\n                _buildStatColumn(\n                  '${summary.deletedCount}',\n                  'Deleted',\n                  colorScheme.onSurfaceVariant,\n                  Icons.delete_outline,\n                ),\n                _buildStatColumn(\n                  '${summary.filesOnDisk}',\n                  'On Disk',\n                  colorScheme.tertiary,\n                  Icons.folder_outlined,\n                ),\n              ],\n            ),\n            if (summary.orphanedBytes > 0) ...[\n              const SizedBox(height: 12),\n              Container(\n                padding: const EdgeInsets.all(8),\n                decoration: BoxDecoration(\n                  color: colorScheme.errorContainer.withValues(alpha: 0.3),\n                  borderRadius: BorderRadius.circular(8),\n                ),\n                child: Row(\n                  children: [\n                    Icon(Icons.warning_amber, size: 18, color: colorScheme.error),\n                    const SizedBox(width: 8),\n                    Expanded(\n                      child: Text(\n                        '${StorageService.formatBytes(summary.orphanedBytes)} in orphaned records (files no longer on disk)',\n                        style: theme.textTheme.bodySmall?.copyWith(\n                          color: colorScheme.error,\n                        ),\n                      ),\n                    ),\n                  ],\n                ),\n              ),\n            ],\n          ],\n        ),\n      ),\n    );\n  }\n\n  Widget _buildStatColumn(String value, String label, Color color, IconData icon) {\n    return Column(\n      children: [\n        Icon(icon, size: 20, color: color),\n        const SizedBox(height: 4),\n        Text(\n          value,\n          style: TextStyle(fontWeight: FontWeight.bold, color: color),\n        ),\n        Text(\n          label,\n          style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),\n        ),\n      ],\n    );\n  }\n\n  Widget _buildPlatformBreakdownCard(ThemeData theme, ColorScheme colorScheme) {\n    final breakdown = _summary!.platformBreakdown;\n    if (breakdown.isEmpty) {\n      return Card(\n        child: Padding(\n          padding: const EdgeInsets.all(16),\n          child: Column(\n            crossAxisAlignment: CrossAxisAlignment.start,\n            children: [\n              Row(\n                children: [\n                  Icon(Icons.pie_chart, color: colorScheme.primary),\n                  const SizedBox(width: 8),\n                  Text(\n                    'Platform Breakdown',\n                    style: theme.textTheme.titleMedium?.copyWith(\n                      fontWeight: FontWeight.bold,\n                    ),\n                  ),\n                ],\n              ),\n              const SizedBox(height: 16),\n              const Center(child: Text('No downloads yet')),\n            ],\n          ),\n        ),\n      );\n    }\n\n    final totalBytes = breakdown.fold(0, (sum, p) => sum + p.totalBytes);\n    final colors = [\n      colorScheme.primary,\n      colorScheme.tertiary,\n      colorScheme.secondary,\n      colorScheme.error,\n      Colors.orange,\n      Colors.purple,\n      Colors.teal,\n      Colors.pink,\n    ];\n\n    return Card(\n      child: Padding(\n        padding: const EdgeInsets.all(16),\n        child: Column(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            Row(\n              children: [\n                Icon(Icons.pie_chart, color: colorScheme.primary),\n                const SizedBox(width: 8),\n                Text(\n                  'Platform Breakdown',\n                  style: theme.textTheme.titleMedium?.copyWith(\n                    fontWeight: FontWeight.bold,\n                  ),\n                ),\n              ],\n            ),\n            const SizedBox(height: 16),\n            // Pie chart\n            SizedBox(\n              height: 180,\n              child: Row(\n                children: [\n                  Expanded(\n                    flex: 3,\n                    child: PieChart(\n                      PieChartData(\n                        sections: breakdown.asMap().entries.map((entry) {\n                          final index = entry.key;\n                          final info = entry.value;\n                          final pct = totalBytes > 0\n                              ? (info.totalBytes / totalBytes) * 100\n                              : 0.0;\n                          return PieChartSectionData(\n                            value: info.totalBytes.toDouble(),\n                            title: pct >= 5\n                                ? '${pct.toStringAsFixed(0)}%'\n                                : '',\n                            color: colors[index % colors.length],\n                            radius: 60,\n                            titleStyle: const TextStyle(\n                              fontSize: 11,\n                              fontWeight: FontWeight.bold,\n                              color: Colors.white,\n                            ),\n                          );\n                        }).toList(),\n                        sectionsSpace: 2,\n                        centerSpaceRadius: 30,\n                      ),\n                    ),\n                  ),\n                  const SizedBox(width: 12),\n                  // Legend\n                  Expanded(\n                    flex: 2,\n                    child: Column(\n                      mainAxisAlignment: MainAxisAlignment.center,\n                      crossAxisAlignment: CrossAxisAlignment.start,\n                      children: breakdown.asMap().entries.map((entry) {\n                        final index = entry.key;\n                        final info = entry.value;\n                        return Padding(\n                          padding: const EdgeInsets.symmetric(vertical: 2),\n                          child: Row(\n                            children: [\n                              Container(\n                                width: 10,\n                                height: 10,\n                                decoration: BoxDecoration(\n                                  color: colors[index % colors.length],\n                                  shape: BoxShape.circle,\n                                ),\n                              ),\n                              const SizedBox(width: 6),\n                              Expanded(\n                                child: Text(\n                                  info.platform,\n                                  style: const TextStyle(fontSize: 12),\n                                  overflow: TextOverflow.ellipsis,\n                                ),\n                              ),\n                            ],\n                          ),\n                        );\n                      }).toList(),\n                    ),\n                  ),\n                ],\n              ),\n            ),\n            const Divider(height: 24),\n            // Detail list\n            ...breakdown.asMap().entries.map((entry) {\n              final index = entry.key;\n              final info = entry.value;\n              final pct = totalBytes > 0\n                  ? (info.totalBytes / totalBytes) * 100\n                  : 0.0;\n              return Padding(\n                padding: const EdgeInsets.symmetric(vertical: 4),\n                child: Row(\n                  children: [\n                    Container(\n                      width: 12,\n                      height: 12,\n                      decoration: BoxDecoration(\n                        color: colors[index % colors.length],\n                        borderRadius: BorderRadius.circular(3),\n                      ),\n                    ),\n                    const SizedBox(width: 8),\n                    Expanded(\n                      child: Column(\n                        crossAxisAlignment: CrossAxisAlignment.start,\n                        children: [\n                          Row(\n                            mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                            children: [\n                              Text(\n                                info.platform,\n                                style: const TextStyle(fontWeight: FontWeight.w500),\n                              ),\n                              Text(\n                                StorageService.formatBytes(info.totalBytes),\n                                style: TextStyle(\n                                  fontSize: 12,\n                                  color: colorScheme.onSurfaceVariant,\n                                ),\n                              ),\n                            ],\n                          ),\n                          const SizedBox(height: 4),\n                          ClipRRect(\n                            borderRadius: BorderRadius.circular(2),\n                            child: LinearProgressIndicator(\n                              value: pct / 100,\n                              backgroundColor: colorScheme.surfaceContainerHighest,\n                              valueColor: AlwaysStoppedAnimation<Color>(\n                                colors[index % colors.length],\n                              ),\n                            ),\n                          ),\n                          const SizedBox(height: 2),\n                          Text(\n                            '${info.completedCount} completed, ${info.fileCount} total',\n                            style: TextStyle(\n                              fontSize: 11,\n                              color: colorScheme.onSurfaceVariant,\n                            ),\n                          ),\n                        ],\n                      ),\n                    ),\n                  ],\n                ),\n              );\n            }),\n          ],\n        ),\n      ),\n    );\n  }\n\n  Widget _buildLargestFilesCard(ThemeData theme, ColorScheme colorScheme) {\n    final files = _summary!.largestFiles;\n    if (files.isEmpty) {\n      return const SizedBox.shrink();\n    }\n\n    return Card(\n      child: Padding(\n        padding: const EdgeInsets.all(16),\n        child: Column(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            Row(\n              children: [\n                Icon(Icons.sort, color: colorScheme.primary),\n                const SizedBox(width: 8),\n                Text(\n                  'Largest Files',\n                  style: theme.textTheme.titleMedium?.copyWith(\n                    fontWeight: FontWeight.bold,\n                  ),\n                ),\n              ],\n            ),\n            const SizedBox(height: 12),\n            ...files.take(10).map((file) => _buildFileTile(file, theme, colorScheme)),\n          ],\n        ),\n      ),\n    );\n  }\n\n  Widget _buildFileTile(LargeFileInfo file, ThemeData theme, ColorScheme colorScheme) {\n    final age = DateTime.now().difference(file.downloadedAt);\n    String ageText;\n    if (age.inDays == 0) {\n      ageText = 'Today';\n    } else if (age.inDays == 1) {\n      ageText = 'Yesterday';\n    } else if (age.inDays < 30) {\n      ageText = '${age.inDays} days ago';\n    } else if (age.inDays < 365) {\n      ageText = '${(age.inDays / 30).floor()} months ago';\n    } else {\n      ageText = '${(age.inDays / 365).floor()} years ago';\n    }\n\n    return Dismissible(\n      key: ValueKey(file.id),\n      direction: DismissDirection.endToStart,\n      background: Container(\n        alignment: Alignment.centerRight,\n        padding: const EdgeInsets.only(right: 16),\n        decoration: BoxDecoration(\n          color: colorScheme.error,\n          borderRadius: BorderRadius.circular(8),\n        ),\n        child: Icon(Icons.delete, color: colorScheme.onError),\n      ),\n      confirmDismiss: (direction) async {\n        return showDialog<bool>(\n          context: context,\n          builder: (ctx) => AlertDialog(\n            title: const Text('Delete Download'),\n            content: Text(\n              'Delete \"${file.title}\"? This will remove the file from your device.',\n            ),\n            actions: [\n              TextButton(\n                onPressed: () => Navigator.pop(ctx, false),\n                child: const Text('Cancel'),\n              ),\n              FilledButton(\n                onPressed: () => Navigator.pop(ctx, true),\n                style: FilledButton.styleFrom(\n                  backgroundColor: colorScheme.error,\n                ),\n                child: const Text('Delete'),\n              ),\n            ],\n          ),\n        );\n      },\n      onDismissed: (direction) async {\n        await _performCleanup(\n          () => _storageService.deleteFiles([file.id]),\n        );\n      },\n      child: ListTile(\n        dense: true,\n        contentPadding: const EdgeInsets.symmetric(horizontal: 4),\n        leading: Icon(\n          file.status == 'completed' ? Icons.videocam : Icons.error_outline,\n          color: file.status == 'completed' ? colorScheme.primary : colorScheme.error,\n          size: 20,\n        ),\n        title: Text(\n          file.title,\n          maxLines: 1,\n          overflow: TextOverflow.ellipsis,\n          style: const TextStyle(fontSize: 13),\n        ),\n        subtitle: Text(\n          '${file.platform} · $ageText',\n          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),\n        ),\n        trailing: Container(\n          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),\n          decoration: BoxDecoration(\n            color: colorScheme.surfaceContainerHighest,\n            borderRadius: BorderRadius.circular(12),\n          ),\n          child: Text(\n            StorageService.formatBytes(file.fileSizeBytes),\n            style: TextStyle(\n              fontSize: 11,\n              fontWeight: FontWeight.w500,\n              color: colorScheme.onSurfaceVariant,\n            ),\n          ),\n        ),\n      ),\n    );\n  }\n\n  Widget _buildCleanupActionsCard(ThemeData theme, ColorScheme colorScheme) {\n    return Card(\n      child: Padding(\n        padding: const EdgeInsets.all(16),\n        child: Column(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            Row(\n              children: [\n                Icon(Icons.cleaning_services, color: colorScheme.primary),\n                const SizedBox(width: 8),\n                Text(\n                  'One-Tap Cleanup',\n                  style: theme.textTheme.titleMedium?.copyWith(\n                    fontWeight: FontWeight.bold,\n                  ),\n                ),\n              ],\n            ),\n            const SizedBox(height: 12),\n            // Cleanup options\n            _buildCleanupOption(\n              icon: Icons.error_outline,\n              title: 'Remove Failed Downloads',\n              subtitle: 'Clear all failed download records',\n              color: colorScheme.error,\n              onTap: _isCleaning\n                  ? null\n                  : () => _performCleanup(\n                        () => _storageService.cleanupFailedDownloads(),\n                      ),\n            ),\n            const SizedBox(height: 8),\n            _buildCleanupOption(\n              icon: Icons.folder_off_outlined,\n              title: 'Remove Orphaned Records',\n              subtitle: 'Clean up records for files no longer on disk',\n              color: colorScheme.tertiary,\n              onTap: _isCleaning\n                  ? null\n                  : () => _performCleanup(\n                        () => _storageService.cleanupOrphanedRecords(),\n                      ),\n            ),\n            const SizedBox(height: 8),\n            _buildCleanupOption(\n              icon: Icons.schedule_outlined,\n              title: 'Remove Downloads Older Than 30 Days',\n              subtitle: 'Delete completed downloads from over 30 days ago',\n              color: colorScheme.secondary,\n              onTap: _isCleaning\n                  ? null\n                  : () => _performCleanup(\n                        () => _storageService.cleanupOldDownloads(30),\n                      ),\n            ),\n            const SizedBox(height: 8),\n            _buildCleanupOption(\n              icon: Icons.delete_sweep_outlined,\n              title: 'Remove All Downloads',\n              subtitle: 'Delete all downloaded files and records',\n              color: colorScheme.error,\n              onTap: _isCleaning ? null : () => _showDeleteAllConfirmation(),\n            ),\n          ],\n        ),\n      ),\n    );\n  }\n\n  Widget _buildCleanupOption({\n    required IconData icon,\n    required String title,\n    required String subtitle,\n    required Color color,\n    required VoidCallback? onTap,\n  }) {\n    return InkWell(\n      onTap: onTap,\n      borderRadius: BorderRadius.circular(8),\n      child: Container(\n        padding: const EdgeInsets.all(12),\n        decoration: BoxDecoration(\n          border: Border.all(color: color.withValues(alpha: 0.3)),\n          borderRadius: BorderRadius.circular(8),\n        ),\n        child: Row(\n          children: [\n            Icon(icon, color: color, size: 22),\n            const SizedBox(width: 12),\n            Expanded(\n              child: Column(\n                crossAxisAlignment: CrossAxisAlignment.start,\n                children: [\n                  Text(\n                    title,\n                    style: const TextStyle(fontWeight: FontWeight.w500),\n                  ),\n                  Text(\n                    subtitle,\n                    style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),\n                  ),\n                ],\n              ),\n            ),\n            if (_isCleaning)\n              const SizedBox(\n                width: 16,\n                height: 16,\n                child: CircularProgressIndicator(strokeWidth: 2),\n              )\n            else\n              Icon(Icons.chevron_right, color: color, size: 20),\n          ],\n        ),\n      ),\n    );\n  }\n\n  Widget _buildAutoCleanupCard(ThemeData theme, ColorScheme colorScheme) {\n    return Card(\n      child: Padding(\n        padding: const EdgeInsets.all(16),\n        child: Column(\n          crossAxisAlignment: CrossAxisAlignment.start,\n          children: [\n            Row(\n              children: [\n                Icon(Icons.auto_delete_outlined, color: colorScheme.primary),\n                const SizedBox(width: 8),\n                Text(\n                  'Auto-Cleanup Rules',\n                  style: theme.textTheme.titleMedium?.copyWith(\n                    fontWeight: FontWeight.bold,\n                  ),\n                ),\n              ],\n            ),\n            const SizedBox(height: 12),\n            // Cleanup rule selector\n            Text(\n              'Automatically delete completed downloads:',\n              style: theme.textTheme.bodyMedium,\n            ),\n            const SizedBox(height: 8),\n            Wrap(\n              spacing: 8,\n              runSpacing: 8,\n              children: CleanupRule.values.map((rule) {\n                final isSelected = _cleanupRule == rule;\n                return ChoiceChip(\n                  label: Text(rule.label),\n                  selected: isSelected,\n                  onSelected: (selected) async {\n                    if (selected) {\n                      await _storageService.setCleanupRule(rule);\n                      setState(() => _cleanupRule = rule);\n                    }\n                  },\n                );\n              }).toList(),\n            ),\n            const SizedBox(height: 16),\n            // Auto-cleanup failed downloads toggle\n            SwitchListTile(\n              value: _cleanupFailed,\n              onChanged: (value) async {\n                await _storageService.setCleanupFailedEnabled(value);\n                setState(() => _cleanupFailed = value);\n              },\n              title: const Text('Auto-remove failed downloads'),\n              subtitle: const Text(\n                'Automatically delete records for failed downloads',\n              ),\n              contentPadding: EdgeInsets.zero,\n              dense: true,\n            ),\n          ],\n        ),\n      ),\n    );\n  }\n\n  Future<void> _showDeleteAllConfirmation() async {\n    final confirmed = await showDialog<bool>(\n      context: context,\n      builder: (ctx) => AlertDialog(\n        title: const Text('Delete All Downloads?'),\n        content: const Text(\n          'This will permanently delete all downloaded files and remove all '\n          'download records. This action cannot be undone.',\n        ),\n        actions: [\n          TextButton(\n            onPressed: () => Navigator.pop(ctx, false),\n            child: const Text('Cancel'),\n          ),\n          FilledButton(\n            onPressed: () => Navigator.pop(ctx, true),\n            style: FilledButton.styleFrom(\n              backgroundColor: Theme.of(context).colorScheme.error,\n            ),\n            child: const Text('Delete All'),\n          ),\n        ],\n      ),\n    );\n\n    if (confirmed == true && mounted) {\n      await _performCleanup(() async {\n        // First delete old downloads (all of them)\n        final result1 = await _storageService.cleanupOldDownloads(0);\n        // Then clean failed\n        final result2 = await _storageService.cleanupFailedDownloads();\n        // Then clean orphaned\n        final result3 = await _storageService.cleanupOrphanedRecords();\n        return CleanupResult(\n          filesDeleted: result1.filesDeleted + result2.filesDeleted + result3.filesDeleted,\n          bytesFreed: result1.bytesFreed + result2.bytesFreed + result3.bytesFreed,\n          errors: [...result1.errors, ...result2.errors, ...result3.errors],\n        );\n      });\n    }\n  }\n}\n"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring current codebase state",
      "content": "Explore current codebase state and existing files",
      "status": "completed"
    },
    {
      "activeForm": "Creating StorageService",
      "content": "Create StorageService for storage calculations and cleanup",
      "status": "completed"
    },
    {
      "activeForm": "Implementing StorageManagementScreen UI",
      "content": "Implement StorageManagementScreen UI",
      "status": "completed"
    },
    {
      "activeForm": "Adding cleanup rules and auto-cleanup",
      "content": "Add cleanup rules and auto-cleanup functionality",
      "status": "completed"
    },
    {
      "activeForm": "Integrating into app navigation",
      "content": "Integrate storage screen into app navigation in main.dart",
      "status": "in_progress"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "pending"
    }
  ]
}
Now integrate the storage screen into `main.dart`. I need to add the import and a button in the app bar.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "import 'download_analytics_screen.dart';\nimport 'dart:async';",
  "new_string": "import 'download_analytics_screen.dart';\nimport 'storage_management_screen.dart';\nimport 'storage_service.dart';\nimport 'dart:async';"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 35
}
The file has been updated since I last read it — there are new imports for `download_scheduler.dart` and `download_schedule_screen.dart`. Let me add the storage imports.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "import 'download_analytics_screen.dart';\nimport 'dart:async';",
  "new_string": "import 'download_analytics_screen.dart';\nimport 'storage_management_screen.dart';\nimport 'storage_service.dart';\nimport 'dart:async';"
}
Now let me add the global StorageService and add auto-cleanup to the `main()` function, plus add the storage button to the AppBar.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 30,
  "offset": 52
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "// --- Global download scheduler ---\nfinal DownloadScheduler _scheduler = DownloadScheduler();\n\n// --- Error handling ---",
  "new_string": "// --- Global download scheduler ---\nfinal DownloadScheduler _scheduler = DownloadScheduler();\n\n// --- Global storage service ---\nfinal StorageService _storageService = StorageService();\n\n// --- Error handling ---"
}
Now add auto-cleanup call in the `main()` function.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 30,
  "offset": 165
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 15,
  "offset": 193
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "  _scheduler.queueManager = _queueManager;\n  _scheduler.networkMonitor = _networkMonitor;\n  await _scheduler.init();\n  runApp(const MyApp());",
  "new_string": "  _scheduler.queueManager = _queueManager;\n  _scheduler.networkMonitor = _networkMonitor;\n  await _scheduler.init();\n  // Run auto-cleanup in background (doesn't block startup)\n  _storageService.runAutoCleanup();\n  runApp(const MyApp());"
}
Now add the storage management button to the AppBar. Let me find the actions section.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 80,
  "offset": 740
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 40,
  "offset": 819
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 20,
  "offset": 858
}
I'll add the Storage Management button in the AppBar, right after the Filename Templates button.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "          IconButton(\n            icon: const Icon(Icons.edit_note),\n            tooltip: 'Filename Templates',\n            onPressed: () {\n              Navigator.push(\n                context,\n                MaterialPageRoute(\n                  builder: (_) => const FilenameTemplateSettingsScreen(),\n                ),\n              );\n            },\n          ),",
  "new_string": "          IconButton(\n            icon: const Icon(Icons.edit_note),\n            tooltip: 'Filename Templates',\n            onPressed: () {\n              Navigator.push(\n                context,\n                MaterialPageRoute(\n                  builder: (_) => const FilenameTemplateSettingsScreen(),\n                ),\n              );\n            },\n          ),\n          IconButton(\n            icon: const Icon(Icons.storage),\n            tooltip: 'Storage Management',\n            onPressed: () {\n              Navigator.push(\n                context,\n                MaterialPageRoute(\n                  builder: (_) => const StorageManagementScreen(),\n                ),\n              );\n            },\n          ),"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring current codebase state",
      "content": "Explore current codebase state and existing files",
      "status": "completed"
    },
    {
      "activeForm": "Creating StorageService",
      "content": "Create StorageService for storage calculations and cleanup",
      "status": "completed"
    },
    {
      "activeForm": "Implementing StorageManagementScreen UI",
      "content": "Implement StorageManagementScreen UI",
      "status": "completed"
    },
    {
      "activeForm": "Adding cleanup rules and auto-cleanup",
      "content": "Add cleanup rules and auto-cleanup functionality",
      "status": "completed"
    },
    {
      "activeForm": "Integrating into app navigation",
      "content": "Integrate storage screen into app navigation in main.dart",
      "status": "completed"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "in_progress"
    }
  ]
}
Let me verify the implementation compiles by running the Flutter analyzer.

🔧 Tool: Bash
Input: {
  "command": "cd C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend && flutter analyze lib/storage_service.dart lib/storage_management_screen.dart lib/main.dart 2>&1",
  "description": "Run Flutter static analysis on new and modified files",
  "timeout": 120000
}

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && flutter analyze lib/storage_service.dart lib/storage_management_screen.dart lib/main.dart 2>&1",
  "description": "Run Flutter static analysis on new and modified files",
  "timeout": 120000
}
Good, only warnings — no errors. Let me clean up those warnings.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\storage_management_screen.dart",
  "old_string": "import 'dart:io';\nimport 'package:flutter/material.dart';",
  "new_string": "import 'package:flutter/material.dart';"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\storage_management_screen.dart",
  "limit": 10,
  "offset": 118
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\storage_management_screen.dart",
  "old_string": "    final completedPct = total > 0 ? summary.completedBytes / total : 0.0;\n    final failedPct = total > 0 ? summary.failedBytes / total : 0.0;",
  "new_string": "    final completedPct = total > 0 ? summary.completedBytes / total : 0.0;"
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\storage_service.dart",
  "old_string": "import 'dart:io';\nimport 'package:path_provider/path_provider.dart';\nimport 'package:shared_preferences/shared_preferences.dart';",
  "new_string": "import 'dart:io';\nimport 'package:shared_preferences/shared_preferences.dart';"
}
Now fix the unused `records` variable in `storage_service.dart`.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\storage_service.dart",
  "limit": 25,
  "offset": 212
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\storage_service.dart",
  "old_string": "    for (final id in ids) {\n      final records = await _db.getAllRecords(limit: 1);\n      // Get the specific record\n      final db = await _db.database;",
  "new_string": "    for (final id in ids) {\n      // Get the specific record\n      final db = await _db.database;"
}

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && flutter analyze lib/storage_service.dart lib/storage_management_screen.dart lib/main.dart 2>&1",
  "description": "Verify all warnings are resolved",
  "timeout": 120000
}
All clean — zero issues. Let me mark the final todo as complete.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring current codebase state",
      "content": "Explore current codebase state and existing files",
      "status": "completed"
    },
    {
      "activeForm": "Creating StorageService",
      "content": "Create StorageService for storage calculations and cleanup",
      "status": "completed"
    },
    {
      "activeForm": "Implementing StorageManagementScreen UI",
      "content": "Implement StorageManagementScreen UI",
      "status": "completed"
    },
    {
      "activeForm": "Adding cleanup rules and auto-cleanup",
      "content": "Add cleanup rules and auto-cleanup functionality",
      "status": "completed"
    },
    {
      "activeForm": "Integrating into app navigation",
      "content": "Integrate storage screen into app navigation in main.dart",
      "status": "completed"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "completed"
    }
  ]
}
<summary>
## Summary: Storage Usage Dashboard

### Changes Implemented

- **StorageService** (`lib/storage_service.dart`): Full-featured service providing:
  - Storage summary calculation (total bytes, completed/failed/deleted counts, files on disk, orphaned records)
  - Platform breakdown (bytes and count per platform)
  - Largest files listing (top 20 by size)
  - File existence verification to detect orphaned records
  - One-tap cleanup actions: failed downloads, orphaned records, old downloads (configurable age), delete all
  - Auto-cleanup rules with configurable age threshold (7/14/30/60/90 days or never)
  - Auto-cleanup of failed downloads toggle
  - Throttled auto-cleanup (max once per hour)
  - SharedPreferences-based settings persistence

- **StorageManagementScreen** (`lib/storage_management_screen.dart`): Complete UI with:
  - Storage overview card with total usage, stats (completed/failed/deleted/on disk), and orphaned records warning
  - Platform breakdown with pie chart (using fl_chart) and detailed per-platform progress bars
  - Largest files list with swipe-to-delete and confirmation dialog
  - One-tap cleanup actions card with: remove failed, remove orphaned, remove older than 30 days, delete all
  - Auto-cleanup rules card with chip-based rule selector and toggle for auto-removing failed downloads
  - Pull-to-refresh support
  - Loading and error states

- **main.dart integration**:
  - Added `StorageService` global instance
  - Added auto-cleanup call on app startup (non-blocking)
  - Added storage management button (storage icon) in AppBar actions

### Files Modified
- `lib/storage_service.dart` (new) — Storage calculation and cleanup service
- `lib/storage_management_screen.dart` (new) — Full storage management UI
- `lib/main.dart` (modified) — Added imports, global service, auto-cleanup on startup, and AppBar navigation button

### Notes for Developer
- Flutter analyze passes with zero issues
- Auto-cleanup runs once per hour maximum (configurable in `StorageService.runAutoCleanup`)
- The pie chart uses `fl_chart` which is already a project dependency
- Individual file deletion uses `Dismissible` swipe gestures with confirmation dialog
- All cleanup operations update the UI immediately via `_loadData()` refresh
</summary>