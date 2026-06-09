import 'package:app/ui/features/setup_permissions/setup_permissions_notifier.dart';
import 'package:app/ui/shared/error_messages.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SetupPermissionsPage extends HookConsumerWidget {
  const SetupPermissionsPage({super.key});

  static const String path = '/setup-permissions';
  static const String name = 'setup_permissions';

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const SetupPermissionsPage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupPermissionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(L10n.translate.setupPermissionsTitle)),
      body: Center(
        child: state.when(
          data: (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  L10n.translate.setupPermissionsHeading,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(L10n.translate.setupPermissionsBody, textAlign: TextAlign.center),
              ],
            ),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text(errorMessage(e)),
        ),
      ),
    );
  }
}
