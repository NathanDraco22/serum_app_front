import '../../data/app_settings_data_source.dart';
import '../models/app_setting/app_setting_model.dart';

class AppSettingsRepository {
  final AppSettingsDataSource appSettingsDataSource;

  AppSettingsRepository(this.appSettingsDataSource);

  AppSettingModel? _currentAppSettings;

  AppSettingModel? get currentAppSettings => _currentAppSettings;

  Future<AppSettingModel> getCurrentAppSettings() async {
    final result = await appSettingsDataSource.getCurrentAppSettings();
    if (result == null) {
      throw Exception("No se pudo obtener la configuración del sistema");
    }
    final model = AppSettingModel.fromJson(result);
    _currentAppSettings = model;
    return model;
  }

  Future<AppSettingModel> updateAppSettings(
    String appSettingId,
    UpdateAppSetting body,
  ) async {
    final result = await appSettingsDataSource.updateAppSettings(
      appSettingId,
      body.toJson(),
    );
    if (result == null) {
      throw Exception("No se pudo actualizar la configuración del sistema");
    }
    final model = AppSettingModel.fromJson(result);
    _currentAppSettings = model;
    return model;
  }
}
