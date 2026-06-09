/// Wire shape of a dump-size event: a run, a moment, and the quantity bucket
/// (`QUARTER` / `HALF` / `THREEQUARTER` / `FULL` / `UNSPECIFIED`).
class DumpSizeDto(final String runId, final String time, final String quantity) {
  factory DumpSizeDto.fromJson(Map<String, Object?> json) =>
      DumpSizeDto(json['runId']! as String, json['time']! as String, json['quantity']! as String);

  Map<String, Object?> toJson() => {'runId': runId, 'time': time, 'quantity': quantity};
}
