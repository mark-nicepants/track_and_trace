class MachineTypeDto(final String id, final String displayName) {
  factory MachineTypeDto.fromJson(Map<String, Object?> json) =>
      MachineTypeDto(json['id']! as String, json['displayName']! as String);

  Map<String, Object?> toJson() => {'id': id, 'displayName': displayName};
}
