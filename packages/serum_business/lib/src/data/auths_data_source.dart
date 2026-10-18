import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class AuthsDataSource with HttpService {
  AuthsDataSource._();
  static final AuthsDataSource instance = AuthsDataSource._();
  factory AuthsDataSource() {
    return instance;
  }

  final _endpoint = "/auths";

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final uri = HttpTools.generateUri("$_endpoint/login");
    final headers = HttpTools.generateTenantHeaders();
    final res = await postQuery(uri, data, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> refreshToken(Map<String, dynamic> data) async {
    final uri = HttpTools.generateUri("$_endpoint/refresh-token");
    final headers = HttpTools.generateTenantHeaders();
    final res = await postQuery(uri, data, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> checkUser(Map<String, dynamic> data) async {
    final uri = HttpTools.generateUri("$_endpoint/check-user");
    final headers = HttpTools.generateTenantHeaders();
    final res = await postQuery(uri, data, headers: headers);
    return res;
  }
}
