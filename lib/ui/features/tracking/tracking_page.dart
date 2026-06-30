import 'dart:async';

import 'package:app/domain/entities/activity_state.dart';
import 'package:app/shared/logarte.dart';
import 'package:app/ui/features/main/main_page.dart';
import 'package:app/ui/features/tracking/dump_size_dialog.dart';
import 'package:app/ui/features/tracking/dump_size_notifier.dart';
import 'package:app/ui/features/tracking/no_network_dialog.dart';
import 'package:app/ui/features/tracking/sending_providers.dart';
import 'package:app/ui/features/tracking/tracking_notifier.dart';
import 'package:app/ui/features/tracking/tracking_state.dart';
import 'package:app/ui/features/tracking/vehicle_settings_dialog.dart';
import 'package:app/ui/shared/error_messages.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Actions surfaced in the tracking screen's AppBar overflow (3-dot) menu.
enum _TrackingMenuAction { updateVehicle, openLogConsole }

/// The driver-facing tracking screen. Owns the entire run lifecycle via
/// [TrackingNotifier]: mounting kicks off `/create-run` + LocationService +
/// SendingService + PredictionService; the body renders the
/// predicted/feedback states, the 4-way activity grid, the nearest-depot
/// label (only while feedbackState=DRIVING), and the Stop button.
///
/// Back gesture is suppressed via `PopScope(canPop: false)`. While
/// mounted, the screen acquires the wakelock so the device doesn't sleep
/// mid-shift; the wakelock is released on dispose.
class TrackingPage extends HookConsumerWidget {
  const TrackingPage({super.key});

