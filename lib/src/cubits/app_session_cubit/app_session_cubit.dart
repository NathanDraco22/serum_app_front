import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'app_session_state.dart';

class AppSessionCubit extends Cubit<AppSessionState> {
  AppSessionCubit() : super(const AppSessionState());

  void login(UserInDb user) {
    emit(state.copyWith(currentUser: user));
  }

  void logout() {
    emit(const AppSessionState());
  }

  void selectCashRegister(CashRegisterInDb cashRegister) {
    emit(state.copyWith(activeCashRegister: cashRegister));
  }

  void clearCashRegister() {
    emit(state.copyWith(clearCashRegister: true));
  }
}
