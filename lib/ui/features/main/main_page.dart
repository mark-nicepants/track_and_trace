import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Launch entry. Renders a splash while `permissionsProvider` and
/// `setupSavedProvider` resolve; the redirect in `app_router.dart` then routes
/// to `/permissions`, `/setup`, or `/tracking`.
class MainPage extends HookConsumerWidget {
  const MainPage({super.key});

  static const String path = '/';
  static const String name = 'main';

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const MainPage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.translate.appTitle, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
