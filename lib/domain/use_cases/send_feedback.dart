import 'package:app/data/models/feedback_dto.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/entities/activity_state.dart';
import 'package:app/domain/use_cases/use_case.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/inject.dart';

/// Posts `/create-feedback` for the operator-selected [activity] on
/// [runId]. Fire-and-forget at the call site — the notifier doesn't block
/// on this returning. Mirrors the Android reference's `onFeedback` in
/// `TrackingViewModel`.
class SendFeedback(final String runId, final ActivityState activity) extends UseCase<void> {
  TrackAndTraceRepository get _repo => inject();
  IsoClock get _clock => inject();

  @override
  Future<void> execute() => _repo.sendFeedback(FeedbackDto(runId, _clock.nowIso(), activity.wireName));
}
