import 'package:app/ui/features/main/main_page.dart';
import 'package:app/ui/features/setup/setup_page.dart';
import 'package:app/ui/features/setup/setup_saved_provider.dart';
import 'package:app/ui/features/setup_permissions/permissions_notifier.dart';
import 'package:app/ui/features/setup_permissions/permissions_state.dart';
import 'package:app/ui/features/setup_permissions/setup_permissions_page.dart';
import 'package:app/ui/features/tracking/tracking_page.dart';
import 'package:app/ui/shared/router/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);

  ref.listen<AsyncValue<PermissionsState>>(permissionsProvider, (_, _) => refresh.value++);
  ref.listen<AsyncValue<bool>>(setupSavedProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: MainPage.path,
    refreshListenable: refresh,
    routes: appRoutes,
    redirect: (context, state) {
      if (state.matchedLocation != MainPage.path) return null;

      final perms = ref.read(permissionsProvider);
      final setupDone = ref.read(setupSavedProvider);

      if (perms.isLoading || setupDone.isLoading) return null;

      final allGranted = perms.value?.allGranted ?? false;
      if (!allGranted) return SetupPermissionsPage.path;

      final hasSetup = setupDone.value ?? false;
      return hasSetup ? TrackingPage.path : SetupPage.path;
    },
  );
});
