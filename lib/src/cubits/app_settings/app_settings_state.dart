import 'package:serum_business/serum_business.dart';

abstract class AppSettingsState {
  const AppSettingsState();
}

class AppSettingsInitial extends AppSettingsState {}

class AppSettingsLoading extends AppSettingsState {}

class AppSettingsLoaded extends AppSettingsState {
  final AppSettingModel settings;

  const AppSettingsLoaded(this.settings);
}

class AppSettingsSaving extends AppSettingsState {
  final AppSettingModel currentSettings;

  const AppSettingsSaving(this.currentSettings);
}

class AppSettingsError extends AppSettingsState {
  final String message;
  final AppSettingModel? lastSettings;

  const AppSettingsError(this.message, {this.lastSettings});
}
