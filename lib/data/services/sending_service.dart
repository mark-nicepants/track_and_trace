import 'dart:async';

import 'package:app/data/data_source/position_queue_entry.dart';
import 'package:app/data/models/create_locations_request_dto.dart';
import 'package:app/data/models/tracking_position_dto.dart';
import 'package:app/data/repositories/position_queue_repository.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/shared/contracts/i_connectivity_service.dart';
import 'package:app/shared/contracts/i_logger.dart';
import 'package:app/shared/contracts/i_sending_service.dart';
import 'package:app/shared/inject.dart';

/// Drains the local [PositionQueueRepository] into `/create-locations` in
/// batches of up to [batchSize] rows. Mirrors the Android reference's
/// `SendingService` loop (see `old_android_app_reference/.../feature_api/
/// SendingService.kt`):
///
///   1. Read up to 5 oldest rows.
///   2. If empty → wait [retryDelay] (or wake on reconnect / new positions
///      arriving — see [LocationService]).
///   3. POST `/create-locations`. On success → delete those exact rows.
///   4. On failure → wait [retryDelay], try again.
///
/// Connectivity is gated by [IConnectivityService]: when offline, the loop
/// parks on a [Completer] until a `true` event wakes it. The loop body
/// never overlaps with itself — only one `_runLoop` future exists per
/// [start]/[stop] cycle, so multiple connectivity events while a POST is
/// in flight cannot cause two concurrent drains (and therefore no
/// double-delete of the same row IDs).
///
/// [retryDelay] defaults to 5 s (Android parity). Tests pass a shorter
/// duration to keep the suite fast.
class SendingService implements ISendingService {
  SendingService({this.retryDelay = const Duration(seconds: 5)});

  /// Mirrors `Constants.maxNumPositionsToSend` in the Android reference.
  static const int batchSize = 5;

  /// Backoff between POST failures and empty-queue polls. Production uses
  /// 5 s; tests override to shrink the loop.
  final Duration retryDelay;

  PositionQueueRepository get _queue => inject();
  TrackAndTraceRepository get _api => inject();
  IConnectivityService get _connectivity => inject();
  ILogger get _log => inject();

  bool _running = false;
  bool _online = true;
  StreamSubscription<bool>? _connSub;
  Future<void>? _loopFuture;
  Completer<void>? _wake;
  final StreamController<int> _depthController = StreamController<int>.broadcast();

  @override
  bool get isRunning => _running;

  @override
  Stream<int> get queueDepth => _depthController.stream;

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _online = await _connectivity.check();
    _connSub = _connectivity.changes.listen(_onConnectivityChanged);
    _depthController.add(await _queue.count());
    _loopFuture = _runLoop();
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _wake?.complete();
    _wake = null;
    final loop = _loopFuture;
    _loopFuture = null;
    await loop;
    await _connSub?.cancel();
    _connSub = null;
  }

  void _onConnectivityChanged(bool online) {
    final wasOffline = !_online;
    _online = online;
    if (wasOffline && online) {
      // Wake the loop if it's parked (offline-wait or retry-sleep).
      _wake?.complete();
      _wake = null;
    }
  }

  Future<void> _runLoop() async {
    while (_running) {
      if (!_online) {
        await _wait(null);
        continue;
      }

      final List<PositionQueueEntry> entries;
      try {
        entries = await _queue.getFirstN(batchSize);
      } catch (e, st) {
        _log.error('SendingService: queue read failed', e, st);
        await _wait(retryDelay);
        continue;
      }

      if (entries.isEmpty) {
        await _wait(retryDelay);
        continue;
      }

      final ids = [for (final e in entries) e.id];
      final request = CreateLocationsRequestDto([
        for (final e in entries) TrackingPositionDto(e.time, e.lat, e.lon, e.runId),
      ]);

      try {
        await _api.createLocations(request);
      } catch (e, st) {
        _log.warning('SendingService: createLocations failed', e, st);
        await _wait(retryDelay);
        continue;
      }

      try {
        await _queue.deleteByIds(ids);
        _depthController.add(await _queue.count());
      } catch (e, st) {
        _log.error('SendingService: queue delete failed', e, st);
        await _wait(retryDelay);
      }
    }
  }

  /// Parks the loop until either:
  ///   - [stop] is called (completes the wake completer),
  ///   - connectivity flips back to online (completes the wake completer),
  ///   - [maxDelay] elapses (`null` means wait indefinitely — used for the
  ///     offline state, where only a reconnect or stop should resume).
  Future<void> _wait(Duration? maxDelay) async {
    if (!_running) return;
    final wake = Completer<void>();
    _wake = wake;
    if (maxDelay == null) {
      await wake.future;
    } else {
      Timer? timer;
      timer = Timer(maxDelay, () {
        if (!wake.isCompleted) wake.complete();
      });
      await wake.future;
      timer.cancel();
    }
    if (identical(_wake, wake)) _wake = null;
  }
}
