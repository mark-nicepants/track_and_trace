/// Source of "now" formatted as the ISO timestamps the API expects.
///
/// Registered as a singleton in GetIt so tests can swap in a deterministic
/// clock without monkey-patching `DateTime.now()`.
///
/// Format: `yyyy-MM-dd'T'HH:mm:ss.SSS` (milliseconds, no timezone suffix).
class IsoClock {
  const IsoClock();

  DateTime now() => DateTime.now();

  String nowIso() => format(now());

  /// Formats a [DateTime] as `yyyy-MM-dd'T'HH:mm:ss.SSS`.
  String format(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final millis = dt.millisecond.toString().padLeft(3, '0');
    return '$year-$month-${day}T$hour:$minute:$second.$millis';
  }
}
