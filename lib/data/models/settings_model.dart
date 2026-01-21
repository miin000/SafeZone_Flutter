import 'package:equatable/equatable.dart';

enum AppTheme { light, dark, system }
enum NotificationType { all, zoneAlerts, reportUpdates, systemOnly }
enum Language { vietnamese, english }
enum MapStyle { standard, satellite, hybrid }
enum FontSize { small, medium, large }
enum DataUsage { low, medium, high }

class AppSettings extends Equatable {
  // Appearance
  final AppTheme theme;
  final FontSize fontSize;
  final bool reduceAnimations;
  final bool highContrastMode;

  // Notifications
  final bool receiveNotifications;
  final NotificationType notificationType;
  final bool notificationSound;
  final bool notificationVibration;
  final bool showNotificationPreview;

  // Privacy & Security
  final bool locationTracking;
  final bool biometricAuth;
  final bool autoLogin;
  final bool shareAnonymousData;
  final bool saveLoginHistory;

  // General
  final Language language;
  final DataUsage dataUsage;
  final MapStyle mapStyle;
  final bool autoUpdate;
  final bool crashReports;

  // Advanced
  final bool developerMode;
  final bool debugLogging;
  final bool showPerformanceOverlay;

  const AppSettings({
    // Appearance
    this.theme = AppTheme.light,
    this.fontSize = FontSize.medium,
    this.reduceAnimations = false,
    this.highContrastMode = false,

    // Notifications
    this.receiveNotifications = true,
    this.notificationType = NotificationType.all,
    this.notificationSound = true,
    this.notificationVibration = true,
    this.showNotificationPreview = true,

    // Privacy & Security
    this.locationTracking = true,
    this.biometricAuth = false,
    this.autoLogin = true,
    this.shareAnonymousData = true,
    this.saveLoginHistory = true,

    // General
    this.language = Language.vietnamese,
    this.dataUsage = DataUsage.medium,
    this.mapStyle = MapStyle.standard,
    this.autoUpdate = true,
    this.crashReports = true,

    // Advanced
    this.developerMode = false,
    this.debugLogging = false,
    this.showPerformanceOverlay = false,
  });

  factory AppSettings.defaultSettings() {
    return const AppSettings();
  }

  Map<String, dynamic> toJson() {
    return {
      // Appearance
      'theme': theme.name,
      'fontSize': fontSize.name,
      'reduceAnimations': reduceAnimations,
      'highContrastMode': highContrastMode,

      // Notifications
      'receiveNotifications': receiveNotifications,
      'notificationType': notificationType.name,
      'notificationSound': notificationSound,
      'notificationVibration': notificationVibration,
      'showNotificationPreview': showNotificationPreview,

      // Privacy & Security
      'locationTracking': locationTracking,
      'biometricAuth': biometricAuth,
      'autoLogin': autoLogin,
      'shareAnonymousData': shareAnonymousData,
      'saveLoginHistory': saveLoginHistory,

      // General
      'language': language.name,
      'dataUsage': dataUsage.name,
      'mapStyle': mapStyle.name,
      'autoUpdate': autoUpdate,
      'crashReports': crashReports,

      // Advanced
      'developerMode': developerMode,
      'debugLogging': debugLogging,
      'showPerformanceOverlay': showPerformanceOverlay,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      // Appearance
      theme: _parseTheme(json['theme']),
      fontSize: _parseFontSize(json['fontSize']),
      reduceAnimations: json['reduceAnimations'] ?? false,
      highContrastMode: json['highContrastMode'] ?? false,

      // Notifications
      receiveNotifications: json['receiveNotifications'] ?? true,
      notificationType: _parseNotificationType(json['notificationType']),
      notificationSound: json['notificationSound'] ?? true,
      notificationVibration: json['notificationVibration'] ?? true,
      showNotificationPreview: json['showNotificationPreview'] ?? true,

      // Privacy & Security
      locationTracking: json['locationTracking'] ?? true,
      biometricAuth: json['biometricAuth'] ?? false,
      autoLogin: json['autoLogin'] ?? true,
      shareAnonymousData: json['shareAnonymousData'] ?? true,
      saveLoginHistory: json['saveLoginHistory'] ?? true,

      // General
      language: _parseLanguage(json['language']),
      dataUsage: _parseDataUsage(json['dataUsage']),
      mapStyle: _parseMapStyle(json['mapStyle']),
      autoUpdate: json['autoUpdate'] ?? true,
      crashReports: json['crashReports'] ?? true,

      // Advanced
      developerMode: json['developerMode'] ?? false,
      debugLogging: json['debugLogging'] ?? false,
      showPerformanceOverlay: json['showPerformanceOverlay'] ?? false,
    );
  }

