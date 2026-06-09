import 'package:app/ui/features/dev/env_switcher_page.dart';
import 'package:app/ui/features/home/home_page.dart';
import 'package:app/ui/features/setup_permissions/setup_permissions_page.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> get appRoutes => [HomePage.route(), SetupPermissionsPage.route(), EnvSwitcherPage.route()];
