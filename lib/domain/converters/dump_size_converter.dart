import 'package:app/data/models/dump_size_dto.dart';
import 'package:app/domain/entities/dump_size.dart';

extension DumpSizeDtoX on DumpSizeDto {
  /// Returns the `DumpSize` parsed from the DTO's `quantity` field. Unknown
  /// values fall back to [DumpSize.unspecified] (matches the Android
  /// reference's `fromString` behaviour).
  DumpSize toEntity() => DumpSize.fromWire(quantity);
}

/// Constructs a [DumpSizeDto] for a `(runId, time, dumpSize)` triple.
///
/// The reverse direction is a free function — not an extension on
/// [DumpSize] — because the DTO carries runId + time that the enum has
/// no knowledge of.
DumpSizeDto dumpSizeDtoOf({required String runId, required String time, required DumpSize dumpSize}) =>
    DumpSizeDto(runId, time, dumpSize.wireName);
