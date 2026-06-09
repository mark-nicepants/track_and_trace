import 'package:app/data/models/dump_size_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson/toJson round-trip preserves all fields', () {
    final json = <String, Object?>{'runId': 'run-1', 'time': '2026-06-09T12:34:56.789', 'quantity': 'HALF'};

    final dto = DumpSizeDto.fromJson(json);
    expect(dto.runId, 'run-1');
    expect(dto.time, json['time']);
    expect(dto.quantity, 'HALF');
    expect(dto.toJson(), json);
  });
}
