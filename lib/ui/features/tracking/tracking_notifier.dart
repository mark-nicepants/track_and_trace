import 'dart:async';

import 'package:app/domain/use_cases/enqueue_position.dart';
import 'package:app/shared/contracts/i_foreground_tracking_service.dart';
import 'package:app/shared/contracts/i_location_client.dart';
import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:app/shared/contracts/i_sending_service.dart';
import 'package:app/shared/inject.dart';
import 'package:app/ui/features/tracking/tracking_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drives the LocationService loop for one tracking session:
///   1. Sets `EXITED_CORRECTLY=false` (primes US-010 crash detection).
///   2. Starts the foreground service + Dutch notification.
///   3. Subscribes to [ILocationClient] and enqueues each fix into
///      [PositionQueueRepository] via the [EnqueuePosition] use case.
///   4. Starts the [ISendingService] (US-007) so queued rows drain into
///      `/create-locations` while tracking is active.
///   5. On clean [stop], cancels the subscription, stops the sending
///      service, stops the foreground service, and sets
///      `EXITED_CORRECTLY=true`.
///
/// Widgets must read state through this notifier — they never touch the
/// tracelet or flutter_foreground_task plugins directly. See the
/// architecture check (`tool/check_architecture_violations.dart`).
class TrackingNotifier extends Notifier<bool> {
  StreamSubscription<LocationFix>? _subscription;
  Future<void> _writeChain = Future.value();

  IPreferenceService get _prefs => inject();
  ILocationClient get _client => inject();
  IForegroundTrackingService get _fg => inject();
  ISendingService get _sender => inject();

  @override
  bool build() {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      _subscription = null;
    });
    return false;
  }

  bool get isTracking => state;

  Future<void> start() async {
    if (state) return;
    await _prefs.writeString(exitedCorrectlyKey, 'false');
    await _fg.start(title: trackingNotificationTitle, body: trackingNotificationBody);
    await _sender.start();
    _writeChain = Future.value();
    _subscription = _client.watch(interval: const Duration(seconds: 1)).listen((fix) {
      _writeChain = _writeChain.then((_) async {
        await EnqueuePosition(fix, null).call();
      });
    });
    state = true;
  }

  Future<void> stop() async {
    if (!state) return;
    await _subscription?.cancel();
    _subscription = null;
    await _writeChain;
    await _sender.stop();
    await _fg.stop();
    await _prefs.writeString(exitedCorrectlyKey, 'true');
    state = false;
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, bool>(TrackingNotifier.new);
