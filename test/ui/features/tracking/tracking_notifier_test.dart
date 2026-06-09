import 'dart:convert';

import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/data/repositories/position_queue_repository.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/entities/activity_state.dart';
import 'package:app/shared/contracts/i_location_client.dart';
import 'package:app/ui/features/setup/setup_keys.dart';
import 'package:app/ui/features/tracking/tracking_keys.dart';
import 'package:app/ui/features/tracking/tracking_notifier.dart';
import 'package:app/ui/features/tracking/tracking_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart' hide Matcher;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/di_test_helper.dart';
import '../../../helpers/fakes/in_memory_foreground_tracking_service.dart';
import '../../../helpers/fakes/in_memory_location_client.dart';
import '../../../helpers/fakes/in_memory_prediction_service.dart';
import '../../../helpers/fakes/in_memory_preference_service.dart';
import '../../../helpers/fakes/in_memory_sending_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late InMemoryPreferenceService prefs;
  late InMemoryLocationClient client;
  late InMemoryForegroundTrackingService foreground;
  late InMemorySendingService sending;
  late InMemoryPredictionService prediction;
  late Dio dio;
  late DioAdapter adapter;

  Future<void> seedSetup({String machineTypeId = 'mt-1', num capacity = 12.5}) async {
    await prefs.writeString(machineTypeKey, jsonEncode({'id': machineTypeId, 'displayName': 'Loader'}));
    await prefs.writeString(machineCapacityKey, capacity.toString());
  }

  void replyCreateRun({String runId = 'run-xyz'}) {
    adapter.onPost('/create-run', (server) => server.reply(200, {'runId': runId}), data: Matchers.any);
  }

  void replyStopRunOk() {
    adapter.onPost('/stop-run', (server) => server.reply(200, <String, Object?>{}), data: Matchers.any);
  }

  void replyCreateFeedbackOk() {
    adapter.onPost('/create-feedback', (server) => server.reply(200, <String, Object?>{}), data: Matchers.any);
  }

  void replyNearestDepot(String name) {
    adapter.onPost('/get-nearest-depot', (server) => server.reply(200, {'name': name}), data: Matchers.any);
  }

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
    sending = InMemorySendingService();
    prediction = InMemoryPredictionService();
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    await setupTestDi(
      prefs: prefs,
      locationClient: client,
      foreground: foreground,
      sending: sending,
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

  test('start() calls /create-run, retains runId, and starts location + sending + prediction', () async {
    await seedSetup();
    replyCreateRun(runId: 'run-1');
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);

    await notifier.start();

    final state = container.read(trackingProvider);
    expect(state.runId, 'run-1');
    expect(state.isTracking, isTrue);
    expect(await prefs.readString(exitedCorrectlyKey), 'false');
    expect(foreground.isRunning, isTrue);
    expect(sending.isRunning, isTrue);
    expect(prediction.isRunning, isTrue);
    expect(prediction.startedRunId, 'run-1');
    expect(client.isActive, isTrue);
  });

  test('start() is a no-op when setup prefs are missing', () async {
    // No seedSetup() — prefs are empty.
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);

    await notifier.start();

    expect(container.read(trackingProvider), TrackingState.initial);
    expect(foreground.isRunning, isFalse);
  });

  test('emitted location fixes land in the queue tagged with the runId', () async {
    await seedSetup();
    replyCreateRun(runId: 'run-abc');
    replyStopRunOk();
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    await notifier.start();

    client.emit(LocationFix(52.0, 4.0, '2026-06-09T12:00:00.000'));
    client.emit(LocationFix(52.1, 4.1, '2026-06-09T12:00:01.000'));

    await notifier.stop();

    final rows = await PositionQueueRepository().getFirstN(10);
    expect(rows, hasLength(2));
    expect(rows.first.runId, 'run-abc');
  });

  test('stop() POSTs /stop-run, cancels services, sets EXITED_CORRECTLY=true and clears state', () async {
    await seedSetup();
    replyCreateRun();
    replyStopRunOk();
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    await notifier.start();

    final ok = await notifier.stop();

    expect(ok, isTrue);
    expect(container.read(trackingProvider), TrackingState.initial);
    expect(await prefs.readString(exitedCorrectlyKey), 'true');
    expect(foreground.isRunning, isFalse);
    expect(sending.isRunning, isFalse);
    expect(prediction.isRunning, isFalse);
    expect(client.isActive, isFalse);
  });

  test('stop() returns false when /stop-run fails but still tears down services', () async {
    await seedSetup();
    replyCreateRun();
    adapter.onPost('/stop-run', (server) => server.reply(500, {'error': 'boom'}), data: Matchers.any);
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    await notifier.start();

    final ok = await notifier.stop();

    expect(ok, isFalse);
    expect(container.read(trackingProvider), TrackingState.initial);
    expect(foreground.isRunning, isFalse);
  });

  test('start() is idempotent: a second call while running is a no-op', () async {
    await seedSetup();
    replyCreateRun();
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);

    await notifier.start();
    await notifier.start();

    expect(foreground.startCalls, hasLength(1));
    expect(prediction.startCallCount, 1);
    expect(client.watchCallCount, 1);
  });

  test('prediction stream updates predictedState; DUMPING→other clears shownDumpsizeDialogThisDump', () async {
    await seedSetup();
    replyCreateRun();
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    await notifier.start();

    prediction.emit('DUMPING');
    expect(container.read(trackingProvider).predictedState, ActivityState.dumping);

    // Simulate US-009: the dialog flips the guard to true.
    notifier.markDumpDialogShown();
    expect(container.read(trackingProvider).shownDumpsizeDialogThisDump, isTrue);

    // Transition out of DUMPING — the guard must clear.
    prediction.emit('DRIVING');
    final s2 = container.read(trackingProvider);
    expect(s2.predictedState, ActivityState.driving);
    expect(s2.shownDumpsizeDialogThisDump, isFalse);
  });

  test('DUMPING→LOADING also clears shownDumpsizeDialogThisDump', () async {
    await seedSetup();
    replyCreateRun();
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    await notifier.start();

    prediction.emit('DUMPING');
    notifier.markDumpDialogShown();
    prediction.emit('LOADING');
    expect(container.read(trackingProvider).shownDumpsizeDialogThisDump, isFalse);
  });

  test('non-DUMPING transitions do NOT touch shownDumpsizeDialogThisDump', () async {
    await seedSetup();
    replyCreateRun();
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    await notifier.start();

    prediction.emit('DRIVING');
    notifier.markDumpDialogShown();
    // Transition between two non-DUMPING states — guard should persist.
    prediction.emit('LOADING');
    expect(container.read(trackingProvider).shownDumpsizeDialogThisDump, isTrue);
  });

  test('feedback selection updates state, fires /create-feedback, and toggles depot polling', () async {
    await seedSetup();
    replyCreateRun(runId: 'run-feed');
    replyCreateFeedbackOk();
    replyNearestDepot('Depot A');
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    notifier.nearestDepotPollInterval = const Duration(milliseconds: 50);
    await notifier.start();

    notifier.selectFeedback(ActivityState.driving);

    final s1 = container.read(trackingProvider);
    expect(s1.feedbackState, ActivityState.driving);
    expect(s1.selectedFeedbackIndex, ActivityState.driving.index);

    // Wait for the immediate depot fetch to land.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(container.read(trackingProvider).nearestDepot?.name, 'Depot A');
  });

  test('switching feedback from DRIVING to LOADING stops depot polling and clears the depot', () async {
    await seedSetup();
    replyCreateRun(runId: 'run-2');
    replyCreateFeedbackOk();
    replyNearestDepot('Depot Z');
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    notifier.nearestDepotPollInterval = const Duration(milliseconds: 50);
    await notifier.start();

    notifier.selectFeedback(ActivityState.driving);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(container.read(trackingProvider).nearestDepot?.name, 'Depot Z');

    notifier.selectFeedback(ActivityState.loading);
    expect(container.read(trackingProvider).feedbackState, ActivityState.loading);
    expect(container.read(trackingProvider).nearestDepot, isNull);
  });

  test('tapping the same feedback row twice clears the selection', () async {
    await seedSetup();
    replyCreateRun();
    replyCreateFeedbackOk();
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    await notifier.start();

    notifier.selectFeedback(ActivityState.loading);
    expect(container.read(trackingProvider).feedbackState, ActivityState.loading);

    notifier.selectFeedback(ActivityState.loading);
    expect(container.read(trackingProvider).feedbackState, isNull);
    expect(container.read(trackingProvider).selectedFeedbackIndex, -1);
  });

  test('selectFeedback is a no-op when no run is active', () async {
    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    notifier.selectFeedback(ActivityState.driving);
    expect(container.read(trackingProvider), TrackingState.initial);
  });
}
