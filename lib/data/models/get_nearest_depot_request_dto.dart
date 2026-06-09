/// Body of `POST /get-nearest-depot`.
class GetNearestDepotRequestDto(final String runId, final String time) {
  factory GetNearestDepotRequestDto.fromJson(Map<String, Object?> json) =>
      GetNearestDepotRequestDto(json['runId']! as String, json['time']! as String);

  Map<String, Object?> toJson() => {'runId': runId, 'time': time};
}
