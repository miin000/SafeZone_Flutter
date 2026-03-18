import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_flutter/data/models/settings_model.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _storageKey = 'app_settings';
  AppSettings _settings = AppSettings.defaultSettings();

  AppSettings get settings => _settings;

  // Appearance
  AppTheme get theme => _settings.theme;
  bool get isDarkMode => _settings.theme == AppTheme.dark;
  FontSize get fontSize => _settings.fontSize;
  bool get reduceAnimations => _settings.reduceAnimations;
  bool get highContrastMode => _settings.highContrastMode;

  // Notifications
  bool get receiveNotifications => _settings.receiveNotifications;
  NotificationType get notificationType => _settings.notificationType;
  bool get notificationSound => _settings.notificationSound;
  bool get notificationVibration => _settings.notificationVibration;
  bool get showNotificationPreview => _settings.showNotificationPreview;

  // Privacy & Security
  bool get locationTracking => _settings.locationTracking;
  bool get biometricAuth => _settings.biometricAuth;
  bool get autoLogin => _settings.autoLogin;
  bool get shareAnonymousData => _settings.shareAnonymousData;
  bool get saveLoginHistory => _settings.saveLoginHistory;

  // General
  Language get language => _settings.language;
  DataUsage get dataUsage => _settings.dataUsage;
  MapStyle get mapStyle => _settings.mapStyle;
  bool get autoUpdate => _settings.autoUpdate;
  bool get crashReports => _settings.crashReports;

  // Advanced
  bool get developerMode => _settings.developerMode;
  bool get debugLogging => _settings.debugLogging;
  bool get showPerformanceOverlay => _settings.showPerformanceOverlay;

  // Update methods for new settings
  void updateFontSize(FontSize size) {
    _settings = _settings.copyWith(fontSize: size);
    _saveSettings();
    notifyListeners();
  }

  void toggleReduceAnimations(bool value) {
    _settings = _settings.copyWith(reduceAnimations: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleHighContrastMode(bool value) {
    _settings = _settings.copyWith(highContrastMode: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleNotificationSound(bool value) {
    _settings = _settings.copyWith(notificationSound: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleNotificationVibration(bool value) {
    _settings = _settings.copyWith(notificationVibration: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShowNotificationPreview(bool value) {
    _settings = _settings.copyWith(showNotificationPreview: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleShareAnonymousData(bool value) {
    _settings = _settings.copyWith(shareAnonymousData: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleSaveLoginHistory(bool value) {
    _settings = _settings.copyWith(saveLoginHistory: value);
    _saveSettings();
    notifyListeners();
  }

  void updateDataUsage(DataUsage usage) {
    _settings = _settings.copyWith(dataUsage: usage);
    _saveSettings();
    notifyListeners();
  }

  void updateMapStyle(MapStyle style) {
    _settings = _settings.copyWith(mapStyle: style);
    _saveSettings();
    notifyListeners();
  }

  void toggleAutoUpdate(bool value) {
    _settings = _settings.copyWith(autoUpdate: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleCrashReports(bool value) {
    _settings = _settings.copyWith(crashReports: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleDeveloperMode(bool value) {
    _settings = _settings.copyWith(developerMode: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleDebugLogging(bool value) {
    _settings = _settings.copyWith(debugLogging: value);
    _saveSettings();
    notifyListeners();
  }

  void togglePerformanceOverlay(bool value) {
    _settings = _settings.copyWith(showPerformanceOverlay: value);
    _saveSettings();
    notifyListeners();
  }

  // Existing methods (keep these)
  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    _saveSettings();
    notifyListeners();
  }

  void updateTheme(AppTheme theme) {
    _settings = _settings.copyWith(theme: theme);
    _saveSettings();
    notifyListeners();
  }

  void toggleTheme() {
    _settings = _settings.copyWith(
      theme: _settings.theme == AppTheme.light ? AppTheme.dark : AppTheme.light,
    );
    _saveSettings();
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _settings = _settings.copyWith(receiveNotifications: value);
    _saveSettings();
    notifyListeners();
  }

  void updateNotificationType(NotificationType type) {
    _settings = _settings.copyWith(notificationType: type);
    _saveSettings();
    notifyListeners();
  }

  void toggleLocationTracking(bool value) {
    _settings = _settings.copyWith(locationTracking: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleBiometricAuth(bool value) {
    _settings = _settings.copyWith(biometricAuth: value);
    _saveSettings();
    notifyListeners();
  }

  void toggleAutoLogin(bool value) {
    _settings = _settings.copyWith(autoLogin: value);
    _saveSettings();
    notifyListeners();
  }

  void updateLanguage(Language language) {
    _settings = _settings.copyWith(language: language);
    _saveSettings();
    notifyListeners();
  }

  void resetToDefaults() {
    _settings = AppSettings.defaultSettings();
    _saveSettings();
    notifyListeners();
  }

  // Simulate saving to storage
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_settings.toJson()));

    if (kDebugMode) {
      print('Settings saved: ${_settings.toJson()}');
    }
  }

  // Load settings from storage
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _settings = AppSettings.fromJson(decoded);
      }
    }
    notifyListeners();
  }
}