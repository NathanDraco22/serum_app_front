part of 'read_orders_cubit.dart';

sealed class ReadOrderState {}

final class ReadOrderInitial extends ReadOrderState {}

final class ReadOrderLoading extends ReadOrderState {}

class ReadOrderSuccess extends ReadOrderState {
  final List<OrderInDb> items;
  List<OrderInDb> newItems;
  List<OrderInDb> updatedItems;
  List<OrderInDb> deletedItems;

  ReadOrderSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadOrderRefreshing extends ReadOrderSuccess {
  ReadOrderRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadOrderRefreshing.fromSuccess(
    ReadOrderSuccess success,
  ) =>
      ReadOrderRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadOrderError extends ReadOrderState {
  final String message;
  ReadOrderError(this.message);
}
