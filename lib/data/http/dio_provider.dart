import 'package:app/data/http/auth_interceptor.dart';
import 'package:app/shared/config/app_env.dart';
import 'package:app/shared/turbo_bridge.dart';
import 'package:dio/dio.dart';

Dio buildDio(AppEnv env) {
  final dio = Dio(
    BaseOptions(
      baseUrl: env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(env.apiKey));
  if (env.enableLogging) {
    dio.interceptors.add(turboBridgeNetworkInterceptor);
  }

  return dio;
}
