import 'package:equatable/equatable.dart';

/// A single GPS sample emitted by the device while tracking a run.
///
/// `time` is the ISO-formatted timestamp (see `IsoClock`). `runId` may be
/// null only while the sample is in flight before being associated with a
/// run (matches the Android reference's `var runId: String? = null`).
class TrackingPosition(final String time, final num latitude, final num longitude, final String? runId)
    extends Equatable {
  TrackingPosition copyWith({String? time, num? latitude, num? longitude, String? runId}) =>
      TrackingPosition(time ?? this.time, latitude ?? this.latitude, longitude ?? this.longitude, runId ?? this.runId);

  bool get isValid {
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    if (runId == null) return false;
    return true;
  }

  @override
  List<Object?> get props => [time, latitude, longitude, runId];
}
