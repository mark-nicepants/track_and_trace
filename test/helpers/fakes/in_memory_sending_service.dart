import 'dart:async';

import 'package:app/shared/contracts/i_sending_service.dart';

/// Test double for [ISendingService]. UI/notifier tests use this to assert
/// that `TrackingNotifier.start()` + `stop()` flip the service lifecycle
/// without exercising the real drain loop (which has its own dedicated
/// test file). The depth stream is driven entirely by [emitDepth].
class InMemorySendingService implements ISendingService {
  int startCallCount = 0;
  int stopCallCount = 0;
  bool _running = false;
  final StreamController<int> _depthController = StreamController<int>.broadcast(sync: true);

  @override
  bool get isRunning => _running;

  @override
  Stream<int> get queueDepth => _depthController.stream;

  @override
  Future<void> start() async {
    startCallCount += 1;
    _running = true;
  }

  @override
  Future<void> stop() async {
    stopCallCount += 1;
    _running = false;
  }

  void emitDepth(int n) => _depthController.add(n);
}
