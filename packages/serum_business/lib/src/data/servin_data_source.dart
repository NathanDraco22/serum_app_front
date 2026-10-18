import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class ServinDataSource with HttpService {
  final _activatorEndpoint = '/api/v1/activators';

  Future<Map<String, dynamic>> getActiveServin(
    String apiKey,
    String nickname, {
    String? originServerUrl,
  }) async {
    const envOriginServer = String.fromEnvironment(
      "ORIGIN_SERVER_URL",
      defaultValue: '',
    );
    final originServer = originServerUrl != null && originServerUrl.isNotEmpty
        ? originServerUrl
        : envOriginServer;

    if (originServer.isEmpty) {
      throw Exception('ORIGIN_SERVER_URL no está configurado');
    }

    final url = Uri.parse('$originServer$_activatorEndpoint/$nickname');

    final res = await getQuery(url, headers: {'X-Api-Key': apiKey});

    return res;
  }

  final _statusEndpoint = "/auths/servin-status";

  Future<Map<String, dynamic>> getServinStatus() async {
    final uri = HttpTools.generateUri(_statusEndpoint);
    final headers = HttpTools.generateTenantHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }
}
