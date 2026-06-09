/// Polls `/get-status` every 2 seconds for the active run and emits each
/// newly-distinct predicted activity (as the wire string `LOADING` /
/// `DRIVING` / `DUMPING` / `STANDING_STILL`) on [predictions]. Mirrors the
/// Android reference's `PredictionService` loop (see
/// `old_android_app_reference/.../feature_location/PredictionService.kt`).
///
/// Production: `PredictionService` (in `lib/data/services/`). Test double:
/// `InMemoryPredictionService` for UI/notifier tests.
///
/// Wire strings (not `ActivityState`) are emitted because this contract
/// lives in the `shared` layer, which by architecture cannot depend on
/// `domain`. The `TrackingNotifier` decodes via `ActivityState.fromWire`.
abstract interface class IPredictionService {
  /// Begins polling for the given run. Subsequent calls while [isRunning]
  /// are no-ops.
  Future<void> start(String runId);

  /// Stops polling. Subsequent calls while not running are no-ops.
  Future<void> stop();

  bool get isRunning;

  /// Emits each newly-observed prediction as the wire form
  /// (`LOADING` / `DRIVING` / `DUMPING` / `STANDING_STILL`). Broadcast —
  /// multiple consumers can subscribe. Duplicate consecutive predictions
  /// are deduped at the source.
  Stream<String> get predictions;
}
