part of 'app_session_cubit.dart';

enum AppSessionStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  accountInactive,
  accountDeleted,
  error,
}

class AppSessionState {
  final AppSessionStatus status;
  final UserInDb? currentUser;
  final BranchInDb? currentBranch;
  final List<BranchInDb> branches;
  final CashRegisterInDb? activeCashRegister;
  final CashShiftInDb? activeShift;
  final String? errorMessage;

  const AppSessionState({
    this.status = AppSessionStatus.initial,
    this.currentUser,
    this.currentBranch,
    this.branches = const [],
    this.activeCashRegister,
    this.activeShift,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AppSessionStatus.authenticated && currentUser != null;
  bool get hasBranch => currentBranch != null;
  bool get hasCashRegister => activeCashRegister != null;
  bool get hasActiveShift => activeShift != null;

  AppSessionState copyWith({
    AppSessionStatus? status,
    UserInDb? currentUser,
    bool clearUser = false,
    BranchInDb? currentBranch,
    bool clearBranch = false,
    List<BranchInDb>? branches,
    CashRegisterInDb? activeCashRegister,
    bool clearCashRegister = false,
    CashShiftInDb? activeShift,
    bool clearActiveShift = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppSessionState(
      status: status ?? this.status,
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      currentBranch: clearBranch ? null : (currentBranch ?? this.currentBranch),
      branches: branches ?? this.branches,
      activeCashRegister: clearCashRegister
          ? null
          : (activeCashRegister ?? this.activeCashRegister),
      activeShift:
          clearActiveShift ? null : (activeShift ?? this.activeShift),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
