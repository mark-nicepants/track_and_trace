import 'package:app/ui/features/setup_permissions/setup_permissions_page.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  static const String path = '/';
  static const String name = 'home';

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const HomePage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.translate.appTitle)),
      body: const SizedBox.shrink(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => SetupPermissionsPage.go(context),
        tooltip: L10n.translate.setupPermissionsTitle,
        child: const Icon(Icons.location_on_outlined),
      ),
    );
  }
}
