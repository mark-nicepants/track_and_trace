import 'package:app/domain/converters/tracking_position_converter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('DTO → entity copies all fields', () {
    final entity = trackingPositionDto(lat: 1.5, lon: 2.5, runId: 'r').toEntity();
    expect(entity.time, '2026-06-09T12:34:56.789');
    expect(entity.latitude, 1.5);
    expect(entity.longitude, 2.5);
    expect(entity.runId, 'r');
  });

  test('entity → DTO is the inverse', () {
    final original = trackingPosition(latitude: -3, longitude: -4, runId: null);
    final dto = original.toDto();
    expect(dto.lat, -3);
    expect(dto.lon, -4);
    expect(dto.runId, isNull);
    expect(dto.toEntity(), original);
  });
}
