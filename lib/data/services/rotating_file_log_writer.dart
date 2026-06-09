import 'dart:io';

import 'package:path/path.dart' as p;

/// Append-only writer that rotates between [fileCount] files of up to
/// [maxBytesPerFile] each. File names are `log.0.logcat`, `log.1.logcat`,
/// `log.2.logcat`, matching the Android `FileDebugTree` filename pattern
/// (`log.%g.logcat`) from FEATURES.md §8.2.
///
/// Rotation strategy is the simplest one that's still observable from
/// outside the class: when the active file reaches the size limit, the
/// older files are shifted up (`log.1` → `log.2`, `log.0` → `log.1`) and a
/// fresh `log.0.logcat` is opened. The newest entries always live in
/// `log.0.logcat`, the oldest in `log.{fileCount-1}.logcat`.
class RotatingFileLogWriter {
  RotatingFileLogWriter({required this.directory, this.maxBytesPerFile = 1 * 1000 * 1000, this.fileCount = 3})
    : assert(fileCount >= 1, 'fileCount must be >= 1'),
      assert(maxBytesPerFile > 0, 'maxBytesPerFile must be > 0');

  /// Directory holding the rotated log files. Created on first write.
  final Directory directory;

  /// Maximum bytes per log file before rotation. Defaults to 1 MB per
  /// FEATURES.md §8.2 ("Max 1 MB per file, 3 files").
  final int maxBytesPerFile;

  /// Total number of rotated files retained on disk. Defaults to 3.
  final int fileCount;

  /// Active file (`log.0.logcat`). Created lazily by [append].
  File get activeFile => File(p.join(directory.path, 'log.0.logcat'));

  /// Files in newest-first order. The active file is at index 0; the
  /// oldest retained file is at index `fileCount - 1`. Some may not exist
  /// on disk yet — callers should filter on `existsSync()` before reading.
  List<File> get files => [for (var i = 0; i < fileCount; i++) File(p.join(directory.path, 'log.$i.logcat'))];

  /// Appends a line of text to the active file, rotating if necessary so
  /// that no single file exceeds [maxBytesPerFile]. Each call appends
  /// [message] followed by a newline.
  ///
  /// Safe to call repeatedly; the directory is created lazily.
  Future<void> append(String message) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = activeFile;
    final payload = '$message\n';
    final payloadBytes = payload.length;

    var current = 0;
    if (await file.exists()) {
      current = await file.length();
    }
    if (current + payloadBytes > maxBytesPerFile) {
      await _rotate();
    }
    await activeFile.writeAsString(payload, mode: FileMode.append, flush: true);
  }

  Future<void> _rotate() async {
    // Drop the oldest file, then shift each lower-index file up by one:
    //   log.{n-1} ← log.{n-2}, ..., log.1 ← log.0
    // Finally the active log.0 will be re-created by the next write.
    final ring = files;
    final oldest = ring.last;
    if (await oldest.exists()) {
      await oldest.delete();
    }
    for (var i = ring.length - 1; i > 0; i--) {
      final from = ring[i - 1];
      final to = ring[i];
      if (await from.exists()) {
        await from.rename(to.path);
      }
    }
  }
}
