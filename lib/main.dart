import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_flutter/app.dart';
import 'package:mobile_flutter/core/services/push_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
    
    // Initialize Push Notifications (skip full init on web for now)
    if (!kIsWeb) {
      await PushNotificationService().initialize();
    } else {
      debugPrint('⚠️ Push notifications limited on web');
    }
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
    // Continue without Firebase on web if there's an error
  }
  
  runApp(const SafeZoneApp());
}
