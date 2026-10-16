import '../domain/query_params/cash_movement_query_params.dart';
import '../services/http_service.dart';
import '../tools/http_tool.dart';

class CashMovementsDataSource with HttpService {
  CashMovementsDataSource._();
  static final CashMovementsDataSource instance = CashMovementsDataSource._();
  factory CashMovementsDataSource() {
    return instance;
  }

  final _endpoint = "/cash-movements";

  Future<Map<String, dynamic>> createCashMovement(
      Map<String, dynamic> cashMovement) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, cashMovement, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllCashMovements(
      {CashMovementQueryParams? queryParams}) async {
    final uri = HttpTools.generateUri(
      _endpoint,
      queryParameters: queryParams?.toQueryParameters(),
    );
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getCashMovementById(
      String cashMovementId) async {
    final uri = HttpTools.generateUri("$_endpoint/$cashMovementId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateCashMovementById(
    String cashMovementId,
    Map<String, dynamic> cashMovement,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$cashMovementId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: cashMovement, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteCashMovementById(
      String cashMovementId) async {
    final uri = HttpTools.generateUri("$_endpoint/$cashMovementId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
