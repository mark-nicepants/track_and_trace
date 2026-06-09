class NearestDepotDto(final String name) {
  factory NearestDepotDto.fromJson(Map<String, Object?> json) => NearestDepotDto(json['name']! as String);

  Map<String, Object?> toJson() => {'name': name};
}
