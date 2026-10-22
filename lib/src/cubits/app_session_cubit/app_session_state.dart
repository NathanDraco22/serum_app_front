part of 'app_session_cubit.dart';

enum AppSessionStatus {
  initial,
  unactivated,
  instanceInactive,
  authenticating,
  authenticated,
  unauthenticated,
  accountInactive,
  accountDeleted,
  error,
}

class AppSessionState {
  final AppSessionStatus status;
  final Servin? servin;
  final UserInDb? currentUser;
  final BranchInDb? currentBranch;
  final List<BranchInDb> branches;
  final CashShiftInDb? activeShift;
  final String? errorMessage;

  const AppSessionState({
    this.status = AppSessionStatus.initial,
    this.servin,
    this.currentUser,
    this.currentBranch,
    this.branches = const [],
    this.activeShift,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AppSessionStatus.authenticated && currentUser != null;
  bool get hasBranch => currentBranch != null;
  bool get hasActiveShift => activeShift != null;

  /// Retorna si el usuario en sesión cuenta con privilegios root del sistema.
  bool get isRootUser {
    final u = currentUser;
    if (u == null || !u.isActive || u.isDeleted) return false;
    return u.id == 'root' ||
        u.isInternal ||
        u.username.toLowerCase() == 'serum' ||
        u.username.toLowerCase() == 'root';
  }

  AppSessionState copyWith({
    AppSessionStatus? status,
    Servin? servin,
    bool clearServin = false,
    UserInDb? currentUser,
    bool clearUser = false,
    BranchInDb? currentBranch,
    bool clearBranch = false,
    List<BranchInDb>? branches,
    CashShiftInDb? activeShift,
    bool clearActiveShift = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppSessionState(
      status: status ?? this.status,
      servin: clearServin ? null : (servin ?? this.servin),
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      currentBranch: clearBranch ? null : (currentBranch ?? this.currentBranch),
      branches: branches ?? this.branches,
      activeShift:
          clearActiveShift ? null : (activeShift ?? this.activeShift),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
