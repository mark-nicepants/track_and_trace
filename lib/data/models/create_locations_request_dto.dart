import 'package:app/data/models/tracking_position_dto.dart';

/// Body of `POST /create-locations`. Wraps a batch of tracked positions.
class CreateLocationsRequestDto(final List<TrackingPositionDto> locations) {
  factory CreateLocationsRequestDto.fromJson(Map<String, Object?> json) => CreateLocationsRequestDto(
    (json['locations']! as List<Object?>)
        .map((e) => TrackingPositionDto.fromJson(e! as Map<String, Object?>))
        .toList(growable: false),
  );

  Map<String, Object?> toJson() => {'locations': locations.map((e) => e.toJson()).toList(growable: false)};
}
