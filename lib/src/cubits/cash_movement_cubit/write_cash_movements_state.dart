part of 'write_cash_movements_cubit.dart';

abstract class WriteCashMovementState {
  const WriteCashMovementState();
}

class WriteCashMovementInitial extends WriteCashMovementState {}

class WritingCashMovement extends WriteCashMovementState {}

class CashMovementCreated extends WriteCashMovementState {
  final CashMovementInDb item;

  const CashMovementCreated(this.item);
}

class CashMovementUpdated extends WriteCashMovementState {
  final CashMovementInDb item;

  const CashMovementUpdated(this.item);
}

class CashMovementDeleted extends WriteCashMovementState {
  final CashMovementInDb item;

  const CashMovementDeleted(this.item);
}

class WriteCashMovementError extends WriteCashMovementState {
  final String message;

  const WriteCashMovementError(this.message);
}
