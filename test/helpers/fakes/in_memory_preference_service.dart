import 'package:app/shared/contracts/i_preference_service.dart';

class InMemoryPreferenceService implements IPreferenceService {
  final Map<String, String> _store = {};
  final Map<String, String> _secureStore = {};

  @override
  Future<String?> readString(String key) async => _store[key];

  @override
  Future<void> writeString(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> removeString(String key) async {
    _store.remove(key);
  }

  @override
  Future<String?> readSecure(String key) async => _secureStore[key];

  @override
  Future<void> writeSecure(String key, String value) async {
    _secureStore[key] = value;
  }

  @override
  Future<void> removeSecure(String key) async {
    _secureStore.remove(key);
  }
}
