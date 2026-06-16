import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/ui/features/tracking/tracking_page.dart';
import 'package:app/ui/shared/l10n/generated/app_localizations.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/di_test_helper.dart';

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
}
