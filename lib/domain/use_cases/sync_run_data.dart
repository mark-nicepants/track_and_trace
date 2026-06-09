import 'package:app/data/models/sync_run_data_request_dto.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/entities/dump_size.dart';
import 'package:app/domain/use_cases/use_case.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/inject.dart';

/// Posts `/sync-run-data` for the operator-chosen [dumpSize] on [runId].
///
/// Per FEATURES.md §5.4 this is fired in parallel with [SendDumpSize] on
/// dump-dialog confirm. The two endpoints accept identical payloads
/// (`runId`, `time`, `quantity`) — the duplication is the backend's
/// cross-validation strategy and MUST be preserved on the port.
class SyncRunData(final String runId, final DumpSize dumpSize) extends UseCase<void> {
  TrackAndTraceRepository get _repo => inject();
  IsoClock get _clock => inject();

  @override
  Future<void> call() => _repo.sendSyncRunData(SyncRunDataRequestDto(runId, _clock.nowIso(), dumpSize.wireName));
}
