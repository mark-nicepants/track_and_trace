import 'dart:io';

import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/data/services/crash_report_service.dart';
import 'package:app/data/services/rotating_file_log_writer.dart';
import 'package:app/shared/config/app_env.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart' hide Matcher;

import '../../helpers/di_test_helper.dart';

void main() {
  late Directory tempDir;
  late Dio dio;
  late DioAdapter adapter;
  late RotatingFileLogWriter writer;
  late CrashReportService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('crash_report_service_');
    writer = RotatingFileLogWriter(directory: Directory('${tempDir.path}/logs'));
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
    adapter = DioAdapter(dio: dio);
    final testEnv = AppEnv('test', 'http://test.local', false, '', '/forward-logs', 'api-key');
    await setupTestDi(dio: dio, trackAndTraceRepository: TrackAndTraceRepository(), env: testEnv);
    service = CrashReportService(writer: writer);
  });

  tearDown(() async {
    await tearDownTestDi();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('uploadLogs returns false when the log directory is missing', () async {
    expect(await writer.directory.exists(), isFalse);
    expect(await service.uploadLogs(), isFalse);
  });

  test('uploadLogs zips every rotated file and POSTs /forward-logs', () async {
    await writer.append('first-line');
    // Force a rotation: a second file is on disk now.
    final writer2 = RotatingFileLogWriter(directory: writer.directory, maxBytesPerFile: 5);
    await writer2.append('AAAAA');
    await writer2.append('BBBBB');

    adapter.onPost('/forward-logs', (server) => server.reply(200, <String, Object?>{}), data: Matchers.any);

    final ok = await service.uploadLogs();
    expect(ok, isTrue);

    // Verify the zip ended up on disk and contains the rotated files.
    final zipPath = '${tempDir.path}/zippedLogs.zip';
    expect(File(zipPath).existsSync(), isTrue);
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((f) => f.name).toSet();
    expect(names.contains('log.0.logcat'), isTrue);
    expect(names.contains('log.1.logcat'), isTrue);
  });

  test('uploadLogs returns false when the upload errors', () async {
    await writer.append('some-line');
    adapter.onPost(
      '/forward-logs',
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: '/forward-logs'),
          type: DioExceptionType.connectionError,
        ),
      ),
      data: Matchers.any,
    );

    final ok = await service.uploadLogs();
    expect(ok, isFalse);
  });
}
