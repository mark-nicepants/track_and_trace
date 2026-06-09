import 'package:app/shared/contracts/i_crash_report_service.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/inject.dart';
import 'package:app/ui/features/crash/crash_detected_provider.dart';
import 'package:app/ui/features/crash/crash_state.dart';
import 'package:app/ui/features/tracking/tracking_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives the crash-report dialog. Owns the state machine
/// `choice → busy → success/failed`, calling [ICrashReportService] to
/// zip + POST the rotating logs. Once the flow terminates (either branch),
/// flips `EXITED_CORRECTLY=true` so a subsequent dismiss + relaunch doesn't
/// re-show the dialog.
class CrashNotifier extends Notifier<CrashState> {
  ICrashReportService get _service => inject();
  IPreferenceService get _prefs => inject();

  @override
  CrashState build() => CrashState.initial;

  /// Kicks off the upload. Transitions through [CrashReportStatus.busy]
  /// with the Dutch progress labels and ends in
  /// [CrashReportStatus.success] / [CrashReportStatus.failed].
  Future<void> sendReport({
    required String gettingLogFilesLabel,
    required String zippingLabel,
    required String sendingLabel,
  }) async {
    state = state.copyWith(status: CrashReportStatus.busy, busyLabel: gettingLogFilesLabel);
    state = state.copyWith(busyLabel: zippingLabel);
    state = state.copyWith(busyLabel: sendingLabel);
    final ok = await _service.uploadLogs();
    state = state.copyWith(status: ok ? CrashReportStatus.success : CrashReportStatus.failed, clearBusyLabel: true);
    await _markHandled();
  }

  /// User declined to upload. Flip the flag back to `true` so the dialog
  /// doesn't re-appear on next launch.
  Future<void> decline() async {
    await _markHandled();
  }

  /// Reset to [CrashReportStatus.choice] — used by the "Opnieuw" retry
  /// button on the failed view.
  void retry() {
    state = CrashState.initial;
  }

  Future<void> _markHandled() async {
    await _prefs.writeString(exitedCorrectlyKey, 'true');
    ref.invalidate(crashDetectedAtLaunchProvider);
  }
}

final crashProvider = NotifierProvider<CrashNotifier, CrashState>(CrashNotifier.new);
