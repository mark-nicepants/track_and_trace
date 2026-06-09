import 'package:app/data/services/in_memory_permission_service.dart';
import 'package:app/data/services/in_memory_preference_service.dart';
import 'package:app/data/services/noop_logger.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/contracts/i_logger.dart';
import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/inject.dart';
import 'package:dio/dio.dart';

/// Sets up a clean GetIt scope for a test. Pass overrides to swap in mocks.
Future<void> setupTestDi({
  IPreferenceService? prefs,
  ILogger? logger,
  AppEnv? env,
  Dio? dio,
  IsoClock? clock,
  IPermissionService? permissions,
}) async {
  await injector.reset();
  injector.registerSingleton<IPreferenceService>(prefs ?? InMemoryPreferenceService());
  injector.registerSingleton<ILogger>(logger ?? const NoopLogger());
  injector.registerSingleton<AppEnv>(env ?? AppEnv('test', 'http://test.local', false));
  injector.registerSingleton<Dio>(dio ?? Dio());
  injector.registerSingleton<IsoClock>(clock ?? const IsoClock());
  injector.registerSingleton<IPermissionService>(permissions ?? InMemoryPermissionService());
}

Future<void> tearDownTestDi() async {
  await injector.reset();
}
