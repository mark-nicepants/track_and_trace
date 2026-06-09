import 'package:app/data/models/run_dto.dart';
import 'package:app/domain/entities/run.dart';

extension RunDtoX on RunDto {
  Run toEntity() => Run(id, startTime, machineTypeId, capacity, endTime);
}

extension RunX on Run {
  RunDto toDto() => RunDto(id, startTime, machineTypeId, capacity, endTime);
}
