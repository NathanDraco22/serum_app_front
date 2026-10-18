import 'dart:convert';

import 'package:serum_business/serum_business.dart';

class AppConfigManager with HiveService implements AppConfigStore {
  final _configBox = 'app_config_box';
  final _configKey = 'servin_config_key';

  static final AppConfigManager _instance = AppConfigManager._internal();
  factory AppConfigManager() => _instance;
  AppConfigManager._internal();

  @override
  Future<void> setConfig(Map<String, dynamic> config) async {
    final jsonString = json.encode(config);
    final box = await getBox(_configBox);
    await box.put(_configKey, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> getConfig() async {
    final box = await getBox(_configBox);
    final jsonString = box.get(_configKey);
    if (jsonString == null) return null;
    final config = json.decode(jsonString as String);
    return config as Map<String, dynamic>;
  }

  final _branchKey = 'selected_branch_key';

  @override
  Future<void> clearConfig() async {
    final box = await getBox(_configBox);
    await box.clear();
  }

  Future<void> saveSelectedBranchId(String branchId) async {
    final box = await getBox(_configBox);
    await box.put(_branchKey, branchId);
  }

  Future<String?> getSelectedBranchId() async {
    final box = await getBox(_configBox);
    final branchId = box.get(_branchKey);
    return branchId as String?;
  }

  Future<void> clearSelectedBranchId() async {
    final box = await getBox(_configBox);
    await box.delete(_branchKey);
  }
}
