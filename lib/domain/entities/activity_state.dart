/// The four activity classifications a tracked vehicle can be in.
///
/// Mirrors the Android reference's `ActivityState` enum and the wire format
/// the API expects (`LOADING` / `DRIVING` / `DUMPING` / `STANDING_STILL`).
enum ActivityState {
  loading,
  driving,
  dumping,
  standingStill;

  /// The wire identifier used in the API (upper snake case).
  String get wireName => switch (this) {
    ActivityState.loading => 'LOADING',
    ActivityState.driving => 'DRIVING',
    ActivityState.dumping => 'DUMPING',
    ActivityState.standingStill => 'STANDING_STILL',
  };

  static ActivityState fromWire(String value) => switch (value) {
    'LOADING' => ActivityState.loading,
    'DRIVING' => ActivityState.driving,
    'DUMPING' => ActivityState.dumping,
    'STANDING_STILL' => ActivityState.standingStill,
    _ => throw ArgumentError('Unknown ActivityState wire value: $value'),
  };
}
