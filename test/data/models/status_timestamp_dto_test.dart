import 'package:app/data/models/status_timestamp_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson/toJson round-trip preserves all fields', () {
    final json = <String, Object?>{'time': '2026-06-09T12:34:56.789', 'name': 'STANDING_STILL'};

    final dto = StatusTimestampDto.fromJson(json);
    expect(dto.time, json['time']);
    expect(dto.name, 'STANDING_STILL');
    expect(dto.toJson(), json);
  });
}
