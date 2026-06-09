import 'package:app/shared/config/app_env.dart';
import 'package:app/ui/features/dev/env_switcher_notifier.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:app/ui/shared/state/app_env_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EnvSwitcherPage extends HookConsumerWidget {
  const EnvSwitcherPage({super.key});

  static const String path = '/dev/env';
  static const String name = 'dev.env';

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const EnvSwitcherPage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(envSwitcherProvider);
    final active = ref.watch(appEnvProvider).name;

    return Scaffold(
      appBar: AppBar(title: Text(L10n.translate.envSwitcherTitle)),
      body: selected.when(
        data: (selectedName) => ListView(
          children: [
            ListTile(
              dense: true,
              title: Text(L10n.translate.envSwitcherActive(active)),
              subtitle: Text(L10n.translate.envSwitcherHint),
            ),
            const Divider(),
            for (final n in AppEnv.knownNames)
              ListTile(
                title: Text(n),
                trailing: n == selectedName ? const Icon(Icons.check) : null,
                onTap: () async {
                  if (n == selectedName) return;
                  await ref.read(envSwitcherProvider.notifier).select(n);
                  if (!context.mounted) return;
                  await _showRestartDialog(context, n);
                },
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showRestartDialog(BuildContext context, String name) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L10n.translate.envSwitcherRestartTitle),
        content: Text(L10n.translate.envSwitcherRestartBody(name)),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(L10n.translate.commonOk))],
      ),
    );
  }
}
