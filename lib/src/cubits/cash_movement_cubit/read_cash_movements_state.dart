part of 'read_cash_movements_cubit.dart';

abstract class ReadCashMovementState {
  const ReadCashMovementState();
}

class ReadCashMovementInitial extends ReadCashMovementState {}

class ReadCashMovementLoading extends ReadCashMovementState {}

class ReadCashMovementSuccess extends ReadCashMovementState {
  final List<CashMovementInDb> items;
  final List<CashMovementInDb> newItems;
  final List<CashMovementInDb> updatedItems;
  final List<CashMovementInDb> deletedItems;

  const ReadCashMovementSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

class ReadCashMovementRefreshing extends ReadCashMovementSuccess {
  const ReadCashMovementRefreshing(super.items,
      {super.newItems, super.updatedItems, super.deletedItems});

  factory ReadCashMovementRefreshing.fromSuccess(
          ReadCashMovementSuccess success) =>
      ReadCashMovementRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

class ReadCashMovementError extends ReadCashMovementState {
  final String message;

  const ReadCashMovementError(this.message);
}
