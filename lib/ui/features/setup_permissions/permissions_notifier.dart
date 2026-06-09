import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:app/shared/inject.dart';
import 'package:app/ui/features/setup_permissions/permissions_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermissionsNotifier extends AsyncNotifier<PermissionsState> {
  IPermissionService get _service => inject();

  @override
  Future<PermissionsState> build() => _refresh();

  Future<PermissionsState> _refresh() async {
    final loc = await _service.getLocationWhenInUseStatus();
    final always = await _service.getLocationAlwaysStatus();
    final notif = await _service.getNotificationStatus();
    return PermissionsState(loc, always, notif);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_refresh);
  }

  Future<void> requestLocationWhenInUse() async {
    final result = await _service.requestLocationWhenInUse();
    state = AsyncData((state.value ?? PermissionsState.initial).copyWith(locationWhenInUse: result));
  }

  Future<void> requestLocationAlways() async {
    final result = await _service.requestLocationAlways();
    state = AsyncData((state.value ?? PermissionsState.initial).copyWith(locationAlways: result));
  }

  Future<void> requestNotification() async {
    final result = await _service.requestNotification();
    state = AsyncData((state.value ?? PermissionsState.initial).copyWith(notification: result));
  }

  Future<bool> openSettings() => _service.openSystemSettings();
}

final permissionsProvider = AsyncNotifierProvider<PermissionsNotifier, PermissionsState>(PermissionsNotifier.new);
