import 'package:app/data/models/get_nearest_depot_request_dto.dart';
import 'package:app/data/repositories/track_and_trace_repository.dart';
import 'package:app/domain/converters/nearest_depot_converter.dart';
import 'package:app/domain/entities/nearest_depot.dart';
import 'package:app/domain/use_cases/use_case.dart';
import 'package:app/shared/clock.dart';
import 'package:app/shared/inject.dart';

/// Posts `/get-nearest-depot` for [runId] and returns the parsed entity.
/// Mirrors the Android reference's nearest-depot polling job in
/// `TrackingViewModel.startShowingNearestDepot`.
class GetNearestDepot(final String runId) extends UseCase<NearestDepot> {
  TrackAndTraceRepository get _repo => inject();
  IsoClock get _clock => inject();

  @override
  Future<NearestDepot> execute() async {
    final dto = await _repo.getNearestDepot(GetNearestDepotRequestDto(runId, _clock.nowIso()));
    return dto.toEntity();
  }
}
