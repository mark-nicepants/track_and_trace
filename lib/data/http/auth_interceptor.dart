import 'package:dio/dio.dart';

/// Attaches the backend's static API key to every outgoing request as the
/// `X-API-Key` header. Mirrors the Android reference app's `AuthInterceptor`
/// in `feature_api/data/repository/HttpConfiguration.kt`.
///
/// The key is sourced from [AppEnv.apiKey], which loads it from
/// `assets/env/<env>.json`. Per-developer keys live in
/// `assets/env/local.json` (gitignored), matching the reference app's
/// `local.properties` pattern.
class AuthInterceptor extends Interceptor {
  const AuthInterceptor(this._apiKey);

  static const String headerName = 'X-API-Key';

  final String _apiKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_apiKey.isNotEmpty) {
      options.headers[headerName] = _apiKey;
    }
    handler.next(options);
  }
}
