/// One row in the local `position_queue` table. The [id] is assigned by
/// SQLite on insert and is the handle used by [deleteByIds].
///
/// The lat/lon/time/runId fields mirror the wire shape of
/// `TrackingPositionDto` so an uploader can map a queued row to a
/// `/create-locations` payload without an intermediate translation step.
class PositionQueueEntry(final int id, final num lat, final num lon, final String time, final String? runId) {
  factory PositionQueueEntry.fromRow(Map<String, Object?> row) => PositionQueueEntry(
    row['id']! as int,
    row['lat']! as num,
    row['lon']! as num,
    row['time']! as String,
    row['runId'] as String?,
  );
}
