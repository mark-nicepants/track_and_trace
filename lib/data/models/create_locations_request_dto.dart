import 'package:app/data/models/tracking_position_dto.dart';

/// Body of `POST /create-locations`. Wraps a batch of tracked positions.
class CreateLocationsRequestDto(final List<TrackingPositionDto> locations) {
  factory CreateLocationsRequestDto.fromJson(Map<String, Object?> json) => CreateLocationsRequestDto(
    (json['locations']! as List<Object?>)
        .map((e) => TrackingPositionDto.fromJson(e! as Map<String, Object?>))
        .toList(growable: false),
  );

  Map<String, Object?> toJson() => {
    'locations': [for (final location in locations) _locationToJson(location)],
  };

  Map<String, Object?> _locationToJson(TrackingPositionDto location) => {
    'time': _stripTimezoneSuffix(location.time),
    'lat': location.lat,
    'lon': location.lon,
    if (location.runId != null) 'runId': location.runId,
  };

  /// API accepts `yyyy-MM-ddTHH:mm:ss.SSS` and rejects timezone suffixes
  /// such as `Z` and `+02:00`.
  String _stripTimezoneSuffix(String value) {
    final match = RegExp(
      r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,6})?)(?:Z|[+-]\d{2}:\d{2})$',
    ).firstMatch(value);
    if (match != null) return match.group(1)!;
    return value;
  }
}
