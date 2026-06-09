CogniLayer v4 active — persistent memory is on. Type /cognihelp for available commands.

Let me start by exploring the codebase properly using the available tools to understand the current structure before implementing the download-scheduling feature.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Explore codebase structure and existing code",
      "status": "in_progress",
      "activeForm": "Exploring codebase structure"
    },
    {
      "content": "Review existing download logic and models",
      "status": "pending",
      "activeForm": "Reviewing download logic and models"
    },
    {
      "content": "Implement scheduled download data models",
      "status": "pending",
      "activeForm": "Implementing scheduled download models"
    },
    {
      "content": "Implement Android JobScheduler integration",
      "status": "pending",
      "activeForm": "Implementing JobScheduler integration"
    },
    {
      "content": "Implement scheduling UI screen",
      "status": "pending",
      "activeForm": "Implementing scheduling UI"
    },
    {
      "content": "Integrate scheduling with main app flow",
      "status": "pending",
      "activeForm": "Integrating with main app"
    },
    {
      "content": "Verify and test implementation",
      "status": "pending",
      "activeForm": "Verifying implementation"
    }
  ]
}

🔧 Tool: Bash
Input: {
  "command": "dir /B \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\"",
  "description": "List Flutter lib directory"
}

🔧 Tool: Bash
Input: {
  "command": "dir /B \"C:\\Projects\\x_video_downloader\"",
  "description": "List project root directory"
}

🔧 Tool: Bash
Input: {
  "command": "ls \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\"",
  "description": "List Flutter lib directory contents"
}

🔧 Tool: Bash
Input: {
  "command": "ls \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\"",
  "description": "List Flutter project root"
}

🔧 Tool: Bash
Input: {
  "command": "ls \"C:\\Projects\\x_video_downloader\\fly.io backend\"",
  "description": "List backend directory"
}
Now let me read the key files to understand the existing download infrastructure.

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
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\background_download_service.dart"
}
Now let me read the remaining key files.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_manager.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\queue_item.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\network_monitor.dart"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart"
}
Now let me read the database file to understand the persistence layer.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart"
}
Now I have a thorough understanding of the codebase. Let me update my task plan and start implementing.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing code",
      "status": "completed"
    },
    {
      "activeForm": "Reviewing download logic and models",
      "content": "Review existing download logic and models",
      "status": "completed"
    },
    {
      "activeForm": "Creating scheduled download model",
      "content": "Create ScheduledDownload model",
      "status": "in_progress"
    },
    {
      "activeForm": "Updating database schema for scheduling",
      "content": "Update database schema with scheduled_downloads table",
      "status": "pending"
    },
    {
      "activeForm": "Creating download scheduler service",
      "content": "Create DownloadScheduler service",
      "status": "pending"
    },
    {
      "activeForm": "Implementing scheduling UI screen",
      "content": "Implement scheduling UI screen",
      "status": "pending"
    },
    {
      "activeForm": "Integrating scheduling with main app",
      "content": "Integrate scheduling with main app and queue screen",
      "status": "pending"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "pending"
    }
  ]
}
Let me create the `ScheduledDownload` model first.

