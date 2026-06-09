import 'dart:io';

import 'package:app/data/services/rotating_file_log_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rotating_file_log_writer_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('append creates the log directory lazily', () async {
    final dir = Directory('${tempDir.path}/nested/logs');
    final writer = RotatingFileLogWriter(directory: dir);
    expect(await dir.exists(), isFalse);

    await writer.append('hello');

    expect(await dir.exists(), isTrue);
    expect(await writer.activeFile.exists(), isTrue);
    expect(await writer.activeFile.readAsString(), 'hello\n');
  });

  test('append writes consecutive lines into log.0.logcat', () async {
    final writer = RotatingFileLogWriter(directory: tempDir);
    await writer.append('one');
    await writer.append('two');
    await writer.append('three');
    expect(await writer.activeFile.readAsString(), 'one\ntwo\nthree\n');
  });

  test('rotation shifts log.0 → log.1 once max size is exceeded', () async {
    final writer = RotatingFileLogWriter(directory: tempDir, maxBytesPerFile: 20, fileCount: 3);
    // 11 chars + newline = 12 bytes — fits.
    await writer.append('first10char');
    // Next 11 chars + newline = 12 bytes → total 24 > 20 → triggers rotation.
    await writer.append('second10ch!');

    final files = writer.files;
    expect(await files[0].exists(), isTrue, reason: 'log.0 exists after rotation');
    expect(await files[1].exists(), isTrue, reason: 'log.1 contains the rotated entries');
    expect(await files[0].readAsString(), 'second10ch!\n');
    expect(await files[1].readAsString(), 'first10char\n');
  });

  test('rotation retains at most fileCount files (oldest is dropped)', () async {
    final writer = RotatingFileLogWriter(directory: tempDir, maxBytesPerFile: 10, fileCount: 3);
    // Each append is 9 bytes (8 chars + newline) — every following append rotates.
    await writer.append('AAAAAAAA');
    await writer.append('BBBBBBBB');
    await writer.append('CCCCCCCC');
    await writer.append('DDDDDDDD');

    final files = writer.files;
    expect(await files[0].readAsString(), 'DDDDDDDD\n');
    expect(await files[1].readAsString(), 'CCCCCCCC\n');
    expect(await files[2].readAsString(), 'BBBBBBBB\n');
    // The original 'AAAAAAAA' line has been dropped — only fileCount=3 retained.
    expect(File('${tempDir.path}/log.3.logcat').existsSync(), isFalse);
  });
}
