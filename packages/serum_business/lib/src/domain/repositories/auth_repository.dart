import 'dart:async';

import '../../data/auths_data_source.dart';
import '../../serum_client.dart';
import '../../services/token_storage.dart';
import '../../tools/token_manager.dart';
import '../models/auth_model/auth_models.dart';

class AuthRepository {
  final AuthsDataSource dataSource;
  final TokenStorage tokenStorage;

  Completer<RefreshTokenResponse?>? _refreshCompleter;

  AuthRepository({
    required this.dataSource,
    required this.tokenStorage,
  });

  Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) async {
    final request = LoginRequest.fromInput(identifier, password);
    final res = await dataSource.login(request.toJson());
    final response = LoginResponse.fromJson(res);

    await tokenStorage.saveTokens(
      token: response.token,
      refreshToken: response.refreshToken,
    );
    SerumClient.instance.authToken = response.token;

    return response;
  }

  /// Verifica si el session token vence dentro de los próximos [threshold] (por defecto 10 minutos).
  /// Si está cerca de vencer o ya venció, solicita automáticamente un nuevo par de tokens.
  Future<String?> ensureValidToken({
    Duration threshold = const Duration(minutes: 10),
  }) async {
    final currentToken = await tokenStorage.getToken();
    if (currentToken == null || currentToken.isEmpty) {
      return null;
    }

    if (TokenManager.isTokenExpiringSoon(currentToken, threshold: threshold)) {
      final refreshed = await refreshToken();
      return refreshed?.token;
    }

    SerumClient.instance.authToken = currentToken;
    return currentToken;
  }

  Future<RefreshTokenResponse?> refreshToken() async {
    // Si ya hay un refresco en progreso, esperar ese mismo resultado
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<RefreshTokenResponse?>();

    try {
      final currentRefreshToken = await tokenStorage.getRefreshToken();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        await logout();
        _refreshCompleter!.complete(null);
        return null;
      }

      final request = RefreshTokenRequest(refreshToken: currentRefreshToken);
      final res = await dataSource.refreshToken(request.toJson());
      final response = RefreshTokenResponse.fromJson(res);

      await tokenStorage.saveTokens(
        token: response.token,
        refreshToken: response.refreshToken,
      );
      SerumClient.instance.authToken = response.token;

      _refreshCompleter!.complete(response);
      return response;
    } catch (e) {
      await logout();
      _refreshCompleter!.complete(null);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Realiza un llamado liviano al servidor (/check-user) para verificar si el usuario
  /// fue desactivado o eliminado lógicamente desde que se emitió la sesión.
  Future<CheckUserResponse> checkUser() async {
    final token = await ensureValidToken();
    if (token == null || token.isEmpty) {
      return CheckUserResponse(status: 'unactive');
    }

    final request = CheckUserRequest(token: token);
    final res = await dataSource.checkUser(request.toJson());
    return CheckUserResponse.fromJson(res);
  }

  Future<void> logout() async {
    await tokenStorage.clearTokens();
    SerumClient.instance.authToken = '';
  }
}
