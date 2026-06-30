class FeedbackDto(final String runId, final String time, final String? activity) {
  factory FeedbackDto.fromJson(Map<String, Object?> json) =>
      FeedbackDto(json['runId']! as String, json['time']! as String, json['name'] as String?);

  // The backend's `/create-feedback` contract names the activity field
  // `name` on the wire; the Dart field is `activity` for clarity.
  Map<String, Object?> toJson() => {'runId': runId, 'time': time, if (activity != null) 'name': activity};
}
