class TrackingPositionDto(final String time, final double lat, final double lon, final String? runId) {
  factory TrackingPositionDto.fromJson(Map<String, Object?> json) => TrackingPositionDto(
    json['time']! as String,
    json['lat']! as double,
    json['lon']! as double,
    json['runId'] as String?,
  );

  Map<String, Object?> toJson() => {'time': time, 'lat': lat, 'lon': lon, if (runId != null) 'runId': runId};
}
