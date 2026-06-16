import 'package:app/data/models/create_locations_request_dto.dart';
import 'package:app/data/models/tracking_position_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson strips trailing Z from location timestamps', () {
    final dto = CreateLocationsRequestDto([TrackingPositionDto('2026-06-16T10:07:06.205Z', 53.27, 6.68, 'run-1')]);

    final json = dto.toJson();
    final locations = json['locations']! as List<Object?>;
    final first = locations.first! as Map<String, Object?>;

    expect(first['time'], '2026-06-16T10:07:06.205');
  });

  test('toJson strips timezone offset from location timestamps', () {
    final dto = CreateLocationsRequestDto([TrackingPositionDto('2026-06-16T10:07:06.205+02:00', 53.27, 6.68, 'run-1')]);

    final json = dto.toJson();
    final locations = json['locations']! as List<Object?>;
    final first = locations.first! as Map<String, Object?>;

    expect(first['time'], '2026-06-16T10:07:06.205');
  });

  test('toJson leaves already-compatible timestamps unchanged', () {
    const compatible = '2026-06-16T10:07:06.205';
    final dto = CreateLocationsRequestDto([TrackingPositionDto(compatible, 53.27, 6.68, 'run-1')]);

    final json = dto.toJson();
    final locations = json['locations']! as List<Object?>;
    final first = locations.first! as Map<String, Object?>;

    expect(first['time'], compatible);
  });
}
