import 'dart:io';

import 'package:app/data/services/log_export_service.dart';
import 'package:app/data/services/rotating_file_log_writer.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late RotatingFileLogWriter writer;
  late LogExportService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('log_export_service_');
    writer = RotatingFileLogWriter(directory: Directory('${tempDir.path}/logs'));
    service = LogExportService(writer: writer);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('exportLogArchive returns null when the log directory is missing', () async {
    expect(await writer.directory.exists(), isFalse);
    expect(await service.exportLogArchive(), isNull);
  });

  test('exportLogArchive returns null when the directory exists but holds no log files', () async {
    await writer.directory.create(recursive: true);
    expect(await service.exportLogArchive(), isNull);
  });

  test('exportLogArchive zips every rotated file and returns the archive path', () async {
    await writer.append('first-line');
    // Force a rotation so a second file is on disk.
    final rotating = RotatingFileLogWriter(directory: writer.directory, maxBytesPerFile: 5);
    await rotating.append('AAAAA');
    await rotating.append('BBBBB');

    final path = await service.exportLogArchive();
    expect(path, isNotNull);
    expect(path, endsWith('sharedLogs.zip'));
    expect(File(path!).existsSync(), isTrue);

    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((f) => f.name).toSet();
    expect(names.contains('log.0.logcat'), isTrue);
    expect(names.contains('log.1.logcat'), isTrue);
  });
}
