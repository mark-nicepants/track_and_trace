import 'package:app/domain/converters/nearest_depot_converter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  test('DTO → entity round-trips', () {
    final original = nearestDepot(name: 'Depot Z');
    expect(original.toDto().toEntity(), original);
  });
}
