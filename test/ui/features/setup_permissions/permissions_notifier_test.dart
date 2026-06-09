import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:app/ui/features/setup_permissions/permissions_notifier.dart';
import 'package:app/ui/features/setup_permissions/permissions_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/di_test_helper.dart';
import '../../../helpers/fakes/in_memory_permission_service.dart';

void main() {
  group('PermissionsNotifier', () {
    tearDown(tearDownTestDi);

    test('build() returns initial denied state from the service', () async {
      await setupTestDi(permissions: InMemoryPermissionService());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(permissionsProvider.future);
      expect(state.locationWhenInUse, PermissionState.denied);
      expect(state.locationAlways, PermissionState.denied);
      expect(state.notification, PermissionState.denied);
      expect(state.allGranted, isFalse);
    });

    test('build() returns granted state when service starts granted', () async {
      await setupTestDi(
        permissions: InMemoryPermissionService(
          locationWhenInUse: PermissionState.granted,
          locationAlways: PermissionState.granted,
          notification: PermissionState.granted,
        ),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(permissionsProvider.future);
      expect(state.allGranted, isTrue);
    });

    test('requestLocationWhenInUse updates state on grant', () async {
      await setupTestDi(permissions: InMemoryPermissionService());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(permissionsProvider.future);
      await container.read(permissionsProvider.notifier).requestLocationWhenInUse();

      final state = container.read(permissionsProvider).value!;
      expect(state.locationWhenInUse, PermissionState.granted);
    });

    test('requestLocationAlways updates state on grant', () async {
      await setupTestDi(permissions: InMemoryPermissionService());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(permissionsProvider.future);
      await container.read(permissionsProvider.notifier).requestLocationAlways();

      final state = container.read(permissionsProvider).value!;
      expect(state.locationAlways, PermissionState.granted);
    });

    test('requestNotification updates state on grant', () async {
      await setupTestDi(permissions: InMemoryPermissionService());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(permissionsProvider.future);
      await container.read(permissionsProvider.notifier).requestNotification();

      final state = container.read(permissionsProvider).value!;
      expect(state.notification, PermissionState.granted);
    });

    test('request preserves permanentlyDenied state', () async {
      await setupTestDi(permissions: InMemoryPermissionService(locationWhenInUse: PermissionState.permanentlyDenied));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(permissionsProvider.future);
      await container.read(permissionsProvider.notifier).requestLocationWhenInUse();

      final state = container.read(permissionsProvider).value!;
      expect(state.locationWhenInUse, PermissionState.permanentlyDenied);
      expect(state.anyPermanentlyDenied, isTrue);
    });

    test('openSettings delegates to the service', () async {
      final fake = InMemoryPermissionService();
      await setupTestDi(permissions: fake);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(permissionsProvider.future);
      final result = await container.read(permissionsProvider.notifier).openSettings();
      expect(result, isTrue);
      expect(fake.openSettingsCallCount, 1);
    });
  });

  group('PermissionsState', () {
    test('allGranted only when all three are granted', () {
      expect(
        PermissionsState(PermissionState.granted, PermissionState.granted, PermissionState.granted).allGranted,
        isTrue,
      );
      expect(
        PermissionsState(PermissionState.granted, PermissionState.granted, PermissionState.denied).allGranted,
        isFalse,
      );
    });

    test('anyPermanentlyDenied is true if any is permanently denied', () {
      expect(
        PermissionsState(
          PermissionState.permanentlyDenied,
          PermissionState.denied,
          PermissionState.denied,
        ).anyPermanentlyDenied,
        isTrue,
      );
      expect(
        PermissionsState(PermissionState.denied, PermissionState.denied, PermissionState.denied).anyPermanentlyDenied,
        isFalse,
      );
    });

    test('copyWith updates only the named field', () {
      final s = PermissionsState(PermissionState.denied, PermissionState.denied, PermissionState.denied);
      final updated = s.copyWith(locationWhenInUse: PermissionState.granted);
      expect(updated.locationWhenInUse, PermissionState.granted);
      expect(updated.locationAlways, PermissionState.denied);
      expect(updated.notification, PermissionState.denied);
    });

    test('equality compares by content', () {
      final a = PermissionsState(PermissionState.denied, PermissionState.granted, PermissionState.denied);
      final b = PermissionsState(PermissionState.denied, PermissionState.granted, PermissionState.denied);
      expect(a, equals(b));
    });
  });
}
