import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';

// Conditional import for platform check
import 'platform_check_stub.dart'
    if (dart.library.io) 'platform_check_io.dart' as platform_check;

/// Handle background messages (not supported on web)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Background message received: ${message.notification?.title}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Notification channels for Android
  static const AndroidNotificationChannel _alertChannel = AndroidNotificationChannel(
    'safezone_alerts',
    'Cảnh báo dịch bệnh',
    description: 'Thông báo khi bạn vào vùng dịch hoặc có cảnh báo mới',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _generalChannel = AndroidNotificationChannel(
    'safezone_general',
    'Thông báo chung',
    description: 'Thông báo bài viết mới, cập nhật hệ thống',
    importance: Importance.defaultImportance,
  );

  // Callbacks for handling notifications
  Function(Map<String, dynamic>)? onNotificationTap;
  Function(RemoteMessage)? onForegroundMessage;

  /// Initialize push notifications
  Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Create notification channels for Android
      await _createNotificationChannels();

      // Get FCM token
      await _getToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('🔄 FCM Token refreshed: ${token.substring(0, 20)}...');
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Subscribe to 'all' topic for broadcasts
      await _messaging.subscribeToTopic('all');

      debugPrint('✅ Push notifications initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize push notifications: $e');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
      announcement: true,
    );

    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          onNotificationTap?.call(data);
        }
      },
    );
  }

  Future<void> _createNotificationChannels() async {
    if (!kIsWeb && platform_check.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.createNotificationChannel(_alertChannel);
      await androidPlugin?.createNotificationChannel(_generalChannel);
    }
  }

  Future<void> _getToken() async {
    try {
      if (kIsWeb) {
        // For web, use VAPID key from Firebase Console
        _fcmToken = await _messaging.getToken(
          vapidKey: 'BJu4gpc7daZbPc3qR_5Q3U5Uw0aBoTUgASdHmzu7WGfdv8r-huS5FeTEE51dHK9BfB8adrB6OQeVH2b-VE-rbwY',
        );
      } else {
        _fcmToken = await _messaging.getToken();
      }

      if (_fcmToken != null) {
        debugPrint('🔑 FCM Token: ${_fcmToken!.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground message: ${message.notification?.title}');

    onForegroundMessage?.call(message);

    // Show local notification
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      final isAlert = message.data['type'] == 'zone_entry' ||
          message.data['type'] == 'epidemic_alert';

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            isAlert ? _alertChannel.id : _generalChannel.id,
            isAlert ? _alertChannel.name : _generalChannel.name,
            channelDescription: isAlert ? _alertChannel.description : _generalChannel.description,
            importance: isAlert ? Importance.max : Importance.defaultImportance,
            priority: isAlert ? Priority.max : Priority.defaultPriority,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: isAlert,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.notification?.title}');
    onNotificationTap?.call(message.data);
  }

  /// Subscribe to a topic (e.g., zone alerts for a specific region)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('📥 Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('📤 Unsubscribed from topic: $topic');
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    _fcmToken = null;
    debugPrint('🗑️ FCM Token deleted');
  }
}