🔧 Tool: Write
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\scheduled_download.dart",
  "content": "/// Represents a scheduled download that will execute at a specified time.\n///\n/// Supports one-time and recurring schedules with optional WiFi-only constraint.\nclass ScheduledDownload {\n  final int? id;\n  final String url;\n  final String platform;\n  final String title;\n  final String? thumbnailUrl;\n\n  // Schedule configuration\n  final DateTime scheduledTime;\n  final ScheduleRecurrence recurrence;\n  final bool wifiOnly;\n\n  // Format selection (optional — null means best quality)\n  final String? formatId;\n  final String? formatLabel;\n\n  // Status tracking\n  final ScheduledDownloadStatus status;\n  final DateTime createdAt;\n  final DateTime? lastExecutedAt;\n  final int executionCount;\n  final String? errorMessage;\n\n  ScheduledDownload({\n    this.id,\n    required this.url,\n    required this.platform,\n    required this.title,\n    this.thumbnailUrl,\n    required this.scheduledTime,\n    this.recurrence = ScheduleRecurrence.once,\n    this.wifiOnly = false,\n    this.formatId,\n    this.formatLabel,\n    this.status = ScheduledDownloadStatus.scheduled,\n    required this.createdAt,\n    this.lastExecutedAt,\n    this.executionCount = 0,\n    this.errorMessage,\n  });\n\n  /// Human-readable description of the recurrence pattern.\n  String get recurrenceLabel {\n    switch (recurrence) {\n      case ScheduleRecurrence.once:\n        return 'One-time';\n      case ScheduleRecurrence.daily:\n        return 'Daily';\n      case ScheduleRecurrence.weekdays:\n        return 'Weekdays';\n      case ScheduleRecurrence.weekends:\n        return 'Weekends';\n      case ScheduleRecurrence.weekly:\n        return 'Weekly';\n    }\n  }\n\n  /// The next execution time based on recurrence and last execution.\n  DateTime? get nextExecution {\n    if (status == ScheduledDownloadStatus.cancelled ||\n        status == ScheduledDownloadStatus.error) {\n      return null;\n    }\n    if (recurrence == ScheduleRecurrence.once) {\n      return status == ScheduledDownloadStatus.scheduled\n          ? scheduledTime\n          : null;\n    }\n    if (lastExecutedAt == null) return scheduledTime;\n\n    // Calculate next occurrence from last execution\n    DateTime next;\n    switch (recurrence) {\n      case ScheduleRecurrence.daily:\n        next = DateTime(\n          lastExecutedAt!.year,\n          lastExecutedAt!.month,\n          lastExecutedAt!.day + 1,\n          scheduledTime.hour,\n          scheduledTime.minute,\n        );\n        break;\n      case ScheduleRecurrence.weekdays:\n        next = _nextWeekday(lastExecutedAt!);\n        break;\n      case ScheduleRecurrence.weekends:\n        next = _nextWeekend(lastExecutedAt!);\n        break;\n      case ScheduleRecurrence.weekly:\n        next = DateTime(\n          lastExecutedAt!.year,\n          lastExecutedAt!.month,\n          lastExecutedAt!.day + 7,\n          scheduledTime.hour,\n          scheduledTime.minute,\n        );\n        break;\n      default:\n        return scheduledTime;\n    }\n\n    // If next is still in the past, advance day by day until future\n    while (next.isBefore(DateTime.now())) {\n      next = next.add(const Duration(days: 1));\n    }\n\n    return next;\n  }\n\n  DateTime _nextWeekday(DateTime from) {\n    var next = DateTime(\n      from.year,\n      from.month,\n      from.day + 1,\n      scheduledTime.hour,\n      scheduledTime.minute,\n    );\n    while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {\n      next = next.add(const Duration(days: 1));\n    }\n    return next;\n  }\n\n  DateTime _nextWeekend(DateTime from) {\n    var next = DateTime(\n      from.year,\n      from.month,\n      from.day + 1,\n      scheduledTime.hour,\n      scheduledTime.minute,\n    );\n    while (next.weekday != DateTime.saturday && next.weekday != DateTime.sunday) {\n      next = next.add(const Duration(days: 1));\n    }\n    return next;\n  }\n\n  factory ScheduledDownload.fromMap(Map<String, dynamic> map) {\n    return ScheduledDownload(\n      id: map['id'] as int?,\n      url: map['url'] as String,\n      platform: map['platform'] as String,\n      title: map['title'] as String,\n      thumbnailUrl: map['thumbnailUrl'] as String?,\n      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduledTime'] as int),\n      recurrence: ScheduleRecurrence.values.firstWhere(\n        (r) => r.name == (map['recurrence'] as String),\n        orElse: () => ScheduleRecurrence.once,\n      ),\n      wifiOnly: (map['wifiOnly'] as int?) == 1,\n      formatId: map['formatId'] as String?,\n      formatLabel: map['formatLabel'] as String?,\n      status: ScheduledDownloadStatus.values.firstWhere(\n        (s) => s.name == (map['status'] as String),\n        orElse: () => ScheduledDownloadStatus.scheduled,\n      ),\n      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),\n      lastExecutedAt: map['lastExecutedAt'] != null\n          ? DateTime.fromMillisecondsSinceEpoch(map['lastExecutedAt'] as int)\n          : null,\n      executionCount: (map['executionCount'] as num?)?.toInt() ?? 0,\n      errorMessage: map['errorMessage'] as String?,\n    );\n  }\n\n  Map<String, dynamic> toMap() {\n    return {\n      if (id != null) 'id': id,\n      'url': url,\n      'platform': platform,\n      'title': title,\n      'thumbnailUrl': thumbnailUrl,\n      'scheduledTime': scheduledTime.millisecondsSinceEpoch,\n      'recurrence': recurrence.name,\n      'wifiOnly': wifiOnly ? 1 : 0,\n      'formatId': formatId,\n      'formatLabel': formatLabel,\n      'status': status.name,\n      'createdAt': createdAt.millisecondsSinceEpoch,\n      'lastExecutedAt': lastExecutedAt?.millisecondsSinceEpoch,\n      'executionCount': executionCount,\n      'errorMessage': errorMessage,\n    };\n  }\n\n  ScheduledDownload copyWith({\n    int? id,\n    String? url,\n    String? platform,\n    String? title,\n    String? thumbnailUrl,\n    DateTime? scheduledTime,\n    ScheduleRecurrence? recurrence,\n    bool? wifiOnly,\n    String? formatId,\n    String? formatLabel,\n    ScheduledDownloadStatus? status,\n    DateTime? createdAt,\n    DateTime? lastExecutedAt,\n    int? executionCount,\n    String? errorMessage,\n  }) {\n    return ScheduledDownload(\n      id: id ?? this.id,\n      url: url ?? this.url,\n      platform: platform ?? this.platform,\n      title: title ?? this.title,\n      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,\n      scheduledTime: scheduledTime ?? this.scheduledTime,\n      recurrence: recurrence ?? this.recurrence,\n      wifiOnly: wifiOnly ?? this.wifiOnly,\n      formatId: formatId ?? this.formatId,\n      formatLabel: formatLabel ?? this.formatLabel,\n      status: status ?? this.status,\n      createdAt: createdAt ?? this.createdAt,\n      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,\n      executionCount: executionCount ?? this.executionCount,\n      errorMessage: errorMessage ?? this.errorMessage,\n    );\n  }\n}\n\n/// How often a scheduled download recurs.\nenum ScheduleRecurrence {\n  once,\n  daily,\n  weekdays,\n  weekends,\n  weekly,\n}\n\n/// Status of a scheduled download.\nenum ScheduledDownloadStatus {\n  scheduled,\n  executing,\n  completed,\n  cancelled,\n  error,\n}\n"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing code",
      "status": "completed"
    },
    {
      "activeForm": "Reviewing download logic and models",
      "content": "Review existing download logic and models",
      "status": "completed"
    },
    {
      "activeForm": "Creating scheduled download model",
      "content": "Create ScheduledDownload model",
      "status": "completed"
    },
    {
      "activeForm": "Updating database schema for scheduling",
      "content": "Update database schema with scheduled_downloads table",
      "status": "in_progress"
    },
    {
      "activeForm": "Creating download scheduler service",
      "content": "Create DownloadScheduler service",
      "status": "pending"
    },
    {
      "activeForm": "Implementing scheduling UI screen",
      "content": "Implement scheduling UI screen",
      "status": "pending"
    },
    {
      "activeForm": "Integrating scheduling with main app",
      "content": "Integrate scheduling with main app and queue screen",
      "status": "pending"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "pending"
    }
  ]
}
Now update the database to add the `scheduled_downloads` table.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "old_string": "import 'download_record.dart';\nimport 'queue_item.dart';",
  "new_string": "import 'download_record.dart';\nimport 'queue_item.dart';\nimport 'scheduled_download.dart';"
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "old_string": "      onCreate: (db, version) async {\n        await _createDownloadsTable(db);\n        await _createQueueItemsTable(db);\n      },",
  "new_string": "      onCreate: (db, version) async {\n        await _createDownloadsTable(db);\n        await _createQueueItemsTable(db);\n        await _createScheduledDownloadsTable(db);\n      },"
}
Now add the migration for existing databases and the new table creation method plus CRUD methods.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "old_string": "    return openDatabase(\n      path,\n      version: 5,",
  "new_string": "    return openDatabase(\n      path,\n      version: 6,"
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "old_string": "        if (oldVersion < 5) {\n          await db.execute(\n            'ALTER TABLE downloads ADD COLUMN thumbnailUrl TEXT',\n          );\n        }",
  "new_string": "        if (oldVersion < 5) {\n          await db.execute(\n            'ALTER TABLE downloads ADD COLUMN thumbnailUrl TEXT',\n          );\n        }\n        if (oldVersion < 6) {\n          await _createScheduledDownloadsTable(db);\n        }"
}
Now add the table creation method and CRUD methods for scheduled downloads. I'll add them after the queue items table creation method.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "old_string": "    await db.execute(\n      'CREATE INDEX idx_queue_items_createdAt ON queue_items(createdAt)',\n    );\n  }",
  "new_string": "    await db.execute(\n      'CREATE INDEX idx_queue_items_createdAt ON queue_items(createdAt)',\n    );\n  }\n\n  Future<void> _createScheduledDownloadsTable(Database db) async {\n    await db.execute('''\n      CREATE TABLE scheduled_downloads (\n        id INTEGER PRIMARY KEY AUTOINCREMENT,\n        url TEXT NOT NULL,\n        platform TEXT NOT NULL,\n        title TEXT NOT NULL,\n        thumbnailUrl TEXT,\n        scheduledTime INTEGER NOT NULL,\n        recurrence TEXT NOT NULL DEFAULT 'once',\n        wifiOnly INTEGER NOT NULL DEFAULT 0,\n        formatId TEXT,\n        formatLabel TEXT,\n        status TEXT NOT NULL DEFAULT 'scheduled',\n        createdAt INTEGER NOT NULL,\n        lastExecutedAt INTEGER,\n        executionCount INTEGER NOT NULL DEFAULT 0,\n        errorMessage TEXT\n      )\n    ''');\n    await db.execute(\n      'CREATE INDEX idx_scheduled_downloads_status ON scheduled_downloads(status)',\n    );\n    await db.execute(\n      'CREATE INDEX idx_scheduled_downloads_scheduledTime ON scheduled_downloads(scheduledTime)',\n    );\n  }"
}
Now add the CRUD methods for scheduled downloads at the end of the class (before the closing brace). Let me read the current end of the file.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "offset": 350
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_database.dart",
  "old_string": "  /// Get all download records for export.\n  Future<List<DownloadRecord>> getAllRecordsForExport() async {\n    final db = await database;\n    final results = await db.query(\n      'downloads',\n      orderBy: 'downloadedAt DESC',\n    );\n    return results.map((m) => DownloadRecord.fromMap(m)).toList();\n  }\n}",
  "new_string": "  /// Get all download records for export.\n  Future<List<DownloadRecord>> getAllRecordsForExport() async {\n    final db = await database;\n    final results = await db.query(\n      'downloads',\n      orderBy: 'downloadedAt DESC',\n    );\n    return results.map((m) => DownloadRecord.fromMap(m)).toList();\n  }\n\n  // --- Scheduled downloads CRUD ---\n\n  /// Insert a new scheduled download.\n  Future<int> insertScheduledDownload(ScheduledDownload schedule) async {\n    final db = await database;\n    return db.insert('scheduled_downloads', schedule.toMap());\n  }\n\n  /// Get all active (scheduled) downloads, ordered by next execution time.\n  Future<List<ScheduledDownload>> getActiveScheduledDownloads() async {\n    final db = await database;\n    final results = await db.query(\n      'scheduled_downloads',\n      where: 'status IN (?, ?)',\n      whereArgs: ['scheduled', 'error'],\n      orderBy: 'scheduledTime ASC',\n    );\n    return results.map((m) => ScheduledDownload.fromMap(m)).toList();\n  }\n\n  /// Get all scheduled downloads (including completed/cancelled).\n  Future<List<ScheduledDownload>> getAllScheduledDownloads() async {\n    final db = await database;\n    final results = await db.query(\n      'scheduled_downloads',\n      orderBy: 'scheduledTime ASC',\n    );\n    return results.map((m) => ScheduledDownload.fromMap(m)).toList();\n  }\n\n  /// Get scheduled downloads that are due for execution.\n  Future<List<ScheduledDownload>> getDueScheduledDownloads() async {\n    final now = DateTime.now().millisecondsSinceEpoch;\n    final db = await database;\n    final results = await db.query(\n      'scheduled_downloads',\n      where: 'status = ? AND scheduledTime <= ?',\n      whereArgs: ['scheduled', now],\n      orderBy: 'scheduledTime ASC',\n    );\n    return results.map((m) => ScheduledDownload.fromMap(m)).toList();\n  }\n\n  /// Update a scheduled download.\n  Future<int> updateScheduledDownload(ScheduledDownload schedule) async {\n    final db = await database;\n    return db.update(\n      'scheduled_downloads',\n      schedule.toMap(),\n      where: 'id = ?',\n      whereArgs: [schedule.id],\n    );\n  }\n\n  /// Delete a scheduled download by ID.\n  Future<int> deleteScheduledDownload(int id) async {\n    final db = await database;\n    return db.delete('scheduled_downloads', where: 'id = ?', whereArgs: [id]);\n  }\n}"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing code",
      "status": "completed"
    },
    {
      "activeForm": "Reviewing download logic and models",
      "content": "Review existing download logic and models",
      "status": "completed"
    },
    {
      "activeForm": "Creating scheduled download model",
      "content": "Create ScheduledDownload model",
      "status": "completed"
    },
    {
      "activeForm": "Updating database schema for scheduling",
      "content": "Update database schema with scheduled_downloads table",
      "status": "completed"
    },
    {
      "activeForm": "Creating download scheduler service",
      "content": "Create DownloadScheduler service",
      "status": "in_progress"
    },
    {
      "activeForm": "Implementing scheduling UI screen",
      "content": "Implement scheduling UI screen",
      "status": "pending"
    },
    {
      "activeForm": "Integrating scheduling with main app",
      "content": "Integrate scheduling with main app and queue screen",
      "status": "pending"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "pending"
    }
  ]
}
Now create the `DownloadScheduler` service. This is the core service that manages scheduled downloads — checking for due schedules, adding them to the queue manager, and handling recurrence.

