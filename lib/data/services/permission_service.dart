import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService implements IPermissionService {
  const PermissionService();

  @override
  Future<PermissionState> getLocationWhenInUseStatus() => _check(ph.Permission.locationWhenInUse);

  @override
  Future<PermissionState> getLocationAlwaysStatus() => _check(ph.Permission.locationAlways);

  @override
  Future<PermissionState> getNotificationStatus() => _check(ph.Permission.notification);

  @override
  Future<PermissionState> requestLocationWhenInUse() => _request(ph.Permission.locationWhenInUse);

  @override
  Future<PermissionState> requestLocationAlways() => _request(ph.Permission.locationAlways);

  @override
  Future<PermissionState> requestNotification() => _request(ph.Permission.notification);

  @override
  Future<bool> openSystemSettings() => ph.openAppSettings();

  Future<PermissionState> _check(ph.Permission p) async => _map(await p.status);
  Future<PermissionState> _request(ph.Permission p) async => _map(await p.request());

  PermissionState _map(ph.PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) return PermissionState.granted;
    if (status.isPermanentlyDenied || status.isRestricted) return PermissionState.permanentlyDenied;
    return PermissionState.denied;
  }
}
