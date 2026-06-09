import 'dart:convert';
import 'dart:io';

import 'package:app/app.dart';
import 'package:app/data/di/data_module.dart';
import 'package:app/data/services/crash_report_service.dart';
import 'package:app/data/services/logger_service.dart';
import 'package:app/data/services/new_relic_service.dart';
import 'package:app/data/services/preference_service.dart';
import 'package:app/data/services/rotating_file_log_writer.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/contracts/i_crash_report_service.dart';
import 'package:app/shared/contracts/i_logger.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/inject.dart';
import 'package:app/ui/features/dev/env_switcher_notifier.dart';
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

  final selectedName = await inject<IPreferenceService>().readString(selectedEnvKey) ?? AppEnv.fallbackName;
  final envName = AppEnv.knownNames.contains(selectedName) ? selectedName : AppEnv.fallbackName;
  final raw = await rootBundle.loadString('assets/env/$envName.json');
  final env = AppEnv.fromJson(envName, jsonDecode(raw) as Map<String, Object?>);
  injector.registerSingleton<AppEnv>(env);

  injector.registerSingleton<ILogger>(LoggerService(writer: writer, consoleEnabled: env.enableLogging));
  injector.registerSingleton<IsoClock>(const IsoClock());

  registerDataModule();

  injector.registerSingleton<ICrashReportService>(CrashReportService(writer: writer));

  // Per FEATURES.md §8.4, New Relic owns runtime crash + ANR reporting. The
  // SDK is initialized via the env-configured token; when the token is
  // empty (e.g. dev / tests) the service is a no-op.
  await NewRelicService.start(token: env.newRelicToken);

  runApp(const ProviderScope(child: App()));
}
