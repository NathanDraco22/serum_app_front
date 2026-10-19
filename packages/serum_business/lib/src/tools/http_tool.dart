import '../serum_client.dart';

class HttpTools {
  static const String _api = "/api";

  static Uri generateUri(String path, {int version = 1, Map<String, String>? queryParameters}) {
    assert(path.startsWith("/"));

    final config = SerumClient.instance;
    final baseUrl = config.baseUrl;

    final decodedBase = Uri.parse(baseUrl);
    final fullPath = "$_api/v$version$path";

    final authority = decodedBase.authority.isNotEmpty
        ? decodedBase.authority
        : (decodedBase.hasPort
            ? "${decodedBase.host}:${decodedBase.port}"
            : decodedBase.host);

    if (decodedBase.scheme == "https") {
      return Uri.https(authority, fullPath, queryParameters);
    } else {
      return Uri.http(authority, fullPath, queryParameters);
    }
  }

  static Map<String, String> generateTenantHeaders() {
    final config = SerumClient.instance;
    final servinNickname = config.servinNickname;
    final branchId = config.branchId;
    return {
      "X-Agent": "Serum",
      if (servinNickname != null && servinNickname.isNotEmpty)
        "x-servin": servinNickname,
      if (branchId != null && branchId.isNotEmpty)
        "x-branch": branchId,
    };
  }

  static Map<String, String> generateAuthHeaders() {
    final config = SerumClient.instance;
    final token = config.authToken;
    return {
      ...generateTenantHeaders(),
      "Authorization": "Bearer $token",
    };
  }
}
