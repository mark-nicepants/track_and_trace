import 'package:equatable/equatable.dart';

/// A machine the user can start a run with (truck, loader, ...).
class MachineType(final String id, final String displayName) extends Equatable {
  MachineType copyWith({String? id, String? displayName}) =>
      MachineType(id ?? this.id, displayName ?? this.displayName);

  @override
  List<Object?> get props => [id, displayName];
}