  static const String path = '/tracking';
  static const String name = 'tracking';

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const TrackingPage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingProvider);
    final notifier = ref.read(trackingProvider.notifier);

    // Wakelock acquire on mount / release on dispose. The notifier's own
    // start() is fired once on first build via the same effect.
    useEffect(() {
      WakelockPlus.enable();
      // Defer start() to after the first frame so the notifier's state
      // transitions don't fight Riverpod's mount cycle.
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(notifier.start()));
      return () => unawaited(WakelockPlus.disable());
    }, const []);

    // Auto-show / auto-dismiss the DumpSizeDialog (US-009). Mounting the
    // provider also wires its ref.listen on trackingProvider, so the
    // dump-size state machine reacts to DUMPING transitions without
    // anyone watching its value.
    final dumpSizeVisible = ref.watch(dumpSizeProvider);
    final dumpDialogOpen = useRef<bool>(false);
    if (dumpSizeVisible && !dumpDialogOpen.value) {
      dumpDialogOpen.value = true;
      final dumpNotifier = ref.read(dumpSizeProvider.notifier);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => DumpSizeDialog(
              onConfirm: (size) {
                dumpNotifier.confirm(size);
                Navigator.of(context, rootNavigator: true).pop();
              },
              onDismiss: () {
                dumpNotifier.dismiss();
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ).whenComplete(() => dumpDialogOpen.value = false),
        );
      });
    } else if (!dumpSizeVisible && dumpDialogOpen.value) {
      // Auto-confirm timer fired (or programmatic dismiss) while the
      // dialog is open — pop it.
      dumpDialogOpen.value = false;
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Auto-show / auto-dismiss the NoNetworkDialog (US-007).
    final dialogOpen = useRef<bool>(false);
    ref.listen<AsyncValue<bool>>(networkAvailableProvider, (_, next) {
      final online = next.value;
      if (online == null) return;
      if (!online && !dialogOpen.value) {
        dialogOpen.value = true;
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const NoNetworkDialog(),
          ).whenComplete(() => dialogOpen.value = false),
        );
      } else if (online && dialogOpen.value) {
        dialogOpen.value = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    // Surface a `/create-run` failure as a one-shot dialog with the HTTP
    // status code. Fires only on the null → non-null transition; the error
    // is cleared immediately so a retry can raise a fresh one.
    ref.listen<TrackingState>(trackingProvider, (prev, next) {
      final error = next.startError;
      if (error == null || prev?.startError != null) return;
      notifier.clearStartError();
      final statusCode = httpStatusCodeOf(error);
      final message = statusCode != null ? L10n.translate.errorCreateRunFailed(statusCode) : errorMessage(error);
      unawaited(
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            key: const Key('startRunErrorDialog'),
            content: Text(message),
            actions: [
              TextButton(
                key: const Key('startRunErrorDismiss'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(L10n.translate.commonOk),
              ),
            ],
          ),
        ),
      );
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(L10n.translate.trackingScreenTitle),
          actions: [
            PopupMenuButton<_TrackingMenuAction>(
              key: const Key('trackingOverflowMenu'),
              onSelected: (action) {
                switch (action) {
                  case _TrackingMenuAction.updateVehicle:
                    unawaited(_onUpdateVehicle(context, ref));
                  case _TrackingMenuAction.openLogConsole:
                    unawaited(_onOpenLogConsole(context));
                }
              },
              itemBuilder: (_) => [
                // PopupMenuItem<_TrackingMenuAction>(
                //   key: const Key('trackingMenuUpdateVehicle'),
                //   value: _TrackingMenuAction.updateVehicle,
                //   // Locked while a run is active: the active run already
                //   // captured its vehicle/capacity, so editing mid-run would
                //   // be misleading. The operator stops first, then edits.
                //   enabled: !tracking.isTracking,
                //   child: Text(L10n.translate.trackingMenuUpdateVehicle),
                // ),
                PopupMenuItem<_TrackingMenuAction>(
                  key: const Key('trackingMenuOpenLogs'),
                  value: _TrackingMenuAction.openLogConsole,
                  child: Text(L10n.translate.trackingMenuOpenLogs),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _settingsLabel(context, tracking),
                const SizedBox(height: 12),
                _statesView(context, tracking),
                const SizedBox(height: 16),
                _depotLabel(context, tracking),
                const SizedBox(height: 16),
                Expanded(child: _feedbackGrid(context, tracking, notifier)),
                const SizedBox(height: 16),
                _stopButton(context, tracking, notifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the in-place vehicle/capacity editor and refreshes the settings
  /// label if the operator saved a change.
  Future<void> _onUpdateVehicle(BuildContext context, WidgetRef ref) async {
    final changed = await showDialog<bool>(context: context, builder: (_) => const VehicleSettingsDialog());
    if (changed == true) {
      await ref.read(trackingProvider.notifier).refreshSettings();
    }
  }

  /// Opens Logarte's in-app debug console (log viewer + network inspector).
  Future<void> _onOpenLogConsole(BuildContext context) async {
    await logarte.openConsole(context);
    logarte.detachOverlay();
  }

  /// Current saved vehicle + capacity, shown beneath the AppBar so the
  /// operator can confirm what the next run will be tagged with.
  Widget _settingsLabel(BuildContext context, TrackingState tracking) {
    final vehicle = tracking.machineTypeName;
    final capacity = tracking.capacity;
    final text = (vehicle == null && capacity == null)
        ? L10n.translate.trackingVehicleNone
        : L10n.translate.trackingVehicleSummary(vehicle ?? '—', capacity == null ? '—' : _formatCapacity(capacity));
    return Text(
      text,
      key: const Key('trackingVehicleSummary'),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  Widget _statesView(BuildContext context, TrackingState tracking) {
    return Row(
      children: [
        Expanded(
          child: _stateBox(
            label: L10n.translate.trackingPrediction,
            value: _activityLabel(context, tracking.predictedState, fallback: L10n.translate.trackingNoActivity),
          ),
        ),
        const VerticalDivider(width: 1, color: Colors.black54),
        Expanded(
          child: _stateBox(
            label: L10n.translate.trackingFeedback,
            value: _activityLabel(context, tracking.feedbackState, fallback: L10n.translate.trackingFeedbackNoActivity),
          ),
        ),
      ],
    );
  }

  Widget _stateBox({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 22)),
      ],
    );
  }

  Widget _depotLabel(BuildContext context, TrackingState tracking) {
    if (tracking.nearestDepot == null) return const SizedBox.shrink();
    return Text(
      '${L10n.translate.trackingNearestDepotIs} ${tracking.nearestDepot!.name}',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
    );
  }

  Widget _feedbackGrid(BuildContext context, TrackingState tracking, TrackingNotifier notifier) {
    final activities = <(ActivityState, String)>[
      (ActivityState.driving, L10n.translate.trackingActivityDriving),
      (ActivityState.loading, L10n.translate.trackingActivityLoading),
      (ActivityState.dumping, L10n.translate.trackingActivityDumping),
      (ActivityState.standingStill, L10n.translate.trackingActivityStandingStill),
    ];
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final (state, label) = activities[index];
        // Match on the activity itself, not on a positional index: the grid's
        // order (driving, loading, …) differs from ActivityState's enum order
        // (loading, driving, …), so comparing indices highlighted the wrong
        // button.
        final selected = tracking.feedbackState == state;
        return OutlinedButton(
          key: Key('feedback_$index'),
          onPressed: tracking.isTracking ? () => notifier.selectFeedback(selected ? null : state) : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? Colors.grey : Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: selected ? Colors.white : Theme.of(context).colorScheme.onSecondaryContainer,
            side: const BorderSide(color: Colors.black, width: 2),
            shape: const RoundedRectangleBorder(),
          ),
          child: Text(label, style: const TextStyle(fontSize: 24)),
        );
      },
    );
  }

  Widget _stopButton(BuildContext context, TrackingState tracking, TrackingNotifier notifier) {
    // The button is the Start button until a run is active (and while it's
    // still spinning up); it becomes the Stop button once tracking begins.
    final isStartButton = !tracking.isTracking && !tracking.stopping;
    // A run transition is in flight: disable the button and show progress.
    final inProgress = tracking.starting || tracking.stopping;
    final labelKey = tracking.stopping
        ? L10n.translate.trackingStoppingRun
        : tracking.starting
        ? L10n.translate.trackingStartingRun
        : tracking.isTracking
        ? L10n.translate.trackingStop
        : L10n.translate.trackingStart;

    return FilledButton(
      key: Key(isStartButton ? 'startButton' : 'stopButton'),
      onPressed: inProgress
          ? null
          : tracking.isTracking
          ? () => unawaited(_confirmStop(context, notifier))
          : () => unawaited(notifier.start()),
      child: Text(labelKey, style: const TextStyle(fontSize: 22)),
    );
  }

  Future<void> _confirmStop(BuildContext context, TrackingNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('stopRunDialog'),
        title: Text(L10n.translate.trackingStopRunTitle),
        content: Text(L10n.translate.trackingStopRunBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(L10n.translate.trackingNo)),
          TextButton(
            key: const Key('stopRunConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(L10n.translate.trackingYes),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await notifier.stop();
    if (!context.mounted) return;
    MainPage.go(context);
  }

  String _activityLabel(BuildContext context, ActivityState? state, {required String fallback}) {
    return switch (state) {
      ActivityState.driving => L10n.translate.trackingActivityDriving,
      ActivityState.loading => L10n.translate.trackingActivityLoading,
      ActivityState.dumping => L10n.translate.trackingActivityDumping,
      ActivityState.standingStill => L10n.translate.trackingActivityStandingStill,
      null => fallback,
    };
  }
}

String _formatCapacity(num v) {
  if (v is int || v == v.truncate()) return v.toInt().toString();
  return v.toString();
}
