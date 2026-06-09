import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/entities/dump_size.dart';
import 'package:app/domain/use_cases/send_dump_size.dart';
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

  test('POSTs /create-dump-size with runId, time, and the wire-form quantity', () async {
    final received = <Object?>[];
    adapter.onPost('/create-dump-size', (server) => server.reply(200, <String, Object?>{}), data: Matchers.any);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          received.add(options.data);
          handler.next(options);
        },
      ),
    );

    await SendDumpSize('run-X', DumpSize.threeQuarter).call();

    final body = received.single as Map<String, Object?>;
    expect(body['runId'], 'run-X');
    expect(body['quantity'], 'THREEQUARTER');
    expect(body['time'], isA<String>());
  });
}
