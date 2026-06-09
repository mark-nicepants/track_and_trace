import 'package:flutter_riverpod/flutter_riverpod.dart';

final setupPermissionsProvider = FutureProvider.autoDispose<String>((ref) async {
  return 'ready';
});
