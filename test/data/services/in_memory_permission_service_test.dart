import 'package:app/data/services/in_memory_permission_service.dart';
import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryPermissionService', () {
    test('defaults all permissions to denied', () async {
      final s = InMemoryPermissionService();
      expect(await s.getLocationWhenInUseStatus(), PermissionState.denied);
      expect(await s.getLocationAlwaysStatus(), PermissionState.denied);
      expect(await s.getNotificationStatus(), PermissionState.denied);
    });

    test('autoGrantOnRequest=true grants on request', () async {
      final s = InMemoryPermissionService();
      expect(await s.requestLocationWhenInUse(), PermissionState.granted);
      expect(await s.getLocationWhenInUseStatus(), PermissionState.granted);
    });

    test('autoGrantOnRequest=false leaves state unchanged on request', () async {
      final s = InMemoryPermissionService(autoGrantOnRequest: false);
      expect(await s.requestLocationAlways(), PermissionState.denied);
      expect(await s.getLocationAlwaysStatus(), PermissionState.denied);
    });

    test('permanentlyDenied state is preserved by request', () async {
      final s = InMemoryPermissionService(notification: PermissionState.permanentlyDenied);
      expect(await s.requestNotification(), PermissionState.permanentlyDenied);
    });

    test('openSystemSettings increments call count and returns true', () async {
      final s = InMemoryPermissionService();
      expect(await s.openSystemSettings(), isTrue);
      expect(s.openSettingsCallCount, 1);
    });

    test('setX mutators update state', () async {
      final s = InMemoryPermissionService()
        ..setLocationWhenInUse(PermissionState.granted)
        ..setLocationAlways(PermissionState.permanentlyDenied)
        ..setNotification(PermissionState.denied);
      expect(await s.getLocationWhenInUseStatus(), PermissionState.granted);
      expect(await s.getLocationAlwaysStatus(), PermissionState.permanentlyDenied);
      expect(await s.getNotificationStatus(), PermissionState.denied);
    });
  });
}
