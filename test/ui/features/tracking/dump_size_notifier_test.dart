import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/data/services/in_memory_prediction_service.dart';
import 'package:app/data/services/in_memory_preference_service.dart';
import 'package:app/domain/entities/activity_state.dart';
import 'package:app/domain/entities/dump_size.dart';
import 'package:app/ui/features/setup/setup_keys.dart';
import 'package:app/ui/features/tracking/dump_size_notifier.dart';
import 'package:app/ui/features/tracking/tracking_notifier.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/di_test_helper.dart';

/// Recording http client adapter. Captures every request body (decoded
/// JSON) by path and returns whatever response the test scripts. Lets us
/// stub multiple calls to the same endpoint without `onPost` handler
/// burnout, and assert the parallelism by reading the in-flight set
/// before completing any request.
class _RecordingAdapter implements HttpClientAdapter {
  final List<String> calledPaths = [];
  final Map<String, List<Map<String, Object?>>> bodiesByPath = {};
  final Map<String, Completer<void>> _holdByPath = {};
  final Map<String, String> responsesByPath = {'/create-run': '{"runId":"run-1"}'};

  /// If set, the adapter waits on this completer before resolving the
  /// matching request. Use to assert that calls are truly parallel.
  void hold(String path) => _holdByPath[path] = Completer<void>();

