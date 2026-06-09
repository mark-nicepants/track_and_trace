import 'package:app/data/data_source/position_queue_entry.dart';
import 'package:sqflite/sqflite.dart';

/// Thin sqflite wrapper around the `position_queue` table. Mirrors the Android
/// reference's `TrackingPositionDao` + `TrackingPositionDatabase`.
///
/// Schema:
///   - `id`     INTEGER PRIMARY KEY AUTOINCREMENT
///   - `lat`    REAL NOT NULL
///   - `lon`    REAL NOT NULL
///   - `time`   TEXT NOT NULL  (ISO timestamp, see [IsoClock])
///   - `runId`  TEXT (nullable while a sample is in flight before being
///                    associated with a run, matching the Android reference)
///
/// Field names match `TrackingPositionDto` so the uploader can map a row
/// straight to a `/create-locations` payload.
class PositionQueueDao(final Database db) {
  static const String tableName = 'position_queue';
  static const int schemaVersion = 1;

  static const String createTableSql =
      'CREATE TABLE $tableName ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'lat REAL NOT NULL, '
      'lon REAL NOT NULL, '
      'time TEXT NOT NULL, '
      'runId TEXT'
      ')';

  Future<int> insert({required num lat, required num lon, required String time, String? runId}) =>
      db.insert(tableName, {'lat': lat, 'lon': lon, 'time': time, 'runId': runId});

  /// Returns the [n] oldest rows (lowest `id` first). Rowids are
  /// monotonically increasing for `AUTOINCREMENT` columns, so ordering by
  /// `id` matches insertion order even when `time` strings tie.
  Future<List<PositionQueueEntry>> getFirstN(int n) async {
    final rows = await db.query(tableName, orderBy: 'id ASC', limit: n);
    return rows.map(PositionQueueEntry.fromRow).toList(growable: false);
  }

  Future<int> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final placeholders = List<String>.filled(ids.length, '?').join(', ');
    return db.delete(tableName, where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<int> count() async {
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM $tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
