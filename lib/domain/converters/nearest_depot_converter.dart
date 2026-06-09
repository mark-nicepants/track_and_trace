import 'package:app/data/models/nearest_depot_dto.dart';
import 'package:app/domain/entities/nearest_depot.dart';

extension NearestDepotDtoX on NearestDepotDto {
  NearestDepot toEntity() => NearestDepot(name);
}

extension NearestDepotX on NearestDepot {
  NearestDepotDto toDto() => NearestDepotDto(name);
}
