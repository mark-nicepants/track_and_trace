import 'package:app/shared/contracts/i_permission_service.dart';
import 'package:equatable/equatable.dart';

class PermissionsState(
  final PermissionState locationWhenInUse,
  final PermissionState locationAlways,
  final PermissionState notification,
) extends Equatable {
  static final PermissionsState initial = PermissionsState(
    PermissionState.denied,
    PermissionState.denied,
    PermissionState.denied,
  );

  bool get allGranted =>
      locationWhenInUse == PermissionState.granted &&
      locationAlways == PermissionState.granted &&
      notification == PermissionState.granted;

  bool get anyPermanentlyDenied =>
      locationWhenInUse == PermissionState.permanentlyDenied ||
      locationAlways == PermissionState.permanentlyDenied ||
      notification == PermissionState.permanentlyDenied;

  PermissionsState copyWith({
    PermissionState? locationWhenInUse,
    PermissionState? locationAlways,
    PermissionState? notification,
  }) => PermissionsState(
    locationWhenInUse ?? this.locationWhenInUse,
    locationAlways ?? this.locationAlways,
    notification ?? this.notification,
  );

  @override
  List<Object?> get props => [locationWhenInUse, locationAlways, notification];
}
