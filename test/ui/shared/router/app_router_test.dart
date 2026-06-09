import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:app/ui/features/crash/crash_page.dart';
import 'package:app/ui/features/setup/setup_keys.dart';
import 'package:app/ui/features/setup/setup_page.dart';
import 'package:app/ui/features/setup_permissions/setup_permissions_page.dart';
import 'package:app/ui/features/tracking/tracking_keys.dart';
import 'package:app/ui/features/tracking/tracking_page.dart';
import 'package:app/ui/shared/l10n/generated/app_localizations.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:app/ui/shared/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/di_test_helper.dart';
import '../../../helpers/fakes/in_memory_permission_service.dart';
import '../../../helpers/fakes/in_memory_preference_service.dart';

Widget _appUnderTest() {
  return ProviderScope(
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          onGenerateTitle: (context) {
            L10n.init(context);
            return 'Test';
          },
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        );
      },
    ),
  );
}

Future<void> _pumpRouter(WidgetTester tester) async {
  await tester.pumpWidget(_appUnderTest());
  // Allow AsyncNotifier.build() futures + redirect listeners to flush.
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  tearDown(tearDownTestDi);

  group('routerProvider redirect', () {
    testWidgets('no permissions → /permissions', (tester) async {
      await setupTestDi(prefs: InMemoryPreferenceService(), permissions: InMemoryPermissionService());

      await _pumpRouter(tester);

      expect(find.byType(SetupPermissionsPage), findsOneWidget);
      expect(find.byType(SetupPage), findsNothing);
      expect(find.byType(TrackingPage), findsNothing);
    });

    testWidgets('permissions OK + no setup persisted → /setup', (tester) async {
      await setupTestDi(prefs: InMemoryPreferenceService(), permissions: _granted());

      await _pumpRouter(tester);

      expect(find.byType(SetupPage), findsOneWidget);
      expect(find.byType(SetupPermissionsPage), findsNothing);
      expect(find.byType(TrackingPage), findsNothing);
    });

    testWidgets('permissions OK + setup persisted → /tracking', (tester) async {
      final prefs = InMemoryPreferenceService();
      await prefs.writeString(machineTypeKey, '{"id":"mt-1","displayName":"Loader"}');
      await prefs.writeString(machineCapacityKey, '12.0');

      await setupTestDi(prefs: prefs, permissions: _granted());

      await _pumpRouter(tester);

      expect(find.byType(TrackingPage), findsOneWidget);
      expect(find.byType(SetupPage), findsNothing);
      expect(find.byType(SetupPermissionsPage), findsNothing);
    });

    testWidgets('EXITED_CORRECTLY=false → /crash', (tester) async {
      final prefs = InMemoryPreferenceService();
      await prefs.writeString(exitedCorrectlyKey, 'false');
      await setupTestDi(prefs: prefs, permissions: _granted());

      await _pumpRouter(tester);

      expect(find.byType(CrashPage), findsOneWidget);
      expect(find.byType(SetupPage), findsNothing);
      expect(find.byType(TrackingPage), findsNothing);
    });

    testWidgets('redirect only fires from the MainPage path (no infinite loop)', (tester) async {
      await setupTestDi(prefs: InMemoryPreferenceService(), permissions: InMemoryPermissionService());

      await _pumpRouter(tester);

      // We landed on /permissions via redirect.
      expect(find.byType(SetupPermissionsPage), findsOneWidget);
    });
  });
}

IPermissionService _granted() => InMemoryPermissionService(
  locationWhenInUse: PermissionState.granted,
  locationAlways: PermissionState.granted,
  notification: PermissionState.granted,
);
