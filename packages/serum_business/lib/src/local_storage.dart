abstract class SessionStore {
  Future<void> storeSession(Map<String, dynamic> session);
  Future<Map<String, dynamic>?> getSession();
  Future<void> removeSession();
}

abstract class AppConfigStore {
  Future<void> setConfig(Map<String, dynamic> config);
  Future<Map<String, dynamic>?> getConfig();
  Future<void> clearConfig();
}
