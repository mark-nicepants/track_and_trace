class RunDto(
  final String id,
  final String startTime,
  final String machineTypeId,
  final double capacity,
  final String? endTime,
) {
  factory RunDto.fromJson(Map<String, Object?> json) => RunDto(
    json['id']! as String,
    json['startTime']! as String,
    json['machineTypeId']! as String,
    (json['capacity']! as num).toDouble(),
    json['endTime'] as String?,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'startTime': startTime,
    'machineTypeId': machineTypeId,
    'capacity': capacity,
    if (endTime != null) 'endTime': endTime,
  };
}
