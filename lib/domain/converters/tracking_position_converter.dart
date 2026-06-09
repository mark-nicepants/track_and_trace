import 'package:app/data/models/tracking_position_dto.dart';
import 'package:app/domain/entities/tracking_position.dart';

extension TrackingPositionDtoX on TrackingPositionDto {
  TrackingPosition toEntity() => TrackingPosition(time, lat, lon, runId);
}

extension TrackingPositionX on TrackingPosition {
  TrackingPositionDto toDto() => TrackingPositionDto(time, latitude, longitude, runId);
}
