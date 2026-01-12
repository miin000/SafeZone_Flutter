// API Constants
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // Base URL configuration
  static String get baseUrl {
    // Web should use the current host to avoid dart:io Platform checks
    if (kIsWeb) {
      final scheme = Uri.base.scheme; // http or https
      final host = Uri.base.host; // e.g., localhost or domain
      // Prefer explicit API port (3001) used by NestJS backend
      return '$scheme://$host:3001/api/v1';
    }

    // Android emulator uses 10.0.2.2 to access host machine
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3001/api/v1';
    }

    // iOS simulator / other platforms use localhost
    return 'http://localhost:3001/api/v1';
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
