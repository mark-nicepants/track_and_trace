/// `IPreferenceService` key for the crash-detection flag (FEATURES.md §13.x).
/// Set to `false` when tracking starts; flipped back to `true` on clean
/// stop. If the app boots and finds the value still `false`, the previous
/// session crashed — the crash-report flow (US-010) reads this flag.
const String exitedCorrectlyKey = 'tracking.exited_correctly';

/// Dutch persistent-notification copy for the foreground tracking service.
///
/// The product is Dutch-only per FEATURES.md §13.2 ("Const string map per
/// FEATURES.md §13.2"), so these live as compile-time constants rather
/// than ARB entries — the notifier writes them directly into the
/// notification (no `BuildContext` available off the widget tree).
const String trackingNotificationTitle = 'Track & Trace actief';
const String trackingNotificationBody = 'GPS-locatie wordt vastgelegd.';
