import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_orders_state.dart';

class WriteOrderCubit extends Cubit<WriteOrderState> {
  final OrdersRepository ordersRepository;

  WriteOrderCubit({required this.ordersRepository}) : super(WriteOrderInitial());

  String _humanizeError(Object error) {
    final message = error.toString();
    if (message.contains('INVALID_PATIENT_DEMOGRAPHICS')) {
      return 'El paciente no tiene fecha de nacimiento ni edad registrada. '
          'Actualice sus datos antes de guardar la orden.';
    }
    if (message.contains('ORDER_HAS_CLINICAL_RESULTS')) {
      return 'No se puede cambiar el paciente porque la orden ya tiene '
          'resultados capturados.';
    }
    if (message.contains('ORDER_HAS_PAYMENTS')) {
      return 'No se pudieron localizar los recibos activos para revertir los pagos de esta orden.';
    }
    if (message.contains('CASH_SHIFT_NOT_OPEN')) {
      return 'No se puede anular la orden porque el turno de caja donde se registró el pago ya está cerrado.';
    }
    if (message.contains('INSUFFICIENT_METHOD_BALANCE')) {
      return 'El turno de caja no tiene saldo suficiente en el método de pago original para revertir el cobro.';
    }
    if (message.contains('CASH_SHIFT_NOT_FOUND')) {
      return 'No se encontró el turno de caja asociado al pago de esta orden.';
    }
    if (message.contains('CASH_REGISTER_NOT_OPEN')) {
      return 'La caja asociada al pago ya se encuentra cerrada.';
    }
    if (message.contains('ORDER_CANNOT_BE_DELETED')) {
      return 'Esta orden ya se encuentra cancelada o no puede eliminarse.';
    }
    return message;
  }

  Future<void> create(CreateOrder createOrder) async {
    emit(WritingOrder());
    try {
      final item = await ordersRepository.createOrder(createOrder);
      emit(OrderCreated(item));
    } catch (e) {
      emit(WriteOrderError(_humanizeError(e)));
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
      emit(WriteOrderError(_humanizeError(e)));
    }
  }

  Future<void> delete(String orderId, {String? reason}) async {
    emit(WritingOrder());
    try {
      final item = await ordersRepository.deleteOrderById(
        orderId,
        reason: reason,
      );
      if (item != null) {
        emit(OrderDeleted(item));
      } else {
        emit(WriteOrderError('Not found'));
      }
    } catch (e) {
      emit(WriteOrderError(_humanizeError(e)));
    }
  }

  Future<void> payOrder(String orderId, OrderPayRequest request) async {
    emit(WritingOrder());
    try {
      final item = await ordersRepository.payOrder(orderId, request);
      emit(OrderPaid(item));
    } catch (e) {
      emit(WriteOrderError(e.toString()));
    }
  }

  Future<void> approveOrder(String orderId, OrderApproveRequest request) async {
    emit(WritingOrder());
    try {
      final item = await ordersRepository.approveOrder(orderId, request);
      emit(OrderApproved(item));
    } catch (e) {
      emit(WriteOrderError(e.toString()));
    }
  }

  Future<void> finalizeOrder(String orderId) async {
    emit(WritingOrder());
    try {
      final item = await ordersRepository.finalizeOrder(orderId);
      emit(OrderFinalized(item));
    } catch (e) {
      emit(WriteOrderError(e.toString()));
    }
  }

  Future<void> reopenOrder(String orderId, OrderReopenRequest request) async {
    emit(WritingOrder());
    try {
      final item = await ordersRepository.reopenOrder(orderId, request);
      emit(OrderReopened(item));
    } catch (e) {
      emit(WriteOrderError(e.toString()));
    }
  }
}
