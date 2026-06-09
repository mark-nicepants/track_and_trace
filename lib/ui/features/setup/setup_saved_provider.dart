import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/inject.dart';
import 'package:app/ui/features/setup/setup_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves to `true` when both [machineTypeKey] and [machineCapacityKey] are
/// present in [IPreferenceService] — i.e. the user has completed the
/// SetupScreen at least once. The router redirect uses this to skip Setup on
/// subsequent launches.
final setupSavedProvider = FutureProvider<bool>((ref) async {
  final prefs = inject<IPreferenceService>();
  final type = await prefs.readString(machineTypeKey);
  final capacity = await prefs.readString(machineCapacityKey);
  return type != null && capacity != null;
});
