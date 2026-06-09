/// Body of `POST /stop-run`.
class StopRunRequestDto(final String runId, final String endTime) {
  factory StopRunRequestDto.fromJson(Map<String, Object?> json) =>
      StopRunRequestDto(json['runId']! as String, json['endTime']! as String);

  Map<String, Object?> toJson() => {'runId': runId, 'endTime': endTime};
}
