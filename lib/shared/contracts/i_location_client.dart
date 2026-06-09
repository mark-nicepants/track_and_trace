/// One GPS sample produced by an [ILocationClient]. Field names match the
/// `TrackingPositionDto` wire shape so consumers can pass the fix straight
/// into the position queue or the `/create-locations` payload.
class LocationFix(final num lat, final num lon, final String time);

/// Abstraction over the continuous GPS source. Production wraps the
/// `tracelet` plugin (see `TraceletLocationClient`); tests use
/// `InMemoryLocationClient` to script scenarios.
///
/// The plugin choice (tracelet over `background_location`, the default in
/// FEATURES.md §13.x) is documented in `TraceletLocationClient`.
abstract interface class ILocationClient {
  /// Starts continuous tracking and yields one [LocationFix] per fix.
  ///
  /// Cancelling the subscription stops the underlying source.
  Stream<LocationFix> watch({required Duration interval});
}
