import 'package:app/domain/entities/machine_type.dart';
import 'package:equatable/equatable.dart';

/// State of [SetupNotifier]: the list of machine types available to choose
/// from, whether that list came from the offline cache (so the UI can show
/// a banner), and the user's current selection.
class SetupState(
  final List<MachineType> machineTypes,
  final bool fromCache,
  final MachineType? selectedType,
  final double? capacity,
  final bool saving,
) extends Equatable {
  static final SetupState initial = SetupState(const [], false, null, null, false);

  SetupState copyWith({
    List<MachineType>? machineTypes,
    bool? fromCache,
    MachineType? selectedType,
    double? capacity,
    bool? saving,
  }) => SetupState(
    machineTypes ?? this.machineTypes,
    fromCache ?? this.fromCache,
    selectedType ?? this.selectedType,
    capacity ?? this.capacity,
    saving ?? this.saving,
  );

  @override
  List<Object?> get props => [machineTypes, fromCache, selectedType, capacity, saving];
}
