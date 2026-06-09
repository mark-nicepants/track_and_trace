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
