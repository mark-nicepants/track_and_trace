import 'dart:async';

import 'package:app/domain/entities/machine_type.dart';
import 'package:app/ui/features/setup/setup_notifier.dart';
import 'package:app/ui/features/setup/setup_state.dart';
import 'package:app/ui/features/tracking/tracking_page.dart';
import 'package:app/ui/shared/error_messages.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SetupPage extends HookConsumerWidget {
  const SetupPage({super.key});

  static const String path = '/setup';
  static const String name = 'setup';
  static const double maxCapacityM3 = 50;

  static GoRoute route() => GoRoute(path: path, name: name, builder: (context, state) => const SetupPage());

  static void go(BuildContext context) => context.goNamed(name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(setupProvider);
    final notifier = ref.read(setupProvider.notifier);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final capacityController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text(L10n.translate.appTitle)),
      body: SafeArea(
        child: asyncState.when(
          loading: () => _LoadingView(message: L10n.translate.setupLoadingMachineTypes),
          error: (e, _) => Center(child: Text(errorMessage(e))),
          data: (state) =>
              _LoadedView(state: state, notifier: notifier, formKey: formKey, capacityController: capacityController),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(message)],
      ),
    );
  }
}

class _LoadedView extends HookConsumerWidget {
  const _LoadedView({
    required this.state,
    required this.notifier,
    required this.formKey,
    required this.capacityController,
  });

  final SetupState state;
  final SetupNotifier notifier;
  final GlobalKey<FormState> formKey;
  final TextEditingController capacityController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      final initial = state.capacity;
      if (initial != null && capacityController.text.isEmpty) {
        capacityController.text = _formatCapacity(initial);
      }
      return null;
      // Run once for the first build with data.
    }, const []);

    Future<void> onStart() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (state.selectedType == null) return;
      final saved = await notifier.confirm();
      if (saved && context.mounted) {
        TrackingPage.go(context);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.fromCache)
              Padding(
                key: const ValueKey('setup.offlineBanner'),
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off_outlined),
                        const SizedBox(width: 12),
                        Expanded(child: Text(L10n.translate.setupOfflineBanner)),
                      ],
                    ),
                  ),
                ),
              ),
            DropdownButtonFormField<MachineType>(
              key: const ValueKey('setup.machineTypeDropdown'),
              initialValue: state.selectedType,
              decoration: InputDecoration(
                labelText: L10n.translate.setupMachineTypeLabel,
                hintText: L10n.translate.setupMachineTypeHint,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final type in state.machineTypes)
                  DropdownMenuItem<MachineType>(value: type, child: Text(type.displayName)),
              ],
              onChanged: (value) {
                if (value != null) notifier.selectType(value);
              },
              validator: (value) => value == null ? L10n.translate.setupMachineTypeHint : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('setup.capacityField'),
              controller: capacityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: L10n.translate.setupCapacityLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                notifier.setCapacity(parsed);
              },
              validator: (value) {
                final raw = (value ?? '').replaceAll(',', '.').trim();
                final parsed = double.tryParse(raw);
                if (parsed == null || parsed <= 0) return L10n.translate.setupCapacityInvalid;
                if (parsed > SetupPage.maxCapacityM3) return L10n.translate.setupCapacityTooLarge;
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              key: const ValueKey('setup.startButton'),
              onPressed: state.saving ? null : () => unawaited(onStart()),
              child: Text(L10n.translate.setupStart),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCapacity(double v) {
  if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
  return v.toString();
}
