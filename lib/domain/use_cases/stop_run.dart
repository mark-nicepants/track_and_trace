import 'package:app/data/models/stop_run_request_dto.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/use_cases/use_case.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/inject.dart';

/// Posts `/stop-run` to close the active run. Mirrors the Android
/// reference's `doStopRunRequest` in `TrackingViewModel`.
class StopRun(final String runId) extends UseCase<void> {
  TrackAndTraceRepository get _repo => inject();
  IsoClock get _clock => inject();

  @override
  Future<void> call() => _repo.sendStopRun(StopRunRequestDto(runId, _clock.nowIso()));
}
