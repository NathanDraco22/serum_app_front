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

final class CashRegisterOpened extends WriteCashRegisterSuccess {
  CashRegisterOpened(super.item);
}

final class CashRegisterClosed extends WriteCashRegisterSuccess {
  CashRegisterClosed(super.item);
}

class WriteCashRegisterTransactionSuccess extends WriteCashRegisterState {
  final CashTransactionInDb transaction;
  WriteCashRegisterTransactionSuccess(this.transaction);
}

final class CashRegisterIncomeRegistered extends WriteCashRegisterTransactionSuccess {
  CashRegisterIncomeRegistered(super.transaction);
}

final class CashRegisterWithdrawalRegistered extends WriteCashRegisterTransactionSuccess {
  CashRegisterWithdrawalRegistered(super.transaction);
}

final class CashRegisterPaymentRegistered extends WriteCashRegisterTransactionSuccess {
  CashRegisterPaymentRegistered(super.transaction);
}

final class WriteCashRegisterError extends WriteCashRegisterState {
  final String message;
  WriteCashRegisterError(this.message);
}
