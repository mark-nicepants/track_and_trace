import 'package:equatable/equatable.dart';

/// A single tracked run: the work session between starting and stopping
/// tracking on a given machine.
///
/// `endTime` is null until the run is closed. `capacity` is the machine
/// capacity captured at start time (kept as `num` since the architecture
/// forbids `double`).
class Run(
  final String id,
  final String startTime,
  final String machineTypeId,
  final num capacity,
  final String? endTime,
) extends Equatable {
  Run copyWith({String? id, String? startTime, String? machineTypeId, num? capacity, String? endTime}) => Run(
    id ?? this.id,
    startTime ?? this.startTime,
    machineTypeId ?? this.machineTypeId,
    capacity ?? this.capacity,
    endTime ?? this.endTime,
  );

  @override
  List<Object?> get props => [id, startTime, machineTypeId, capacity, endTime];
}
