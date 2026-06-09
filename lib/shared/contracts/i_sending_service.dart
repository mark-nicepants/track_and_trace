/// Drains the on-device position queue into `/create-locations` in
/// batches of up to 5 rows. Pauses while offline (per
/// [IConnectivityService]); resumes on reconnect. Retries 5 s after a
/// failed POST.
///
/// Production: `SendingService` (in `lib/data/services/`). Test double:
/// `InMemorySendingService` for UI tests that don't exercise the drain
/// logic itself.
///
/// The UI consumes [queueDepth] (current rows still buffered) but never
/// starts/stops the service directly — that's the `TrackingNotifier`'s
/// responsibility, in lock-step with [LocationService].
abstract interface class ISendingService {
  /// Starts the drain loop. Subsequent calls while [isRunning] are no-ops.
  Future<void> start();

  /// Stops the drain loop. Subsequent calls while not running are no-ops.
  /// Awaits any in-flight drain so the queue is left in a consistent state.
  Future<void> stop();

  bool get isRunning;

  /// Emits the remaining row count after each drain cycle (plus once on
  /// [start]). Broadcast — multiple UI consumers can subscribe.
  Stream<int> get queueDepth;
}
