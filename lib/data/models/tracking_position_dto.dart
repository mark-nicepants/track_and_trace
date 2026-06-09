class TrackingPositionDto(final String time, final num lat, final num lon, final String? runId) {
  factory TrackingPositionDto.fromJson(Map<String, Object?> json) =>
      TrackingPositionDto(json['time']! as String, json['lat']! as num, json['lon']! as num, json['runId'] as String?);

  Map<String, Object?> toJson() => {'time': time, 'lat': lat, 'lon': lon, if (runId != null) 'runId': runId};
}