🔧 Tool: Write
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_scheduler.dart",
  "content": "import 'dart:async';\n\nimport 'package:flutter/foundation.dart';\n\nimport 'download_database.dart';\nimport 'download_queue_manager.dart';\nimport 'network_monitor.dart';\nimport 'scheduled_download.dart';\n\n/// Service that manages scheduled downloads by periodically checking for\n/// due schedules and submitting them to the download queue.\n///\n/// Uses a periodic timer that checks every minute for scheduled downloads\n/// whose execution time has arrived. Supports WiFi-only constraints and\n/// automatic recurrence handling.\nclass DownloadScheduler extends ChangeNotifier {\n  final DownloadDatabase _db = DownloadDatabase();\n  DownloadQueueManager? queueManager;\n  NetworkMonitor? networkMonitor;\n\n  /// In-memory list of active scheduled downloads.\n  final List<ScheduledDownload> _schedules = [];\n  List<ScheduledDownload> get schedules => List.unmodifiable(_schedules);\n\n  /// Timer that fires every minute to check for due schedules.\n  Timer? _checkTimer;\n\n  bool _initialized = false;\n\n  /// Initialize the scheduler: load persisted schedules and start the timer.\n  Future<void> init() async {\n    if (_initialized) return;\n    _initialized = true;\n\n    final items = await _db.getActiveScheduledDownloads();\n    _schedules.addAll(items);\n\n    // Check immediately on startup for any schedules that were due while\n    // the app was closed.\n    await _checkAndExecuteDue();\n\n    // Start periodic check — every 60 seconds\n    _checkTimer = Timer.periodic(const Duration(seconds: 60), (_) {\n      _checkAndExecuteDue();\n    });\n\n    notifyListeners();\n  }\n\n  /// Add a new scheduled download.\n  Future<ScheduledDownload> addSchedule(ScheduledDownload schedule) async {\n    final id = await _db.insertScheduledDownload(schedule);\n    final saved = schedule.copyWith(id: id);\n    _schedules.add(saved);\n    notifyListeners();\n    return saved;\n  }\n\n  /// Cancel a scheduled download.\n  Future<void> cancelSchedule(int scheduleId) async {\n    final index = _schedules.indexWhere((s) => s.id == scheduleId);\n    if (index == -1) return;\n\n    _schedules[index] = _schedules[index].copyWith(\n      status: ScheduledDownloadStatus.cancelled,\n    );\n    await _db.updateScheduledDownload(_schedules[index]);\n    _schedules.removeAt(index);\n    notifyListeners();\n  }\n\n  /// Update an existing scheduled download.\n  Future<void> updateSchedule(ScheduledDownload schedule) async {\n    final index = _schedules.indexWhere((s) => s.id == schedule.id);\n    if (index == -1) return;\n\n    _schedules[index] = schedule;\n    await _db.updateScheduledDownload(schedule);\n    notifyListeners();\n  }\n\n  /// Delete a scheduled download (regardless of status).\n  Future<void> deleteSchedule(int scheduleId) async {\n    _schedules.removeWhere((s) => s.id == scheduleId);\n    await _db.deleteScheduledDownload(scheduleId);\n    notifyListeners();\n  }\n\n  /// Check for schedules that are due and execute them.\n  Future<void> _checkAndExecuteDue() async {\n    if (queueManager == null) return;\n\n    final now = DateTime.now();\n    final toExecute = <ScheduledDownload>[];\n\n    for (int i = 0; i < _schedules.length; i++) {\n      final schedule = _schedules[i];\n      if (schedule.status != ScheduledDownloadStatus.scheduled) continue;\n\n      final nextTime = schedule.nextExecution;\n      if (nextTime != null && !nextTime.isAfter(now)) {\n        // Check WiFi constraint\n        if (schedule.wifiOnly &&\n            networkMonitor != null &&\n            !networkMonitor!.isOnWifi) {\n          continue; // Skip — not on WiFi\n        }\n        toExecute.add(schedule);\n      }\n    }\n\n    for (final schedule in toExecute) {\n      await _executeSchedule(schedule);\n    }\n  }\n\n  /// Execute a single scheduled download by adding it to the queue.\n  Future<void> _executeSchedule(ScheduledDownload schedule) async {\n    final index = _schedules.indexWhere((s) => s.id == schedule.id);\n    if (index == -1) return;\n\n    try {\n      // Mark as executing\n      _schedules[index] = schedule.copyWith(\n        status: ScheduledDownloadStatus.executing,\n      );\n      await _db.updateScheduledDownload(_schedules[index]);\n      notifyListeners();\n\n      // Add to the download queue\n      await queueManager!.addToQueue(\n        url: schedule.url,\n        title: schedule.title,\n        thumbnailUrl: schedule.thumbnailUrl,\n        formatId: schedule.formatId,\n        formatLabel: schedule.formatLabel,\n      );\n\n      // Handle recurrence\n      if (schedule.recurrence == ScheduleRecurrence.once) {\n        // One-time schedule — mark completed and remove\n        _schedules[index] = _schedules[index].copyWith(\n          status: ScheduledDownloadStatus.completed,\n          lastExecutedAt: DateTime.now(),\n          executionCount: _schedules[index].executionCount + 1,\n        );\n        await _db.updateScheduledDownload(_schedules[index]);\n        _schedules.removeAt(index);\n      } else {\n        // Recurring schedule — update last execution and keep active\n        _schedules[index] = _schedules[index].copyWith(\n          lastExecutedAt: DateTime.now(),\n          executionCount: _schedules[index].executionCount + 1,\n        );\n        await _db.updateScheduledDownload(_schedules[index]);\n\n        // Advance scheduledTime for next occurrence\n        final nextTime = _schedules[index].nextExecution;\n        if (nextTime != null) {\n          _schedules[index] = _schedules[index].copyWith(\n            scheduledTime: nextTime,\n          );\n          await _db.updateScheduledDownload(_schedules[index]);\n        }\n      }\n\n      notifyListeners();\n    } catch (e) {\n      debugPrint('Scheduled download execution failed: $e');\n\n      final idx = _schedules.indexWhere((s) => s.id == schedule.id);\n      if (idx != -1) {\n        _schedules[idx] = _schedules[idx].copyWith(\n          status: ScheduledDownloadStatus.error,\n          errorMessage: e.toString(),\n        );\n        await _db.updateScheduledDownload(_schedules[idx]);\n        notifyListeners();\n      }\n    }\n  }\n\n  /// Get the number of active (scheduled) downloads.\n  int get activeCount =>\n      _schedules.where((s) => s.status == ScheduledDownloadStatus.scheduled).length;\n\n  @override\n  void dispose() {\n    _checkTimer?.cancel();\n    super.dispose();\n  }\n}\n"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing code",
      "status": "completed"
    },
    {
      "activeForm": "Reviewing download logic and models",
      "content": "Review existing download logic and models",
      "status": "completed"
    },
    {
      "activeForm": "Creating scheduled download model",
      "content": "Create ScheduledDownload model",
      "status": "completed"
    },
    {
      "activeForm": "Updating database schema for scheduling",
      "content": "Update database schema with scheduled_downloads table",
      "status": "completed"
    },
    {
      "activeForm": "Creating download scheduler service",
      "content": "Create DownloadScheduler service",
      "status": "completed"
    },
    {
      "activeForm": "Implementing scheduling UI screen",
      "content": "Implement scheduling UI screen",
      "status": "in_progress"
    },
    {
      "activeForm": "Integrating scheduling with main app",
      "content": "Integrate scheduling with main app and queue screen",
      "status": "pending"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "pending"
    }
  ]
}
Now create the scheduling UI screen. This will allow users to view, create, and manage scheduled downloads.

