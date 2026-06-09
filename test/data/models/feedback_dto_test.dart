import 'package:app/data/models/feedback_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson/toJson round-trip preserves all fields', () {
    final json = <String, Object?>{'runId': 'run-1', 'time': '2026-06-09T12:34:56.789', 'name': 'LOADING'};

    final dto = FeedbackDto.fromJson(json);
    expect(dto.runId, 'run-1');
    expect(dto.time, json['time']);
    expect(dto.name, 'LOADING');
    expect(dto.toJson(), json);
  });

  test('toJson omits name when null', () {
    final dto = FeedbackDto('run-1', '2026-06-09T00:00:00.000', null);
    expect(dto.toJson().containsKey('name'), isFalse);
  });
}
