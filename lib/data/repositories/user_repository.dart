import 'package:app/data/http/guard_dio.dart';
import 'package:app/data/models/user_dto.dart';
import 'package:app/shared/inject.dart';
import 'package:dio/dio.dart';

class UserRepository {
  // ignore: unused_element
  Dio get _dio => inject();

  /// Placeholder implementation so the template runs without a backend.
  /// Swap to the real version (commented below) when wiring an API.
  Future<UserDto> fetchMe() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return UserDto('user-1', 'Template User', 'user@example.com');
  }

  /// Reference shape for a real implementation:
  Future<UserDto> fetchMeReal() => guardDio(() async {
    final r = await _dio.get<Map<String, Object?>>('/me');
    return UserDto.fromJson(r.data!);
  });
}
