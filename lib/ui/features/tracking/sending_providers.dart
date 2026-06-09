import 'package:app/shared/contracts/i_connectivity_service.dart';
import 'package:app/shared/contracts/i_sending_service.dart';
import 'package:app/shared/inject.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` when at least one network interface is up. Seeded via
/// [IConnectivityService.check] so listeners see the current state
/// immediately, then driven by [IConnectivityService.changes].
///
/// The tracking screen's `NoNetworkDialog` keys off this provider.
final networkAvailableProvider = StreamProvider<bool>((ref) async* {
  final service = inject<IConnectivityService>();
  yield await service.check();
  yield* service.changes;
});

/// Remaining rows in the on-device position queue. Emits after each
/// [ISendingService] drain cycle (plus once on start). The UI surfaces
/// this as a small queue-depth indicator while tracking is active.
final queueDepthProvider = StreamProvider<int>((ref) {
  return inject<ISendingService>().queueDepth;
});
