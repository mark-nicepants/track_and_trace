import 'package:equatable/equatable.dart';

/// Stage of the crash-report upload flow. Matches the four discrete
/// states from the Android `CrashScreenViewModel` (FEATURES.md §8.3):
///   - [choice]   — initial state; user hasn't decided yet.
///   - [busy]     — upload in flight.
///   - [success]  — upload finished successfully.
///   - [failed]   — upload errored; retry available.
enum CrashReportStatus { choice, busy, success, failed }

/// Snapshot of the [CrashReportStatus] state machine plus the most-recent
/// progress label rendered while [CrashReportStatus.busy].
class CrashState(final CrashReportStatus status, final String? busyLabel) extends Equatable {
  static final CrashState initial = CrashState(CrashReportStatus.choice, null);

  CrashState copyWith({CrashReportStatus? status, String? busyLabel, bool clearBusyLabel = false}) =>
      CrashState(status ?? this.status, clearBusyLabel ? null : (busyLabel ?? this.busyLabel));

  @override
  List<Object?> get props => [status, busyLabel];
}
