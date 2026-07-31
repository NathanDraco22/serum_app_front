abstract class TokenStorage {
  Future<void> saveTokens({required String token, required String refreshToken});
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}

class InMemoryTokenStorage implements TokenStorage {
  String? _token;
  String? _refreshToken;

  @override
  Future<void> saveTokens({required String token, required String refreshToken}) async {
    _token = token;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<String?> getRefreshToken() async {
    return _refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    _token = null;
    _refreshToken = null;
  }
}
