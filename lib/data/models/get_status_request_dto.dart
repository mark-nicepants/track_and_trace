/// Body of `POST /get-status`. `activity` is the wire form of
/// `ActivityState` (`LOADING` / `DRIVING` / `DUMPING` / `STANDING_STILL`).
class GetStatusRequestDto(final String runId, final String time, final String activity) {
  factory GetStatusRequestDto.fromJson(Map<String, Object?> json) =>
      GetStatusRequestDto(json['runId']! as String, json['time']! as String, json['activity']! as String);

  Map<String, Object?> toJson() => {'runId': runId, 'time': time, 'activity': activity};
}
