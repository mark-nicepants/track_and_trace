import 'package:app/domain/errors/domain_exception.dart';
import 'package:app/shared/errors/data_exception.dart';
import 'package:app/ui/shared/l10n/l10n.dart';

/// Central exception → user-readable message helper. Strings live in the
/// ARB files (`assets/l10n/*.arb`) — see the `error*` keys. Add new
/// branches here AND a matching key in both `en.arb` and `nl.arb` when a
/// new exception type is introduced.
///
/// Order matters: more specific [DomainException] subtypes come first;
/// [DataException] subtypes catch the cases where a use-case let the data
/// layer's exception propagate. The trailing `_` returns the generic
/// fallback for anything else thrown into [AsyncValue.guard].
String errorMessage(Object error) {
  return switch (error) {
    UnauthorizedException() => L10n.translate.errorUnauthorized,
    NotFoundException() => L10n.translate.errorNotFound,
    ConflictException() => L10n.translate.errorConflict,
    ValidationException(:final field, :final message) => L10n.translate.errorValidation(field, message),
    ServerException(:final statusCode) => L10n.translate.errorServer(statusCode),
    NetworkException() => L10n.translate.errorNetwork,
    TimeoutException() => L10n.translate.errorTimeout,
    HttpException(:final statusCode) => L10n.translate.errorHttp(statusCode),
    ParseException() => L10n.translate.errorParse,
    UnknownDataException() => L10n.translate.errorUnknownData,
    _ => L10n.translate.errorGeneric,
  };
}
