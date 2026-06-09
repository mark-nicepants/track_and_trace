import 'package:app/data/repositories/position_queue_repository.dart';
import 'package:app/data/services/in_memory_connectivity_service.dart';
import 'package:app/data/services/in_memory_foreground_tracking_service.dart';
import 'package:app/data/services/in_memory_location_client.dart';
import 'package:app/data/services/in_memory_permission_service.dart';
import 'package:app/data/services/in_memory_preference_service.dart';
import 'package:app/data/services/in_memory_sending_service.dart';
import 'package:app/data/services/noop_logger.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/contracts/i_connectivity_service.dart';
import 'package:app/shared/contracts/i_foreground_tracking_service.dart';
import 'package:app/shared/contracts/i_location_client.dart';
import 'package:app/shared/contracts/i_logger.dart';
import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/contracts/i_sending_service.dart';
import 'package:app/shared/inject.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

/// Sets up a clean GetIt scope for a test. Pass overrides to swap in mocks.
Future<void> setupTestDi({
  IPreferenceService? prefs,
  ILogger? logger,
  AppEnv? env,
  Dio? dio,
  IsoClock? clock,
  IPermissionService? permissions,
  ILocationClient? locationClient,
  IForegroundTrackingService? foreground,
  IConnectivityService? connectivity,
  ISendingService? sending,
  Database? database,
}) async {
  await injector.reset();
  injector.registerSingleton<IPreferenceService>(prefs ?? InMemoryPreferenceService());
  injector.registerSingleton<ILogger>(logger ?? const NoopLogger());
  injector.registerSingleton<AppEnv>(env ?? AppEnv('test', 'http://test.local', false));
  injector.registerSingleton<Dio>(dio ?? Dio());
  injector.registerSingleton<IsoClock>(clock ?? const IsoClock());
  injector.registerSingleton<IPermissionService>(permissions ?? InMemoryPermissionService());
  injector.registerSingleton<ILocationClient>(locationClient ?? InMemoryLocationClient());
  injector.registerSingleton<IForegroundTrackingService>(foreground ?? InMemoryForegroundTrackingService());
  injector.registerSingleton<IConnectivityService>(connectivity ?? InMemoryConnectivityService());
  injector.registerSingleton<ISendingService>(sending ?? InMemorySendingService());
  if (database != null) {
    injector.registerSingletonAsync<Database>(() async => database);
    await injector.allReady();
    injector.registerSingleton<PositionQueueRepository>(PositionQueueRepository());
  }
}

Future<void> tearDownTestDi() async {
  await injector.reset();
}
