import 'package:app/data/models/run_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson/toJson round-trip with endTime', () {
    final json = <String, Object?>{
      'id': 'run-1',
      'startTime': '2026-06-09T12:00:00.000',
      'machineTypeId': 'mt-1',
      'capacity': 12.5,
      'endTime': '2026-06-09T13:00:00.000',
    };

    final dto = RunDto.fromJson(json);
    expect(dto.id, 'run-1');
    expect(dto.startTime, json['startTime']);
    expect(dto.machineTypeId, 'mt-1');
    expect(dto.capacity, 12.5);
    expect(dto.endTime, json['endTime']);
    expect(dto.toJson(), json);
  });

  test('toJson omits endTime when null', () {
    final dto = RunDto('run-1', '2026-06-09T12:00:00.000', 'mt-1', 5, null);
    expect(dto.toJson().containsKey('endTime'), isFalse);
  });
}
