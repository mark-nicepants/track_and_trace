import 'package:app/shared/contracts/i_logger.dart';
import 'package:logger/logger.dart' as pkg;

class LoggerService implements ILogger {
  LoggerService()
    : _logger = pkg.Logger(
        printer: pkg.PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 8,
          printEmojis: false,
          dateTimeFormat: pkg.DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );

  final pkg.Logger _logger;

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
