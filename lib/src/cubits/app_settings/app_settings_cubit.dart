import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import 'app_settings_state.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  final AppSettingsRepository appSettingsRepository;

  AppSettingsCubit(this.appSettingsRepository) : super(AppSettingsInitial());

  AppSettingModel? get currentSettings {
    final s = state;
    if (s is AppSettingsLoaded) return s.settings;
    if (s is AppSettingsSaving) return s.currentSettings;
    if (s is AppSettingsError) return s.lastSettings;
    return appSettingsRepository.currentAppSettings;
  }

  bool get useCost => currentSettings?.useCost ?? false;
  bool get usePrice2 => currentSettings?.usePrice2 ?? false;
  bool get allowEditPrice => currentSettings?.allowEditPrice ?? false;

  Future<void> loadSettings() async {
    emit(AppSettingsLoading());
    try {
      final settings = await appSettingsRepository.getCurrentAppSettings();
      emit(AppSettingsLoaded(settings));
    } catch (e) {
      emit(AppSettingsError(e.toString()));
    }
  }

  Future<bool> updateSettings(UpdateAppSetting update) async {
    var current = currentSettings;

    if (current == null) {
      try {
        current = await appSettingsRepository.getCurrentAppSettings();
      } catch (_) {}
    }

    if (current == null) {
      emit(const AppSettingsError("No hay configuración activa cargada"));
      return false;
    }

    emit(AppSettingsSaving(current));
    try {
      final updated = await appSettingsRepository.updateAppSettings(
        current.id,
        update,
      );
      emit(AppSettingsLoaded(updated));
      return true;
    } catch (e) {
      emit(AppSettingsError(e.toString(), lastSettings: current));
      return false;
    }
  }
}
