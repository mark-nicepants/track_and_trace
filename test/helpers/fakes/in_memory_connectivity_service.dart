import 'dart:async';

import 'package:app/shared/contracts/i_connectivity_service.dart';

/// Test double for [IConnectivityService]. Tests script the stream via
/// [emit]; [check] returns whatever the most recent emission was (or the
/// `initial` value passed at construction).
///
/// Uses `broadcast(sync: true)` so a test that calls `emit(false)` and
/// immediately stops the SendingService observes the transition before
/// the listener cancels (mirrors [InMemoryLocationClient]).
class InMemoryConnectivityService implements IConnectivityService {
  InMemoryConnectivityService({bool initial = true}) : _current = initial;

  bool _current;
  final StreamController<bool> _controller = StreamController<bool>.broadcast(sync: true);

  /// Pushes a new connectivity state through the stream and updates the
  /// snapshot returned by [check].
  void emit(bool online) {
    _current = online;
    _controller.add(online);
  }

  @override
  Future<bool> check() async => _current;

  @override
  Stream<bool> get changes => _controller.stream;

  /// Releases the underlying controller. Most tests can rely on garbage
  /// collection, but call this in `tearDown` if a test is assertion-strict
  /// about leftover subscribers.
  Future<void> dispose() => _controller.close();
}
