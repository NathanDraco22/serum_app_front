import 'package:serum_business/serum_business.dart';

class AppSerumConfig implements SerumClientConfig {
  static const _baseUrl = String.fromEnvironment("SERVER_URL");
  String _token = '';

  @override
  String get baseUrl => _baseUrl;

  @override
  String get authToken => _token;

  @override
  set authToken(String token) {
    _token = token;
  }
}
