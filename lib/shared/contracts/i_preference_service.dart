abstract interface class IPreferenceService {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
  Future<void> removeString(String key);

  Future<String?> readSecure(String key);
  Future<void> writeSecure(String key, String value);
  Future<void> removeSecure(String key);
}
