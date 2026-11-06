// API Constants

class ApiConstants {
  ApiConstants._();

  static const String _defaultPublicBaseUrl =
      'https://safezone-be.onrender.com/api/v1';

  static String get baseUrl {
    // Allow overriding API URL at build/run time:
    // flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3002/api/v1
    // or: flutter run --dart-define=API_HOST=192.168.1.10
    const explicitBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (explicitBaseUrl.isNotEmpty) return explicitBaseUrl;

    const apiScheme = String.fromEnvironment(
      'API_SCHEME',
      defaultValue: 'http',
    );
    const apiHost = String.fromEnvironment('API_HOST');
    const apiPort = int.fromEnvironment('API_PORT', defaultValue: 3002);
    if (apiHost.isNotEmpty) return '$apiScheme://$apiHost:$apiPort/api/v1';

    // Default: use public backend.
    // For local development, pass --dart-define=API_BASE_URL=... (recommended)
    // or --dart-define=API_HOST=... to override.
    return _defaultPublicBaseUrl;
  }

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';
  static const String verifyToken = '/auth/verify';
  static const String updateFcmToken = '/auth/fcm-token';
  static const String verificationStatus = '/auth/verification-status';
  static const String sendEmailOtp = '/auth/send-email-otp';
  static const String verifyEmail = '/auth/verify-email';
  static const String sendPhoneOtp = '/auth/send-phone-otp';
  static const String verifyPhone = '/auth/verify-phone';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Report endpoints
  static const String reports = '/reports';
  static const String myReports = '/reports/my-reports';
  static const String reportsNearby = '/reports/nearby';
  static const String reportsStats = '/reports/stats';

  // Zone endpoints
  static const String zones = '/zones';
  static const String zonesNearby = '/zones/nearby';
  static const String zonesStats = '/zones/stats';
  static const String zonesCheck = '/zones/check';
  static const String zonesCheckLocation = '/zones/check-location';

  // Post endpoints
  static const String posts = '/posts';
  static const String myPosts = '/posts/my-posts';

  // Disease endpoints
  static const String diseases = '/diseases';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnread = '/notifications/unread';

  // GIS endpoints
  static const String gisCases = '/gis/cases';
  static const String gisStats = '/gis/stats';
}
