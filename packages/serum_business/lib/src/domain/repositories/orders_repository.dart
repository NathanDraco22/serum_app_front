import 'package:serum_business/src/domain/models/order_model/order_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';
import 'package:serum_business/src/data/data_sources.dart';
import 'package:serum_business/src/tools/reactive_repo/reactive_repository.dart';

class OrdersRepository with ReactiveRepository<OrderInDb> {
  final OrdersDataSource ordersDataSource;

  OrdersRepository(this.ordersDataSource);

  List<OrderInDb> _orders = [];

  Future<OrderInDb> createOrder(CreateOrder createOrder) async {
    final result = await ordersDataSource.createOrder(createOrder.toJson());
    final newOrder = OrderInDb.fromJson(result);
    _orders = [newOrder, ..._orders];
    notifyItemCreated(newOrder);
    return newOrder;
  }

  Future<List<OrderInDb>> getAllOrders() async {
    final results = await ordersDataSource.getAllOrders();
    final response = ListResponse<OrderInDb>.fromJson(
      results,
      OrderInDb.fromJson,
    );

    _orders = response.data;
    return _orders;
  }

  Future<OrderInDb?> getOrderById(String orderId) async {
    final result = await ordersDataSource.getOrderById(orderId);
    if (result == null) return null;
    return OrderInDb.fromJson(result);
  }

  Future<OrderInDb?> updateOrderById(
    String orderId,
    UpdateOrder order,
  ) async {
    final result = await ordersDataSource.updateOrderById(
      orderId,
      order.toJson(),
    );
    if (result == null) return null;

    final updatedOrder = OrderInDb.fromJson(result);
    final index = _orders.indexWhere((u) => u.id == orderId);
    if (index != -1) {
      _orders[index] = updatedOrder;
      notifyItemUpdated(updatedOrder);
    }
    return updatedOrder;
  }

  Future<OrderInDb?> deleteOrderById(String orderId) async {
    final result = await ordersDataSource.deleteOrderById(orderId);
    if (result == null) return null;

    final deletedOrder = OrderInDb.fromJson(result);
    _orders.removeWhere((u) => u.id == orderId);
    notifyItemDeleted(deletedOrder);
    return deletedOrder;
  }

  Future<OrderInDb> payOrder(String orderId, OrderPayRequest payRequest) async {
    final result = await ordersDataSource.payOrder(orderId, payRequest.toJson());
    final paidOrder = OrderInDb.fromJson(result);
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = paidOrder;
      notifyItemUpdated(paidOrder);
    }
    return paidOrder;
  }
}
