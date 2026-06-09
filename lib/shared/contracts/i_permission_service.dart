/// Platform-agnostic permission state. Hides `permission_handler`'s richer
/// `PermissionStatus` (which has iOS-only variants like `provisional`,
/// `limited`, `restricted`) behind the three states this app actually reacts to.
enum PermissionState { granted, denied, permanentlyDenied }

/// Thin facade over the `permission_handler` plugin. Lives in
/// `shared/contracts/` so notifiers can `inject<IPermissionService>()` without
/// pulling the plugin into the UI layer, and so tests can swap in an
/// in-memory implementation.
abstract interface class IPermissionService {
  Future<PermissionState> getLocationWhenInUseStatus();
  Future<PermissionState> getLocationAlwaysStatus();
  Future<PermissionState> getNotificationStatus();

  Future<PermissionState> requestLocationWhenInUse();
  Future<PermissionState> requestLocationAlways();
  Future<PermissionState> requestNotification();

  Future<bool> openSystemSettings();
}
