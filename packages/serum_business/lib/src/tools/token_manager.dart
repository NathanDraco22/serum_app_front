import 'dart:convert';

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

  /// Decodifica el payload JSON de un token JWT
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalizedPayload = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalizedPayload));
      return jsonDecode(payloadString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Retorna true si el token ya expiró o si expirará dentro de los próximos [threshold] (por defecto 10 minutos).
  /// Asume que los claims de expiración (`exp`) vienen en segundos Unix según el estándar RFC 7519.
  static bool isTokenExpiringSoon(
    String token, {
    Duration threshold = const Duration(minutes: 10),
  }) {
    final payload = decodePayload(token);
    if (payload == null) return true;

    final expRaw = payload['exp'];
    if (expRaw is! int) return true;

    final expMs = expRaw * 1000;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = expMs - nowMs;

    return remainingMs <= threshold.inMilliseconds;
  }

  bool isTokenGotExpired(String token) {
    return isTokenExpiringSoon(token, threshold: Duration.zero);
  }
}
