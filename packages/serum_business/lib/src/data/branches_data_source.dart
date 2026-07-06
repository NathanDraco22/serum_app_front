import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class BranchesDataSource with HttpService {
  BranchesDataSource._();
  static final BranchesDataSource instance = BranchesDataSource._();
  factory BranchesDataSource() {
    return instance;
  }

  final _endpoint = "/branches";

  Future<Map<String, dynamic>> createBranch(Map<String, dynamic> branch) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, branch, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllBranches() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getBranchById(String branchId) async {
    final uri = HttpTools.generateUri("$_endpoint/$branchId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateBranchById(
    String branchId,
    Map<String, dynamic> branch,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$branchId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: branch, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteBranchById(String branchId) async {
    final uri = HttpTools.generateUri("$_endpoint/$branchId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
