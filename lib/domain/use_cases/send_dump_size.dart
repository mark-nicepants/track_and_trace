import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/converters/dump_size_converter.dart';
import 'package:app/domain/entities/dump_size.dart';
import 'package:app/domain/use_cases/use_case.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/inject.dart';

/// Posts `/create-dump-size` for the operator-chosen [dumpSize] on [runId].
///
/// Per FEATURES.md §5.4 this is fired in parallel with [SyncRunData] on
/// dump-dialog confirm; the duplication is intentional (two independent
/// server-side records for cross-validation), so callers should NOT
/// collapse the two into one.
class SendDumpSize(final String runId, final DumpSize dumpSize) extends UseCase<void> {
  TrackAndTraceRepository get _repo => inject();
  IsoClock get _clock => inject();

  @override
  Future<void> execute() => _repo.sendDumpSize(dumpSizeDtoOf(runId: runId, time: _clock.nowIso(), dumpSize: dumpSize));
}
