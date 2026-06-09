import 'package:app/data/repositories/user_repository.dart';
import 'package:app/domain/converters/user_converter.dart';
import 'package:app/domain/entities/user.dart';
import 'package:app/domain/use_cases/use_case.dart';
import 'package:app/shared/inject.dart';

class GetCurrentUser implements UseCase<User> {
  UserRepository get _repo => inject();

  @override
  Future<User> call() async => (await _repo.fetchMe()).toEntity();
}
