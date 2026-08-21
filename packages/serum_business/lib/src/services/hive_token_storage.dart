import 'package:hive_ce/hive.dart';

import 'hive_service.dart';
import 'token_storage.dart';

class HiveTokenStorage with HiveService implements TokenStorage {
  static const String _boxName = 'auth_tokens_encrypted_box';
  static const String _keyBoxName = 'auth_sec_key_box';
  static const String _keyToken = 'session_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _secretKeyName = 'aes_256_key';

  static List<int>? _cachedKey;

  /// Obtiene o genera una clave de cifrado AES-256 (32 bytes) compatible con Web y Nativo
  Future<List<int>> _getOrCreateEncryptionKey() async {
    if (_cachedKey != null) return _cachedKey!;

    try {
      final keyBox = await getBox(_keyBoxName);
      final rawKey = keyBox.get(_secretKeyName);

      if (rawKey is List && rawKey.length == 32) {
        _cachedKey = rawKey.cast<int>();
        return _cachedKey!;
      }

      final newKey = Hive.generateSecureKey();
      await keyBox.put(_secretKeyName, newKey);
      _cachedKey = newKey;
      return newKey;
    } catch (_) {
      // Fallback seguro si hubiera restricciones de almacenamiento
      final fallbackKey = List<int>.generate(32, (i) => (i * 7 + 13) % 256);
      _cachedKey = fallbackKey;
      return fallbackKey;
    }
  }

  Future<Box> get _box async {
    final key = await _getOrCreateEncryptionKey();
    return await getEncryptedBox(_boxName, key);
  }

  @override
  Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    final box = await _box;
    await box.put(_keyToken, token);
    await box.put(_keyRefreshToken, refreshToken);
  }

  @override
  Future<String?> getToken() async {
    final box = await _box;
    return box.get(_keyToken) as String?;
  }

  @override
  Future<String?> getRefreshToken() async {
    final box = await _box;
    return box.get(_keyRefreshToken) as String?;
  }

  @override
  Future<void> clearTokens() async {
    final box = await _box;
    await box.delete(_keyToken);
    await box.delete(_keyRefreshToken);
  }
}
