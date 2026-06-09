import 'package:app/data/repositories/user_repository.dart';
import 'package:app/domain/use_cases/get_current_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/di_test_helper.dart';
import '../../helpers/fixtures.dart';

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockUserRepository repo;

  setUp(() async {
    repo = _MockUserRepository();
    await setupTestDi(userRepository: repo);
  });

  tearDown(tearDownTestDi);

  test('returns the converted user entity', () async {
    when(repo.fetchMe).thenAnswer((_) async => userDto(id: 'abc', fullName: 'Alice', email: 'a@x'));

    final user = await GetCurrentUser().call();

    expect(user.id, 'abc');
    expect(user.name, 'Alice');
    expect(user.email, 'a@x');
  });

  test('propagates exceptions from the repository', () async {
    when(repo.fetchMe).thenThrow(Exception('boom'));

    expect(GetCurrentUser().call(), throwsException);
  });
}
