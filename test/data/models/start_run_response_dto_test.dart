import 'package:app/data/models/start_run_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson/toJson round-trip preserves runId', () {
    final json = <String, Object?>{'runId': 'run-42'};

    final dto = StartRunResponseDto.fromJson(json);
    expect(dto.runId, 'run-42');
    expect(dto.toJson(), json);
  });
}
