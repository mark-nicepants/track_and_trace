import 'package:app/domain/converters/run_converter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('DTO → entity round-trips with endTime', () {
    final original = run(endTime: '2026-06-09T13:00:00.000');
    expect(original.toDto().toEntity(), original);
  });

  test('DTO → entity round-trips without endTime', () {
    final original = run();
    expect(original.toDto().toEntity(), original);
  });
}
