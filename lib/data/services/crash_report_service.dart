import 'dart:io';

import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/data/services/rotating_file_log_writer.dart';
import 'package:app/shared/contracts/i_crash_report_service.dart';
import 'package:app/shared/inject.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

/// Production [ICrashReportService]. Collects the rotated log files
/// produced by [RotatingFileLogWriter], zips them into a single archive,
/// and POSTs them to `/forward-logs` via [TrackAndTraceRepository].
///
/// Mirrors the Android `CrashScreenViewModel` flow (FEATURES.md §8.3):
///   1. Find log directory.
///   2. Zip every `log.*.logcat` into `zippedLogs.zip`.
///   3. Multipart POST to `/forward-logs`.
class CrashReportService implements ICrashReportService {
  CrashReportService({required this.writer});

  final RotatingFileLogWriter writer;

  TrackAndTraceRepository get _repo => inject();

  @override
  Future<bool> uploadLogs() async {
    try {
      final logDir = writer.directory;
      if (!await logDir.exists()) return false;

      final zipPath = p.join(logDir.parent.path, 'zippedLogs.zip');
      final zipFile = File(zipPath);
      if (await zipFile.exists()) await zipFile.delete();

      final encoder = ZipFileEncoder()..create(zipPath);
      try {
        for (final file in writer.files) {
          if (await file.exists()) {
            await encoder.addFile(file);
          }
        }
      } finally {
        await encoder.close();
      }

      await _repo.uploadLogfile(zipFile, fieldName: 'name');
      return true;
    } catch (_) {
      return false;
    }
  }
}
