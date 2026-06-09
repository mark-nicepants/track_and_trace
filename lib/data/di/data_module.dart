import 'package:app/data/http/dio_provider.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/data/services/permission_service.dart';
import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:app/shared/inject.dart';
import 'package:dio/dio.dart';

/// Registers all data-layer singletons. Called from [main] AFTER:
///   - IPreferenceService is registered,
///   - ILogger is registered,
///   - IsoClock is registered,
///   - AppEnv is registered.
void registerDataModule() {
  final env = inject<AppEnv>();

  injector.registerSingleton<Dio>(buildDio(env));
  injector.registerSingleton<TrackAndTraceRepository>(TrackAndTraceRepository());
  injector.registerSingleton<IPermissionService>(const PermissionService());
}
