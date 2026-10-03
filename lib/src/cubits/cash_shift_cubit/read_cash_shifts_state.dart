part of 'read_cash_shifts_cubit.dart';

sealed class ReadCashShiftState {}

final class ReadCashShiftInitial extends ReadCashShiftState {}

final class ReadCashShiftLoading extends ReadCashShiftState {}

class ReadCashShiftSuccess extends ReadCashShiftState {
  final List<CashShiftInDb> items;
  List<CashShiftInDb> newItems;
  List<CashShiftInDb> updatedItems;
  List<CashShiftInDb> deletedItems;

  ReadCashShiftSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadCashShiftRefreshing extends ReadCashShiftSuccess {
  ReadCashShiftRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadCashShiftRefreshing.fromSuccess(
    ReadCashShiftSuccess success,
  ) =>
      ReadCashShiftRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadCashShiftError extends ReadCashShiftState {
  final String message;
  ReadCashShiftError(this.message);
}
