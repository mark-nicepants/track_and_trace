import 'package:app/data/errors/data_exception.dart';
import 'package:dio/dio.dart' as dio;

/// Wraps a dio call and translates any low-level failure into a sealed
/// [DataException] subtype. Repositories should funnel every HTTP call
/// through this helper so they never need their own try/catch.
Future<T> guardDio<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on dio.DioException catch (e) {
    switch (e.type) {
      case dio.DioExceptionType.connectionError:
        throw const NetworkException();
      case dio.DioExceptionType.connectionTimeout:
      case dio.DioExceptionType.sendTimeout:
      case dio.DioExceptionType.receiveTimeout:
        throw const TimeoutException();
      case dio.DioExceptionType.badResponse:
        throw HttpException(e.response?.statusCode ?? 0, e.response?.data);
      case dio.DioExceptionType.cancel:
      case dio.DioExceptionType.badCertificate:
      case dio.DioExceptionType.unknown:
        throw UnknownDataException(e);
    }
  } on FormatException catch (e) {
    throw ParseException(e);
  } on TypeError catch (e) {
    throw ParseException(e);
  } catch (e) {
    throw UnknownDataException(e);
  }
}
