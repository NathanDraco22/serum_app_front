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
  final CashRegisterInDb? activeCashRegister;
  final String? errorMessage;

  const AppSessionState({
    this.status = AppSessionStatus.initial,
    this.currentUser,
    this.activeCashRegister,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AppSessionStatus.authenticated && currentUser != null;
  bool get hasCashRegister => activeCashRegister != null;

  AppSessionState copyWith({
    AppSessionStatus? status,
    UserInDb? currentUser,
    bool clearUser = false,
    CashRegisterInDb? activeCashRegister,
    bool clearCashRegister = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppSessionState(
      status: status ?? this.status,
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      activeCashRegister:
          clearCashRegister ? null : (activeCashRegister ?? this.activeCashRegister),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
