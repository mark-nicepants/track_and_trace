sealed class DomainException implements Exception {
  const DomainException();
}

class NotFoundException extends DomainException {
  const NotFoundException();
}

class UnauthorizedException extends DomainException {
  const UnauthorizedException();
}

class ConflictException extends DomainException {
  const ConflictException();
}

class ValidationException(final String field, final String message) extends DomainException;

/// Backend returned a 5xx. Distinguishes a server-side outage from
/// network/transport errors (which surface as [NetworkException]) and from
/// well-formed 4xx responses (which become more specific subtypes above).
class ServerException(final int statusCode) extends DomainException;
