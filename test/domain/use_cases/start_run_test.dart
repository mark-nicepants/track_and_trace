import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/use_cases/start_run.dart';
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

  test('returns runId from /create-run response', () async {
    adapter.onPost('/create-run', (server) => server.reply(200, {'runId': 'run-99'}), data: Matchers.any);

    final result = await StartRun('mt-1', 12.5).call();

    expect(result, 'run-99');
  });
}
