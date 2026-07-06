import 'serum_client_config.dart';

class SerumClient {
  static SerumClientConfig? _config;

  static void initialize(SerumClientConfig config) {
    _config = config;
  }

  static SerumClientConfig get instance {
    if (_config == null) {
      throw StateError('SerumClient not initialized. Call SerumClient.initialize() first.');
    }
    return _config!;
  }
}
