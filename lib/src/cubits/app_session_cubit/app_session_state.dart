part of 'app_session_cubit.dart';

class AppSessionState {
  final UserInDb? currentUser;
  final CashRegisterInDb? activeCashRegister;

  const AppSessionState({
    this.currentUser,
    this.activeCashRegister,
  });

  bool get isAuthenticated => currentUser != null;
  bool get hasCashRegister => activeCashRegister != null;

  AppSessionState copyWith({
    UserInDb? currentUser,
    bool clearUser = false,
    CashRegisterInDb? activeCashRegister,
    bool clearCashRegister = false,
  }) {
    return AppSessionState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      activeCashRegister:
          clearCashRegister ? null : (activeCashRegister ?? this.activeCashRegister),
    );
  }
}
