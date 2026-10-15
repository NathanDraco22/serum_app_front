import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class LabTestAccountsDataSource with HttpService {
  LabTestAccountsDataSource._();
  static final LabTestAccountsDataSource instance =
      LabTestAccountsDataSource._();
  factory LabTestAccountsDataSource() {
    return instance;
  }

  final _endpoint = "/lab-test-accounts";

  Future<Map<String, dynamic>> getAccountsByBranch(String branchId) async {
    final uri = HttpTools.generateUri("$_endpoint/branch/$branchId");
    final headers = HttpTools.generateAuthHeaders();
    return await getQuery(uri, headers: headers);
  }

  Future<Map<String, dynamic>> getAccountsByTest(String labTestId) async {
    final uri = HttpTools.generateUri("$_endpoint/test/$labTestId");
    final headers = HttpTools.generateAuthHeaders();
    return await getQuery(uri, headers: headers);
  }

  Future<Map<String, dynamic>?> getByBranchAndTest(
    String branchId,
    String labTestId,
  ) async {
    final uri =
        HttpTools.generateUri("$_endpoint/branch/$branchId/test/$labTestId");
    final headers = HttpTools.generateAuthHeaders();
    return await getQuery(uri, headers: headers);
  }

  Future<Map<String, dynamic>?> updateCommercial(
    String accountId,
    Map<String, dynamic> commercial,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$accountId/commercial");
    final headers = HttpTools.generateAuthHeaders();
    return await patchQuery(uri, body: commercial, headers: headers);
  }

  Future<Map<String, dynamic>?> updateCommercialByBranchAndTest(
    String branchId,
    String labTestId,
    Map<String, dynamic> commercial,
  ) async {
    final uri = HttpTools.generateUri(
        "$_endpoint/branch/$branchId/test/$labTestId/commercial");
    final headers = HttpTools.generateAuthHeaders();
    return await patchQuery(uri, body: commercial, headers: headers);
  }
}
