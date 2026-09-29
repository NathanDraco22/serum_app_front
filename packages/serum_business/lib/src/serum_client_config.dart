abstract class SerumClientConfig {
  String get baseUrl;
  String get authToken;
  set authToken(String token);
  String? get branchId;
  set branchId(String? id);
}

