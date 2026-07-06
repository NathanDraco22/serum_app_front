part of 'read_cash_transactions_cubit.dart';

sealed class ReadCashTransactionState {}

final class ReadCashTransactionInitial extends ReadCashTransactionState {}

final class ReadCashTransactionLoading extends ReadCashTransactionState {}

class ReadCashTransactionSuccess extends ReadCashTransactionState {
  final List<CashTransactionInDb> items;

  ReadCashTransactionSuccess(this.items);
}

final class ReadCashTransactionRefreshing extends ReadCashTransactionSuccess {
  ReadCashTransactionRefreshing(super.items);

  factory ReadCashTransactionRefreshing.fromSuccess(
    ReadCashTransactionSuccess success,
  ) =>
      ReadCashTransactionRefreshing(success.items);
}

final class ReadCashTransactionError extends ReadCashTransactionState {
  final String message;
  ReadCashTransactionError(this.message);
}
