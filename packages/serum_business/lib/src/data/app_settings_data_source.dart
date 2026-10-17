import '../services/http_service.dart';
import '../tools/http_tool.dart';

class AppSettingsDataSource with HttpService {
  AppSettingsDataSource._();
  static final AppSettingsDataSource instance = AppSettingsDataSource._();
  factory AppSettingsDataSource() {
    return instance;
  }

  final _endpoint = "/app-settings";

  Future<Map<String, dynamic>?> getCurrentAppSettings() async {
    final headers = HttpTools.generateAuthHeaders();
    final uri = HttpTools.generateUri("$_endpoint/current");
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateAppSettings(
    String appSettingId,
    Map<String, dynamic> body,
  ) async {
    final headers = HttpTools.generateAuthHeaders();
    final uri = HttpTools.generateUri("$_endpoint/$appSettingId");
    final res = await patchQuery(uri, body: body, headers: headers);
    return res;
  }
}
