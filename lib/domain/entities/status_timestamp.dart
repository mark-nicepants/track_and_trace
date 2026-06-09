import 'package:app/domain/entities/activity_state.dart';
import 'package:equatable/equatable.dart';

/// Pairs an [ActivityState] with the ISO-formatted moment it became active.
///
/// The Android reference stored this as `(Date, ActivityState)`; we keep
/// the timestamp as a string so it round-trips through the API without
/// timezone surprises.
class StatusTimestamp(final String time, final ActivityState name) extends Equatable {
  StatusTimestamp copyWith({String? time, ActivityState? name}) =>
      StatusTimestamp(time ?? this.time, name ?? this.name);

  @override
  List<Object?> get props => [time, name];
}
