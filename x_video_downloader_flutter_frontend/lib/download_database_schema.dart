import 'package:sqflite/sqflite.dart';

/// Ensures columns exist for installs where [onCreate] was missing fields that
/// `DownloadRecord.toMap` / `QueueItem.toMap` always supply (fresh v7 DB bug).
Future<void> repairDownloadDatabaseSchemaV8(Database db) async {
  Future<void> ensure(String table, String column, String ddlSuffix) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    if (rows.any((r) => r['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $ddlSuffix');
  }

  await ensure('downloads', 'thumbnailUrl', 'TEXT');
  await ensure('queue_items', 'formatId', 'TEXT');
  await ensure('queue_items', 'formatLabel', 'TEXT');
  await ensure('queue_items', 'subtitleLang', 'TEXT');
  await ensure('queue_items', 'subtitleFormat', 'TEXT');
  await ensure('queue_items', 'embedSubtitles', 'INTEGER NOT NULL DEFAULT 0');
  await ensure(
    'queue_items',
    'downloadSidecarSubtitles',
    'INTEGER NOT NULL DEFAULT 0',
  );
}
