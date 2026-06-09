import 'package:app/data/models/user_dto.dart';
import 'package:app/domain/entities/user.dart';

extension UserDtoX on UserDto {
  User toEntity() => User(id, fullName, email);
}

extension UserX on User {
  UserDto toDto() => UserDto(id, name, email);
}
