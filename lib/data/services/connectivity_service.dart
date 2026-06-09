import 'package:app/shared/contracts/i_connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Production [IConnectivityService] backed by `connectivity_plus`. Any
/// non-`none` interface (WiFi, cellular, ethernet, VPN, bluetooth) maps to
/// "available"; an exclusively-`none` result maps to "offline".
class ConnectivityService implements IConnectivityService {
  const ConnectivityService();

  @override
  Future<bool> check() async => _hasNetwork(await Connectivity().checkConnectivity());

  @override
  Stream<bool> get changes => Connectivity().onConnectivityChanged.map(_hasNetwork);

  static bool _hasNetwork(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);
}
