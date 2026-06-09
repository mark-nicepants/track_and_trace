/// Discrete bucket of "how full was the dump load."
///
/// Mirrors the Android reference's `DumpSize` enum and the wire vocabulary
/// the API expects.
enum DumpSize {
  quarter,
  half,
  threeQuarter,
  full,
  unspecified;

  /// The wire identifier used in the API (upper snake case from the
  /// Kotlin enum names).
  String get wireName => switch (this) {
    DumpSize.quarter => 'QUARTER',
    DumpSize.half => 'HALF',
    DumpSize.threeQuarter => 'THREEQUARTER',
    DumpSize.full => 'FULL',
    DumpSize.unspecified => 'UNSPECIFIED',
  };

  /// Inverse of [wireName]; falls back to [unspecified] for unknown values
  /// (matches the Kotlin `fromString` behaviour).
  static DumpSize fromWire(String? value) => switch (value) {
    'QUARTER' => DumpSize.quarter,
    'HALF' => DumpSize.half,
    'THREEQUARTER' => DumpSize.threeQuarter,
    'FULL' => DumpSize.full,
    _ => DumpSize.unspecified,
  };
}
