import 'dart:convert';

import 'package:app/domain/entities/machine_type.dart';
import 'package:app/domain/use_cases/get_machine_types.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/inject.dart';
import 'package:app/ui/features/setup/setup_keys.dart';
import 'package:app/ui/features/setup/setup_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads machine types (with offline-cache fallback), tracks the user's
/// selection + capacity, and persists the choice to [IPreferenceService].
class SetupNotifier extends AsyncNotifier<SetupState> {
  IPreferenceService get _prefs => inject();
  GetMachineTypes _getMachineTypes() => GetMachineTypes();

  @override
  Future<SetupState> build() async {
    final cached = await _readCache();
    final saved = await _readSaved();
    try {
      final fresh = await _getMachineTypes().call();
      await _writeCache(fresh);
      return SetupState(fresh, false, _matchSavedType(fresh, saved.$1), saved.$2, false);
    } catch (_) {
      return SetupState(cached, cached.isNotEmpty, _matchSavedType(cached, saved.$1), saved.$2, false);
    }
  }

  void selectType(MachineType type) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedType: type));
  }

  void setCapacity(double? capacity) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(capacity: capacity));
  }

  /// Persists `selectedType` (as JSON) and `capacity` (as a double string) to
  /// [IPreferenceService]. Returns `true` when both values were present and
  /// successfully written.
  Future<bool> confirm() async {
    final current = state.value;
    if (current == null) return false;
    final type = current.selectedType;
    final capacity = current.capacity;
    if (type == null || capacity == null) return false;

    state = AsyncData(current.copyWith(saving: true));
    await _prefs.writeString(machineTypeKey, jsonEncode(_typeToJson(type)));
    await _prefs.writeString(machineCapacityKey, capacity.toString());
    state = AsyncData(current.copyWith(saving: false));
    return true;
  }

  Future<List<MachineType>> _readCache() async {
    final raw = await _prefs.readString(machineTypesCacheKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<Object?>;
      return decoded.map((e) => _typeFromJson(e! as Map<String, Object?>)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeCache(List<MachineType> types) async {
    final json = jsonEncode(types.map(_typeToJson).toList(growable: false));
    await _prefs.writeString(machineTypesCacheKey, json);
  }

  Future<(MachineType?, double?)> _readSaved() async {
    MachineType? type;
    double? capacity;
    final typeRaw = await _prefs.readString(machineTypeKey);
    if (typeRaw != null && typeRaw.isNotEmpty) {
      try {
        type = _typeFromJson(jsonDecode(typeRaw) as Map<String, Object?>);
      } catch (_) {
        type = null;
      }
    }
    final capacityRaw = await _prefs.readString(machineCapacityKey);
    if (capacityRaw != null && capacityRaw.isNotEmpty) {
      capacity = double.tryParse(capacityRaw);
    }
    return (type, capacity);
  }

  MachineType? _matchSavedType(List<MachineType> available, MachineType? saved) {
    if (saved == null) return null;
    for (final t in available) {
      if (t.id == saved.id) return t;
    }
    return saved;
  }

  Map<String, Object?> _typeToJson(MachineType t) => {'id': t.id, 'displayName': t.displayName};

  MachineType _typeFromJson(Map<String, Object?> j) => MachineType(j['id']! as String, j['displayName']! as String);
}

final setupProvider = AsyncNotifierProvider<SetupNotifier, SetupState>(SetupNotifier.new);
