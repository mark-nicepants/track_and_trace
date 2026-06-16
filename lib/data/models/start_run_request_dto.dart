/// Body of `POST /create-run`.
class StartRunRequestDto(final String startTime, final String machineTypeId, final double capacity) {
  factory StartRunRequestDto.fromJson(Map<String, Object?> json) => StartRunRequestDto(
    json['startTime']! as String,
    json['machineTypeId']! as String,
    (json['capacity']! as num).toDouble(),
  );

  Map<String, Object?> toJson() => {'startTime': startTime, 'machineTypeId': machineTypeId, 'capacity': capacity};
}
