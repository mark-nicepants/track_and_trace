import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/data/repositories/position_queue_repository.dart';
import 'package:app/domain/use_cases/enqueue_position.dart';
import 'package:app/shared/contracts/i_location_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/di_test_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: PositionQueueDao.schemaVersion,
        onCreate: (db, version) => db.execute(PositionQueueDao.createTableSql),
      ),
    );
    await setupTestDi(database: db);
  });

  tearDown(() async {
    await db.close();
    await tearDownTestDi();
  });

  test('inserts the fix and returns the new row id', () async {
    final fix = LocationFix(52.0, 4.0, '2026-06-09T12:00:00.000');
    final id = await EnqueuePosition(fix, null).call();
    expect(id, greaterThan(0));

    final rows = await PositionQueueRepository().getFirstN(10);
    expect(rows, hasLength(1));
    expect(rows.single.lat, 52.0);
    expect(rows.single.lon, 4.0);
    expect(rows.single.time, '2026-06-09T12:00:00.000');
    expect(rows.single.runId, isNull);
  });

  test('forwards runId when provided', () async {
    final fix = LocationFix(52.0, 4.0, '2026-06-09T12:00:00.000');
    await EnqueuePosition(fix, 'run-42').call();

    final rows = await PositionQueueRepository().getFirstN(10);
    expect(rows.single.runId, 'run-42');
  });
}
