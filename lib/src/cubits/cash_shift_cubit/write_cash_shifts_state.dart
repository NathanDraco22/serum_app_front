part of 'write_cash_shifts_cubit.dart';

sealed class WriteCashShiftState {}

final class WriteCashShiftInitial extends WriteCashShiftState {}

final class WritingCashShift extends WriteCashShiftState {}

class WriteCashShiftSuccess extends WriteCashShiftState {
  final CashShiftInDb item;
  WriteCashShiftSuccess(this.item);
}

final class CashShiftCreated extends WriteCashShiftSuccess {
  CashShiftCreated(super.item);
}

final class CashShiftUpdated extends WriteCashShiftSuccess {
  CashShiftUpdated(super.item);
}

final class CashShiftClosed extends WriteCashShiftSuccess {
  CashShiftClosed(super.item);
}

final class CashShiftDeleted extends WriteCashShiftSuccess {
  CashShiftDeleted(super.item);
}

final class WriteCashShiftError extends WriteCashShiftState {
  final String message;
  WriteCashShiftError(this.message);
}
