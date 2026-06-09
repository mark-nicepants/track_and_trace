import 'package:app/data/models/machine_type_dto.dart';
import 'package:app/domain/entities/machine_type.dart';

extension MachineTypeDtoX on MachineTypeDto {
  MachineType toEntity() => MachineType(id, displayName);
}

extension MachineTypeX on MachineType {
  MachineTypeDto toDto() => MachineTypeDto(id, displayName);
}
