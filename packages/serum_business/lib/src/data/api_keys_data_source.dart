import '../services/http_service.dart';
import '../tools/http_tool.dart';

class ApiKeysDataSource with HttpService {
  ApiKeysDataSource._();
  static final ApiKeysDataSource instance = ApiKeysDataSource._();
  factory ApiKeysDataSource() {
    return instance;
  }

  final _endpoint = "/api-keys";

  Future<List<dynamic>> getAllApiKeys() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return (res['data'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> createApiKey(Map<String, dynamic> body) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, body, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> toggleApiKeyStatus(
    String keyId,
    bool isActive,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$keyId/toggle");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(
      uri,
      body: {'isActive': isActive},
      headers: headers,
    );
    return res;
  }

  Future<Map<String, dynamic>> deleteApiKey(String keyId) async {
    final uri = HttpTools.generateUri("$_endpoint/$keyId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
