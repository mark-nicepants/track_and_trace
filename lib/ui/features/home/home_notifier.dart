import 'package:app/domain/entities/user.dart';
import 'package:app/domain/use_cases/get_current_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserProvider = FutureProvider.autoDispose<User>((ref) async {
  return GetCurrentUser().call();
});
