import 'package:hive_ce/hive.dart';
import 'hive_service.dart';
import 'token_storage.dart';

class HiveTokenStorage with HiveService implements TokenStorage {
  static const String _boxName = 'auth_tokens_box';
  static const String _keyToken = 'session_token';
  static const String _keyRefreshToken = 'refresh_token';

  Future<Box> get _box async => await getBox(_boxName);

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
