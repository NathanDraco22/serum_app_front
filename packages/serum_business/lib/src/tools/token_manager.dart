class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  String _currentSessionToken = "";

  void storeToken(String token) {
    _currentSessionToken = token;
  }

  String getToken() {
    if (_currentSessionToken.isEmpty) {
      throw Exception("Token not found");
    }
    return _currentSessionToken;
  }

  void removeToken() => _currentSessionToken = "";

  bool isTokenGotExpired(String token) {
    return false;
  }
}
