import 'package:app/data/models/tracking_position_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson/toJson round-trip preserves all fields', () {
    final json = <String, Object?>{'time': '2026-06-09T12:34:56.789', 'lat': 52.37, 'lon': 4.89, 'runId': 'run-1'};

    final dto = TrackingPositionDto.fromJson(json);
    expect(dto.time, json['time']);
    expect(dto.lat, json['lat']);
    expect(dto.lon, json['lon']);
    expect(dto.runId, json['runId']);

    expect(dto.toJson(), json);
  });

  test('toJson omits runId when null', () {
    final dto = TrackingPositionDto('2026-06-09T00:00:00.000', 0, 0, null);
    expect(dto.toJson().containsKey('runId'), isFalse);
  });
}
