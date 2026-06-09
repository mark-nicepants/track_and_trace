import 'package:app/shared/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const clock = IsoClock();

  test('formats a DateTime with millisecond precision and no timezone', () {
    expect(clock.format(DateTime(2026, 6, 9, 12, 34, 56, 789)), '2026-06-09T12:34:56.789');
  });

  test('zero-pads every field', () {
    expect(clock.format(DateTime(7, 1, 2, 3, 4, 5, 6)), '0007-01-02T03:04:05.006');
  });

  test('nowIso returns a string in the expected format', () {
    expect(clock.nowIso(), matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}$')));
  });
}
