import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/use_cases/get_nearest_depot.dart';
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

  test('returns the parsed depot entity', () async {
    adapter.onPost('/get-nearest-depot', (server) => server.reply(200, {'name': 'Hub East'}), data: Matchers.any);

    final result = await GetNearestDepot('run-1').call();

    expect(result.name, 'Hub East');
  });
}