  void release(String path) {
    final c = _holdByPath.remove(path);
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calledPaths.add(options.path);
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      final bytes = chunks.expand((c) => c).toList();
      final raw = utf8.decode(bytes);
      try {
        bodiesByPath.putIfAbsent(options.path, () => []).add(jsonDecode(raw) as Map<String, Object?>);
      } catch (_) {
        // body wasn't JSON — ignore
      }
    }
    final hold = _holdByPath[options.path];
    if (hold != null) await hold.future;
    return ResponseBody.fromString(
      responsesByPath[options.path] ?? '{}',
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late InMemoryPreferenceService prefs;
  late InMemoryPredictionService prediction;
  late Dio dio;
  late _RecordingAdapter adapter;

  Future<void> seedSetup() async {
    await prefs.writeString(machineTypeKey, jsonEncode({'id': 'mt-1', 'displayName': 'Loader'}));
    await prefs.writeString(machineCapacityKey, '12.5');
  }

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: PositionQueueDao.schemaVersion,
        onCreate: (db, _) => db.execute(PositionQueueDao.createTableSql),
      ),
    );
    prefs = InMemoryPreferenceService();
    prediction = InMemoryPredictionService();
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = _RecordingAdapter();
    dio.httpClientAdapter = adapter;
    await setupTestDi(
      prefs: prefs,
      prediction: prediction,
      dio: dio,
      database: db,
      trackAndTraceRepository: TrackAndTraceRepository(),
    );
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

  Future<void> startRunAndPrime(ProviderContainer container) async {
    await seedSetup();
    // Mount the dump-size provider BEFORE start() so its ref.listen on
    // trackingProvider is wired up to receive the DUMPING transition.
    container.read(dumpSizeProvider);
    await container.read(trackingProvider.notifier).start();
  }

  test('shows the dialog when prediction emits DUMPING', () async {
    final container = makeContainer();
    await startRunAndPrime(container);

    expect(container.read(dumpSizeProvider), isFalse);

    prediction.emit('DUMPING');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(dumpSizeProvider), isTrue);
    expect(container.read(trackingProvider).shownDumpsizeDialogThisDump, isTrue);
  });

  test('shows the dialog when feedback selects DUMPING (not just prediction)', () async {
    final container = makeContainer();
    await startRunAndPrime(container);

    container.read(trackingProvider.notifier).selectFeedback(ActivityState.dumping);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(dumpSizeProvider), isTrue);
  });

  test('does NOT re-show when DUMPING re-emits within the same episode', () async {
    final container = makeContainer();
    await startRunAndPrime(container);
    prediction.emit('DUMPING');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(dumpSizeProvider), isTrue);

    // Dismiss the dialog — guard stays set until DUMPING → other.
    container.read(dumpSizeProvider.notifier).dismiss();
    expect(container.read(dumpSizeProvider), isFalse);

    // Re-emitting DUMPING (same episode) must NOT re-show.
    prediction.emit('DUMPING');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(dumpSizeProvider), isFalse);
  });

  test('re-shows on a NEW DUMPING episode after a DUMPING→other→DUMPING cycle', () async {
    final container = makeContainer();
    await startRunAndPrime(container);
    prediction.emit('DUMPING');
    await Future<void>.delayed(Duration.zero);
    container.read(dumpSizeProvider.notifier).dismiss();

    // Leave DUMPING — the tracking notifier clears the guard.
    prediction.emit('DRIVING');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(trackingProvider).shownDumpsizeDialogThisDump, isFalse);

    // New episode — dialog must come back.
    prediction.emit('DUMPING');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(dumpSizeProvider), isTrue);
  });

  test('confirm fires /create-dump-size AND /sync-run-data — both calls start before either resolves', () async {
    final container = makeContainer();
    await startRunAndPrime(container);
    prediction.emit('DUMPING');
    await Future<void>.delayed(Duration.zero);

    // Hold both responses so we can assert that BOTH requests are
    // in-flight simultaneously (the parallel-firing acceptance criterion).
    adapter.hold('/create-dump-size');
    adapter.hold('/sync-run-data');

    container.read(dumpSizeProvider.notifier).confirm(DumpSize.quarter);
    await pumpEventQueue();

    expect(adapter.calledPaths.toSet().containsAll({'/create-dump-size', '/sync-run-data'}), isTrue);

    // Neither completer has been released yet — both calls were truly
    // parallel, neither awaited the other.
    adapter.release('/create-dump-size');
    adapter.release('/sync-run-data');
    await pumpEventQueue();
  });

  test('confirm sends the chosen wire-form quantity on both endpoints', () async {
    final container = makeContainer();
    await startRunAndPrime(container);
    prediction.emit('DUMPING');
    await Future<void>.delayed(Duration.zero);

    container.read(dumpSizeProvider.notifier).confirm(DumpSize.threeQuarter);
    await pumpEventQueue();

    expect(adapter.bodiesByPath['/create-dump-size']?.single['quantity'], 'THREEQUARTER');
    expect(adapter.bodiesByPath['/sync-run-data']?.single['quantity'], 'THREEQUARTER');
    expect(container.read(dumpSizeProvider), isFalse);
  });

  test('auto-confirm timer fires FULL after 5 minutes if user does not interact', () async {
    // Boot the run with real async first — start() involves microtask
    // chains that don't compose cleanly with fakeAsync.
    final container = makeContainer();
    await startRunAndPrime(container);

    // The 5-minute Timer is created INSIDE the dump-size notifier's
    // listener, which fires after prediction.emit. Wrap emit + elapse in
    // fakeAsync so the Timer lands in fakeAsync's zone.
    fakeAsync((async) {
      // Triggering the dump-size flow via `prediction.emit` would run
      // its stream listener in the zone the listener was registered in
      // (the test's outer zone), so the auto-confirm Timer would land
      // OUTSIDE fakeAsync and the 5-minute elapse wouldn't fire it.
      // Driving the same state transition through
      // `selectFeedback(ActivityState.dumping)` runs the state update
      // synchronously inside the fakeAsync zone, so Riverpod's listener
      // microtask + the Timer it creates both end up tracked by
      // fakeAsync.
      container.read(trackingProvider.notifier).selectFeedback(ActivityState.dumping);
      async.elapse(Duration.zero);
      expect(container.read(dumpSizeProvider), isTrue);

      adapter.calledPaths.clear();
      adapter.bodiesByPath.clear();

      // Advance 5 minutes → auto-confirm should fire with FULL.
      async.elapse(const Duration(minutes: 5));
      async.flushMicrotasks();

      expect(container.read(dumpSizeProvider), isFalse);
      expect(adapter.bodiesByPath['/create-dump-size']?.single['quantity'], 'FULL');
      expect(adapter.bodiesByPath['/sync-run-data']?.single['quantity'], 'FULL');
    });
  });

  test('dismiss cancels the timer and fires no API calls', () async {
    final container = makeContainer();
    container.read(dumpSizeProvider.notifier).autoConfirmAfter = const Duration(milliseconds: 50);
    await startRunAndPrime(container);
    prediction.emit('DUMPING');
    await Future<void>.delayed(Duration.zero);

    adapter.calledPaths.clear();
    adapter.bodiesByPath.clear();

    container.read(dumpSizeProvider.notifier).dismiss();
    expect(container.read(dumpSizeProvider), isFalse);

    // Wait past the auto-confirm window — nothing should fire.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(adapter.calledPaths, isEmpty);
  });

  test('confirm cancels the auto-confirm timer (subsequent fire is a no-op)', () async {
    final container = makeContainer();
    container.read(dumpSizeProvider.notifier).autoConfirmAfter = const Duration(milliseconds: 50);
    await startRunAndPrime(container);
    prediction.emit('DUMPING');
    await Future<void>.delayed(Duration.zero);

    adapter.calledPaths.clear();
    adapter.bodiesByPath.clear();

    container.read(dumpSizeProvider.notifier).confirm(DumpSize.half);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    // Two calls from confirm; auto-confirm timer was cancelled, so no
    // extra firings.
    expect(adapter.calledPaths.where((p) => p == '/create-dump-size'), hasLength(1));
    expect(adapter.calledPaths.where((p) => p == '/sync-run-data'), hasLength(1));
  });

  test('default autoConfirmAfter is 5 minutes (FEATURES.md §5.4)', () {
    final container = makeContainer();
    expect(container.read(dumpSizeProvider.notifier).autoConfirmAfter, const Duration(minutes: 5));
  });
}
