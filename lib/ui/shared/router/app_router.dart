import 'package:app/ui/features/home/home_page.dart';
import 'package:app/ui/shared/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(initialLocation: HomePage.path, routes: appRoutes);
});
