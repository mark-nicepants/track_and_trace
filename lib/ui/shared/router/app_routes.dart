import 'package:app/ui/features/crash/crash_page.dart';
import 'package:app/ui/features/dev/env_switcher_page.dart';
import 'package:app/ui/features/main/main_page.dart';
import 'package:app/ui/features/setup/setup_page.dart';
import 'package:app/ui/features/setup_permissions/setup_permissions_page.dart';
import 'package:app/ui/features/tracking/tracking_page.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> get appRoutes => [
  MainPage.route(),
  SetupPermissionsPage.route(),
  SetupPage.route(),
  TrackingPage.route(),
  CrashPage.route(),
  EnvSwitcherPage.route(),
];
