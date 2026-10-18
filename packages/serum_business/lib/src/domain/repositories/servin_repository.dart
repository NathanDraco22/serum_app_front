import 'package:serum_business/src/data/servin_data_source.dart';
import 'package:serum_business/src/domain/models/servin/servin.dart';
import 'package:serum_business/src/domain/responses/servin_status_response.dart';
import 'package:serum_business/src/local_storage.dart';

class ServinRepository {
  ServinRepository({
    required this.servinDataSource,
    required this.appConfigStore,
  });

  final ServinDataSource servinDataSource;
  final AppConfigStore appConfigStore;

  Future<Servin> getActiveServin(
    String apiKey,
    String nickname, {
    String? originServerUrl,
  }) async {
    final res = await servinDataSource.getActiveServin(
      apiKey,
      nickname,
      originServerUrl: originServerUrl,
    );
    final servin = Servin.fromJson(res);
    await appConfigStore.setConfig(servin.toJson());
    return servin;
  }

  Future<Servin?> getCurrentServinFromLocal() async {
    final config = await appConfigStore.getConfig();
    if (config == null) return null;
    return Servin.fromJson(config);
  }

  Future<void> clearCurrentServin() async {
    await appConfigStore.clearConfig();
  }

  Future<Servin?> refreshServinStatus() async {
    try {
      final res = await servinDataSource.getServinStatus();
      final servinResponse = ServinStatusResponse.fromJson(res);

      final localServin = await getCurrentServinFromLocal();
      if (localServin == null) return null;

      final updatedServin = localServin.copyWith(
        nickname: servinResponse.nickname,
        isActive: servinResponse.isActive,
        isMultiBranch: servinResponse.isMultiBranch,
        isUsingExpirationDate: servinResponse.isUsingExpirationDate,
      );

      await appConfigStore.setConfig(updatedServin.toJson());

      return updatedServin;
    } catch (_) {
      return await getCurrentServinFromLocal();
    }
  }
}
