import 'package:app/data/repositories/position_queue_repository.dart';
import 'package:app/domain/use_cases/use_case.dart';
import 'package:app/shared/contracts/i_location_client.dart';
import 'package:app/shared/inject.dart';

/// Persists a single GPS fix into the durable [PositionQueueRepository].
/// The uploader (later story) drains the queue and batches the rows into
/// `/create-locations` payloads. `runId` is optional — it stays null until
/// run management arrives.
class EnqueuePosition(final LocationFix fix, final String? runId) extends UseCase<int> {
  PositionQueueRepository get _repo => inject();

  @override
  Future<int> call() => _repo.insert(lat: fix.lat, lon: fix.lon, time: fix.time, runId: runId);
}
