import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class UsersDataSource with HttpService {
  UsersDataSource._();
  static final UsersDataSource instance = UsersDataSource._();
  factory UsersDataSource() {
    return instance;
  }

  final _endpoint = "/users";

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> user) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, user, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final uri = HttpTools.generateUri("$_endpoint/$userId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateUserById(String userId, Map<String, dynamic> user) async {
    final uri = HttpTools.generateUri("$_endpoint/$userId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: user, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteUserById(String userId) async {
    final uri = HttpTools.generateUri("$_endpoint/$userId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
