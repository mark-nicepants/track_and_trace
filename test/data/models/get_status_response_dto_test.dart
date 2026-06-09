import 'package:app/data/models/get_status_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson/toJson round-trip preserves activity + time', () {
    final json = <String, Object?>{'activity': 'DUMPING', 'time': '2026-06-09T12:34:56.789'};

    final dto = GetStatusResponseDto.fromJson(json);
    expect(dto.activity, 'DUMPING');
    expect(dto.time, '2026-06-09T12:34:56.789');
    expect(dto.toJson(), json);
  });
}
