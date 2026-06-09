import 'package:equatable/equatable.dart';

/// User-supplied feedback that an activity (loading / driving / dumping)
/// happened at a given moment. `name` is the wire representation of the
/// activity (see `ActivityState.wireName`) and may be null when the user
/// clears a previous feedback.
class Feedback(final String runId, final String time, final String? name) extends Equatable {
  Feedback copyWith({String? runId, String? time, String? name}) =>
      Feedback(runId ?? this.runId, time ?? this.time, name ?? this.name);

  @override
  List<Object?> get props => [runId, time, name];
}
