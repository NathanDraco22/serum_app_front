import 'package:serum_business/serum_business.dart';

abstract class ApiKeysState {}

class ApiKeysInitial extends ApiKeysState {}

class ApiKeysLoading extends ApiKeysState {}

class ApiKeysLoaded extends ApiKeysState {
  final List<ApiKeyModel> apiKeys;
  ApiKeysLoaded(this.apiKeys);
}

class ApiKeysError extends ApiKeysState {
  final String message;
  ApiKeysError(this.message);
}
