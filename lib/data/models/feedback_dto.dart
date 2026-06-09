class FeedbackDto(final String runId, final String time, final String? name) {
  factory FeedbackDto.fromJson(Map<String, Object?> json) =>
      FeedbackDto(json['runId']! as String, json['time']! as String, json['name'] as String?);

  Map<String, Object?> toJson() => {'runId': runId, 'time': time, if (name != null) 'name': name};
}
