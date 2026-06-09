import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/data/data_source/position_queue_entry.dart';
import 'package:app/shared/inject.dart';
import 'package:sqflite/sqflite.dart';

/// Durable offline queue for GPS samples. Backed by sqflite in production;
/// tests register an in-memory [Database] (via `sqflite_common_ffi`).
///
/// The [Database] is resolved lazily via `getAsync<Database>()`, so callers
/// don't have to await app-wide DB readiness at startup — the first method
/// call triggers (and caches) the open. See `data_module.dart` for the
/// production registration.
class PositionQueueRepository {
  Future<Database> get _db => injector.getAsync<Database>();

  Future<int> insert({required num lat, required num lon, required String time, String? runId}) async =>
      PositionQueueDao(await _db).insert(lat: lat, lon: lon, time: time, runId: runId);

  Future<List<PositionQueueEntry>> getFirstN(int n) async => PositionQueueDao(await _db).getFirstN(n);

  Future<int> deleteByIds(List<int> ids) async => PositionQueueDao(await _db).deleteByIds(ids);

  Future<int> count() async => PositionQueueDao(await _db).count();
}
