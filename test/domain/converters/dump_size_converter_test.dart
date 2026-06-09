import 'package:app/data/models/dump_size_dto.dart';
import 'package:app/domain/converters/dump_size_converter.dart';
import 'package:app/domain/entities/dump_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DTO → entity maps every known quantity', () {
    expect(DumpSizeDto('r', 't', 'QUARTER').toEntity(), DumpSize.quarter);
    expect(DumpSizeDto('r', 't', 'HALF').toEntity(), DumpSize.half);
    expect(DumpSizeDto('r', 't', 'THREEQUARTER').toEntity(), DumpSize.threeQuarter);
    expect(DumpSizeDto('r', 't', 'FULL').toEntity(), DumpSize.full);
    expect(DumpSizeDto('r', 't', 'UNSPECIFIED').toEntity(), DumpSize.unspecified);
  });

  test('DTO → entity falls back to unspecified for unknown values', () {
    expect(DumpSizeDto('r', 't', 'gibberish').toEntity(), DumpSize.unspecified);
  });

  test('dumpSizeDtoOf builds the wire shape from the enum', () {
    final dto = dumpSizeDtoOf(runId: 'r', time: 't', dumpSize: DumpSize.threeQuarter);
    expect(dto.runId, 'r');
    expect(dto.time, 't');
    expect(dto.quantity, 'THREEQUARTER');
    expect(dto.toEntity(), DumpSize.threeQuarter);
  });
}
