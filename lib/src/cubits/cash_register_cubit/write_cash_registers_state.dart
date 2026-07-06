part of 'write_cash_registers_cubit.dart';

sealed class WriteCashRegisterState {}

final class WriteCashRegisterInitial extends WriteCashRegisterState {}

final class WritingCashRegister extends WriteCashRegisterState {}

class WriteCashRegisterSuccess extends WriteCashRegisterState {
  final CashRegisterInDb item;
  WriteCashRegisterSuccess(this.item);
}

final class CashRegisterCreated extends WriteCashRegisterSuccess {
  CashRegisterCreated(super.item);
}

final class CashRegisterUpdated extends WriteCashRegisterSuccess {
  CashRegisterUpdated(super.item);
}

final class CashRegisterDeleted extends WriteCashRegisterSuccess {
  CashRegisterDeleted(super.item);
}

final class WriteCashRegisterError extends WriteCashRegisterState {
  final String message;
  WriteCashRegisterError(this.message);
}
