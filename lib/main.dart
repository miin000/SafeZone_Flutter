import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_flutter/app.dart';
import 'package:mobile_flutter/core/services/push_notification_service.dart';
import 'package:mobile_flutter/data/adapters/hive_adapters.dart';
import 'package:mobile_flutter/data/models/post_model.dart';
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

  try {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    registerHiveAdapters();

    // Clear corrupted boxes and recreate
    try {
      if (Hive.isBoxOpen('posts_box')) {
        await Hive.box('posts_box').clear();
      }
      if (Hive.isBoxOpen('draft_posts_box')) {
        await Hive.box('draft_posts_box').clear();
      }
    } catch (e) {
      debugPrint('Error clearing boxes: $e');
    }

    // Open boxes with error handling
    try {
      await Hive.openBox<PostModel>('posts_box');
    } catch (e) {
      debugPrint('Error opening posts_box: $e');
      // Delete and recreate
      await Hive.deleteBoxFromDisk('posts_box');
      await Hive.openBox<PostModel>('posts_box');
    }

    try {
      await Hive.openBox<Map<String, dynamic>>('draft_posts_box');
    } catch (e) {
      debugPrint('Error opening draft_posts_box: $e');
      // Delete and recreate
      await Hive.deleteBoxFromDisk('draft_posts_box');
      await Hive.openBox<Map<String, dynamic>>('draft_posts_box');
    }
  } catch (e) {
    debugPrint('Error initializing Hive: $e');
  }
  
  runApp(const SafeZoneApp());
}
