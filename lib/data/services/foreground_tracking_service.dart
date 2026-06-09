import 'package:app/shared/contracts/i_foreground_tracking_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Production [IForegroundTrackingService] backed by `flutter_foreground_task`.
///
/// On Android, hosts a foreground service of type `LOCATION` (set via
/// [ForegroundServiceTypes.location]) — the AndroidManifest also declares
/// `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` permissions so
/// Android 14+ allows the service to start. On iOS the notification is
/// shown opportunistically; killed-state tracking is driven by tracelet's
/// own `LocationAuthorizationRequest.always`.
class ForegroundTrackingService implements IForegroundTrackingService {
  const ForegroundTrackingService();

  void _initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tracking',
        channelName: 'Track & Trace',
        channelDescription: 'GPS-locatie wordt vastgelegd.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
      ),
    );
  }

  @override
  Future<void> start({required String title, required String body}) async {
    _initialize();
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.location],
      notificationTitle: title,
      notificationText: body,
    );
  }

  @override
  Future<void> stop() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}
