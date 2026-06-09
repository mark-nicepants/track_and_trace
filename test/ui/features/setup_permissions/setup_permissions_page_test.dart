import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:app/ui/features/setup_permissions/setup_permissions_page.dart';
import 'package:app/ui/shared/l10n/generated/app_localizations.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/di_test_helper.dart';
import '../../../helpers/fakes/in_memory_permission_service.dart';
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
      home: const SetupPermissionsPage(),
    ),
  );
}

void main() {
  tearDown(tearDownTestDi);

  testWidgets('shows location rationale first when nothing granted', (tester) async {
    await setupTestDi(prefs: InMemoryPreferenceService(), permissions: InMemoryPermissionService());

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Toestemming'), findsOneWidget);
    expect(find.text('Deze app heeft uw locatie nodig om de locaties bij te houden.'), findsOneWidget);
    expect(find.text('Accepteer'), findsOneWidget);
  });

  testWidgets('shows notification rationale after both location grants', (tester) async {
    await setupTestDi(
      prefs: InMemoryPreferenceService(),
      permissions: InMemoryPermissionService(
        locationWhenInUse: PermissionState.granted,
        locationAlways: PermissionState.granted,
      ),
    );

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Deze app heeft notificaties nodig om te laten zien dat de app bezig is.'), findsOneWidget);
  });

  testWidgets('shows open-settings view when location is permanently denied', (tester) async {
    final service = InMemoryPermissionService(locationWhenInUse: PermissionState.permanentlyDenied);
    await setupTestDi(prefs: InMemoryPreferenceService(), permissions: service);

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Het lijkt erop dat u de locatie toestemming permanent hebt afgewezen…'), findsOneWidget);
    expect(find.text('Open instellingen'), findsOneWidget);

    await tester.tap(find.text('Open instellingen'));
    await tester.pumpAndSettle();
    expect(service.openSettingsCallCount, 1);
  });

  testWidgets('tapping Accept calls request and progresses to the next step', (tester) async {
    await setupTestDi(prefs: InMemoryPreferenceService(), permissions: InMemoryPermissionService());

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // Step 1: location-when-in-use rationale → Accept grants it.
    expect(find.text('Deze app heeft uw locatie nodig om de locaties bij te houden.'), findsOneWidget);
    await tester.tap(find.text('Accepteer'));
    await tester.pumpAndSettle();

    // Step 2: still on the location rationale, this time for location-always.
    expect(find.text('Deze app heeft uw locatie nodig om de locaties bij te houden.'), findsOneWidget);
    await tester.tap(find.text('Accepteer'));
    await tester.pumpAndSettle();

    // Step 3: notification rationale.
    expect(find.text('Deze app heeft notificaties nodig om te laten zien dat de app bezig is.'), findsOneWidget);
  });
}
