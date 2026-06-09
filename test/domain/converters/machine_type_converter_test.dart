import 'package:app/domain/converters/machine_type_converter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('DTO → entity round-trips', () {
    final original = machineType(id: 'a', displayName: 'b');
    expect(original.toDto().toEntity(), original);
  });
}
