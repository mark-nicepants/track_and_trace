import 'dart:async';

import 'package:app/domain/entities/activity_state.dart';
import 'package:app/ui/features/main/main_page.dart';
import 'package:app/ui/features/tracking/dump_size_dialog.dart';
import 'package:app/ui/features/tracking/dump_size_notifier.dart';
import 'package:app/ui/features/tracking/no_network_dialog.dart';
import 'package:app/ui/features/tracking/sending_providers.dart';
import 'package:app/ui/features/tracking/tracking_notifier.dart';
import 'package:app/ui/features/tracking/tracking_state.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
    final l = L10n.translate;

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

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: Text(l.trackingScreenTitle)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

  Widget _statesView(BuildContext context, TrackingState tracking) {
    final l = L10n.translate;
    return Row(
      children: [
        Expanded(
          child: _stateBox(
            label: l.trackingPrediction,
            value: _activityLabel(context, tracking.predictedState, fallback: l.trackingNoActivity),
          ),
        ),
        const VerticalDivider(width: 1, color: Colors.black54),
        Expanded(
          child: _stateBox(
            label: l.trackingFeedback,
            value: _activityLabel(context, tracking.feedbackState, fallback: l.trackingFeedbackNoActivity),
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
    final l = L10n.translate;
    return Text(
      '${l.trackingNearestDepotIs} ${tracking.nearestDepot!.name}',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
    );
  }

  Widget _feedbackGrid(BuildContext context, TrackingState tracking, TrackingNotifier notifier) {
    final l = L10n.translate;
    final activities = <(ActivityState, String)>[
      (ActivityState.driving, l.trackingActivityDriving),
      (ActivityState.loading, l.trackingActivityLoading),
      (ActivityState.dumping, l.trackingActivityDumping),
      (ActivityState.standingStill, l.trackingActivityStandingStill),
    ];
    final selectedIndex = tracking.selectedFeedbackIndex;
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
        final selected = selectedIndex == index;
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
    final l = L10n.translate;
    return FilledButton(
      key: const Key('stopButton'),
      onPressed: tracking.stopping ? null : () => unawaited(_confirmStop(context, notifier)),
      child: Text(tracking.stopping ? l.trackingStoppingRun : l.trackingStop, style: const TextStyle(fontSize: 22)),
    );
  }

  Future<void> _confirmStop(BuildContext context, TrackingNotifier notifier) async {
    final l = L10n.translate;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('stopRunDialog'),
        title: Text(l.trackingStopRunTitle),
        content: Text(l.trackingStopRunBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l.trackingNo)),
          TextButton(
            key: const Key('stopRunConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.trackingYes),
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
    final l = L10n.translate;
    return switch (state) {
      ActivityState.driving => l.trackingActivityDriving,
      ActivityState.loading => l.trackingActivityLoading,
      ActivityState.dumping => l.trackingActivityDumping,
      ActivityState.standingStill => l.trackingActivityStandingStill,
      null => fallback,
    };
  }
}
