// API Constants
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    // Flutter Web
    if (kIsWeb) {
      return 'http://localhost:3001/api/v1';
    }

    // Mobile platforms
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      // Android emulator -> host machine
        return 'http://10.0.2.2:3001/api/v1';

      case TargetPlatform.iOS:
      // iOS simulator
        return 'http://localhost:3001/api/v1';

      default:
      // Windows / macOS / Linux
        return 'http://localhost:3001/api/v1';
    }
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

  // Post endpoints
  static const String posts = '/posts';
  static const String myPosts = '/posts/my-posts';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnread = '/notifications/unread';

  // GIS endpoints
  static const String gisCases = '/gis/cases';
  static const String gisStats = '/gis/stats';
}
