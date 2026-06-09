class UserDto(final String id, final String fullName, final String? email) {
  factory UserDto.fromJson(Map<String, Object?> json) =>
      UserDto(json['id']! as String, json['full_name']! as String, json['email'] as String?);

  Map<String, Object?> toJson() => {'id': id, 'full_name': fullName, if (email != null) 'email': email};
}
