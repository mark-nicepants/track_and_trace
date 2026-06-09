import 'package:app/data/models/status_timestamp_dto.dart';
import 'package:app/domain/entities/activity_state.dart';
import 'package:app/domain/entities/status_timestamp.dart';

extension StatusTimestampDtoX on StatusTimestampDto {
  StatusTimestamp toEntity() => StatusTimestamp(time, ActivityState.fromWire(name));
}

extension StatusTimestampX on StatusTimestamp {
  StatusTimestampDto toDto() => StatusTimestampDto(time, name.wireName);
}
