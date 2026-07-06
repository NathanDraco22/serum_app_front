part of 'read_cash_registers_cubit.dart';

sealed class ReadCashRegisterState {}

final class ReadCashRegisterInitial extends ReadCashRegisterState {}

final class ReadCashRegisterLoading extends ReadCashRegisterState {}

class ReadCashRegisterSuccess extends ReadCashRegisterState {
  final List<CashRegisterInDb> items;
  List<CashRegisterInDb> newItems;
  List<CashRegisterInDb> updatedItems;
  List<CashRegisterInDb> deletedItems;

  ReadCashRegisterSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadCashRegisterRefreshing extends ReadCashRegisterSuccess {
  ReadCashRegisterRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadCashRegisterRefreshing.fromSuccess(
    ReadCashRegisterSuccess success,
  ) =>
      ReadCashRegisterRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadCashRegisterError extends ReadCashRegisterState {
  final String message;
  ReadCashRegisterError(this.message);
}
