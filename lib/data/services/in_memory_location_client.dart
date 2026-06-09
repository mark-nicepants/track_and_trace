import 'dart:async';

import 'package:app/shared/contracts/i_location_client.dart';

/// Test double for [ILocationClient]. Tests call [emit] to push scripted
/// fixes into the active subscription; [watchCallCount] / [isActive] can be
/// asserted to verify the notifier started/cancelled the stream correctly.
class InMemoryLocationClient implements ILocationClient {
  final List<Duration> watchIntervals = [];
  StreamController<LocationFix>? _controller;

  int get watchCallCount => watchIntervals.length;
  bool get isActive => _controller != null && !_controller!.isClosed;

  @override
  Stream<LocationFix> watch({required Duration interval}) {
    watchIntervals.add(interval);
    // `sync: true` ensures [emit] invokes the listener synchronously inside
    // `add`, so tests can chain emit() calls and then `await notifier.stop()`
    // with a fully-built write chain — no microtask races.
    final controller = StreamController<LocationFix>.broadcast(sync: true);
    _controller = controller;
    controller.onCancel = () {
      controller.close();
      if (identical(_controller, controller)) _controller = null;
    };
    return controller.stream;
  }

  /// Pushes [fix] to the live subscription, if any.
  void emit(LocationFix fix) {
    final c = _controller;
    if (c == null || c.isClosed) return;
    c.add(fix);
  }
}
