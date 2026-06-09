/// Body of the response from `POST /create-run`. The backend echoes back a
/// freshly-minted `runId` which the client retains for the lifetime of the
/// run.
class StartRunResponseDto(final String runId) {
  factory StartRunResponseDto.fromJson(Map<String, Object?> json) => StartRunResponseDto(json['runId']! as String);

  Map<String, Object?> toJson() => {'runId': runId};
}
