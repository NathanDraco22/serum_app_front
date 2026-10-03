import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../config/app_serum_config.dart';

part 'app_session_state.dart';

class AppSessionCubit extends Cubit<AppSessionState> {
  final AuthRepository authRepository;
  final BranchesRepository branchesRepository;
  final CashShiftsRepository? cashShiftsRepository;
  final UsersDataSource usersDataSource;

  AppSessionCubit({
    required this.authRepository,
    required this.branchesRepository,
    this.cashShiftsRepository,
    UsersDataSource? usersDataSource,
  })  : usersDataSource = usersDataSource ?? UsersDataSource(),
        super(const AppSessionState());

  String get currentBranchId => state.currentBranch?.id ?? kOriginBranchId;
  BranchInDb? get currentBranch => state.currentBranch;
  List<BranchInDb> get branches => state.branches;
  String get currentBranchName =>
      state.currentBranch?.name ?? 'Sucursal Matriz (ORIGIN_BRANCH)';
  UserInDb? get user => state.currentUser;
  CashShiftInDb? get activeShift => state.activeShift;
  bool get hasActiveShift => state.hasActiveShift;

  bool get hasMultipleBranches {
    final currentUser = state.currentUser;
    if (currentUser == null) return false;
    final isAdmin = currentUser.role.toLowerCase() == 'admin';
    return isAdmin || currentUser.branches.length > 1;
  }

  BranchInDb? getBranchById(String id) {
    try {
      return state.branches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

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
        emit(
          state.copyWith(
            status: AppSessionStatus.unauthenticated,
            clearUser: true,
            clearBranch: true,
            clearCashRegister: true,
            clearActiveShift: true,
          ),
        );
        return;
      }

      // Llamado liviano para validar el estado actual del usuario en la BD
      final check = await authRepository.checkUser();
      if (check.isUnactive) {
        emit(state.copyWith(
            status: AppSessionStatus.accountInactive, clearUser: true));
        return;
      }
      if (check.isDeleted) {
        emit(state.copyWith(
            status: AppSessionStatus.accountDeleted, clearUser: true));
        return;
      }

      // Sesión activa y válida
      await _fetchAndSetCurrentUser();
    } catch (e) {
      await authRepository.logout();
      AppSerumConfig().setBranchId(null);
      emit(
        state.copyWith(
          status: AppSessionStatus.unauthenticated,
          clearUser: true,
          clearBranch: true,
          clearCashRegister: true,
          clearActiveShift: true,
          errorMessage: 'Sesión expirada o no válida.',
        ),
      );
    }
  }

  /// Autentica al usuario con username, email o teléfono y contraseña
  Future<bool> login(String identifier, String password) async {
    emit(state.copyWith(
        status: AppSessionStatus.authenticating, clearError: true));

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

      await _setupBranchesAndUser(response.user);
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

  /// Cambia la sucursal activa y actualiza la configuración de red
  Future<void> changeBranch(String branchId) async {
    try {
      BranchInDb? branch = getBranchById(branchId);
      branch ??= await branchesRepository.getBranchById(branchId);

      if (branch == null && branchId == kOriginBranchId) {
        branch = BranchInDb(
          id: kOriginBranchId,
          name: 'Sucursal Matriz (ORIGIN_BRANCH)',
          address: 'Matriz Principal',
          phone: '',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
      }

      if (branch == null) {
        throw Exception("Sucursal no encontrada");
      }

      AppSerumConfig().setBranchId(branch.id);

      emit(
        state.copyWith(
          currentBranch: branch,
          clearCashRegister: true,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  /// Cierra la sesión activa y limpia los tokens guardados
  Future<void> logout() async {
    await authRepository.logout();
    AppSerumConfig().setBranchId(null);
    emit(
      state.copyWith(
        status: AppSessionStatus.unauthenticated,
        clearUser: true,
        clearBranch: true,
        clearCashRegister: true,
        clearActiveShift: true,
        clearError: true,
      ),
    );
  }

  /// Consulta el turno activo del usuario actual
  Future<void> fetchActiveShift() async {
    final currentUser = state.currentUser;
    if (currentUser == null || cashShiftsRepository == null) return;
    try {
      final shift = await cashShiftsRepository!.getCurrentShift(currentUser.id);
      emit(
        state.copyWith(
          activeShift: shift,
          clearActiveShift: shift == null,
        ),
      );
    } catch (_) {}
  }

  /// Establece el turno activo
  void setActiveShift(CashShiftInDb shift) {
    emit(state.copyWith(activeShift: shift));
  }

  /// Limpia el turno activo
  void clearActiveShift() {
    emit(state.copyWith(clearActiveShift: true));
  }

  /// Selecciona la caja registradora activa para operar (retrocompatibilidad)
  void selectCashRegister(CashRegisterInDb cashRegister) {
    emit(state.copyWith(activeCashRegister: cashRegister));
  }

  /// Limpia la caja seleccionada (retrocompatibilidad)
  void clearCashRegister() {
    emit(state.copyWith(clearCashRegister: true));
  }

  Future<void> _fetchAndSetCurrentUser() async {
    try {
      final res = await usersDataSource.getAllUsers();
      final list = (res['items'] as List<dynamic>?) ??
          (res['data'] as List<dynamic>?) ??
          [];
      if (list.isNotEmpty) {
        final user = UserInDb.fromJson(list.first as Map<String, dynamic>);
        await _setupBranchesAndUser(user);
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

  Future<void> _setupBranchesAndUser(UserInDb user) async {
    List<BranchInDb> allBranches = [];
    try {
      allBranches = await branchesRepository.getAllBranches();
    } catch (_) {
      allBranches = branchesRepository.branches;
    }

    final defaultOriginBranch = BranchInDb(
      id: kOriginBranchId,
      name: 'Sucursal Matriz (ORIGIN_BRANCH)',
      address: 'Matriz Principal',
      phone: '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (allBranches.isEmpty) {
      allBranches = [defaultOriginBranch];
    } else if (!allBranches.any((b) => b.id == kOriginBranchId)) {
      allBranches = [defaultOriginBranch, ...allBranches];
    }

    final isAdmin = user.role.toLowerCase() == 'admin';
    final userBranches = isAdmin
        ? allBranches
        : allBranches.where((b) => user.branches.contains(b.id)).toList();

    final initBranchId = user.branches.firstOrNull ?? kOriginBranchId;

    BranchInDb selectedBranch = allBranches.firstWhere(
      (b) => b.id == initBranchId,
      orElse: () => allBranches.firstWhere(
        (b) => b.id == kOriginBranchId,
        orElse: () => allBranches.first,
      ),
    );

    AppSerumConfig().setBranchId(selectedBranch.id);

    final finalAvailableBranches =
        userBranches.isNotEmpty ? userBranches : allBranches;

    emit(
      state.copyWith(
        status: AppSessionStatus.authenticated,
        currentUser: user,
        currentBranch: selectedBranch,
        branches: finalAvailableBranches,
        clearError: true,
      ),
    );

    // Consultar turno activo tras configurar usuario
    await fetchActiveShift();
  }
}
