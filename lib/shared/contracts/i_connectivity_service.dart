/// Platform-agnostic connectivity signal: `true` when at least one network
/// interface (WiFi, cellular, ethernet, …) is up, `false` otherwise.
///
/// Production wraps `connectivity_plus`'s `Connectivity()`; tests use
/// `InMemoryConnectivityService` to script offline/online transitions.
abstract interface class IConnectivityService {
  /// One-shot read of the current connectivity. Used to seed UI providers
  /// and to gate the first drain cycle in [SendingService] before any
  /// stream event has fired.
  Future<bool> check();

  /// Hot stream of connectivity transitions. The contract does NOT promise
  /// an initial emit on listen — callers seed initial state via [check].
  /// `connectivity_plus` already de-duplicates so consecutive `true` or
  /// consecutive `false` events are collapsed.
  Stream<bool> get changes;
}
