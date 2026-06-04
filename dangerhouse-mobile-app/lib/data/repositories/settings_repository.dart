import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String keyFasterRcnnEnabled = 'settings_faster_rcnn_enabled';
  static const String keyRiskAnalysisEnabled = 'settings_risk_analysis_enabled';
  static const String keyDbscanEnabled = 'settings_dbscan_enabled';
  static const String keyAutoUpload = 'settings_auto_upload';
  static const String keyOfflineCache = 'settings_offline_cache';
  static const String keyWifiOnly = 'settings_wifi_only';
  static const String keySensitivity = 'settings_sensitivity';
  static const String keyConfThreshold = 'settings_conf_threshold';

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fasterRcnnEnabled': prefs.getBool(keyFasterRcnnEnabled) ?? true,
      'riskAnalysisEnabled': prefs.getBool(keyRiskAnalysisEnabled) ?? true,
      'dbscanEnabled': prefs.getBool(keyDbscanEnabled) ?? true,
      'autoUpload': prefs.getBool(keyAutoUpload) ?? true,
      'offlineCache': prefs.getBool(keyOfflineCache) ?? true,
      'wifiOnly': prefs.getBool(keyWifiOnly) ?? false,
      'sensitivity': prefs.getDouble(keySensitivity) ?? 85.0,
      'confThreshold': prefs.getDouble(keyConfThreshold) ?? 0.72,
    };
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyFasterRcnnEnabled, settings['fasterRcnnEnabled']);
    await prefs.setBool(keyRiskAnalysisEnabled, settings['riskAnalysisEnabled']);
    await prefs.setBool(keyDbscanEnabled, settings['dbscanEnabled']);
    await prefs.setBool(keyAutoUpload, settings['autoUpload']);
    await prefs.setBool(keyOfflineCache, settings['offlineCache']);
    await prefs.setBool(keyWifiOnly, settings['wifiOnly']);
    await prefs.setDouble(keySensitivity, settings['sensitivity']);
    await prefs.setDouble(keyConfThreshold, settings['confThreshold']);
  }
}
