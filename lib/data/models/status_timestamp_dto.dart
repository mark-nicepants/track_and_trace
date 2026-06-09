class StatusTimestampDto(final String time, final String name) {
  factory StatusTimestampDto.fromJson(Map<String, Object?> json) =>
      StatusTimestampDto(json['time']! as String, json['name']! as String);

  Map<String, Object?> toJson() => {'time': time, 'name': name};
}
