import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Placeholder for SetupScreen (US-004). The redirect targets this route once
/// permissions are granted but vehicle setup has not been persisted yet.
class SetupPage extends HookConsumerWidget {
  const SetupPage({super.key});

  static const String path = '/setup';
  static const String name = 'setup';

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const SetupPage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.translate.appTitle)),
      body: const Center(child: Text('Setup')),
    );
  }
}
