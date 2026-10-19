import '../services/http_service.dart';
import '../tools/http_tool.dart';

class ImportsDataSource with HttpService {
  ImportsDataSource._();
  static final ImportsDataSource instance = ImportsDataSource._();
  factory ImportsDataSource() {
    return instance;
  }

  final _endpoint = "/imports";

  Future<Map<String, dynamic>> importDefaultCatalog() async {
    final headers = HttpTools.generateAuthHeaders();
    final uri = HttpTools.generateUri("$_endpoint/default-catalog");
    final res = await postQuery(uri, {}, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> importLabTests() async {
    final headers = HttpTools.generateAuthHeaders();
    final uri = HttpTools.generateUri("$_endpoint/lab-tests");
    final res = await postQuery(uri, {}, headers: headers);
    return res;
  }
}
