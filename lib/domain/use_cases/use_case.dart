/// Base contract for one-shot operations.
///
/// Implementations:
/// - Resolve internal dependencies via private `inject<T>()` getters.
/// - Accept per-call inputs as constructor parameters.
/// - Are stateless beyond their constructor parameters.
abstract class UseCase<R> {
  Future<R> call();
}

/// Base contract for stream-producing operations.
abstract class StreamUseCase<R> {
  Stream<R> call();
}
