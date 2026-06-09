import 'dart:convert';

import 'package:app/app.dart';
import 'package:app/data/di/data_module.dart';
import 'package:app/data/services/logger_service.dart';
import 'package:app/data/services/preference_service.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/contracts/i_logger.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/inject.dart';
import 'package:app/ui/features/dev/env_switcher_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  injector.registerSingleton<IPreferenceService>(PreferenceService());
  injector.registerSingleton<ILogger>(LoggerService());
  injector.registerSingleton<IsoClock>(const IsoClock());

  final selectedName = await inject<IPreferenceService>().readString(selectedEnvKey) ?? AppEnv.fallbackName;
  final envName = AppEnv.knownNames.contains(selectedName) ? selectedName : AppEnv.fallbackName;
  final raw = await rootBundle.loadString('assets/env/$envName.json');
  final env = AppEnv.fromJson(envName, jsonDecode(raw) as Map<String, Object?>);
  injector.registerSingleton<AppEnv>(env);

  registerDataModule();

  runApp(const ProviderScope(child: App()));
}
