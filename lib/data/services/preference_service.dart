import 'package:app/shared/contracts/i_preference_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService implements IPreferenceService {
  SharedPreferences? _prefsCache;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<SharedPreferences> get _prefs async => _prefsCache ??= await SharedPreferences.getInstance();

  @override
  Future<String?> readString(String key) async => (await _prefs).getString(key);

  @override
  Future<void> writeString(String key, String value) async => (await _prefs).setString(key, value);

  @override
  Future<void> removeString(String key) async {
    await (await _prefs).remove(key);
  }

  @override
  Future<String?> readSecure(String key) => _secure.read(key: key);

  @override
  Future<void> writeSecure(String key, String value) => _secure.write(key: key, value: value);

  @override
  Future<void> removeSecure(String key) => _secure.delete(key: key);
}
