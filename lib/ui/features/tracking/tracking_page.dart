import 'dart:async';

import 'package:app/ui/features/tracking/tracking_notifier.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Tracking screen with start/stop control. The notifier owns the
/// LocationService side-effects; the widget never references tracelet or
/// flutter_foreground_task directly.
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
    return Scaffold(
      appBar: AppBar(title: Text(L10n.translate.appTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isTracking ? 'Tracking actief' : 'Tracking gestopt'),
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
