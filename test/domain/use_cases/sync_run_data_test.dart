import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/entities/dump_size.dart';
import 'package:app/domain/use_cases/sync_run_data.dart';
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

  test('POSTs /sync-run-data with runId, time, and the wire-form quantity', () async {
    final received = <Object?>[];
    adapter.onPost('/sync-run-data', (s) => s.reply(200, <String, Object?>{}), data: Matchers.any);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          received.add(options.data);
          handler.next(options);
        },
      ),
    );

    await SyncRunData('run-2', DumpSize.full).call();

    final body = received.single as Map<String, Object?>;
    expect(body['runId'], 'run-2');
    expect(body['quantity'], 'FULL');
    expect(body['time'], isA<String>());
  });
}
