import 'package:app/domain/errors/domain_exception.dart';

/// Central exception → user-readable message helper.
/// Extend the switch as new exception types are introduced.
String errorMessage(Object error) {
  return switch (error) {
    NotFoundException() => 'Not found.',
    UnauthorizedException() => 'You are not signed in.',
    ConflictException() => 'This action conflicts with the current state.',
    ValidationException(:final field, :final message) => 'Invalid $field: $message',
    _ => 'Something went wrong. Please try again.',
  };
}
