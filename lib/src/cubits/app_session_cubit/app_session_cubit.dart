import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../config/app_serum_config.dart';
import '../../../config/service_locator.dart';
import '../../core/app_config_manager.dart';
import '../../tools/cache/app_image_cache.dart';
import '../app_settings/app_settings_cubit.dart';

part 'app_session_state.dart';

class AppSessionCubit extends Cubit<AppSessionState> {
  final AuthRepository authRepository;
  final BranchesRepository branchesRepository;
  final ServinRepository servinRepository;
  final CashShiftsRepository? cashShiftsRepository;
  final UsersDataSource usersDataSource;
  StreamSubscription<RepoEvent<BranchInDb>>? _branchesSubscription;

  AppSessionCubit({
    required this.authRepository,
    required this.branchesRepository,
    required this.servinRepository,
    this.cashShiftsRepository,
    UsersDataSource? usersDataSource,
  })  : usersDataSource = usersDataSource ?? UsersDataSource(),
        super(const AppSessionState()) {
    _branchesSubscription =
        branchesRepository.eventStream.listen(_handleBranchEvent);
  }

  void _handleBranchEvent(RepoEvent<BranchInDb> event) {
    if (isClosed) return;
    if (!state.isAuthenticated || state.currentUser == null) return;
    if (!isRootUser) return;

    if (event is RepoItemCreated<BranchInDb>) {
      final existing = state.branches;
      if (!existing.any((b) => b.id == event.item.id)) {
        emit(state.copyWith(branches: [...existing, event.item]));
      }
    } else if (event is RepoItemUpdated<BranchInDb>) {
      final updatedList = state.branches
          .map((b) => b.id == event.item.id ? event.item : b)
          .toList();
      final updatedCurrent =
          state.currentBranch?.id == event.item.id ? event.item : state.currentBranch;
      emit(state.copyWith(
        branches: updatedList,
        currentBranch: updatedCurrent,
      ));
    } else if (event is RepoItemDeleted<BranchInDb>) {
      final updatedList =
          state.branches.where((b) => b.id != event.item.id).toList();
      emit(state.copyWith(branches: updatedList));
      if (state.currentBranch?.id == event.item.id) {
        final nextBranch = updatedList.firstOrNull;
        if (nextBranch != null) {
          changeBranch(nextBranch.id);
        }
      }
    }
  }

  String get currentBranchId => state.currentBranch?.id ?? kOriginBranchId;
  BranchInDb? get currentBranch => state.currentBranch;
  List<BranchInDb> get branches => state.branches;
  String get currentBranchName =>
      state.currentBranch?.name ?? 'Sucursal Matriz (ORIGIN_BRANCH)';
  UserInDb? get user => state.currentUser;
  Servin? get servin => state.servin;
  CashShiftInDb? get activeShift => state.activeShift;
  bool get hasActiveShift => state.hasActiveShift;
  bool get isRootUser => state.isRootUser;

  bool get hasMultipleBranches {
    final currentUser = state.currentUser;
    if (currentUser == null) return false;
    if (isRootUser) {
      return state.branches.length > 1;
    }
    return currentUser.branches.length > 1 && state.branches.length > 1;
  }