🔧 Tool: Write
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_schedule_screen.dart",
  "content": "import 'package:flutter/material.dart';\nimport 'package:intl/intl.dart';\n\nimport 'download_record.dart';\nimport 'download_scheduler.dart';\nimport 'format_option.dart';\nimport 'network_monitor.dart';\nimport 'scheduled_download.dart';\n\n/// Screen for viewing and managing scheduled downloads.\nclass DownloadScheduleScreen extends StatefulWidget {\n  final DownloadScheduler scheduler;\n  final NetworkMonitor networkMonitor;\n\n  const DownloadScheduleScreen({\n    super.key,\n    required this.scheduler,\n    required this.networkMonitor,\n  });\n\n  @override\n  State<DownloadScheduleScreen> createState() => _DownloadScheduleScreenState();\n}\n\nclass _DownloadScheduleScreenState extends State<DownloadScheduleScreen> {\n  @override\n  void initState() {\n    super.initState();\n    widget.scheduler.addListener(_onChanged);\n  }\n\n  @override\n  void dispose() {\n    widget.scheduler.removeListener(_onChanged);\n    super.dispose();\n  }\n\n  void _onChanged() {\n    if (mounted) setState(() {});\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final schedules = widget.scheduler.schedules;\n\n    return Scaffold(\n      appBar: AppBar(\n        title: const Text('Scheduled Downloads'),\n      ),\n      body: schedules.isEmpty\n          ? Center(\n              child: Column(\n                mainAxisSize: MainAxisSize.min,\n                children: [\n                  Icon(Icons.schedule, size: 64, color: Colors.grey[400]),\n                  const SizedBox(height: 16),\n                  Text(\n                    'No scheduled downloads',\n                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),\n                  ),\n                  const SizedBox(height: 8),\n                  Text(\n                    'Tap + to schedule a download for later',\n                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),\n                  ),\n                ],\n              ),\n            )\n          : ListView.builder(\n              padding: const EdgeInsets.symmetric(vertical: 8),\n              itemCount: schedules.length,\n              itemBuilder: (context, index) {\n                final schedule = schedules[index];\n                return _ScheduleTile(\n                  schedule: schedule,\n                  onCancel: () => _confirmCancel(schedule),\n                  onEdit: () => _showEditSheet(schedule),\n                );\n              },\n            ),\n      floatingActionButton: FloatingActionButton(\n        onPressed: _showAddScheduleSheet,\n        tooltip: 'Schedule download',\n        child: const Icon(Icons.add),\n      ),\n    );\n  }\n\n  void _showAddScheduleSheet() {\n    showModalBottomSheet(\n      context: context,\n      isScrollControlled: true,\n      shape: const RoundedRectangleBorder(\n        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),\n      ),\n      builder: (context) => _ScheduleFormSheet(\n        networkMonitor: widget.networkMonitor,\n        onSave: (schedule) async {\n          await widget.scheduler.addSchedule(schedule);\n          if (mounted) Navigator.pop(context);\n        },\n      ),\n    );\n  }\n\n  void _showEditSheet(ScheduledDownload schedule) {\n    showModalBottomSheet(\n      context: context,\n      isScrollControlled: true,\n      shape: const RoundedRectangleBorder(\n        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),\n      ),\n      builder: (context) => _ScheduleFormSheet(\n        networkMonitor: widget.networkMonitor,\n        existingSchedule: schedule,\n        onSave: (updated) async {\n          await widget.scheduler.updateSchedule(updated);\n          if (mounted) Navigator.pop(context);\n        },\n      ),\n    );\n  }\n\n  void _confirmCancel(ScheduledDownload schedule) {\n    showDialog(\n      context: context,\n      builder: (ctx) => AlertDialog(\n        title: const Text('Cancel Schedule'),\n        content: Text(\n          'Cancel the scheduled download for \"${schedule.title}\"?',\n        ),\n        actions: [\n          TextButton(\n            onPressed: () => Navigator.pop(ctx),\n            child: const Text('Keep'),\n          ),\n          TextButton(\n            onPressed: () {\n              Navigator.pop(ctx);\n              widget.scheduler.cancelSchedule(schedule.id!);\n            },\n            style: TextButton.styleFrom(foregroundColor: Colors.red),\n            child: const Text('Cancel Schedule'),\n          ),\n        ],\n      ),\n    );\n  }\n}\n\n/// A single scheduled download tile.\nclass _ScheduleTile extends StatelessWidget {\n  final ScheduledDownload schedule;\n  final VoidCallback onCancel;\n  final VoidCallback onEdit;\n\n  const _ScheduleTile({\n    required this.schedule,\n    required this.onCancel,\n    required this.onEdit,\n  });\n\n  @override\n  Widget build(BuildContext context) {\n    final timeFormat = DateFormat('h:mm a');\n    final dateFormat = DateFormat('MMM d, yyyy');\n    final nextExec = schedule.nextExecution;\n\n    Color statusColor;\n    IconData statusIcon;\n    switch (schedule.status) {\n      case ScheduledDownloadStatus.scheduled:\n        statusColor = Colors.blue;\n        statusIcon = Icons.schedule;\n        break;\n      case ScheduledDownloadStatus.executing:\n        statusColor = Colors.orange;\n        statusIcon = Icons.downloading;\n        break;\n      case ScheduledDownloadStatus.completed:\n        statusColor = Colors.green;\n        statusIcon = Icons.check_circle;\n        break;\n      case ScheduledDownloadStatus.cancelled:\n        statusColor = Colors.grey;\n        statusIcon = Icons.cancel;\n        break;\n      case ScheduledDownloadStatus.error:\n        statusColor = Colors.red;\n        statusIcon = Icons.error;\n        break;\n    }\n\n    return ListTile(\n      leading: Container(\n        padding: const EdgeInsets.all(8),\n        decoration: BoxDecoration(\n          color: statusColor.withValues(alpha: 0.1),\n          borderRadius: BorderRadius.circular(8),\n        ),\n        child: Icon(statusIcon, size: 20, color: statusColor),\n      ),\n      title: Text(\n        schedule.title,\n        maxLines: 1,\n        overflow: TextOverflow.ellipsis,\n        style: const TextStyle(fontSize: 14),\n      ),\n      subtitle: Column(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          const SizedBox(height: 4),\n          Row(\n            children: [\n              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),\n              const SizedBox(width: 4),\n              Text(\n                nextExec != null\n                    ? '${dateFormat.format(nextExec)} at ${timeFormat.format(nextExec)}'\n                    : 'No upcoming execution',\n                style: TextStyle(fontSize: 12, color: Colors.grey[600]),\n              ),\n            ],\n          ),\n          const SizedBox(height: 2),\n          Row(\n            children: [\n              Icon(Icons.repeat, size: 14, color: Colors.grey[500]),\n              const SizedBox(width: 4),\n              Text(\n                schedule.recurrenceLabel,\n                style: TextStyle(fontSize: 11, color: Colors.grey[500]),\n              ),\n              if (schedule.wifiOnly) ...[\n                const SizedBox(width: 8),\n                Icon(Icons.wifi, size: 14, color: Colors.green[600]),\n                const SizedBox(width: 2),\n                Text(\n                  'WiFi only',\n                  style: TextStyle(fontSize: 11, color: Colors.green[600]),\n                ),\n              ],\n              if (schedule.formatLabel != null) ...[\n                const SizedBox(width: 8),\n                Text(\n                  schedule.formatLabel!,\n                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),\n                ),\n              ],\n              const Spacer(),\n              if (schedule.executionCount > 0)\n                Text(\n                  'Run ${schedule.executionCount}x',\n                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),\n                ),\n            ],\n          ),\n          if (schedule.errorMessage != null)\n            Padding(\n              padding: const EdgeInsets.only(top: 2),\n              child: Text(\n                schedule.errorMessage!,\n                maxLines: 1,\n                overflow: TextOverflow.ellipsis,\n                style: TextStyle(fontSize: 10, color: Colors.red[300]),\n              ),\n            ),\n        ],\n      ),\n      trailing: PopupMenuButton<String>(\n        onSelected: (value) {\n          if (value == 'cancel') onCancel();\n          if (value == 'edit') onEdit();\n        },\n        itemBuilder: (ctx) => [\n          const PopupMenuItem(value: 'edit', child: Text('Edit')),\n          const PopupMenuItem(\n            value: 'cancel',\n            child: Text('Cancel Schedule', style: TextStyle(color: Colors.red)),\n          ),\n        ],\n      ),\n    );\n  }\n}\n\n/// Bottom sheet form for creating or editing a scheduled download.\nclass _ScheduleFormSheet extends StatefulWidget {\n  final NetworkMonitor networkMonitor;\n  final ScheduledDownload? existingSchedule;\n  final Future<void> Function(ScheduledDownload) onSave;\n\n  const _ScheduleFormSheet({\n    required this.networkMonitor,\n    this.existingSchedule,\n    required this.onSave,\n  });\n\n  @override\n  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();\n}\n\nclass _ScheduleFormSheetState extends State<_ScheduleFormSheet> {\n  final _urlController = TextEditingController();\n  final _titleController = TextEditingController();\n  late TimeOfDay _selectedTime;\n  late DateTime _selectedDate;\n  late ScheduleRecurrence _recurrence;\n  late bool _wifiOnly;\n  bool _isSaving = false;\n\n  @override\n  void initState() {\n    super.initState();\n    final existing = widget.existingSchedule;\n    if (existing != null) {\n      _urlController.text = existing.url;\n      _titleController.text = existing.title;\n      _selectedTime = TimeOfDay.fromDateTime(existing.scheduledTime);\n      _selectedDate = DateTime(\n        existing.scheduledTime.year,\n        existing.scheduledTime.month,\n        existing.scheduledTime.day,\n      );\n      _recurrence = existing.recurrence;\n      _wifiOnly = existing.wifiOnly;\n    } else {\n      // Default: tomorrow at 2:00 AM\n      final tomorrow = DateTime.now().add(const Duration(days: 1));\n      _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);\n      _selectedTime = const TimeOfDay(hour: 2, minute: 0);\n      _recurrence = ScheduleRecurrence.once;\n      _wifiOnly = false;\n    }\n  }\n\n  @override\n  void dispose() {\n    _urlController.dispose();\n    _titleController.dispose();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final isEditing = widget.existingSchedule != null;\n    final timeFormat = DateFormat('h:mm a');\n    final dateFormat = DateFormat('MMM d, yyyy');\n\n    final scheduledDateTime = DateTime(\n      _selectedDate.year,\n      _selectedDate.month,\n      _selectedDate.day,\n      _selectedTime.hour,\n      _selectedTime.minute,\n    );\n\n    return Padding(\n      padding: EdgeInsets.only(\n        left: 16,\n        right: 16,\n        top: 16,\n        bottom: MediaQuery.of(context).viewInsets.bottom + 16,\n      ),\n      child: Column(\n        mainAxisSize: MainAxisSize.min,\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          // Handle bar\n          Center(\n            child: Container(\n              margin: const EdgeInsets.only(bottom: 12),\n              width: 40,\n              height: 4,\n              decoration: BoxDecoration(\n                color: Colors.grey[300],\n                borderRadius: BorderRadius.circular(2),\n              ),\n            ),\n          ),\n          Text(\n            isEditing ? 'Edit Scheduled Download' : 'Schedule a Download',\n            style: Theme.of(context).textTheme.titleMedium,\n          ),\n          const SizedBox(height: 16),\n\n          // URL field\n          TextField(\n            controller: _urlController,\n            decoration: const InputDecoration(\n              labelText: 'Video URL',\n              border: OutlineInputBorder(),\n              hintText: 'Paste a video URL to download',\n            ),\n            enabled: !isEditing,\n          ),\n          const SizedBox(height: 12),\n\n          // Title field\n          TextField(\n            controller: _titleController,\n            decoration: const InputDecoration(\n              labelText: 'Title (optional)',\n              border: OutlineInputBorder(),\n              hintText: 'Auto-detected from URL',\n            ),\n          ),\n          const SizedBox(height: 16),\n\n          // Date & Time pickers\n          Text(\n            'Schedule Time',\n            style: TextStyle(\n              fontSize: 12,\n              fontWeight: FontWeight.w600,\n              color: Colors.grey[700],\n            ),\n          ),\n          const SizedBox(height: 8),\n          Row(\n            children: [\n              Expanded(\n                child: OutlinedButton.icon(\n                  onPressed: _pickDate,\n                  icon: const Icon(Icons.calendar_today, size: 16),\n                  label: Text(dateFormat.format(_selectedDate)),\n                ),\n              ),\n              const SizedBox(width: 8),\n              Expanded(\n                child: OutlinedButton.icon(\n                  onPressed: _pickTime,\n                  icon: const Icon(Icons.access_time, size: 16),\n                  label: Text(timeFormat.format(scheduledDateTime)),\n                ),\n              ),\n            ],\n          ),\n          const SizedBox(height: 16),\n\n          // Recurrence selector\n          Text(\n            'Repeat',\n            style: TextStyle(\n              fontSize: 12,\n              fontWeight: FontWeight.w600,\n              color: Colors.grey[700],\n            ),\n          ),\n          const SizedBox(height: 8),\n          Wrap(\n            spacing: 8,\n            children: ScheduleRecurrence.values.map((r) {\n              final selected = r == _recurrence;\n              return ChoiceChip(\n                label: Text(r == ScheduleRecurrence.once\n                    ? 'One-time'\n                    : r == ScheduleRecurrence.weekdays\n                        ? 'Weekdays'\n                        : r == ScheduleRecurrence.weekends\n                            ? 'Weekends'\n                            : r.name[0].toUpperCase() + r.name.substring(1)),\n                selected: selected,\n                onSelected: (_) {\n                  setState(() => _recurrence = r);\n                },\n              );\n            }).toList(),\n          ),\n          const SizedBox(height: 16),\n\n          // WiFi-only toggle\n          SwitchListTile(\n            value: _wifiOnly,\n            onChanged: (val) => setState(() => _wifiOnly = val),\n            title: const Text('WiFi only'),\n            subtitle: Text(\n              _wifiOnly\n                  ? 'Will only download when connected to WiFi'\n                  : 'Downloads on any network',\n              style: TextStyle(fontSize: 12, color: Colors.grey[600]),\n            ),\n            secondary: Icon(\n              _wifiOnly ? Icons.wifi : Icons.wifi_off,\n              color: _wifiOnly ? Colors.green : Colors.grey,\n            ),\n            contentPadding: EdgeInsets.zero,\n            dense: true,\n          ),\n          const SizedBox(height: 16),\n\n          // Save button\n          SizedBox(\n            width: double.infinity,\n            child: ElevatedButton.icon(\n              onPressed: _isSaving ? null : _save,\n              icon: _isSaving\n                  ? const SizedBox(\n                      width: 16,\n                      height: 16,\n                      child: CircularProgressIndicator(strokeWidth: 2),\n                    )\n                  : const Icon(Icons.schedule),\n              label: Text(isEditing ? 'Update Schedule' : 'Schedule Download'),\n              style: ElevatedButton.styleFrom(\n                padding: const EdgeInsets.symmetric(vertical: 14),\n              ),\n            ),\n          ),\n          const SizedBox(height: 8),\n        ],\n      ),\n    );\n  }\n\n  Future<void> _pickDate() async {\n    final picked = await showDatePicker(\n      context: context,\n      initialDate: _selectedDate,\n      firstDate: DateTime.now(),\n      lastDate: DateTime.now().add(const Duration(days: 365)),\n    );\n    if (picked != null) {\n      setState(() => _selectedDate = picked);\n    }\n  }\n\n  Future<void> _pickTime() async {\n    final picked = await showTimePicker(\n      context: context,\n      initialTime: _selectedTime,\n    );\n    if (picked != null) {\n      setState(() => _selectedTime = picked);\n    }\n  }\n\n  Future<void> _save() async {\n    final url = _urlController.text.trim();\n    if (url.isEmpty) {\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(content: Text('Please enter a video URL')),\n      );\n      return;\n    }\n\n    final scheduledDateTime = DateTime(\n      _selectedDate.year,\n      _selectedDate.month,\n      _selectedDate.day,\n      _selectedTime.hour,\n      _selectedTime.minute,\n    );\n\n    if (scheduledDateTime.isBefore(DateTime.now())) {\n      ScaffoldMessenger.of(context).showSnackBar(\n        const SnackBar(content: Text('Scheduled time must be in the future')),\n      );\n      return;\n    }\n\n    setState(() => _isSaving = true);\n\n    final title = _titleController.text.trim().isEmpty\n        ? 'Scheduled download'\n        : _titleController.text.trim();\n\n    final schedule = ScheduledDownload(\n      id: widget.existingSchedule?.id,\n      url: url,\n      platform: DownloadRecord.detectPlatform(url),\n      title: title,\n      thumbnailUrl: widget.existingSchedule?.thumbnailUrl,\n      scheduledTime: scheduledDateTime,\n      recurrence: _recurrence,\n      wifiOnly: _wifiOnly,\n      formatId: widget.existingSchedule?.formatId,\n      formatLabel: widget.existingSchedule?.formatLabel,\n      status: widget.existingSchedule?.status ?? ScheduledDownloadStatus.scheduled,\n      createdAt: widget.existingSchedule?.createdAt ?? DateTime.now(),\n      lastExecutedAt: widget.existingSchedule?.lastExecutedAt,\n      executionCount: widget.existingSchedule?.executionCount ?? 0,\n    );\n\n    await widget.onSave(schedule);\n\n    if (mounted) {\n      setState(() => _isSaving = false);\n    }\n  }\n}\n"
}

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing code",
      "status": "completed"
    },
    {
      "activeForm": "Reviewing download logic and models",
      "content": "Review existing download logic and models",
      "status": "completed"
    },
    {
      "activeForm": "Creating scheduled download model",
      "content": "Create ScheduledDownload model",
      "status": "completed"
    },
    {
      "activeForm": "Updating database schema for scheduling",
      "content": "Update database schema with scheduled_downloads table",
      "status": "completed"
    },
    {
      "activeForm": "Creating download scheduler service",
      "content": "Create DownloadScheduler service",
      "status": "completed"
    },
    {
      "activeForm": "Implementing scheduling UI screen",
      "content": "Implement scheduling UI screen",
      "status": "completed"
    },
    {
      "activeForm": "Integrating scheduling with main app",
      "content": "Integrate scheduling with main app and queue screen",
      "status": "in_progress"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "pending"
    }
  ]
}
Now integrate the scheduler into `main.dart`. I need to add the global scheduler, initialize it, and add navigation to the schedule screen from both the main screen and the queue screen.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "import 'download_queue_manager.dart';\nimport 'download_queue_screen.dart';\nimport 'queue_item.dart';\nimport 'format_option.dart';\nimport 'auth_service.dart';",
  "new_string": "import 'download_queue_manager.dart';\nimport 'download_queue_screen.dart';\nimport 'queue_item.dart';\nimport 'format_option.dart';\nimport 'download_scheduler.dart';\nimport 'download_schedule_screen.dart';\nimport 'auth_service.dart';"
}

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "limit": 30
}
The file has been modified since I last read it — there are new imports. Let me read the full current state.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart"
}
Good, now I have the full current state. Let me add the imports and global scheduler, then add navigation to the schedule screen.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "import 'format_option.dart';\nimport 'auth_service.dart';",
  "new_string": "import 'format_option.dart';\nimport 'download_scheduler.dart';\nimport 'download_schedule_screen.dart';\nimport 'auth_service.dart';"
}
Now add the global scheduler singleton after the theme provider.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "// --- Global theme provider ---\nfinal ThemeProvider _themeProvider = ThemeProvider();",
  "new_string": "// --- Global theme provider ---\nfinal ThemeProvider _themeProvider = ThemeProvider();\n\n// --- Global download scheduler ---\nfinal DownloadScheduler _scheduler = DownloadScheduler();"
}
Now initialize the scheduler in the `main()` function, after queue manager init.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "  _queueManager.authService = _authService;\n  _queueManager.networkMonitor = _networkMonitor;\n  await _queueManager.init();\n  runApp(const MyApp());",
  "new_string": "  _queueManager.authService = _authService;\n  _queueManager.networkMonitor = _networkMonitor;\n  await _queueManager.init();\n  _scheduler.queueManager = _queueManager;\n  _scheduler.networkMonitor = _networkMonitor;\n  await _scheduler.init();\n  runApp(const MyApp());"
}
Now add a schedule button in the AppBar actions. I'll add it before the palette icon button.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "          IconButton(\n            icon: const Icon(Icons.bar_chart),\n            tooltip: 'Analytics',\n            onPressed: () {\n              Navigator.push(\n                context,\n                MaterialPageRoute(\n                  builder: (_) => const DownloadAnalyticsScreen(),\n                ),\n              );\n            },\n          ),",
  "new_string": "          IconButton(\n            icon: const Icon(Icons.bar_chart),\n            tooltip: 'Analytics',\n            onPressed: () {\n              Navigator.push(\n                context,\n                MaterialPageRoute(\n                  builder: (_) => const DownloadAnalyticsScreen(),\n                ),\n              );\n            },\n          ),\n          IconButton(\n            icon: const Icon(Icons.schedule),\n            tooltip: 'Scheduled Downloads',\n            onPressed: () {\n              Navigator.push(\n                context,\n                MaterialPageRoute(\n                  builder: (_) => DownloadScheduleScreen(\n                    scheduler: _scheduler,\n                    networkMonitor: _networkMonitor,\n                  ),\n                ),\n              );\n            },\n          ),"
}
Now let me also add a "Schedule download" button in the main body, after the Download History button. This gives a more discoverable entry point.

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\main.dart",
  "old_string": "            OutlinedButton.icon(\n              onPressed: () {\n                Navigator.push(\n                  context,\n                  MaterialPageRoute(\n                    builder: (_) => const DownloadHistoryScreen(),\n                  ),\n                );\n              },\n              icon: const Icon(Icons.history),\n              label: const Text(\"Download History\"),\n              style: OutlinedButton.styleFrom(\n                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),\n                textStyle: const TextStyle(fontSize: 18),\n              ),\n            ),",
  "new_string": "            OutlinedButton.icon(\n              onPressed: () {\n                Navigator.push(\n                  context,\n                  MaterialPageRoute(\n                    builder: (_) => const DownloadHistoryScreen(),\n                  ),\n                );\n              },\n              icon: const Icon(Icons.history),\n              label: const Text(\"Download History\"),\n              style: OutlinedButton.styleFrom(\n                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),\n                textStyle: const TextStyle(fontSize: 18),\n              ),\n            ),\n            const SizedBox(height: 10),\n            OutlinedButton.icon(\n              onPressed: () {\n                Navigator.push(\n                  context,\n                  MaterialPageRoute(\n                    builder: (_) => DownloadScheduleScreen(\n                      scheduler: _scheduler,\n                      networkMonitor: _networkMonitor,\n                    ),\n                  ),\n                );\n              },\n              icon: const Icon(Icons.schedule),\n              label: const Text(\"Scheduled Downloads\"),\n              style: OutlinedButton.styleFrom(\n                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),\n                textStyle: const TextStyle(fontSize: 18),\n              ),\n            ),"
}
Now let me also add a schedule button in the download queue screen for easy access.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_queue_screen.dart",
  "limit": 25
}
The queue screen already has its own imports and doesn't need to directly reference the scheduler screen (to keep dependencies clean). The main entry points are through the main screen's AppBar and body buttons. Let me verify the implementation compiles.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing code",
      "status": "completed"
    },
    {
      "activeForm": "Reviewing download logic and models",
      "content": "Review existing download logic and models",
      "status": "completed"
    },
    {
      "activeForm": "Creating scheduled download model",
      "content": "Create ScheduledDownload model",
      "status": "completed"
    },
    {
      "activeForm": "Updating database schema for scheduling",
      "content": "Update database schema with scheduled_downloads table",
      "status": "completed"
    },
    {
      "activeForm": "Creating download scheduler service",
      "content": "Create DownloadScheduler service",
      "status": "completed"
    },
    {
      "activeForm": "Implementing scheduling UI screen",
      "content": "Implement scheduling UI screen",
      "status": "completed"
    },
    {
      "activeForm": "Integrating scheduling with main app",
      "content": "Integrate scheduling with main app and queue screen",
      "status": "completed"
    },
    {
      "activeForm": "Verifying implementation compiles",
      "content": "Verify implementation compiles",
      "status": "in_progress"
    }
  ]
}

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && flutter analyze --no-pub 2>&1 | head -80",
  "description": "Run Flutter static analysis",
  "timeout": 120000
}
Analysis is clean for our new code. There's one unused import in `download_schedule_screen.dart` and two `use_build_context_synchronously` infos. Let me fix the unused import.

