import 'dart:async';

import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:app/ui/features/main/main_page.dart';
import 'package:app/ui/features/setup_permissions/permissions_notifier.dart';
import 'package:app/ui/features/setup_permissions/permissions_state.dart';
import 'package:app/ui/shared/error_messages.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SetupPermissionsPage extends HookConsumerWidget {
  const SetupPermissionsPage({super.key});

  static const String path = '/permissions';
  static const String name = 'permissions';

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const SetupPermissionsPage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(permissionsProvider);
    final notifier = ref.read(permissionsProvider.notifier);

    ref.listen<AsyncValue<PermissionsState>>(permissionsProvider, (_, next) {
      final value = next.value;
      if (value != null && value.allGranted && context.mounted) {
        context.go(MainPage.path);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(L10n.translate.permissionsTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: asyncState.when(
            data: (state) => _stepView(context, state, notifier),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(errorMessage(e))),
          ),
        ),
      ),
    );
  }

  Widget _stepView(BuildContext context, PermissionsState state, PermissionsNotifier notifier) {
    if (state.locationWhenInUse != PermissionState.granted) {
      return _viewFor(
        stepKey: 'locationWhenInUse',
        status: state.locationWhenInUse,
        rationale: L10n.translate.permissionsLocationRationale,
        onAccept: notifier.requestLocationWhenInUse,
        onOpenSettings: notifier.openSettings,
      );
    }
    if (state.locationAlways != PermissionState.granted) {
      return _viewFor(
        stepKey: 'locationAlways',
        status: state.locationAlways,
        rationale: L10n.translate.permissionsLocationRationale,
        onAccept: notifier.requestLocationAlways,
        onOpenSettings: notifier.openSettings,
      );
    }
    if (state.notification != PermissionState.granted) {
      return _viewFor(
        stepKey: 'notification',
        status: state.notification,
        rationale: L10n.translate.permissionsNotificationRationale,
        onAccept: notifier.requestNotification,
        onOpenSettings: notifier.openSettings,
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _viewFor({
    required String stepKey,
    required PermissionState status,
    required String rationale,
    required Future<void> Function() onAccept,
    required Future<bool> Function() onOpenSettings,
  }) {
    if (status == PermissionState.permanentlyDenied) {
      return _PermanentlyDeniedView(key: ValueKey('$stepKey.permanent'), onOpenSettings: onOpenSettings);
    }
    return _RationaleView(key: ValueKey('$stepKey.rationale'), rationale: rationale, onAccept: onAccept);
  }
}

class _RationaleView extends StatelessWidget {
  const _RationaleView({super.key, required this.rationale, required this.onAccept});

  final String rationale;
  final Future<void> Function() onAccept;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 48),
        const SizedBox(height: 24),
        Text(rationale, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: () => unawaited(onAccept()), child: Text(L10n.translate.permissionsAccept)),
      ],
    );
  }
}

class _PermanentlyDeniedView extends StatelessWidget {
  const _PermanentlyDeniedView({super.key, required this.onOpenSettings});

  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.report_outlined, size: 48),
        const SizedBox(height: 24),
        Text(
          L10n.translate.permissionsPermanentlyDeniedBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => unawaited(onOpenSettings()),
          child: Text(L10n.translate.permissionsOpenSettings),
        ),
      ],
    );
  }
}
