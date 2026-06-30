sealed class DomainException implements Exception {
  const DomainException();
}

class NotFoundException(final int statusCode) extends DomainException;

class UnauthorizedException(final int statusCode) extends DomainException;

class ConflictException(final int statusCode) extends DomainException;

class ValidationException(final String field, final String message) extends DomainException;

/// Backend returned a 5xx. Distinguishes a server-side outage from
/// network/transport errors (which surface as [NetworkException]) and from
/// well-formed 4xx responses (which become more specific subtypes above).
class ServerException(final int statusCode) extends DomainException;
