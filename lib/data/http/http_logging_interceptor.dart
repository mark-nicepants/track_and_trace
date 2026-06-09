import 'package:app/shared/log.dart';
import 'package:dio/dio.dart';

class HttpLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log.debug('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    log.debug('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log.warning('✗ ${err.requestOptions.method} ${err.requestOptions.uri}', err);
    handler.next(err);
  }
}
