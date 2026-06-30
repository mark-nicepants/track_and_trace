import 'dart:convert';
import 'dart:io';

import 'package:app/app.dart';
import 'package:app/data/di/data_module.dart';
import 'package:app/data/services/crash_report_service.dart';
import 'package:app/data/services/log_export_service.dart';
import 'package:app/data/services/logger_service.dart';
import 'package:app/data/services/preference_service.dart';
import 'package:app/data/services/rotating_file_log_writer.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/contracts/i_crash_report_service.dart';
import 'package:app/shared/contracts/i_log_export_service.dart';
import 'package:app/shared/contracts/i_logger.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/inject.dart';
import 'package:app/shared/turbo_bridge.dart';
import 'package:app/ui/features/dev/env_switcher_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  injector.registerSingleton<IPreferenceService>(PreferenceService());

  final supportDir = await getApplicationSupportDirectory();
  final logDir = Directory(p.join(supportDir.path, 'logs'));
  final writer = RotatingFileLogWriter(directory: logDir);

  const envFromArg = String.fromEnvironment('ENV', defaultValue: '');
  final selectedName = envFromArg.isNotEmpty
      ? envFromArg
      : await inject<IPreferenceService>().readString(selectedEnvKey) ?? AppEnv.fallbackName;
  final envName = AppEnv.knownNames.contains(selectedName) ? selectedName : AppEnv.fallbackName;
  final raw = await rootBundle.loadString('assets/env/$envName.json');
  final env = AppEnv.fromJson(envName, jsonDecode(raw) as Map<String, Object?>);
  injector.registerSingleton<AppEnv>(env);

  injector.registerSingleton<ILogger>(LoggerService(writer: writer, consoleEnabled: !kReleaseMode));
  injector.registerSingleton<IsoClock>(const IsoClock());

  registerDataModule();

  injector.registerSingleton<ICrashReportService>(CrashReportService(writer: writer));
  injector.registerSingleton<ILogExportService>(LogExportService(writer: writer));

  runApp(const ProviderScope(child: App()));

  initializeTurboBridge();
}
