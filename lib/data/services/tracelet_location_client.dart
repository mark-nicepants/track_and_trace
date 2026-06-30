import 'dart:async';

import 'package:app/shared/contracts/i_location_client.dart';
import 'package:tracelet/tracelet.dart' as tl;

/// Production [ILocationClient] backed by the `tracelet` plugin.
///
/// FEATURES.md §13.x defaults to `background_location`; we override that
/// choice here because tracelet ships with battery-aware filtering, a
/// configurable foreground-service notification, and built-in
/// SQLite-backed persistence that we'll wire into the queue uploader in
/// later stories. Two background-location plugins cannot coexist on one
/// device (FEATURES.md §"Suggested Tiny Additions"), so the decision is
/// locked at this layer.
///
/// `interval` is honored by setting `GeoConfig.distanceFilter: 0`, which
/// emits every native GPS update (the platform default rate is ~1 Hz on
/// the high-accuracy provider). The plugin's own foreground notification
/// is kept silent — the persistent notification visible to the driver is
/// hosted by [IForegroundTrackingService] (flutter_foreground_task) per
/// the story.
class TraceletLocationClient implements ILocationClient {
  const TraceletLocationClient();

  @override
  Stream<LocationFix> watch({required Duration interval}) {
    final controller = StreamController<LocationFix>();
    StreamSubscription<tl.Location>? sub;

    Future<void> startNative() async {
      await tl.Tracelet.ready(
        const tl.Config(
          geo: tl.GeoConfig(distanceFilter: 0, desiredAccuracy: tl.DesiredAccuracy.high),
          // tracelet 3.x moved location-authorization configuration out of
          // GeoConfig and into the iOS-specific config block.
          ios: tl.IosConfig(locationAuthorizationRequest: tl.LocationAuthorizationRequest.always),
        ),
      );
      await tl.Tracelet.start();
      sub = tl.Tracelet.locationStream.listen((loc) {
        controller.add(LocationFix(loc.coords.latitude, loc.coords.longitude, loc.timestamp));
      });
    }

    controller.onListen = () {
      unawaited(startNative());
    };
    controller.onCancel = () async {
      await sub?.cancel();
      sub = null;
      await tl.Tracelet.stop();
    };

    return controller.stream;
  }
}
