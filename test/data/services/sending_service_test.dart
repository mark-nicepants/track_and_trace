import 'dart:async';

import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/data/repositories/position_queue_repository.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/data/services/in_memory_connectivity_service.dart';
import 'package:app/data/services/sending_service.dart';
import 'package:app/shared/inject.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/di_test_helper.dart';

/// Spy/script for `POST /create-locations`. http_mock_adapter consumes
/// each registered handler after a single match, which makes multi-batch
/// drain tests awkward — this interceptor stays for the life of the Dio.
class _CreateLocationsFake extends Interceptor {
  _CreateLocationsFake();

  /// Optional hook fired before each response is computed. Tests use it
  /// to wait on a [Completer] or flip a flag mid-flight.
  Future<void> Function()? onRequestHook;

  /// Returns true to succeed (200), false to throw a network error.
  /// Defaults to always-succeed.
  bool Function(int callIndex) shouldSucceed = (_) => true;

  int callCount = 0;
  final List<Map<String, Object?>> capturedBodies = [];

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.path != '/create-locations') {
      handler.next(options);
      return;
    }
    final index = callCount++;
    capturedBodies.add(options.data as Map<String, Object?>);
    if (onRequestHook != null) await onRequestHook!();
    if (shouldSucceed(index)) {
      handler.resolve(Response<void>(requestOptions: options, statusCode: 200));
    } else {
      handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError));
    }
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late Dio dio;
  late _CreateLocationsFake fake;
  late PositionQueueRepository queue;
  late InMemoryConnectivityService connectivity;
  late SendingService service;

  /// Fast retry so the suite doesn't actually sleep 5 s between attempts.
  /// The production default (5 s) is asserted separately.
  const fastRetry = Duration(milliseconds: 30);

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: PositionQueueDao.schemaVersion,
        onCreate: (db, version) => db.execute(PositionQueueDao.createTableSql),
      ),
    );
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    fake = _CreateLocationsFake();
    dio.interceptors.add(fake);
    connectivity = InMemoryConnectivityService();
    await setupTestDi(dio: dio, connectivity: connectivity, database: db);
    // Override the default in-memory TrackAndTraceRepository so the drain
    // exercises the real Dio-backed implementation against our fake.
    if (injector.isRegistered<TrackAndTraceRepository>()) {
      injector.unregister<TrackAndTraceRepository>();
    }
    injector.registerSingleton<TrackAndTraceRepository>(TrackAndTraceRepository());
    queue = inject<PositionQueueRepository>();
    service = SendingService(retryDelay: fastRetry);
  });

  tearDown(() async {
    await service.stop();
    await db.close();
    await tearDownTestDi();
  });

  Future<void> seed(int n) async {
    for (var i = 0; i < n; i++) {
      await queue.insert(
        lat: 52.0 + i / 1000,
        lon: 4.0 + i / 1000,
        time: '2026-06-09T12:00:00.${i.toString().padLeft(3, '0')}',
      );
    }
  }

  /// Polls until [predicate] returns true or [timeout] elapses.
  Future<void> waitFor(Future<bool> Function() predicate, {Duration timeout = const Duration(seconds: 3)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await predicate()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Condition not met within ${timeout.inMilliseconds}ms');
  }

  test('production default retryDelay is 5 s', () {
    expect(SendingService().retryDelay, const Duration(seconds: 5));
  });

  test('drains 5 rows, POSTs /create-locations, deletes on success', () async {
    await seed(5);

    await service.start();

    await waitFor(() async => fake.callCount == 1 && await queue.count() == 0);
    expect(fake.callCount, 1);
    expect(await queue.count(), 0);
    // The wire payload carries exactly the 5 rows under `locations`.
    final locations = fake.capturedBodies.first['locations']! as List;
    expect(locations, hasLength(5));
  });

  test('drains in batches of 5 — 7 rows yields 2 POSTs', () async {
    await seed(7);

    await service.start();

    await waitFor(() async => fake.callCount == 2 && await queue.count() == 0);
    expect(fake.callCount, 2);
    expect(await queue.count(), 0);
    // First batch is full (5), second batch is the leftover (2).
    expect((fake.capturedBodies[0]['locations']! as List), hasLength(5));
    expect((fake.capturedBodies[1]['locations']! as List), hasLength(2));
  });

  test('retries after a failed POST then deletes on success', () async {
    fake.shouldSucceed = (i) => i > 0; // first call fails, then succeeds
    await seed(5);

    await service.start();

    await waitFor(() async => fake.callCount >= 2 && await queue.count() == 0);
    expect(fake.callCount, greaterThanOrEqualTo(2));
    expect(await queue.count(), 0);
  });

  test('connectivity loss pauses sending; reconnect resumes', () async {
    connectivity.emit(false);
    await seed(5);

    await service.start();

    // Give the loop a chance to attempt — it shouldn't, because offline.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(fake.callCount, 0);
    expect(await queue.count(), 5);

    connectivity.emit(true);

    await waitFor(() async => fake.callCount == 1 && await queue.count() == 0);
    expect(await queue.count(), 0);
  });

  test('does not double-delete when reconnect fires during an in-flight drain', () async {
    final gate = Completer<void>();
    fake.onRequestHook = () => gate.future;
    await seed(5);

    await service.start();
    await waitFor(() async => fake.callCount == 1);

    // Flicker connectivity during the in-flight drain. A naïve "reconnect
    // → fresh drain" implementation would re-read the same 5 rows and try
    // to delete them a second time after the first POST completes.
    connectivity
      ..emit(false)
      ..emit(true)
      ..emit(false)
      ..emit(true);

    gate.complete();
    await waitFor(() async => await queue.count() == 0);

    expect(fake.callCount, 1, reason: 'a second drain would have re-fetched + re-POSTed the same rows');
    expect(await queue.count(), 0);
  });

  test('empty queue does not POST', () async {
    await service.start();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(fake.callCount, 0);
  });

  test('start() while running is a no-op', () async {
    await service.start();
    expect(service.isRunning, isTrue);
    await service.start();
    expect(service.isRunning, isTrue);
  });

  test('stop() while not running is a no-op', () async {
    expect(service.isRunning, isFalse);
    await service.stop();
    expect(service.isRunning, isFalse);
  });

  test('queueDepth stream emits initial depth on start', () async {
    await seed(3);
    final depths = <int>[];
    final sub = service.queueDepth.listen(depths.add);

    await service.start();
    await waitFor(() async => depths.isNotEmpty);
    expect(depths.first, 3);

    await sub.cancel();
  });

  test('queueDepth stream emits 0 after queue is fully drained', () async {
    await seed(7);

    final depths = <int>[];
    final sub = service.queueDepth.listen(depths.add);

    await service.start();
    await waitFor(() async => depths.contains(0));
    expect(depths.first, 7);
    expect(depths.last, 0);

    await sub.cancel();
  });
}
