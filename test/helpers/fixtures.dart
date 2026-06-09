import 'package:app/data/models/user_dto.dart';
import 'package:app/domain/entities/user.dart';

UserDto userDto({String id = 'user-1', String fullName = 'Test User', String? email = 'test@example.com'}) =>
    UserDto(id, fullName, email);

User user({String id = 'user-1', String name = 'Test User', String? email = 'test@example.com'}) =>
    User(id, name, email);
