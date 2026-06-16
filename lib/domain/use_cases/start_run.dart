import 'package:app/data/models/start_run_request_dto.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/use_cases/use_case.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/inject.dart';

/// Posts `/create-run` for [machineTypeId] + [capacity] and returns the
/// freshly-minted `runId`. Mirrors the Android reference's
/// `doStartRunRequest` in `TrackingViewModel`.
class StartRun(final String machineTypeId, final num capacity) extends UseCase<String> {
  TrackAndTraceRepository get _repo => inject();
  IsoClock get _clock => inject();

  @override
  Future<String> execute() async {
    final response = await _repo.sendStartRun(StartRunRequestDto(_clock.nowIso(), machineTypeId, capacity.toDouble()));
    return response.runId;
  }
}
