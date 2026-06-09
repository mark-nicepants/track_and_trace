/// Body of the response from `POST /get-status`. `activity` is the wire
/// form of `ActivityState` (`LOADING` / `DRIVING` / `DUMPING` /
/// `STANDING_STILL`). `time` is the ISO timestamp the backend stamped the
/// prediction with.
class GetStatusResponseDto(final String activity, final String time) {
  factory GetStatusResponseDto.fromJson(Map<String, Object?> json) =>
      GetStatusResponseDto(json['activity']! as String, json['time']! as String);

  Map<String, Object?> toJson() => {'activity': activity, 'time': time};
}
