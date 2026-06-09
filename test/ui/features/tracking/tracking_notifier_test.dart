import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/data/repositories/position_queue_repository.dart';
import 'package:app/data/services/in_memory_foreground_tracking_service.dart';
import 'package:app/data/services/in_memory_location_client.dart';
import 'package:app/data/services/in_memory_preference_service.dart';
import 'package:app/shared/contracts/i_location_client.dart';
import 'package:app/ui/features/tracking/tracking_keys.dart';
import 'package:app/ui/features/tracking/tracking_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/di_test_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late InMemoryPreferenceService prefs;
  late InMemoryLocationClient client;
  late InMemoryForegroundTrackingService foreground;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: PositionQueueDao.schemaVersion,
        onCreate: (db, version) => db.execute(PositionQueueDao.createTableSql),
      ),
    );
    prefs = InMemoryPreferenceService();
    client = InMemoryLocationClient();
    foreground = InMemoryForegroundTrackingService();
    await setupTestDi(prefs: prefs, locationClient: client, foreground: foreground, database: db);
  });

  tearDown(() async {
    await db.close();
    await tearDownTestDi();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('start() sets EXITED_CORRECTLY=false and starts the foreground service', () async {
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);

    await notifier.start();

    expect(notifier.isTracking, isTrue);
    expect(container.read(trackingProvider), isTrue);
    expect(await prefs.readString(exitedCorrectlyKey), 'false');
    expect(foreground.startCalls, hasLength(1));
    expect(foreground.startCalls.single.title, trackingNotificationTitle);
    expect(foreground.startCalls.single.body, trackingNotificationBody);
    expect(foreground.isRunning, isTrue);
  });

  test('start() subscribes to the location client at a 1 second interval', () async {
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);

    await notifier.start();

    expect(client.watchCallCount, 1);
    expect(client.watchIntervals.single, const Duration(seconds: 1));
    expect(client.isActive, isTrue);
  });

  test('emitted fixes land in the position queue in order', () async {
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    await notifier.start();

    client.emit(LocationFix(52.0, 4.0, '2026-06-09T12:00:00.000'));
    client.emit(LocationFix(52.1, 4.1, '2026-06-09T12:00:01.000'));
    client.emit(LocationFix(52.2, 4.2, '2026-06-09T12:00:02.000'));

    // Calling stop() awaits the in-flight write chain, so every queued
    // insert lands before we assert on the queue contents.
    await notifier.stop();

    final rows = await PositionQueueRepository().getFirstN(10);
    expect(rows, hasLength(3));
    expect(rows[0].lat, 52.0);
    expect(rows[0].lon, 4.0);
    expect(rows[0].time, '2026-06-09T12:00:00.000');
    expect(rows[1].lat, 52.1);
    expect(rows[2].time, '2026-06-09T12:00:02.000');
    for (final row in rows) {
      expect(row.runId, isNull);
    }
  });

  test('stop() cancels the subscription, stops the foreground service, and sets EXITED_CORRECTLY=true', () async {
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    await notifier.start();

    await notifier.stop();

    expect(notifier.isTracking, isFalse);
    expect(container.read(trackingProvider), isFalse);
    expect(await prefs.readString(exitedCorrectlyKey), 'true');
    expect(foreground.stopCallCount, 1);
    expect(foreground.isRunning, isFalse);
    expect(client.isActive, isFalse);
  });

  test('fixes emitted after stop() are not enqueued', () async {
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);

    await notifier.start();
    client.emit(LocationFix(52.0, 4.0, '2026-06-09T12:00:00.000'));
    await pumpEventQueue();
    await notifier.stop();
    client.emit(LocationFix(99.0, 99.0, '2026-06-09T12:00:01.000'));
    await pumpEventQueue();

    expect(await PositionQueueRepository().count(), 1);
  });

  test('start() is idempotent: a second call is a no-op', () async {
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);

    await notifier.start();
    await notifier.start();

    expect(foreground.startCalls, hasLength(1));
    expect(client.watchCallCount, 1);
  });

  test('stop() before start() is a no-op and leaves the flag unset', () async {
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);

    await notifier.stop();

    expect(notifier.isTracking, isFalse);
    expect(foreground.stopCallCount, 0);
    expect(await prefs.readString(exitedCorrectlyKey), isNull);
  });

  test('start() after a clean stop() re-arms the EXITED_CORRECTLY flag', () async {
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);

    await notifier.start();
    await notifier.stop();
    expect(await prefs.readString(exitedCorrectlyKey), 'true');

    await notifier.start();
    expect(await prefs.readString(exitedCorrectlyKey), 'false');
    expect(foreground.startCalls, hasLength(2));
  });
}
