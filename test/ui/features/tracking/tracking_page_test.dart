import 'dart:convert';

import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/ui/features/setup/setup_keys.dart';
import 'package:app/ui/features/tracking/tracking_page.dart';
import 'package:app/ui/shared/l10n/generated/app_localizations.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart' hide Matcher;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/di_test_helper.dart';
import '../../../helpers/fakes/in_memory_preference_service.dart';

Widget _harness() {
  return ProviderScope(
    child: MaterialApp(
      onGenerateTitle: (context) {
        L10n.init(context);
        return 'Test';
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const TrackingPage(),
    ),
  );
}

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

  testWidgets('renders the Dutch screen title + feedback grid labels', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Tracking Scherm'), findsOneWidget);
    expect(find.text('Rijden'), findsOneWidget);
    expect(find.text('Opladen'), findsOneWidget);
    expect(find.text('Storten'), findsOneWidget);
    expect(find.text('Stilstaan'), findsOneWidget);
    expect(find.text('Voorspelling'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
  });

  testWidgets('tracking page renders a button', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // The button should exist (either Start or Stop, depending on tracking state)
    expect(
      find.byKey(const Key('startButton')).evaluate().isNotEmpty ||
          find.byKey(const Key('stopButton')).evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('shows an error dialog with the HTTP status code when /create-run fails', (tester) async {
    final prefs = InMemoryPreferenceService();
    await prefs.writeString(machineTypeKey, jsonEncode({'id': 'mt-1', 'displayName': 'Loader'}));
    await prefs.writeString(machineCapacityKey, '12.5');

    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    DioAdapter(dio: dio).onPost('/create-run', (server) => server.reply(503, {'error': 'down'}), data: Matchers.any);

    await setupTestDi(prefs: prefs, dio: dio, database: db, trackAndTraceRepository: TrackAndTraceRepository());

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('startRunErrorDialog')), findsOneWidget);
    expect(find.textContaining('503'), findsOneWidget);

    await tester.tap(find.byKey(const Key('startRunErrorDismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('startRunErrorDialog')), findsNothing);
  });

  testWidgets('shows the saved vehicle + capacity label', (tester) async {
    final prefs = InMemoryPreferenceService();
    await prefs.writeString(machineTypeKey, jsonEncode({'id': 'mt-1', 'displayName': 'Loader'}));
    await prefs.writeString(machineCapacityKey, '12.5');

    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    DioAdapter(dio: dio).onPost('/create-run', (server) => server.reply(200, {'runId': 'r1'}), data: Matchers.any);
    await setupTestDi(prefs: prefs, dio: dio, database: db, trackAndTraceRepository: TrackAndTraceRepository());

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trackingVehicleSummary')), findsOneWidget);
    expect(find.text('Loader · 12.5 m³'), findsOneWidget);
  });

  testWidgets('shows the no-vehicle fallback label when nothing is saved', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Geen voertuig ingesteld'), findsOneWidget);
  });

  testWidgets('AppBar overflow menu exposes update-vehicle and share-logs', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('trackingOverflowMenu')));
    await tester.pumpAndSettle();

    expect(find.text('Voertuig & inhoud wijzigen'), findsOneWidget);
    expect(find.text('Logbestand delen'), findsOneWidget);
  });

  testWidgets('Update vehicle is disabled during an active run, share logs stays enabled', (tester) async {
    final prefs = InMemoryPreferenceService();
    await prefs.writeString(machineTypeKey, jsonEncode({'id': 'mt-1', 'displayName': 'Loader'}));
    await prefs.writeString(machineCapacityKey, '12.5');

    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    DioAdapter(dio: dio).onPost('/create-run', (server) => server.reply(200, {'runId': 'r1'}), data: Matchers.any);
    await setupTestDi(prefs: prefs, dio: dio, database: db, trackAndTraceRepository: TrackAndTraceRepository());

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle(); // start() runs → isTracking == true

    await tester.tap(find.byKey(const Key('trackingOverflowMenu')));
    await tester.pumpAndSettle();

    final updateItem = tester.widget(find.byKey(const Key('trackingMenuUpdateVehicle'))) as PopupMenuItem;
    expect(updateItem.enabled, isFalse);

    final shareItem = tester.widget(find.byKey(const Key('trackingMenuShareLogs'))) as PopupMenuItem;
    expect(shareItem.enabled, isTrue);
  });

  testWidgets('Share logs shows a snackbar when there are no logs on disk', (tester) async {
    // The default test log-export fake returns null (no logs).
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('trackingOverflowMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trackingMenuShareLogs')));
    await tester.pumpAndSettle();

    expect(find.text('Geen logbestanden om te delen.'), findsOneWidget);
  });

  testWidgets('Update vehicle opens the in-place settings dialog', (tester) async {
    final prefs = InMemoryPreferenceService();
    // Seed the offline cache so the dialog can populate the dropdown without
    // depending on a live machine-types response.
    await prefs.writeString(
      machineTypesCacheKey,
      jsonEncode([
        {'id': 'mt-1', 'displayName': 'Loader'},
      ]),
    );

    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    DioAdapter(dio: dio).onPost(
      '/get-machine-types',
      (server) => server.reply(200, [
        {'id': 'mt-1', 'displayName': 'Loader'},
      ]),
    );
    await setupTestDi(prefs: prefs, dio: dio, database: db, trackAndTraceRepository: TrackAndTraceRepository());

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('trackingOverflowMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trackingMenuUpdateVehicle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('vehicleSettingsDialog')), findsOneWidget);
    expect(find.byKey(const ValueKey('vehicleSettings.machineTypeDropdown')), findsOneWidget);
    expect(find.byKey(const ValueKey('vehicleSettings.capacityField')), findsOneWidget);
  });
}
