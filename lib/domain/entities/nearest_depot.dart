import 'package:equatable/equatable.dart';

/// Result of the "find the nearest depot" lookup. The reference API only
/// returns a name; latitude/longitude are not surfaced.
class NearestDepot(final String name) extends Equatable {
  NearestDepot copyWith({String? name}) => NearestDepot(name ?? this.name);

  @override
  List<Object?> get props => [name];
}
