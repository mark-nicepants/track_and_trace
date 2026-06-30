import 'package:dio/dio.dart';
import 'package:logarte/logarte.dart';

/// Shared in-app debug console (log viewer + network inspector + storage
/// monitor). A single [Logarte] instance is reused by three call sites:
///   1. [buildDio] adds [logarteDioInterceptor] so every request/response is
///      captured by the network inspector (only when `AppEnv.enableLogging`),
///   2. `LoggerService` mirrors every log line into the console, and
///   3. the tracking screen's overflow menu opens the dashboard via
///      [Logarte.openConsole].
///
/// `disableDebugConsoleLogs` is on because the app already prints to the
/// console through the `logger` package — without it Logarte would duplicate
/// every line (and every captured request) to `dart:developer`.
final Logarte logarte = Logarte(disableDebugConsoleLogs: true);

/// Dio interceptor that feeds Logarte's network inspector.
Interceptor get logarteDioInterceptor => LogarteDioInterceptor(logarte);
