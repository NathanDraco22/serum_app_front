part of 'write_orders_cubit.dart';

sealed class WriteOrderState {}

final class WriteOrderInitial extends WriteOrderState {}

final class WritingOrder extends WriteOrderState {}

class WriteOrderSuccess extends WriteOrderState {
  final OrderInDb item;
  WriteOrderSuccess(this.item);
}

final class OrderCreated extends WriteOrderSuccess {
  OrderCreated(super.item);
}

final class OrderUpdated extends WriteOrderSuccess {
  OrderUpdated(super.item);
}

final class OrderDeleted extends WriteOrderSuccess {
  OrderDeleted(super.item);
}

final class OrderPaid extends WriteOrderSuccess {
  OrderPaid(super.item);
}

final class WriteOrderError extends WriteOrderState {
  final String message;
  WriteOrderError(this.message);
}