  BranchInDb? getBranchById(String id) {
    try {
      return state.branches.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Inicializa la sesión comprobando primero la activación de la instancia (Servin).
  /// Si no hay Servin configurado localmente, emite `unactivated`.
  /// Si existe Servin, actualiza configuración de red y consulta `/auths/servin-status`.
  /// Si la instancia está inactiva (`isActive == false`), emite `instanceInactive`.
  /// Luego verifica la sesión con tokens guardados y `checkUser()`.
  Future<void> initSession() async {
    emit(state.copyWith(status: AppSessionStatus.initial, clearError: true));

    try {
      final currentServin = await servinRepository.getCurrentServinFromLocal();
      if (currentServin == null) {
        emit(
          state.copyWith(
            status: AppSessionStatus.unactivated,
            clearUser: true,
            clearBranch: true,
            clearActiveShift: true,
            clearServin: true,
          ),
        );
        return;
      }

      // Configurar red con los datos de la instancia local
      _updateNetworkConfig(servin: currentServin);
      final savedBranchId = await AppConfigManager().getSelectedBranchId();
      if (savedBranchId != null && savedBranchId.isNotEmpty) {
        AppSerumConfig().setBranchId(savedBranchId);
      }

      // Refrescar y validar estado de la instancia con el backend tenant
      final refreshedServin = await servinRepository.refreshServinStatus();
      final activeServin = refreshedServin ?? currentServin;

      if (!activeServin.isActive) {
        emit(
          state.copyWith(
            status: AppSessionStatus.instanceInactive,
            servin: activeServin,
            clearUser: true,
            clearBranch: true,
            clearActiveShift: true,
          ),
        );
        return;
      }

      // Garantizar que contemos con un token válido (refresca si le quedan <= 10 min)
      final token = await authRepository.ensureValidToken(
        threshold: const Duration(minutes: 10),
      );

      if (token == null || token.isEmpty) {
        emit(
          state.copyWith(
            status: AppSessionStatus.unauthenticated,
            servin: activeServin,
            clearUser: true,
            clearBranch: true,
            clearActiveShift: true,
          ),
        );
        return;
      }

      // Llamado liviano para validar el estado actual del usuario en la BD
      final check = await authRepository.checkUser();
      if (check.isUnactive) {
        emit(
          state.copyWith(
            status: AppSessionStatus.accountInactive,
            servin: activeServin,
            clearUser: true,
          ),
        );
        return;
      }
      if (check.isDeleted) {
        emit(
          state.copyWith(
            status: AppSessionStatus.accountDeleted,
            servin: activeServin,
            clearUser: true,
          ),
        );
        return;
      }

      // Sesión activa y válida
      await _fetchAndSetCurrentUser(servin: activeServin);
    } catch (e) {
      await authRepository.logout();
      AppSerumConfig().setBranchId(null);
      final currentServin = await servinRepository.getCurrentServinFromLocal();
      emit(
        state.copyWith(
          status: currentServin == null
              ? AppSessionStatus.unactivated
              : AppSessionStatus.unauthenticated,
          servin: currentServin,
          clearUser: true,
          clearBranch: true,
          clearActiveShift: true,
          errorMessage: 'Sesión expirada o no válida.',
        ),
      );
    }
  }

  /// Autentica al usuario con username, email o teléfono y contraseña.
  /// Paralelamente valida el estado del Servin; si fue desactivado, redirige a inactivo.
  Future<bool> login(String identifier, String password) async {
    emit(state.copyWith(
        status: AppSessionStatus.authenticating, clearError: true));

    try {
      final currentServin = await servinRepository.getCurrentServinFromLocal();
      if (currentServin == null) {
        emit(state.copyWith(status: AppSessionStatus.unactivated));
        return false;
      }

      _updateNetworkConfig(servin: currentServin);

      // Ejecutar login y refresco de estado de instancia en paralelo
      final [responseObj, servinObj] = await Future.wait([
        authRepository.login(
          identifier: identifier,
          password: password,
        ),
        servinRepository.refreshServinStatus(),
      ]);

      final response = responseObj as LoginResponse;
      final refreshedServin = (servinObj as Servin?) ?? currentServin;

      if (!refreshedServin.isActive) {
        emit(
          state.copyWith(
            status: AppSessionStatus.instanceInactive,
            servin: refreshedServin,
            clearUser: true,
          ),
        );
        return false;
      }

      if (!response.user.isActive) {
        emit(
          state.copyWith(
            status: AppSessionStatus.accountInactive,
            servin: refreshedServin,
            errorMessage: 'Esta cuenta se encuentra desactivada.',
          ),
        );
        return false;
      }

      if (response.user.isDeleted) {
        emit(
          state.copyWith(
            status: AppSessionStatus.accountDeleted,
            servin: refreshedServin,
            errorMessage: 'Esta cuenta ha sido eliminada.',
          ),
        );
        return false;
      }

      await _setupBranchesAndUser(response.user, servin: refreshedServin);
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

  /// Configura una instancia recién activada y pasa a estado no autenticado (para hacer login)
  void initServinUnauthenticated(Servin servin) {
    _updateNetworkConfig(servin: servin);
    emit(
      state.copyWith(
        status: AppSessionStatus.unauthenticated,
        servin: servin,
        clearUser: true,
        clearBranch: true,
        clearActiveShift: true,
        clearError: true,
      ),
    );
  }

  /// Desvincula la instancia localmente y limpia la sesión completa para reconfigurar la app
  Future<void> exitBusiness() async {
    await servinRepository.clearCurrentServin();
    await authRepository.logout();
    await AppConfigManager().clearSelectedBranchId();
    AppSerumConfig().setBranchId(null);
    AppSerumConfig().setServinNickname(null);
    emit(
      state.copyWith(
        status: AppSessionStatus.unactivated,
        clearServin: true,
        clearUser: true,
        clearBranch: true,
        clearActiveShift: true,
        clearError: true,
      ),
    );
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
      await AppConfigManager().saveSelectedBranchId(branch.id);

      emit(
        state.copyWith(
          currentBranch: branch,
          clearError: true,
        ),
      );

      // Precargar logotipos de la sucursal activa en caché de disco y memoria
      unawaited(AppImageCache.precacheBranchLogos(branch));

      await fetchActiveShift(branch.id);
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  /// Actualiza la lista de sucursales autorizadas desde el repositorio
  Future<void> refreshBranches() async {
    try {
      final allBranches = await branchesRepository.getAllBranches();
      if (isRootUser && allBranches.isNotEmpty) {
        final defaultOriginBranch = BranchInDb(
          id: kOriginBranchId,
          name: 'Sucursal Matriz (ORIGIN_BRANCH)',
          address: 'Matriz Principal',
          phone: '',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        final branchesList = allBranches.any((b) => b.id == kOriginBranchId)
            ? allBranches
            : [defaultOriginBranch, ...allBranches];
        emit(state.copyWith(branches: branchesList));
      }
    } catch (_) {}
  }

  /// Cierra la sesión activa y limpia los tokens guardados (permaneciendo en el mismo negocio)
  Future<void> logout() async {
    await authRepository.logout();
    AppSerumConfig().setBranchId(null);
    emit(
      state.copyWith(
        status: AppSessionStatus.unauthenticated,
        clearUser: true,
        clearBranch: true,
        clearActiveShift: true,
        clearError: true,
      ),
    );
  }

  /// Consulta el turno activo del usuario actual para la sucursal activa
  Future<void> fetchActiveShift([String? branchId]) async {
    final currentUser = state.currentUser;
    if (currentUser == null || cashShiftsRepository == null) return;
    try {
      final targetBranchId = branchId ?? state.currentBranch?.id;
      final shift = await cashShiftsRepository!.getCurrentShift(
        currentUser.id,
        branchId: targetBranchId,
      );
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

  void _updateNetworkConfig({
    required Servin servin,
    BranchInDb? branch,
  }) {
    AppSerumConfig().setBaseUrl(servin.url);
    AppSerumConfig().setServinNickname(servin.nickname);
    if (branch != null) {
      AppSerumConfig().setBranchId(branch.id);
    }
  }

  Future<void> _fetchAndSetCurrentUser({Servin? servin}) async {
    try {
      final token = SerumClient.instance.authToken;
      final payload = TokenManager.decodePayload(token);
      final userId = payload?['userId'] as String?;

      UserInDb? user;
      if (userId != null && userId.isNotEmpty) {
        try {
          final userMap = await usersDataSource.getUserById(userId);
          if (userMap != null) {
            user = UserInDb.fromJson(userMap);
          }
        } catch (_) {}
      }

      if (user != null) {
        await _setupBranchesAndUser(user, servin: servin);
      } else {
        await logout();
      }
    } catch (_) {
      await logout();
    }
  }

  Future<void> _setupBranchesAndUser(UserInDb user, {Servin? servin}) async {
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

    final isRoot = isRootUser ||
        user.isRoot ||
        user.id == 'root' ||
        user.isInternal ||
        user.username.toLowerCase() == 'serum' ||
        user.username.toLowerCase() == 'root';
    final isAdmin = user.role.toLowerCase() == 'admin';

    // Para el usuario root, SIEMPRE tiene libertad total y acceso a TODAS las sucursales del sistema
    final List<BranchInDb> allowedBranches;
    if (isRoot) {
      allowedBranches =
          allBranches.isNotEmpty ? allBranches : [defaultOriginBranch];
    } else if (user.branches.isNotEmpty) {
      final filtered =
          allBranches.where((b) => user.branches.contains(b.id)).toList();
      allowedBranches = filtered.isNotEmpty
          ? filtered
          : (isAdmin ? allBranches : [defaultOriginBranch]);
    } else if (isAdmin) {
      allowedBranches =
          allBranches.isNotEmpty ? allBranches : [defaultOriginBranch];
    } else {
      allowedBranches = [defaultOriginBranch];
    }

    final savedBranchId = await AppConfigManager().getSelectedBranchId();
    final candidateBranchId = (savedBranchId != null &&
            allowedBranches.any((b) => b.id == savedBranchId))
        ? savedBranchId
        : (user.branches.firstOrNull ?? allowedBranches.first.id);

    BranchInDb selectedBranch = allowedBranches.firstWhere(
      (b) => b.id == candidateBranchId,
      orElse: () => allowedBranches.first,
    );

    AppSerumConfig().setBranchId(selectedBranch.id);
    await AppConfigManager().saveSelectedBranchId(selectedBranch.id);

    emit(
      state.copyWith(
        status: AppSessionStatus.authenticated,
        servin: servin ?? state.servin,
        currentUser: user,
        currentBranch: selectedBranch,
        branches: allowedBranches,
        clearError: true,
      ),
    );

    // Precargar logotipos de la sucursal activa en caché de disco y memoria
    unawaited(AppImageCache.precacheBranchLogos(selectedBranch));

    // Cargar configuraciones del sistema ahora que el tenant y la sesión están activos
    try {
      if (sl.isRegistered<AppSettingsCubit>()) {
        sl<AppSettingsCubit>().loadSettings();
      }
    } catch (_) {}

    // Consultar turno activo tras configurar usuario
    await fetchActiveShift();
  }

  @override
  Future<void> close() {
    _branchesSubscription?.cancel();
    return super.close();
  }
}
