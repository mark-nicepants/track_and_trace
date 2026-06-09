import 'package:app/shared/contracts/i_permission_service.dart';

/// Test/in-memory permission service. Defaults all states to [PermissionState.denied].
/// Use [setLocationWhenInUse]/[setLocationAlways]/[setNotification] to seed a
/// state and [autoGrantOnRequest] to control whether `requestX()` grants the
/// permission on call.
class InMemoryPermissionService implements IPermissionService {
  InMemoryPermissionService({
    PermissionState locationWhenInUse = PermissionState.denied,
    PermissionState locationAlways = PermissionState.denied,
    PermissionState notification = PermissionState.denied,
    this.autoGrantOnRequest = true,
    // ignore: prefer_initializing_formals
  }) : _locationWhenInUse = locationWhenInUse,
       // ignore: prefer_initializing_formals
       _locationAlways = locationAlways,
       // ignore: prefer_initializing_formals
       _notification = notification;

  PermissionState _locationWhenInUse;
  PermissionState _locationAlways;
  PermissionState _notification;
  bool autoGrantOnRequest;
  int openSettingsCallCount = 0;

  void setLocationWhenInUse(PermissionState s) => _locationWhenInUse = s;
  void setLocationAlways(PermissionState s) => _locationAlways = s;
  void setNotification(PermissionState s) => _notification = s;

  @override
  Future<PermissionState> getLocationWhenInUseStatus() async => _locationWhenInUse;

  @override
  Future<PermissionState> getLocationAlwaysStatus() async => _locationAlways;

  @override
  Future<PermissionState> getNotificationStatus() async => _notification;

  @override
  Future<PermissionState> requestLocationWhenInUse() async {
    if (_locationWhenInUse == PermissionState.permanentlyDenied) return _locationWhenInUse;
    if (autoGrantOnRequest) _locationWhenInUse = PermissionState.granted;
    return _locationWhenInUse;
  }

  @override
  Future<PermissionState> requestLocationAlways() async {
    if (_locationAlways == PermissionState.permanentlyDenied) return _locationAlways;
    if (autoGrantOnRequest) _locationAlways = PermissionState.granted;
    return _locationAlways;
  }

  @override
  Future<PermissionState> requestNotification() async {
    if (_notification == PermissionState.permanentlyDenied) return _notification;
    if (autoGrantOnRequest) _notification = PermissionState.granted;
    return _notification;
  }

  @override
  Future<bool> openSystemSettings() async {
    openSettingsCallCount++;
    return true;
  }
}
