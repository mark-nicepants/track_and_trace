import 'dart:async';

import 'package:app/domain/entities/activity_state.dart';
import 'package:app/domain/entities/dump_size.dart';
import 'package:app/domain/use_cases/send_dump_size.dart';
import 'package:app/domain/use_cases/sync_run_data.dart';
import 'package:app/ui/features/tracking/tracking_notifier.dart';
import 'package:app/ui/features/tracking/tracking_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives the dump-size dialog lifecycle per FEATURES.md §5.4.
///
/// Triggered whenever the tracking activity (predicted OR feedback)
/// transitions into [ActivityState.dumping] while
/// `shownDumpsizeDialogThisDump=false`. On show:
///   - Flips [TrackingNotifier.markDumpDialogShown] so the guard prevents
///     a second show within the same DUMPING episode.
///   - Starts a 5-minute auto-confirm timer. If the timer fires before
///     the operator confirms, the dialog auto-confirms as
///     [DumpSize.full] (the safety-net measurement when the driver is
///     too busy to interact).
///   - On [confirm]/[dismiss] the timer is cancelled.
///
/// On [confirm], `/create-dump-size` and `/sync-run-data` fire **in
/// parallel** — both [UseCase.call] invocations happen synchronously,
/// neither awaits the other. The duplication is intentional per
/// FEATURES.md §5.4 (two independent backend records cross-validate the
/// measurement). Both are wrapped in `unawaited(... .catchError((_) {}))`
/// so network failures don't leak into the UI.
class DumpSizeNotifier extends Notifier<bool> {
  Timer? _autoConfirmTimer;
  String? _runId;

  /// Auto-confirm window (5 minutes in production per FEATURES.md §5.4).
  /// Shrunk in tests so fake_async can drive the timer cheaply.
  Duration autoConfirmAfter = const Duration(minutes: 5);

  @override
  bool build() {
    ref.onDispose(() {
      _autoConfirmTimer?.cancel();
      _autoConfirmTimer = null;
    });
    // `fireImmediately` is intentionally omitted — at mount time the
    // tracking notifier is always in `TrackingState.initial` (no runId,
    // not DUMPING), so there's nothing to react to. The first useful
    // event comes from the tracking notifier itself when activity flips
    // to DUMPING.
    ref.listen<TrackingState>(trackingProvider, _onTrackingChanged);
    return false;
  }

  void _onTrackingChanged(TrackingState? previous, TrackingState next) {
    if (state) return;
    if (next.shownDumpsizeDialogThisDump) return;
    final runId = next.runId;
    if (runId == null) return;
    final isDumping = next.predictedState == ActivityState.dumping || next.feedbackState == ActivityState.dumping;
    if (!isDumping) return;

    _show(runId);
  }

  void _show(String runId) {
    _runId = runId;
    ref.read(trackingProvider.notifier).markDumpDialogShown();
    state = true;
    _autoConfirmTimer?.cancel();
    _autoConfirmTimer = Timer(autoConfirmAfter, _onAutoConfirm);
  }

  void _onAutoConfirm() => confirm(DumpSize.full);

  /// User-confirm or auto-confirm path. Fires `/create-dump-size` and
  /// `/sync-run-data` in parallel and dismisses the dialog. No-op if the
  /// dialog isn't currently showing.
  void confirm(DumpSize size) {
    if (!state) return;
    final runId = _runId;
    _autoConfirmTimer?.cancel();
    _autoConfirmTimer = null;
    _runId = null;
    state = false;

    if (runId == null) return;

    // Both .call() invocations fire synchronously here — neither awaits
    // the other. FEATURES.md §5.4 demands the parallel double-write.
    unawaited(SendDumpSize(runId, size).call().catchError((_) {}));
    unawaited(SyncRunData(runId, size).call().catchError((_) {}));
  }

  /// Operator-dismiss path ("Afwijzen"). Cancels the timer and hides the
  /// dialog without firing any API calls. The
  /// `shownDumpsizeDialogThisDump` guard remains set so the dialog won't
  /// re-show until the next DUMPING episode.
  void dismiss() {
    if (!state) return;
    _autoConfirmTimer?.cancel();
    _autoConfirmTimer = null;
    _runId = null;
    state = false;
  }
}

final dumpSizeProvider = NotifierProvider<DumpSizeNotifier, bool>(DumpSizeNotifier.new);
