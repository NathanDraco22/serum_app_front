import '../services/http_service.dart';
import '../tools/http_tool.dart';

class CashShiftsDataSource with HttpService {
  CashShiftsDataSource._();
  static final CashShiftsDataSource instance = CashShiftsDataSource._();
  factory CashShiftsDataSource() {
    return instance;
  }

  final _endpoint = "/cash-shifts";

  Future<Map<String, dynamic>> openCashShift(
      Map<String, dynamic> cashShift) async {
    final uri = HttpTools.generateUri("$_endpoint/open");
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, cashShift, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getCurrentCashShift(String userId) async {
    final uri = HttpTools.generateUri(
      "$_endpoint/current",
      queryParameters: {'user_id': userId},
    );
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> closeCashShift(
    String shiftId,
    Map<String, dynamic> body, {
    String? userId,
  }) async {
    final queryParameters = userId != null ? {'user_id': userId} : null;
    final uri = HttpTools.generateUri(
      "$_endpoint/$shiftId/close",
      queryParameters: queryParameters,
    );
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, body, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllCashShifts({
    String? branchId,
    String? userId,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (branchId != null) queryParams['branch_id'] = branchId;
    if (userId != null) queryParams['user_id'] = userId;
    if (status != null) queryParams['status'] = status;

    final uri = HttpTools.generateUri(
      _endpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getCashShiftById(String shiftId) async {
    final uri = HttpTools.generateUri("$_endpoint/$shiftId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateCashShiftById(
    String shiftId,
    Map<String, dynamic> cashShift,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$shiftId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: cashShift, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteCashShiftById(String shiftId) async {
    final uri = HttpTools.generateUri("$_endpoint/$shiftId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
