import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Placeholder for TrackingScreen. The redirect targets this route once
/// permissions are granted and vehicle setup has been persisted.
class TrackingPage extends HookConsumerWidget {
  const TrackingPage({super.key});

  static const String path = '/tracking';
  static const String name = 'tracking';

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const TrackingPage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.translate.appTitle)),
      body: const Center(child: Text('Tracking')),
    );
  }
}
