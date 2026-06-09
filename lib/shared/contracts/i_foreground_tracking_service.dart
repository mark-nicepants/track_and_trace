/// Hosts the persistent foreground service + notification while tracking.
///
/// Production wraps `flutter_foreground_task` (see
/// `ForegroundTrackingService`); tests use
/// `InMemoryForegroundTrackingService` to assert that start/stop were
/// called with the expected Dutch notification copy.
abstract interface class IForegroundTrackingService {
  Future<void> start({required String title, required String body});
  Future<void> stop();
}
