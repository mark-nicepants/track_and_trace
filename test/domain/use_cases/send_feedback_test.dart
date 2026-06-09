import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/entities/activity_state.dart';
import 'package:app/domain/use_cases/send_feedback.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart' hide Matcher;

import '../../helpers/di_test_helper.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() async {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    await setupTestDi(dio: dio, trackAndTraceRepository: TrackAndTraceRepository());
  });

  tearDown(tearDownTestDi);

  test('POSTs /create-feedback with the wire-form activity', () async {
    adapter.onPost('/create-feedback', (server) => server.reply(200, <String, Object?>{}), data: Matchers.any);

    await SendFeedback('run-1', ActivityState.driving).call();
  });
}
