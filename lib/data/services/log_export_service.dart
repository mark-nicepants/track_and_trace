import 'dart:io';

import 'package:app/data/services/rotating_file_log_writer.dart';
import 'package:app/shared/contracts/i_log_export_service.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

/// Production [ILogExportService]. Zips the rotated log files produced by
/// [RotatingFileLogWriter] into `sharedLogs.zip` (sibling of the log
/// directory) and returns its path for the share sheet.
///
/// Mirrors the zipping half of [CrashReportService] but writes to a
/// distinct file name so a manual share and a crash upload never clobber
/// each other's archive.
class LogExportService implements ILogExportService {
  LogExportService({required this.writer});

  final RotatingFileLogWriter writer;

  @override
  Future<String?> exportLogArchive() async {
    final logDir = writer.directory;
    if (!await logDir.exists()) return null;

    final existing = <File>[];
    for (final file in writer.files) {
      if (await file.exists()) existing.add(file);
    }
    if (existing.isEmpty) return null;

    final zipPath = p.join(logDir.parent.path, 'sharedLogs.zip');
    final zipFile = File(zipPath);
    if (await zipFile.exists()) await zipFile.delete();

    final encoder = ZipFileEncoder()..create(zipPath);
    try {
      for (final file in existing) {
        await encoder.addFile(file);
      }
    } finally {
      await encoder.close();
    }
    return zipPath;
  }
}
