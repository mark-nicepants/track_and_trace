import 'dart:io';

import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/shared/errors/data_exception.dart' as app_errors;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart' hide Matcher;

import '../../helpers/di_test_helper.dart';
import '../../helpers/fixtures.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late TrackAndTraceRepository repo;

  setUp(() async {
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    await setupTestDi(dio: dio);
    repo = TrackAndTraceRepository();
  });

  tearDown(tearDownTestDi);

  void replyOk(String path, {Object? body}) {
    adapter.onPost(path, (server) => server.reply(200, body ?? <String, Object?>{}), data: Matchers.any);
  }

  void replyHttpError(String path) {
    adapter.onPost(path, (server) => server.reply(500, {'error': 'boom'}), data: Matchers.any);
  }

  void throwsNetworkError(String path) {
    adapter.onPost(
      path,
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: path),
          type: DioExceptionType.connectionError,
        ),
      ),
      data: Matchers.any,
    );
  }

  void runErrorPair(String label, String path, Future<void> Function() invoke) {
    test('$label HTTP error -> HttpException', () async {
      replyHttpError(path);
      await expectLater(invoke(), throwsA(isA<app_errors.HttpException>()));
    });

    test('$label network error -> NetworkException', () async {
      throwsNetworkError(path);
      await expectLater(invoke(), throwsA(isA<app_errors.NetworkException>()));
    });
  }

  group('/create-run', () {
    Future<void> invoke() async {
      await repo.sendStartRun(startRunRequestDto());
    }

    test('success returns parsed runId', () async {
      adapter.onPost('/create-run', (server) => server.reply(200, {'runId': 'run-abc'}), data: Matchers.any);
      final result = await repo.sendStartRun(startRunRequestDto());
      expect(result.runId, 'run-abc');
    });

    runErrorPair('/create-run', '/create-run', invoke);
  });

  group('/stop-run', () {
    Future<void> invoke() => repo.sendStopRun(stopRunRequestDto());

    test('success', () async {
      replyOk('/stop-run');
      await invoke();
    });

    runErrorPair('/stop-run', '/stop-run', invoke);
  });

  group('/create-locations', () {
    Future<void> invoke() => repo.createLocations(createLocationsRequestDto());

    test('success', () async {
      replyOk('/create-locations');
      await invoke();
    });

    runErrorPair('/create-locations', '/create-locations', invoke);
  });

  group('/create-feedback', () {
    Future<void> invoke() => repo.sendFeedback(feedbackDto());

    test('success', () async {
      replyOk('/create-feedback');
      await invoke();
    });

    runErrorPair('/create-feedback', '/create-feedback', invoke);
  });

  group('/get-status', () {
    Future<void> invoke() async {
      await repo.getStatus(getStatusRequestDto());
    }

    test('success returns parsed activity + time', () async {
      adapter.onPost(
        '/get-status',
        (server) => server.reply(200, {'activity': 'DRIVING', 'time': '2026-06-09T12:00:00.000'}),
        data: Matchers.any,
      );
      final result = await repo.getStatus(getStatusRequestDto());
      expect(result.activity, 'DRIVING');
      expect(result.time, '2026-06-09T12:00:00.000');
    });

    runErrorPair('/get-status', '/get-status', invoke);
  });

  group('/create-dump-size', () {
    Future<void> invoke() => repo.sendDumpSize(dumpSizeDto());

    test('success', () async {
      replyOk('/create-dump-size');
      await invoke();
    });

    runErrorPair('/create-dump-size', '/create-dump-size', invoke);
  });

  group('/get-nearest-depot', () {
    Future<void> invoke() async {
      await repo.getNearestDepot(getNearestDepotRequestDto());
    }

    test('success returns parsed NearestDepotDto', () async {
      adapter.onPost('/get-nearest-depot', (server) => server.reply(200, {'name': 'Depot A'}), data: Matchers.any);
      final result = await repo.getNearestDepot(getNearestDepotRequestDto());
      expect(result.name, 'Depot A');
    });

    runErrorPair('/get-nearest-depot', '/get-nearest-depot', invoke);
  });

  group('/sync-run-data', () {
    Future<void> invoke() => repo.sendSyncRunData(syncRunDataRequestDto());

    test('success', () async {
      replyOk('/sync-run-data');
      await invoke();
    });

    runErrorPair('/sync-run-data', '/sync-run-data', invoke);
  });

  group('/forward-logs', () {
    late Directory tempDir;
    late File logfile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('forward_logs_test_');
      logfile = await File('${tempDir.path}/logs.zip').writeAsBytes([1, 2, 3, 4]);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> invoke() => repo.uploadLogfile(logfile, fieldName: 'file');

    test('success uploads multipart body', () async {
      replyOk('/forward-logs');
      await invoke();
    });

    runErrorPair('/forward-logs', '/forward-logs', invoke);
  });

  group('/get-machine-types', () {
    Future<void> invoke() async {
      await repo.getMachineTypes();
    }

    test('success returns parsed list of MachineTypeDto', () async {
      adapter.onPost(
        '/get-machine-types',
        (server) => server.reply(200, [
          {'id': 'mt-1', 'displayName': 'Loader'},
          {'id': 'mt-2', 'displayName': 'Truck'},
        ]),
        data: Matchers.any,
      );
      final result = await repo.getMachineTypes();
      expect(result, hasLength(2));
      expect(result[0].id, 'mt-1');
      expect(result[1].displayName, 'Truck');
    });

    runErrorPair('/get-machine-types', '/get-machine-types', invoke);
  });
}
