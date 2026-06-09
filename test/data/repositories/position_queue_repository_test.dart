import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/data/repositories/position_queue_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/di_test_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late PositionQueueRepository repo;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: PositionQueueDao.schemaVersion,
        onCreate: (db, version) => db.execute(PositionQueueDao.createTableSql),
      ),
    );
    await setupTestDi(database: db);
    repo = PositionQueueRepository();
  });

  tearDown(() async {
    await db.close();
    await tearDownTestDi();
  });

  test('insert returns a positive row id and increments count', () async {
    expect(await repo.count(), 0);

    final id = await repo.insert(lat: 52.37, lon: 4.89, time: '2026-06-09T12:00:00.000', runId: 'run-1');

    expect(id, greaterThan(0));
    expect(await repo.count(), 1);
  });

  test('insert preserves all columns including nullable runId', () async {
    await repo.insert(lat: 52.37, lon: 4.89, time: '2026-06-09T12:00:00.000', runId: null);

    final rows = await repo.getFirstN(10);
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.lat, 52.37);
    expect(row.lon, 4.89);
    expect(row.time, '2026-06-09T12:00:00.000');
    expect(row.runId, isNull);
  });

  test('getFirstN returns rows in insertion order, capped at n', () async {
    await repo.insert(lat: 1, lon: 1, time: '2026-06-09T12:00:00.001', runId: 'run-1');
    await repo.insert(lat: 2, lon: 2, time: '2026-06-09T12:00:00.002', runId: 'run-1');
    await repo.insert(lat: 3, lon: 3, time: '2026-06-09T12:00:00.003', runId: 'run-1');
    await repo.insert(lat: 4, lon: 4, time: '2026-06-09T12:00:00.004', runId: 'run-1');

    final first2 = await repo.getFirstN(2);
    expect(first2.map((e) => e.lat).toList(), [1, 2]);

    final allTimes = (await repo.getFirstN(10)).map((e) => e.time).toList();
    expect(allTimes, [
      '2026-06-09T12:00:00.001',
      '2026-06-09T12:00:00.002',
      '2026-06-09T12:00:00.003',
      '2026-06-09T12:00:00.004',
    ]);
  });

  test('getFirstN returns empty list when queue is empty', () async {
    expect(await repo.getFirstN(10), isEmpty);
  });

  test('deleteByIds removes the named rows and leaves the rest', () async {
    await repo.insert(lat: 1, lon: 1, time: 't1', runId: 'r');
    await repo.insert(lat: 2, lon: 2, time: 't2', runId: 'r');
    await repo.insert(lat: 3, lon: 3, time: 't3', runId: 'r');

    final all = await repo.getFirstN(10);
    final firstId = all.first.id;
    final lastId = all.last.id;

    final deleted = await repo.deleteByIds([firstId, lastId]);
    expect(deleted, 2);
    expect(await repo.count(), 1);

    final remaining = await repo.getFirstN(10);
    expect(remaining.single.time, 't2');
  });

  test('deleteByIds with empty list is a no-op', () async {
    await repo.insert(lat: 1, lon: 1, time: 't1', runId: 'r');

    final deleted = await repo.deleteByIds(<int>[]);
    expect(deleted, 0);
    expect(await repo.count(), 1);
  });

  test('deleteByIds ignores ids that are not in the table', () async {
    await repo.insert(lat: 1, lon: 1, time: 't1', runId: 'r');

    final deleted = await repo.deleteByIds([99999, 88888]);
    expect(deleted, 0);
    expect(await repo.count(), 1);
  });

  test('count reflects insertions and deletions', () async {
    expect(await repo.count(), 0);

    for (var i = 0; i < 5; i++) {
      await repo.insert(lat: i, lon: i, time: 't$i', runId: 'r');
    }
    expect(await repo.count(), 5);

    final ids = (await repo.getFirstN(3)).map((e) => e.id).toList();
    await repo.deleteByIds(ids);

    expect(await repo.count(), 2);
  });

  test('AUTOINCREMENT ids keep climbing after deletions', () async {
    final first = await repo.insert(lat: 1, lon: 1, time: 't1', runId: 'r');
    await repo.deleteByIds([first]);
    final second = await repo.insert(lat: 2, lon: 2, time: 't2', runId: 'r');

    expect(second, greaterThan(first));
  });
}
