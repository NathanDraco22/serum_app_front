import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'app_session_state.dart';

class AppSessionCubit extends Cubit<AppSessionState> {
  final AuthRepository authRepository;
  final UsersDataSource usersDataSource;

  AppSessionCubit({
    required this.authRepository,
    UsersDataSource? usersDataSource,
  }) : usersDataSource = usersDataSource ?? UsersDataSource(),
       super(const AppSessionState());

  /// Inicializa la sesión usando los tokens guardados.
  /// Si el token de sesión está a menos de 10 minutos de vencer (o ya venció),
  /// se refresca automáticamente antes de continuar.
  /// Posteriormente ejecuta `checkUser()` para confirmar si el usuario no fue desactivado/eliminado.
  Future<void> initSession() async {
    emit(state.copyWith(status: AppSessionStatus.initial, clearError: true));

    try {
      // Garantizar que contemos con un token válido (refresca si le quedan <= 10 min)
      final token = await authRepository.ensureValidToken(
        threshold: const Duration(minutes: 10),
      );

      if (token == null || token.isEmpty) {
        emit(state.copyWith(status: AppSessionStatus.unauthenticated, clearUser: true));
        return;
      }

      // Llamado liviano para validar el estado actual del usuario en la BD
      final check = await authRepository.checkUser();
      if (check.isUnactive) {
        emit(state.copyWith(status: AppSessionStatus.accountInactive, clearUser: true));
        return;
      }
      if (check.isDeleted) {
        emit(state.copyWith(status: AppSessionStatus.accountDeleted, clearUser: true));
        return;
      }

      // Sesión activa y válida
      await _fetchAndSetCurrentUser();
    } catch (e) {
      await authRepository.logout();
      emit(
        state.copyWith(
          status: AppSessionStatus.unauthenticated,
          clearUser: true,
          errorMessage: 'Sesión expirada o no válida.',
        ),
      );
    }
  }

  /// Autentica al usuario con username, email o teléfono y contraseña
  Future<bool> login(String identifier, String password) async {
    emit(state.copyWith(status: AppSessionStatus.authenticating, clearError: true));

    try {
      final response = await authRepository.login(
        identifier: identifier,
        password: password,
      );

      if (!response.user.isActive) {
        emit(
          state.copyWith(
            status: AppSessionStatus.accountInactive,
            errorMessage: 'Esta cuenta se encuentra desactivada.',
          ),
        );
        return false;
      }

      if (response.user.isDeleted) {
        emit(
          state.copyWith(
            status: AppSessionStatus.accountDeleted,
            errorMessage: 'Esta cuenta ha sido eliminada.',
          ),
        );
        return false;
      }

      emit(
        state.copyWith(
          status: AppSessionStatus.authenticated,
          currentUser: response.user,
          clearError: true,
        ),
      );
      return true;
    } on UnauthorizedException {
      emit(
        state.copyWith(
          status: AppSessionStatus.unauthenticated,
          errorMessage: 'Credenciales inválidas. Por favor verifique sus datos.',
        ),
      );
      return false;
    } catch (e) {
      emit(
        state.copyWith(
          status: AppSessionStatus.error,
          errorMessage: 'Error de conexión: ${e.toString()}',
        ),
      );
      return false;
    }
  }

  /// Cierra la sesión activa y limpia los tokens guardados
  Future<void> logout() async {
    await authRepository.logout();
    emit(
      state.copyWith(
        status: AppSessionStatus.unauthenticated,
        clearUser: true,
        clearCashRegister: true,
        clearError: true,
      ),
    );
  }

  /// Selecciona la caja registradora activa para operar
  void selectCashRegister(CashRegisterInDb cashRegister) {
    emit(state.copyWith(activeCashRegister: cashRegister));
  }

  /// Limpia la caja seleccionada
  void clearCashRegister() {
    emit(state.copyWith(clearCashRegister: true));
  }

  Future<void> _fetchAndSetCurrentUser() async {
    try {
      final res = await usersDataSource.getAllUsers();
      final list = (res['items'] as List<dynamic>?) ?? (res['data'] as List<dynamic>?) ?? [];
      if (list.isNotEmpty) {
        final user = UserInDb.fromJson(list.first as Map<String, dynamic>);
        emit(
          state.copyWith(
            status: AppSessionStatus.authenticated,
            currentUser: user,
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AppSessionStatus.authenticated,
            clearError: true,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: AppSessionStatus.authenticated,
          clearError: true,
        ),
      );
    }
  }
}
