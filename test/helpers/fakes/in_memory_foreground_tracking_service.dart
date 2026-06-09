import 'package:app/shared/contracts/i_foreground_tracking_service.dart';

/// Test double for [IForegroundTrackingService]. Records every start/stop
/// call so tests can assert that the notifier wired the Dutch copy through.
class InMemoryForegroundTrackingService implements IForegroundTrackingService {
  final List<({String title, String body})> startCalls = [];
  int stopCallCount = 0;
  bool isRunning = false;

  @override
  Future<void> start({required String title, required String body}) async {
    startCalls.add((title: title, body: body));
    isRunning = true;
  }

  @override
  Future<void> stop() async {
    stopCallCount += 1;
    isRunning = false;
  }
}
