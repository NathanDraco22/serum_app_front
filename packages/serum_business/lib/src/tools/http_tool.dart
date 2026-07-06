import '../serum_client.dart';

class HttpTools {
  static const String _api = "/api";

  static Uri generateUri(String path, {int version = 1, Map<String, String>? queryParameters}) {
    assert(path.startsWith("/"));

    final config = SerumClient.instance;
    final baseUrl = config.baseUrl;

    final decodedBase = Uri.parse(baseUrl);
    final fullPath = "$_api/v$version$path";

    if (decodedBase.scheme == "https") {
      return Uri.https(decodedBase.authority, fullPath, queryParameters);
    } else {
      final result = Uri.http(
        "${decodedBase.host}:${decodedBase.port}",
        fullPath,
        queryParameters,
      );
      return result;
    }
  }

  static Map<String, String> generateAuthHeaders() {
    final config = SerumClient.instance;
    final token = config.authToken;
    return {
      "Authorization": "Bearer $token",
      "X-Agent": "Neptuno",
    };
  }
}