🔧 Tool: Read
Input: {
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_schedule_screen.dart",
  "limit": 10
}

🔧 Tool: Edit
Input: {
  "replace_all": false,
  "file_path": "C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\\lib\\download_schedule_screen.dart",
  "old_string": "import 'download_record.dart';\nimport 'download_scheduler.dart';\nimport 'format_option.dart';\nimport 'network_monitor.dart';",
  "new_string": "import 'download_record.dart';\nimport 'download_scheduler.dart';\nimport 'network_monitor.dart';"
}
Now let me run the analysis again to confirm it's clean.

🔧 Tool: Bash
Input: {
  "command": "cd \"C:\\Projects\\x_video_downloader\\x_video_downloader_flutter_frontend\" && flutter analyze --no-pub 2>&1 | head -40",
  "description": "Run Flutter static analysis to verify clean",
  "timeout": 120000
}
All issues from our new code are now only `info` level (the `use_build_context_synchronously` warnings are guarded by `mounted` checks, which is the correct pattern). The remaining warnings are in pre-existing files (`storage_service.dart`). No errors.

🔧 Tool: TodoWrite
Input: {
  "todos": [
    {
      "activeForm": "Exploring codebase structure",
      "content": "Explore codebase structure and existing code",
      "status": "completed"
    },
    {
      "activeForm": "Reviewing download logic and models",
      "content": "Review existing download logic and models",
      "status": "completed"
    },
    {
      "activeForm": "Creating scheduled download model",
      "content": "Create ScheduledDownload model",
      "status": "completed"
    },
    {
      "activeForm": "Updating database schema for scheduling",
      "content": "Update database schema with scheduled_downloads table",
      "status": "completed"
    },
    {
      "activeForm": "Creating download scheduler service",
      "content": "Create DownloadScheduler service",
      "status": "completed"
    },
    {
      "activeForm": "Implementing scheduling UI screen",
      "content": "Implement scheduling UI screen",
      "status": "completed"
    },
    {
      "activeForm": "Integrating scheduling with main app",
      "content": "Integrate scheduling with main app and queue screen",
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
## Summary: Scheduled Downloads

### Changes Implemented
- **ScheduledDownload model** (`scheduled_download.dart`): Data model with support for one-time and recurring schedules (daily, weekdays, weekends, weekly), WiFi-only constraint, format selection, execution tracking, and computed next execution time.
- **Database schema migration** (`download_database.dart`): Added `scheduled_downloads` table with migration from version 5 to 6, including indexes on status and scheduledTime. Full CRUD methods for scheduled downloads.
- **DownloadScheduler service** (`download_scheduler.dart`): Core scheduling engine with a 60-second periodic timer that checks for due schedules, validates WiFi constraints, submits downloads to the queue manager, handles recurrence by advancing scheduled time, and tracks execution count.
- **DownloadScheduleScreen UI** (`download_schedule_screen.dart`): Full screen with list of active schedules showing next execution time, recurrence, WiFi-only status, and execution count. FAB to add new scheduled downloads. Bottom sheet form with URL input, date/time pickers, recurrence selection (one-time/daily/weekdays/weekends/weekly), and WiFi-only toggle. Edit and cancel support via popup menus.
- **Main app integration** (`main.dart`): Added global `DownloadScheduler` singleton, initialized in `main()` with queue manager and network monitor references. Added schedule icon button in AppBar and "Scheduled Downloads" button in the main screen body.

### Files Modified
- `lib/scheduled_download.dart` (created) — Scheduled download data model
- `lib/download_scheduler.dart` (created) — Scheduler service with periodic check timer
- `lib/download_schedule_screen.dart` (created) — UI for managing scheduled downloads
- `lib/download_database.dart` (modified) — Added `scheduled_downloads` table, migration v5→v6, CRUD methods
- `lib/main.dart` (modified) — Added global scheduler, initialization, navigation to schedule screen

### Notes for Developer
- The scheduler uses a simple Timer.periodic(60s) approach rather than Android's native JobScheduler. This works while the app is running but won't wake the app if it's been killed by the OS. For true background scheduling (app killed/device reboot), you'd need to add a platform channel using Android's WorkManager or a similar plugin like `android_alarm_manager_plus` or `workmanager`.
- Database migration is automatic: existing users on v5 will get the new table created on next app launch.
- The `nextExecution` computed property on `ScheduledDownload` handles recurrence calculation for daily, weekdays, weekends, and weekly patterns.
- Flutter analyze passes with 0 errors, 0 warnings from new code (only pre-existing warnings remain).
</summary>