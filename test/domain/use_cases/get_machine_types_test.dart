import 'package:app/data/errors/data_exception.dart' as app_errors;
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/use_cases/get_machine_types.dart';
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

  test('returns domain entities mapped from DTOs', () async {
    adapter.onPost(
      '/get-machine-types',
      (server) => server.reply(200, [
        {'id': 'mt-1', 'displayName': 'Loader'},
        {'id': 'mt-2', 'displayName': 'Truck'},
      ]),
    );

    final result = await GetMachineTypes().call();

    expect(result, hasLength(2));
    expect(result[0].id, 'mt-1');
    expect(result[0].displayName, 'Loader');
    expect(result[1].id, 'mt-2');
    expect(result[1].displayName, 'Truck');
  });

  test('propagates HttpException on backend error', () async {
    adapter.onPost('/get-machine-types', (server) => server.reply(500, {'error': 'boom'}));

    await expectLater(GetMachineTypes().call(), throwsA(isA<app_errors.HttpException>()));
  });

  test('propagates NetworkException on connection error', () async {
    adapter.onPost(
      '/get-machine-types',
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: '/get-machine-types'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );

    await expectLater(GetMachineTypes().call(), throwsA(isA<app_errors.NetworkException>()));
  });
}
