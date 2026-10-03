
import '../services/http_service.dart';
import '../tools/http_tool.dart';

class RolesDataSource with HttpService {
  RolesDataSource._();
  static final RolesDataSource instance = RolesDataSource._();
  factory RolesDataSource() {
    return instance;
  }

  final _endpoint = "/roles";

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> role) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, role, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllRoles() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getRoleById(String roleId) async {
    final uri = HttpTools.generateUri("$_endpoint/$roleId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> searchRoleByKeyword(String keyword) async {
    final uri = HttpTools.generateUri("$_endpoint/search/$keyword");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateRoleById(
    String roleId,
    Map<String, dynamic> role,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$roleId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: role, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteRoleById(String roleId) async {
    final uri = HttpTools.generateUri("$_endpoint/$roleId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
