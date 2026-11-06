import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../firebase_options.dart';

// Conditional import for platform check
import 'platform_check_stub.dart'
    if (dart.library.io) 'platform_check_io.dart'
    as platform_check;

/// Handle background messages (not supported on web)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Background message received: ${message.notification?.title}');
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  Future<void>? _initializeFuture;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Notification channels for Android
  static const AndroidNotificationChannel _alertChannel =
      AndroidNotificationChannel(
        'safezone_alerts',
        'Cảnh báo dịch bệnh',
        description: 'Thông báo khi bạn vào vùng dịch hoặc có cảnh báo mới',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  static const AndroidNotificationChannel _generalChannel =
      AndroidNotificationChannel(
        'safezone_general',
        'Thông báo chung',
        description: 'Thông báo bài viết mới, cập nhật hệ thống',
        importance: Importance.defaultImportance,
      );

  static const AndroidNotificationChannel _socialChannel =
      AndroidNotificationChannel(
        'safezone_social',
        'Tin nhắn & bài viết',
        description: 'Thông báo khi có tin nhắn hoặc bài viết mới',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  // Callbacks for handling notifications
  Function(Map<String, dynamic>)? onNotificationTap;
  Function(RemoteMessage)? onForegroundMessage;

  /// Initialize push notifications
  Future<void> initialize() {
    _initializeFuture ??= _initializeInternal();
    return _initializeFuture!;
  }

  Future<void> _initializeInternal() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Local notifications first (needed for Android permission prompt + channels)
      await _initializeLocalNotifications();
      await _createNotificationChannels();

      // Request permission (Android 13+/iOS)
      await _requestPermission();

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
    if (!kIsWeb && platform_check.isAndroid) {
      // Android 13+ requires POST_NOTIFICATIONS runtime permission.
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      try {
        await androidPlugin?.requestNotificationsPermission();
      } catch (_) {
        // ignore
      }

      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

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
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.createNotificationChannel(_alertChannel);
      await androidPlugin?.createNotificationChannel(_generalChannel);
      await androidPlugin?.createNotificationChannel(_socialChannel);
    }
  }

  Future<void> _getToken() async {
    try {
      if (kIsWeb) {
        // For web, use VAPID key from Firebase Console
        _fcmToken = await _messaging.getToken(
          vapidKey:
              'BJu4gpc7daZbPc3qR_5Q3U5Uw0aBoTUgASdHmzu7WGfdv8r-huS5FeTEE51dHK9BfB8adrB6OQeVH2b-VE-rbwY',
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

    final notification = message.notification;
    if (notification == null || kIsWeb) return;

    showLocalNotification(
      id: notification.hashCode,
      title: notification.title ?? 'SafeZone',
      body: notification.body ?? '',
      data: message.data,
      type: (message.data['type'] ?? '').toString(),
      androidSmallIcon:
          message.notification?.android?.smallIcon ?? '@mipmap/ic_launcher',
    );
  }

  bool _isAlertType(String type) {
    final t = type.trim().toLowerCase();
    return t == 'zone_entry' ||
        t == 'epidemic_alert' ||
        t == 'zone_warning' ||
        t == 'epidemic_warning';
  }

  bool _isMessageOrPostType(String type) {
    final t = type.trim().toLowerCase();
    return t == 'new_message' ||
        t == 'message' ||
        t == 'chat_message' ||
        t == 'new_post' ||
        t == 'post' ||
        t == 'post_created';
  }

  /// Show a local heads-up notification (used for FCM foreground + periodic warnings).
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String type = 'system',
    String? androidSmallIcon,
  }) async {
    if (kIsWeb) return;

    final isAlert = _isAlertType(type);
    final isMessageOrPost = _isMessageOrPostType(type);

    final channel = isAlert
        ? _alertChannel
        : (isMessageOrPost ? _socialChannel : _generalChannel);
    final importance = isAlert
        ? Importance.max
        : (isMessageOrPost ? Importance.high : Importance.defaultImportance);
    final priority = isAlert
        ? Priority.max
        : (isMessageOrPost ? Priority.high : Priority.defaultPriority);

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: importance,
      priority: priority,
      icon: androidSmallIcon ?? '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: isAlert || isMessageOrPost,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: data == null ? null : jsonEncode(data),
    );
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
