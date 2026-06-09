# Fixes log (append-only)

<!-- Record resolved issues here after removing them from active work. This audit did not apply code fixes. -->

## 2026-05-02 — Direct download never wrote history / stable file path

- **Issue:** Main **Download** button and probe→single-video flow use `_downloadDirectly`, which **never called** `DownloadDatabase.insertRecord`, so **history + analytics stayed empty** while the UI showed progress. Files were written under **`getTemporaryDirectory()`**, so they were easy to lose / not where you’d look.
- **Fix:** After a successful direct download, call `_persistDirectDownloadHistory` (writes `downloads` table). Save the file under **`…/x_video_downloads`** via `_appVideoDownloadDir()` (same pattern as the queue) before copying into **MediaStore** `Downloads/x_video_downloads`.
- **Commands:** `dart analyze lib/main.dart`

## 2026-05-01 — SQLite schema out of sync with Dart models (queue/history broken)

- **Issue:** On **fresh install**, `onCreate` built `downloads` without `thumbnailUrl` and `queue_items` without `formatId`, subtitle, and related columns, while `DownloadRecord.toMap()` / `QueueItem.toMap()` always insert those keys → SQLite throws **no such column** → queue inserts fail → no downloads, no history rows, no gallery publish, thumbnails never persist.
- **Fix:** Extended `CREATE TABLE` definitions; bumped DB version **7 → 8**; added `repairDownloadDatabaseSchemaV8()` in `lib/download_database_schema.dart` (PRAGMA-based `ALTER TABLE` for devices already on the broken v7 schema); strip null `id` on insert for cleanliness.
- **Commands:** `dart analyze lib/download_database.dart lib/download_database_schema.dart`
