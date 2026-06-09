import 'package:app/domain/converters/feedback_converter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('DTO → entity round-trips with name', () {
    final original = feedback();
    expect(original.toDto().toEntity(), original);
  });

  test('DTO → entity round-trips with null name', () {
    final original = feedback(name: null);
    expect(original.toDto().toEntity(), original);
  });
}
