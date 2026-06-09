import 'package:app/shared/errors/data_exception.dart';
import 'package:app/domain/errors/domain_exception.dart';

/// Base contract for one-shot operations.
///
/// Subclasses override [execute]. The public [call] entry point wraps that
/// invocation and translates well-known HTTP status codes into domain-level
/// exceptions (see [mapHttpStatusToDomain]), so consumers can pattern-match
/// on `UnauthorizedException`, `NotFoundException`, etc. without having to
/// inspect raw status codes. Anything that doesn't map propagates as-is.
///
/// Implementations:
/// - Resolve internal dependencies via private `inject<T>()` getters.
/// - Accept per-call inputs as constructor parameters.
/// - Are stateless beyond their constructor parameters.
abstract class UseCase<R> {
  const UseCase();

  Future<R> call() async {
    try {
      return await execute();
    } on HttpException catch (e) {
      final mapped = mapHttpStatusToDomain(e.statusCode);
      if (mapped != null) throw mapped;
      rethrow;
    }
  }

  Future<R> execute();
}

/// Base contract for stream-producing operations. No HTTP mapping is
/// applied — stream-based use-cases typically wrap local sources.
abstract class StreamUseCase<R> {
  const StreamUseCase();

  Stream<R> call();
}

/// Maps an HTTP status code to a [DomainException], or `null` if the
/// status carries no domain-specific meaning (in which case the caller
/// should let the original [HttpException] propagate).
DomainException? mapHttpStatusToDomain(int statusCode) {
  if (statusCode == 401 || statusCode == 403) return const UnauthorizedException();
  if (statusCode == 404) return const NotFoundException();
  if (statusCode == 409) return const ConflictException();
  if (statusCode >= 500 && statusCode < 600) return ServerException(statusCode);
  return null;
}
