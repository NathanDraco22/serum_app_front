import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_orders_state.dart';

class WriteOrderCubit extends Cubit<WriteOrderState> {
  final OrdersRepository ordersRepository;

  WriteOrderCubit({required this.ordersRepository})
      : super(WriteOrderInitial());

  Future<void> create(CreateOrder createOrder) async {
    emit(WritingOrder());
    try {
      final item = await ordersRepository.createOrder(createOrder);
      emit(OrderCreated(item));
    } catch (e) {
      emit(WriteOrderError(e.toString()));
    }
  }

  Future<void> update(String orderId, UpdateOrder order) async {
    emit(WritingOrder());
    try {
      final item = await ordersRepository.updateOrderById(orderId, order);
      if (item != null) {
        emit(OrderUpdated(item));
      } else {
        emit(WriteOrderError('Not found'));
      }
    } catch (e) {
      emit(WriteOrderError(e.toString()));
    }
  }

  Future<void> delete(String orderId) async {
    emit(WritingOrder());
    try {
      final item = await ordersRepository.deleteOrderById(orderId);
      if (item != null) {
        emit(OrderDeleted(item));
      } else {
        emit(WriteOrderError('Not found'));
      }
    } catch (e) {
      emit(WriteOrderError(e.toString()));
    }
  }
}
