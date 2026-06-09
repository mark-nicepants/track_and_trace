import 'dart:async';

import 'package:app/ui/features/tracking/no_network_dialog.dart';
import 'package:app/ui/features/tracking/sending_providers.dart';
import 'package:app/ui/features/tracking/tracking_notifier.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Tracking screen with start/stop control. The notifier owns the
/// LocationService + SendingService side-effects; the widget never
/// references tracelet or flutter_foreground_task directly.
///
/// The screen also surfaces:
///   - the current queue depth (rows still buffered locally),
///   - a modal [NoNetworkDialog] when connectivity drops; auto-dismissed
///     on reconnect via [WidgetRef.listen] on [networkAvailableProvider].
class TrackingPage extends HookConsumerWidget {
  const TrackingPage({super.key});

  static const String path = '/tracking';
  static const String name = 'tracking';

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const TrackingPage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTracking = ref.watch(trackingProvider);
    final notifier = ref.read(trackingProvider.notifier);
    final network = ref.watch(networkAvailableProvider);
    final queueDepth = ref.watch(queueDepthProvider);

    // We hold a ref-cell so the dialog isn't shown twice if connectivity
    // flickers within a single frame, and so we can `pop` it on reconnect.
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

    return Scaffold(
      appBar: AppBar(title: Text(L10n.translate.appTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isTracking ? 'Tracking actief' : 'Tracking gestopt'),
            const SizedBox(height: 8),
            Text('Wachtrij: ${queueDepth.value ?? 0}'),
            const SizedBox(height: 8),
            Text(network.value == false ? 'Offline' : 'Online'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => unawaited(isTracking ? notifier.stop() : notifier.start()),
              child: Text(isTracking ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}
