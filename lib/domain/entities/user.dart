import 'package:equatable/equatable.dart';

class User(final String id, final String name, final String? email) extends Equatable {
  User copyWith({String? id, String? name, String? email}) =>
      User(id ?? this.id, name ?? this.name, email ?? this.email);

  @override
  List<Object?> get props => [id, name, email];
}