  static AppTheme _parseTheme(String? theme) {
    switch (theme) {
      case 'dark':
        return AppTheme.dark;
      case 'system':
        return AppTheme.system;
      default:
        return AppTheme.light;
    }
  }

  static FontSize _parseFontSize(String? size) {
    switch (size) {
      case 'small':
        return FontSize.small;
      case 'large':
        return FontSize.large;
      default:
        return FontSize.medium;
    }
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'zoneAlerts':
        return NotificationType.zoneAlerts;
      case 'reportUpdates':
        return NotificationType.reportUpdates;
      case 'systemOnly':
        return NotificationType.systemOnly;
      default:
        return NotificationType.all;
    }
  }

  static Language _parseLanguage(String? lang) {
    switch (lang) {
      case 'english':
        return Language.english;
      default:
        return Language.vietnamese;
    }
  }

  static DataUsage _parseDataUsage(String? usage) {
    switch (usage) {
      case 'low':
        return DataUsage.low;
      case 'high':
        return DataUsage.high;
      default:
        return DataUsage.medium;
    }
  }

  static MapStyle _parseMapStyle(String? style) {
    switch (style) {
      case 'satellite':
        return MapStyle.satellite;
      case 'hybrid':
        return MapStyle.hybrid;
      default:
        return MapStyle.standard;
    }
  }

  AppSettings copyWith({
    // Appearance
    AppTheme? theme,
    FontSize? fontSize,
    bool? reduceAnimations,
    bool? highContrastMode,

    // Notifications
    bool? receiveNotifications,
    NotificationType? notificationType,
    bool? notificationSound,
    bool? notificationVibration,
    bool? showNotificationPreview,

    // Privacy & Security
    bool? locationTracking,
    bool? biometricAuth,
    bool? autoLogin,
    bool? shareAnonymousData,
    bool? saveLoginHistory,

    // General
    Language? language,
    DataUsage? dataUsage,
    MapStyle? mapStyle,
    bool? autoUpdate,
    bool? crashReports,

    // Advanced
    bool? developerMode,
    bool? debugLogging,
    bool? showPerformanceOverlay,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      highContrastMode: highContrastMode ?? this.highContrastMode,

      receiveNotifications: receiveNotifications ?? this.receiveNotifications,
      notificationType: notificationType ?? this.notificationType,
      notificationSound: notificationSound ?? this.notificationSound,
      notificationVibration: notificationVibration ?? this.notificationVibration,
      showNotificationPreview: showNotificationPreview ?? this.showNotificationPreview,

      locationTracking: locationTracking ?? this.locationTracking,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      autoLogin: autoLogin ?? this.autoLogin,
      shareAnonymousData: shareAnonymousData ?? this.shareAnonymousData,
      saveLoginHistory: saveLoginHistory ?? this.saveLoginHistory,

      language: language ?? this.language,
      dataUsage: dataUsage ?? this.dataUsage,
      mapStyle: mapStyle ?? this.mapStyle,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      crashReports: crashReports ?? this.crashReports,

      developerMode: developerMode ?? this.developerMode,
      debugLogging: debugLogging ?? this.debugLogging,
      showPerformanceOverlay: showPerformanceOverlay ?? this.showPerformanceOverlay,
    );
  }

  @override
  List<Object?> get props => [
    theme,
    fontSize,
    reduceAnimations,
    highContrastMode,
    receiveNotifications,
    notificationType,
    notificationSound,
    notificationVibration,
    showNotificationPreview,
    locationTracking,
    biometricAuth,
    autoLogin,
    shareAnonymousData,
    saveLoginHistory,
    language,
    dataUsage,
    mapStyle,
    autoUpdate,
    crashReports,
    developerMode,
    debugLogging,
    showPerformanceOverlay,
  ];
}