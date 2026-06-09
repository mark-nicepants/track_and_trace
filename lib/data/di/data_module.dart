import 'package:app/data/http/dio_provider.dart';
import 'package:app/data/repositories/user_repository.dart';
import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/inject.dart';
import 'package:dio/dio.dart';

/// Registers all data-layer singletons. Called from [main] AFTER:
///   - IPreferenceService is registered,
///   - ILogger is registered,
///   - AppEnv is registered.
void registerDataModule() {
  final env = inject<AppEnv>();

  injector.registerSingleton<Dio>(buildDio(env));

  // Repositories
  injector.registerSingleton<UserRepository>(UserRepository());
}
