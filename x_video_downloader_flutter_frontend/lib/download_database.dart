import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'download_database_schema.dart';
import 'download_record.dart';
import 'queue_item.dart';
import 'scheduled_download.dart';

/// Singleton helper for the SQLite download history database.
class DownloadDatabase {
  static final DownloadDatabase _instance = DownloadDatabase._internal();
  factory DownloadDatabase() => _instance;
  DownloadDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'download_history.db');

    return openDatabase(
      path,
      version: 8,
      onCreate: (db, version) async {
        await _createDownloadsTable(db);
        await _createQueueItemsTable(db);
        await _createScheduledDownloadsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createQueueItemsTable(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE queue_items ADD COLUMN speedBps REAL NOT NULL DEFAULT 0.0',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE queue_items ADD COLUMN formatId TEXT',
          );
          await db.execute(
            'ALTER TABLE queue_items ADD COLUMN formatLabel TEXT',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE downloads ADD COLUMN thumbnailUrl TEXT',
          );
        }
        if (oldVersion < 6) {
          await _createScheduledDownloadsTable(db);
        }
        if (oldVersion < 7) {
          await db.execute(
            'ALTER TABLE queue_items ADD COLUMN subtitleLang TEXT',
          );
          await db.execute(
            'ALTER TABLE queue_items ADD COLUMN subtitleFormat TEXT',
          );
          await db.execute(
            'ALTER TABLE queue_items ADD COLUMN embedSubtitles INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE queue_items ADD COLUMN downloadSidecarSubtitles INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 8) {
          await repairDownloadDatabaseSchemaV8(db);
        }
      },
    );
  }

  Future<void> _createDownloadsTable(Database db) async {
    await db.execute('''
      CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        platform TEXT NOT NULL,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        fileSizeBytes INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        errorMessage TEXT,
        downloadedAt INTEGER NOT NULL,
        thumbnailUrl TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_downloads_status ON downloads(status)',
    );
    await db.execute(
      'CREATE INDEX idx_downloads_downloadedAt ON downloads(downloadedAt)',
    );
  }

  Future<void> _createQueueItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE queue_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        platform TEXT NOT NULL,
        title TEXT NOT NULL,
        thumbnailUrl TEXT,
        status TEXT NOT NULL DEFAULT 'queued',
        progress REAL NOT NULL DEFAULT 0.0,
        filePath TEXT,
        fileSizeBytes INTEGER NOT NULL DEFAULT 0,
        errorMessage TEXT,
        errorCode TEXT,
        retryable INTEGER NOT NULL DEFAULT 0,
        retryCount INTEGER NOT NULL DEFAULT 0,
        maxRetries INTEGER NOT NULL DEFAULT 3,
        videoIndex INTEGER,
        createdAt INTEGER NOT NULL,
        startedAt INTEGER,
        completedAt INTEGER,
        downloadedBytes INTEGER NOT NULL DEFAULT 0,
        speedBps REAL NOT NULL DEFAULT 0.0,
        formatId TEXT,
        formatLabel TEXT,
        subtitleLang TEXT,
        subtitleFormat TEXT,
        embedSubtitles INTEGER NOT NULL DEFAULT 0,
        downloadSidecarSubtitles INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_queue_items_status ON queue_items(status)',
    );
    await db.execute(
      'CREATE INDEX idx_queue_items_createdAt ON queue_items(createdAt)',
    );
  }

  Future<void> _createScheduledDownloadsTable(Database db) async {
    await db.execute('''
      CREATE TABLE scheduled_downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        platform TEXT NOT NULL,
        title TEXT NOT NULL,
        thumbnailUrl TEXT,
        scheduledTime INTEGER NOT NULL,
        recurrence TEXT NOT NULL DEFAULT 'once',
        wifiOnly INTEGER NOT NULL DEFAULT 0,
        formatId TEXT,
        formatLabel TEXT,
        status TEXT NOT NULL DEFAULT 'scheduled',
        createdAt INTEGER NOT NULL,
        lastExecutedAt INTEGER,
        executionCount INTEGER NOT NULL DEFAULT 0,
        errorMessage TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_scheduled_downloads_status ON scheduled_downloads(status)',
    );
    await db.execute(
      'CREATE INDEX idx_scheduled_downloads_scheduledTime ON scheduled_downloads(scheduledTime)',
    );
  }

  // --- Download history CRUD ---

  /// Insert a new download record.
  Future<int> insertRecord(DownloadRecord record) async {
    final db = await database;
    final map = Map<String, dynamic>.from(record.toMap())..remove('id');
    return db.insert('downloads', map);
  }

  /// Get all download records, most recent first.
  Future<List<DownloadRecord>> getAllRecords({int? limit, int? offset}) async {
    final db = await database;
    final results = await db.query(
      'downloads',
      orderBy: 'downloadedAt DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((m) => DownloadRecord.fromMap(m)).toList();
  }

  /// Get records filtered by status.
  Future<List<DownloadRecord>> getRecordsByStatus(String status) async {
    final db = await database;
    final results = await db.query(
      'downloads',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'downloadedAt DESC',
    );
    return results.map((m) => DownloadRecord.fromMap(m)).toList();
  }

  /// Update a record's status (e.g., mark as deleted after file removal).
  Future<int> updateStatus(int id, String status) async {
    final db = await database;
    return db.update(
      'downloads',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a single record by ID.
  Future<int> deleteRecord(int id) async {
    final db = await database;
    return db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all records.
  Future<int> deleteAllRecords() async {
    final db = await database;
    return db.delete('downloads');
  }

  /// Delete records older than the given number of days.
  Future<int> deleteOlderThan(int days) async {
    final db = await database;
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    return db.delete('downloads', where: 'downloadedAt < ?', whereArgs: [cutoff]);
  }

  /// Get count of records by status.
  Future<Map<String, int>> getStatusCounts() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT status, COUNT(*) as count FROM downloads GROUP BY status',
    );
    return {for (var r in results) r['status'] as String: r['count'] as int};
  }

  // --- Queue items CRUD ---

  /// Insert a new queue item.
  Future<int> insertQueueItem(QueueItem item) async {
    final db = await database;
    final map = Map<String, dynamic>.from(item.toMap())..remove('id');
    return db.insert('queue_items', map);
  }

  /// Get all queue items ordered by creation time.
  Future<List<QueueItem>> getAllQueueItems() async {
    final db = await database;
    final results = await db.query(
      'queue_items',
      orderBy: 'createdAt ASC',
    );
    return results.map((m) => QueueItem.fromMap(m)).toList();
  }

  /// Get active queue items (queued or downloading or paused).
  Future<List<QueueItem>> getActiveQueueItems() async {
    final db = await database;
    final results = await db.query(
      'queue_items',
      where: 'status IN (?, ?, ?)',
      whereArgs: ['queued', 'downloading', 'paused'],
      orderBy: 'createdAt ASC',
    );
    return results.map((m) => QueueItem.fromMap(m)).toList();
  }

  /// Update a queue item.
  Future<int> updateQueueItem(QueueItem item) async {
    final db = await database;
    return db.update(
      'queue_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Update only the status and progress fields of a queue item (lightweight).
  Future<int> updateQueueItemProgress(int id, {
    required QueueItemStatus status,
    double? progress,
    int? downloadedBytes,
  }) async {
    final db = await database;
    final values = <String, dynamic>{
      'status': status.name,
    };
    if (progress != null) values['progress'] = progress;
    if (downloadedBytes != null) values['downloadedBytes'] = downloadedBytes;
    return db.update(
      'queue_items',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a queue item by ID.
  Future<int> deleteQueueItem(int id) async {
    final db = await database;
    return db.delete('queue_items', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all completed/failed/cancelled queue items.
  Future<int> clearFinishedQueueItems() async {
    final db = await database;
    return db.delete(
      'queue_items',
      where: 'status IN (?, ?, ?)',
      whereArgs: ['completed', 'failed', 'cancelled'],
    );
  }

  /// Delete all queue items.
  Future<int> deleteAllQueueItems() async {
    final db = await database;
    return db.delete('queue_items');
  }

  /// Get count of queue items by status.
  Future<Map<String, int>> getQueueStatusCounts() async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT status, COUNT(*) as count FROM queue_items GROUP BY status',
    );
    return {for (var r in results) r['status'] as String: r['count'] as int};
  }

  // --- Analytics queries ---

  /// Get total download count and breakdown by status.
  Future<Map<String, int>> getAnalyticsCounts() async {
    final db = await database;
    final total = (await db.rawQuery('SELECT COUNT(*) as count FROM downloads')).first['count'] as int;
    final completed = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM downloads WHERE status = 'completed'",
    )).first['count'] as int;
    final failed = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM downloads WHERE status = 'failed'",
    )).first['count'] as int;
    return {
      'total': total,
      'completed': completed,
      'failed': failed,
    };
  }

  /// Get total bytes downloaded (completed only).
  Future<int> getTotalBytesDownloaded() async {
    final db = await database;
    final result = (await db.rawQuery(
      "SELECT COALESCE(SUM(fileSizeBytes), 0) as total FROM downloads WHERE status = 'completed'",
    )).first;
    return result['total'] as int;
  }

  /// Get average download speed from completed queue items.
  Future<double> getAverageSpeed() async {
    final db = await database;
    final result = (await db.rawQuery(
      "SELECT AVG(speedBps) as avg_speed FROM queue_items WHERE status = 'completed' AND speedBps > 0",
    )).first;
    return (result['avg_speed'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get download counts grouped by platform.
  Future<List<Map<String, dynamic>>> getDownloadsByPlatform() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        platform,
        COUNT(*) as count,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as success_count,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN fileSizeBytes ELSE 0 END), 0) as total_bytes
      FROM downloads
      GROUP BY platform
      ORDER BY count DESC
    ''');
  }

  /// Get daily download counts for the last [days] days.
  Future<List<Map<String, dynamic>>> getDailyCounts({int days = 30}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    return db.rawQuery('''
      SELECT
        (downloadedAt / 86400000) as day_epoch,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed
      FROM downloads
      WHERE downloadedAt >= ?
      GROUP BY day_epoch
      ORDER BY day_epoch ASC
    ''', [cutoff]);
  }

  /// Get daily bandwidth consumed for the last [days] days.
  Future<List<Map<String, dynamic>>> getDailyBandwidth({int days = 30}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    return db.rawQuery('''
      SELECT
        (downloadedAt / 86400000) as day_epoch,
        COALESCE(SUM(CASE WHEN status = 'completed' THEN fileSizeBytes ELSE 0 END), 0) as bytes
      FROM downloads
      WHERE downloadedAt >= ?
      GROUP BY day_epoch
      ORDER BY day_epoch ASC
    ''', [cutoff]);
  }

  /// Get the date range of all downloads.
  Future<Map<String, int?>> getDownloadDateRange() async {
    final db = await database;
    final result = (await db.rawQuery(
      'SELECT MIN(downloadedAt) as first_dl, MAX(downloadedAt) as last_dl FROM downloads',
    )).first;
    return {
      'first': result['first_dl'] as int?,
      'last': result['last_dl'] as int?,
    };
  }

  /// Get all download records for export.
  Future<List<DownloadRecord>> getAllRecordsForExport() async {
    final db = await database;
    final results = await db.query(
      'downloads',
      orderBy: 'downloadedAt DESC',
    );
    return results.map((m) => DownloadRecord.fromMap(m)).toList();
  }

  // --- Scheduled downloads CRUD ---

  /// Insert a new scheduled download.
  Future<int> insertScheduledDownload(ScheduledDownload schedule) async {
    final db = await database;
    return db.insert('scheduled_downloads', schedule.toMap());
  }

  /// Get all active (scheduled) downloads, ordered by next execution time.
  Future<List<ScheduledDownload>> getActiveScheduledDownloads() async {
    final db = await database;
    final results = await db.query(
      'scheduled_downloads',
      where: 'status IN (?, ?)',
      whereArgs: ['scheduled', 'error'],
      orderBy: 'scheduledTime ASC',
    );
    return results.map((m) => ScheduledDownload.fromMap(m)).toList();
  }

  /// Get all scheduled downloads (including completed/cancelled).
  Future<List<ScheduledDownload>> getAllScheduledDownloads() async {
    final db = await database;
    final results = await db.query(
      'scheduled_downloads',
      orderBy: 'scheduledTime ASC',
    );
    return results.map((m) => ScheduledDownload.fromMap(m)).toList();
  }

  /// Get scheduled downloads that are due for execution.
  Future<List<ScheduledDownload>> getDueScheduledDownloads() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await database;
    final results = await db.query(
      'scheduled_downloads',
      where: 'status = ? AND scheduledTime <= ?',
      whereArgs: ['scheduled', now],
      orderBy: 'scheduledTime ASC',
    );
    return results.map((m) => ScheduledDownload.fromMap(m)).toList();
  }

  /// Update a scheduled download.
  Future<int> updateScheduledDownload(ScheduledDownload schedule) async {
    final db = await database;
    return db.update(
      'scheduled_downloads',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  /// Delete a scheduled download by ID.
  Future<int> deleteScheduledDownload(int id) async {
    final db = await database;
    return db.delete('scheduled_downloads', where: 'id = ?', whereArgs: [id]);
  }
}
