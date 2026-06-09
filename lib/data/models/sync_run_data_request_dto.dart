/// Body of `POST /sync-run-data`. `quantity` is the wire form of `DumpSize`
/// (`QUARTER` / `HALF` / `THREEQUARTER` / `FULL` / `UNSPECIFIED`).
class SyncRunDataRequestDto(final String runId, final String time, final String quantity) {
  factory SyncRunDataRequestDto.fromJson(Map<String, Object?> json) =>
      SyncRunDataRequestDto(json['runId']! as String, json['time']! as String, json['quantity']! as String);

  Map<String, Object?> toJson() => {'runId': runId, 'time': time, 'quantity': quantity};
}
