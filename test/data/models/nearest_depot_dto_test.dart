import 'package:app/data/models/nearest_depot_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson/toJson round-trip preserves all fields', () {
    final json = <String, Object?>{'name': 'Depot A'};

    final dto = NearestDepotDto.fromJson(json);
    expect(dto.name, 'Depot A');
    expect(dto.toJson(), json);
  });
}
