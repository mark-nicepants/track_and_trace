import 'dart:async';

import 'package:app/shared/contracts/i_prediction_service.dart';

/// Test double for [IPredictionService]. UI/notifier tests use this to
/// drive the prediction stream from the test body via [emit]. Counts
/// [startCallCount] / [stopCallCount] so the test can assert lifecycle.
class InMemoryPredictionService implements IPredictionService {
  int startCallCount = 0;
  int stopCallCount = 0;
  String? startedRunId;
  bool _running = false;
  final StreamController<String> _controller = StreamController<String>.broadcast(sync: true);

  @override
  bool get isRunning => _running;

  @override
  Stream<String> get predictions => _controller.stream;

  @override
  Future<void> start(String runId) async {
    startCallCount += 1;
    startedRunId = runId;
    _running = true;
  }

  @override
  Future<void> stop() async {
    stopCallCount += 1;
    _running = false;
  }

  /// Push a wire-format prediction (`LOADING` / `DRIVING` / `DUMPING` /
  /// `STANDING_STILL`) into the stream.
  void emit(String activity) => _controller.add(activity);
}
