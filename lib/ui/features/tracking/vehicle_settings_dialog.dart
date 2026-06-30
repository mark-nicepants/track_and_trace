import 'dart:async';

import 'package:app/domain/entities/machine_type.dart';
import 'package:app/ui/features/setup/setup_notifier.dart';
import 'package:app/ui/features/setup/setup_page.dart';
import 'package:app/ui/features/setup/setup_state.dart';
import 'package:app/ui/shared/error_messages.dart';
import 'package:app/ui/shared/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// In-place editor for the operator's saved vehicle (machine type) and
/// capacity, opened from the tracking screen's overflow menu.
///
/// Reuses [setupProvider] so the machine-type list (with offline-cache
/// fallback), validation rules, and persistence keys are identical to the
/// first-run setup screen — there's a single source of truth for "load
/// types + persist selection".
///
/// Pops `true` once the new values are written to prefs (the caller then
/// refreshes the tracking label). Cancel pops with no result. Changes apply
/// to the next run; the currently-active run keeps the values it started
/// with.
class VehicleSettingsDialog extends HookConsumerWidget {
  const VehicleSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(setupProvider);
    final notifier = ref.read(setupProvider.notifier);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final capacityController = useTextEditingController();
    final saving = useState(false);

    Future<void> onSave() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (asyncState.value?.selectedType == null) return;
      saving.value = true;
      final saved = await notifier.confirm();
      if (!context.mounted) return;
      if (saved) {
        Navigator.of(context).pop(true);
      } else {
        saving.value = false;
      }
    }

    return AlertDialog(
      key: const Key('vehicleSettingsDialog'),
      title: Text(L10n.translate.trackingSettingsTitle),
      content: asyncState.when(
        loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
        error: (error, _) => Text(errorMessage(error)),
        data: (state) =>
            _VehicleForm(state: state, notifier: notifier, formKey: formKey, capacityController: capacityController),
      ),
      actions: [
        TextButton(
          key: const Key('vehicleSettingsCancel'),
          onPressed: saving.value ? null : () => Navigator.of(context).pop(),
          child: Text(L10n.translate.commonCancel),
        ),
        FilledButton(
          key: const Key('vehicleSettingsSave'),
          onPressed: (saving.value || asyncState.value == null) ? null : () => unawaited(onSave()),
          child: Text(L10n.translate.trackingSettingsSave),
        ),
      ],
    );
  }
}

class _VehicleForm extends HookConsumerWidget {
  const _VehicleForm({
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
      // Prefill once on the first build that carries data.
    }, const []);

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<MachineType>(
            key: const ValueKey('vehicleSettings.machineTypeDropdown'),
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
            key: const ValueKey('vehicleSettings.capacityField'),
            controller: capacityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: L10n.translate.setupCapacityLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              final parsed = num.tryParse(value.replaceAll(',', '.'));
              notifier.setCapacity(parsed);
            },
            validator: (value) {
              final raw = (value ?? '').replaceAll(',', '.').trim();
              final parsed = num.tryParse(raw);
              if (parsed == null || parsed <= 0) return L10n.translate.setupCapacityInvalid;
              if (parsed > SetupPage.maxCapacityM3) return L10n.translate.setupCapacityTooLarge;
              return null;
            },
          ),
        ],
      ),
    );
  }
}

String _formatCapacity(num v) {
  if (v is int || v == v.truncate()) return v.toInt().toString();
  return v.toString();
}
