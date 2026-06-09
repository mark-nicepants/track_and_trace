import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/converters/machine_type_converter.dart';
import 'package:app/domain/entities/machine_type.dart';
import 'package:app/domain/use_cases/use_case.dart';
import 'package:app/shared/inject.dart';

/// Fetches the available machine types from the backend and maps DTOs to
/// domain entities. Wraps [TrackAndTraceRepository.getMachineTypes].
class GetMachineTypes extends UseCase<List<MachineType>> {
  TrackAndTraceRepository get _repo => inject();

  @override
  Future<List<MachineType>> execute() async {
    final dtos = await _repo.getMachineTypes();
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }
}
