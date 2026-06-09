import 'package:app/domain/converters/status_timestamp_converter.dart';
import 'package:app/domain/entities/activity_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('DTO → entity decodes wire string into ActivityState', () {
    expect(statusTimestampDto(name: 'LOADING').toEntity().name, ActivityState.loading);
    expect(statusTimestampDto(name: 'DRIVING').toEntity().name, ActivityState.driving);
    expect(statusTimestampDto(name: 'DUMPING').toEntity().name, ActivityState.dumping);
    expect(statusTimestampDto(name: 'STANDING_STILL').toEntity().name, ActivityState.standingStill);
  });

  test('entity → DTO encodes ActivityState into wire string', () {
    final dto = statusTimestamp(name: ActivityState.standingStill).toDto();
    expect(dto.name, 'STANDING_STILL');
  });

  test('round-trip preserves equality', () {
    final original = statusTimestamp(name: ActivityState.driving);
    expect(original.toDto().toEntity(), original);
  });
}
