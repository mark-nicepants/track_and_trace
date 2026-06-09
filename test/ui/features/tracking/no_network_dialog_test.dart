import 'package:app/data/data_source/position_queue_dao.dart';
import 'package:app/data/services/in_memory_connectivity_service.dart';
import 'package:app/ui/features/tracking/no_network_dialog.dart';
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
  late InMemoryConnectivityService connectivity;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: PositionQueueDao.schemaVersion,
        onCreate: (db, version) => db.execute(PositionQueueDao.createTableSql),
      ),
    );
    connectivity = InMemoryConnectivityService();
    await setupTestDi(connectivity: connectivity, database: db);
  });

  tearDown(() async {
    await db.close();
    await tearDownTestDi();
  });

  testWidgets('NoNetworkDialog renders the Dutch title + body', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          onGenerateTitle: (context) {
            L10n.init(context);
            return 'Test';
          },
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: NoNetworkDialog()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Geen netwerk'), findsOneWidget);
    expect(find.textContaining('Momenteel is er geen internetverbinding'), findsOneWidget);
    expect(find.textContaining('zullen de trackinggegevens naar Gisib worden verstuurd'), findsOneWidget);
  });

  testWidgets('tracking page shows the dialog when connectivity drops', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Initially online — no dialog.
    expect(find.byKey(NoNetworkDialog.dialogKey), findsNothing);

    connectivity.emit(false);
    await tester.pumpAndSettle();

    expect(find.byKey(NoNetworkDialog.dialogKey), findsOneWidget);
    expect(find.text('Geen netwerk'), findsOneWidget);
  });

  testWidgets('dialog dismisses on reconnect', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    connectivity.emit(false);
    await tester.pumpAndSettle();
    expect(find.byKey(NoNetworkDialog.dialogKey), findsOneWidget);

    connectivity.emit(true);
    await tester.pumpAndSettle();

    expect(find.byKey(NoNetworkDialog.dialogKey), findsNothing);
  });
}
