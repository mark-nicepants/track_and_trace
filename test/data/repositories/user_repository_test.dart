import 'package:app/data/repositories/user_repository.dart';
import 'package:app/shared/inject.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/di_test_helper.dart';

void main() {
  setUp(setupTestDi);
  tearDown(tearDownTestDi);

  test('fetchMe returns the placeholder UserDto', () async {
    final dto = await inject<UserRepository>().fetchMe();

    expect(dto.id, 'user-1');
    expect(dto.fullName, 'Template User');
    expect(dto.email, 'user@example.com');
  });
}
