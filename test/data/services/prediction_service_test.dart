import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/data/services/prediction_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/di_test_helper.dart';

class _StatusFake extends Interceptor {
  final Map<String, int> hits = {};

  /// Path → list of activity strings to return on each successive hit.
  final Map<String, List<String>> script;

  _StatusFake(this.script);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    if (path == '/get-status') {
      final hit = hits.update('/get-status', (v) => v + 1, ifAbsent: () => 0);
      final s = script['/get-status'] ?? const [];
      final activity = hit < s.length ? s[hit] : (s.isEmpty ? 'DRIVING' : s.last);
      handler.resolve(
        Response<Map<String, Object?>>(
          requestOptions: options,
          statusCode: 200,
          data: {'activity': activity, 'time': '2026-06-09T12:00:00.000'},
        ),
      );
      return;
    }
    handler.next(options);
  }
}

void main() {
  test('production default pollInterval is 2 s', () {
    expect(PredictionService().pollInterval, const Duration(seconds: 2));
  });

  test('emits each newly-distinct prediction and dedupes consecutives', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    final fake = _StatusFake({
      '/get-status': ['LOADING', 'LOADING', 'DRIVING', 'DRIVING', 'DUMPING'],
    });
    dio.interceptors.add(fake);
    await setupTestDi(dio: dio, trackAndTraceRepository: TrackAndTraceRepository());

    final service = PredictionService(pollInterval: const Duration(milliseconds: 5));
    final received = <String>[];
    final sub = service.predictions.listen(received.add);

    await service.start('run-1');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await service.stop();
    await sub.cancel();
    await tearDownTestDi();

    expect(received, containsAllInOrder(['LOADING', 'DRIVING', 'DUMPING']));
    // No duplicates of LOADING or DRIVING in a row.
    for (var i = 1; i < received.length; i++) {
      expect(received[i] == received[i - 1], isFalse);
    }
  });

  test('drops unknown activity strings', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    final fake = _StatusFake({
      '/get-status': ['MOWING', 'DRIVING'],
    });
    dio.interceptors.add(fake);
    await setupTestDi(dio: dio, trackAndTraceRepository: TrackAndTraceRepository());

    final service = PredictionService(pollInterval: const Duration(milliseconds: 5));
    final received = <String>[];
    final sub = service.predictions.listen(received.add);

    await service.start('run-1');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await service.stop();
    await sub.cancel();
    await tearDownTestDi();

    expect(received, isNot(contains('MOWING')));
    expect(received, contains('DRIVING'));
  });

  test('start() is idempotent: a second call is a no-op', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    final fake = _StatusFake({
      '/get-status': ['DRIVING'],
    });
    dio.interceptors.add(fake);
    await setupTestDi(dio: dio, trackAndTraceRepository: TrackAndTraceRepository());

    final service = PredictionService(pollInterval: const Duration(milliseconds: 10));
    await service.start('run-1');
    await service.start('run-2');
    expect(service.isRunning, isTrue);
    await service.stop();
    await tearDownTestDi();
  });
}
