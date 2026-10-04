import '../services/http_service.dart';
import '../tools/http_tool.dart';

class ReportsDataSource with HttpService {
  ReportsDataSource._();
  static final ReportsDataSource instance = ReportsDataSource._();
  factory ReportsDataSource() => instance;

  final String _endpoint = "/reports";

  Future<Map<String, dynamic>> getFinancialReport({
    required int startDate,
    required int endDate,
    String? branchId,
  }) async {
    final queryParams = <String, String>{
      'start_date': startDate.toString(),
      'end_date': endDate.toString(),
      if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
    };
    final uri = HttpTools.generateUri(
      '$_endpoint/financial',
      queryParameters: queryParams,
    );
    final headers = HttpTools.generateAuthHeaders();
    return await getQuery(uri, headers: headers);
  }

  Future<Map<String, dynamic>> getTopDoctorsReport({
    required int startDate,
    required int endDate,
    String? branchId,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'start_date': startDate.toString(),
      'end_date': endDate.toString(),
      'limit': limit.toString(),
      if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
    };
    final uri = HttpTools.generateUri(
      '$_endpoint/top-doctors',
      queryParameters: queryParams,
    );
    final headers = HttpTools.generateAuthHeaders();
    return await getQuery(uri, headers: headers);
  }

  Future<Map<String, dynamic>> getLabTestsVolumeReport({
    required int startDate,
    required int endDate,
    String? branchId,
    String source = 'orders',
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'start_date': startDate.toString(),
      'end_date': endDate.toString(),
      'source': source,
      'limit': limit.toString(),
      if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
    };
    final uri = HttpTools.generateUri(
      '$_endpoint/lab-tests-volume',
      queryParameters: queryParams,
    );
    final headers = HttpTools.generateAuthHeaders();
    return await getQuery(uri, headers: headers);
  }

  Future<Map<String, dynamic>> getPendingBalancesReport({
    required int startDate,
    required int endDate,
    String? branchId,
  }) async {
    final queryParams = <String, String>{
      'start_date': startDate.toString(),
      'end_date': endDate.toString(),
      if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
    };
    final uri = HttpTools.generateUri(
      '$_endpoint/pending-balances',
      queryParameters: queryParams,
    );
    final headers = HttpTools.generateAuthHeaders();
    return await getQuery(uri, headers: headers);
  }

  Future<Map<String, dynamic>> getShiftsAuditReport({
    required int startDate,
    required int endDate,
    String? branchId,
    bool onlyDiscrepancies = false,
  }) async {
    final queryParams = <String, String>{
      'start_date': startDate.toString(),
      'end_date': endDate.toString(),
      'only_discrepancies': onlyDiscrepancies.toString(),
      if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
    };
    final uri = HttpTools.generateUri(
      '$_endpoint/shifts-audit',
      queryParameters: queryParams,
    );
    final headers = HttpTools.generateAuthHeaders();
    return await getQuery(uri, headers: headers);
  }
}
