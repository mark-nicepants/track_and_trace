import 'package:app/data/models/machine_type_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson/toJson round-trip preserves all fields', () {
    final json = <String, Object?>{'id': 'mt-1', 'displayName': 'Loader'};

    final dto = MachineTypeDto.fromJson(json);
    expect(dto.id, 'mt-1');
    expect(dto.displayName, 'Loader');
    expect(dto.toJson(), json);
  });
}
