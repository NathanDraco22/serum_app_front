import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class OrdersDataSource with HttpService {
  OrdersDataSource._();
  static final OrdersDataSource instance = OrdersDataSource._();
  factory OrdersDataSource() {
    return instance;
  }

  final _endpoint = "/orders";

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, order, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllOrders() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final uri = HttpTools.generateUri("$_endpoint/$orderId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateOrderById(
    String orderId,
    Map<String, dynamic> order,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$orderId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: order, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteOrderById(String orderId) async {
    final uri = HttpTools.generateUri("$_endpoint/$orderId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
