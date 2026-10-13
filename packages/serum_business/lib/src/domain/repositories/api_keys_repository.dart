import '../../data/api_keys_data_source.dart';
import '../../tools/reactive_repo/reactive_repository.dart';
import '../models/api_key/api_key_model.dart';

class ApiKeysRepository with ReactiveRepository<ApiKeyModel> {
  final ApiKeysDataSource apiKeysDataSource;

  ApiKeysRepository(this.apiKeysDataSource);

  List<ApiKeyModel> _apiKeys = [];

  List<ApiKeyModel> get apiKeys => _apiKeys;

  Future<List<ApiKeyModel>> getAllApiKeys() async {
    final results = await apiKeysDataSource.getAllApiKeys();
    _apiKeys = results.map((e) => ApiKeyModel.fromJson(e as Map<String, dynamic>)).toList();
    return _apiKeys;
  }

  Future<ApiKeyModel> createApiKey({
    required String name,
    String serviceType = 'power_bi',
    List<String> scopes = const ['bi:read'],
    String? branchId,
  }) async {
    final body = {
      'name': name,
      'serviceType': serviceType,
      'scopes': scopes,
      'branchId': ?branchId,
    };

    final result = await apiKeysDataSource.createApiKey(body);
    final created = ApiKeyModel.fromJson(result);
    _apiKeys = [created, ..._apiKeys];
    notifyItemCreated(created);
    return created;
  }

  Future<ApiKeyModel?> toggleApiKeyStatus(
    String keyId,
    bool isActive,
  ) async {
    final result = await apiKeysDataSource.toggleApiKeyStatus(keyId, isActive);
    final updated = ApiKeyModel.fromJson(result);
    final index = _apiKeys.indexWhere((k) => k.id == keyId);
    if (index != -1) {
      _apiKeys[index] = updated;
      notifyItemUpdated(updated);
    }
    return updated;
  }

  Future<void> deleteApiKey(String keyId) async {
    final result = await apiKeysDataSource.deleteApiKey(keyId);
    final deleted = ApiKeyModel.fromJson(result);
    _apiKeys.removeWhere((k) => k.id == keyId);
    notifyItemDeleted(deleted);
  }
}
