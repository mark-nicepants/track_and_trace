sealed class DataException implements Exception {
  const DataException();
}

class NetworkException extends DataException {
  const NetworkException();
}

class TimeoutException extends DataException {
  const TimeoutException();
}

class HttpException(final int statusCode, final Object? body) extends DataException;

class ParseException(final Object cause) extends DataException;

class UnknownDataException(final Object cause) extends DataException;
