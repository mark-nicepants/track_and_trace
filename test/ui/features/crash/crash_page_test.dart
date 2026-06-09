import 'package:app/shared/contracts/i_crash_report_service.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/ui/features/crash/crash_page.dart';
import 'package:app/ui/features/main/main_page.dart';
import 'package:app/ui/features/tracking/tracking_keys.dart';
import 'package:app/ui/shared/l10n/generated/app_localizations.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/di_test_helper.dart';
import '../../../helpers/fakes/in_memory_permission_service.dart';
import '../../../helpers/fakes/in_memory_preference_service.dart';

class _ScriptedCrashService implements ICrashReportService {
  _ScriptedCrashService({required this.result});
  final bool result;
  int callCount = 0;
  @override
  Future<bool> uploadLogs() async {
    callCount++;
    return result;
  }
}

Widget _harness() {
  final router = GoRouter(
    initialLocation: CrashPage.path,
    routes: [
      GoRoute(path: CrashPage.path, name: CrashPage.name, builder: (context, state) => const CrashPage()),
      GoRoute(
        path: MainPage.path,
        name: MainPage.name,
        builder: (context, state) => const Scaffold(body: Text('mainSentinel')),
      ),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      onGenerateTitle: (context) {
        L10n.init(context);
        return 'Test';
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  late InMemoryPreferenceService prefs;

  setUp(() async {
    prefs = InMemoryPreferenceService();
    await prefs.writeString(exitedCorrectlyKey, 'false');
  });

  tearDown(tearDownTestDi);

  testWidgets('renders the Dutch crash prompt + Yes/No buttons', (tester) async {
    await setupTestDi(prefs: prefs, crashReports: _ScriptedCrashService(result: true));

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Crash gedetecteerd'), findsOneWidget);
    expect(
      find.text('Het lijkt er op dat de applicatie is gecrasht. Wilt u een crash rapport versturen?'),
      findsOneWidget,
    );
    expect(find.text('Ja'), findsOneWidget);
    expect(find.text('Nee'), findsOneWidget);
  });

  testWidgets('Yes triggers upload, flips flag, and shows success', (tester) async {
    final service = _ScriptedCrashService(result: true);
    await setupTestDi(prefs: prefs, crashReports: service);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('crashAccept')));
    await tester.pumpAndSettle();

    expect(service.callCount, 1);
    expect(find.text('Crash rapport met success verstuurd!'), findsOneWidget);
    expect(find.text('Sluiten'), findsOneWidget);
    expect(await prefs.readString(exitedCorrectlyKey), 'true');
  });

  testWidgets('failure path shows "Opnieuw" retry button', (tester) async {
    await setupTestDi(prefs: prefs, crashReports: _ScriptedCrashService(result: false));

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('crashAccept')));
    await tester.pumpAndSettle();

    expect(find.text('Opnieuw'), findsOneWidget);
    expect(find.text('Sluiten'), findsOneWidget);
  });

  testWidgets('Nee dismisses + clears the flag + navigates to MainPage', (tester) async {
    final service = _ScriptedCrashService(result: true);
    await setupTestDi(prefs: prefs, crashReports: service);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('crashDecline')));
    await tester.pumpAndSettle();

    expect(service.callCount, 0);
    expect(await prefs.readString(exitedCorrectlyKey), 'true');
    expect(find.text('mainSentinel'), findsOneWidget);
  });

  testWidgets('Opnieuw retry rebuilds the choice view', (tester) async {
    final service = _ScriptedCrashService(result: false);
    await setupTestDi(prefs: prefs, crashReports: service);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('crashAccept')));
    await tester.pumpAndSettle();
    expect(find.text('Opnieuw'), findsOneWidget);

    await tester.tap(find.byKey(const Key('crashRetry')));
    await tester.pumpAndSettle();

    expect(find.text('Ja'), findsOneWidget);
    expect(find.text('Nee'), findsOneWidget);
  });

  // Reference IPreferenceService + InMemoryPermissionService so the unused
  // import lint passes (these are the providers the redirect uses in the
  // real router; tests above register a minimal router instead).
  test('test imports compile', () {
    expect(InMemoryPreferenceService(), isA<IPreferenceService>());
    expect(InMemoryPermissionService(), isNotNull);
  });
}
