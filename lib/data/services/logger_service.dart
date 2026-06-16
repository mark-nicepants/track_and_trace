import 'package:app/data/services/rotating_file_log_writer.dart';
import 'package:app/shared/contracts/i_logger.dart';
import 'package:app/shared/turbo_bridge.dart';
import 'package:logger/logger.dart' as pkg;

/// Production [ILogger] that mirrors every line to:
///   1. the console, when [consoleEnabled] is true (driven by
///      `AppEnv.enableLogging` — off in prod), and
///   2. a rotating on-disk log file (1 MB × 3 by default per FEATURES.md
///      §8.2), so the crash-upload flow has something to ship.
///
/// File appends are fire-and-forget; the writer serializes them so callers
/// don't have to await. Failures are swallowed — logging must never crash
/// the caller.
class LoggerService implements ILogger {
  LoggerService({required this.writer, required this.consoleEnabled})
    : _console = pkg.Logger(
        printer: pkg.PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 8,
          printEmojis: false,
          dateTimeFormat: pkg.DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );

  final RotatingFileLogWriter writer;
  final bool consoleEnabled;
  final pkg.Logger _console;
  Future<void> _writeChain = Future.value();

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (consoleEnabled) {
      turboBridge?.logs.debug(message);
      _console.d(message, error: error, stackTrace: stackTrace);
    }

    _appendFile('D', message, error, stackTrace);
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (consoleEnabled) {
      turboBridge?.logs.info(message);
      _console.i(message, error: error, stackTrace: stackTrace);
    }
    _appendFile('I', message, error, stackTrace);
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (consoleEnabled) {
      turboBridge?.logs.warn(message, error: error, stackTrace: stackTrace);
      _console.w(message, error: error, stackTrace: stackTrace);
    }
    _appendFile('W', message, error, stackTrace);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (consoleEnabled) {
      turboBridge?.logs.error(message, error: error, stackTrace: stackTrace);
      _console.e(message, error: error, stackTrace: stackTrace);
    }
    _appendFile('E', message, error, stackTrace);
  }

  void _appendFile(String level, String message, Object? error, StackTrace? stackTrace) {
    final timestamp = _formatTimestamp(DateTime.now());
    final buffer = StringBuffer('$timestamp $level/ $message');
    if (error != null) buffer.write(' | error=$error');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    final line = buffer.toString();
    _writeChain = _writeChain.then((_) async {
      try {
        await writer.append(line);
      } catch (_) {
        // Logging must never throw — drop the line.
      }
    });
  }

  /// Awaits any in-flight file writes — exposed so callers (e.g. the
  /// crash-upload flow) can flush the on-disk log before zipping.
  Future<void> flush() => _writeChain;

  static String _formatTimestamp(DateTime now) {
    final l = now;
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    return '${l.year}${two(l.month)}${two(l.day)}_'
        '${two(l.hour)}${two(l.minute)}${two(l.second)}_'
        '${three(l.millisecond)}';
  }
}
