import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_flutter/app.dart';
import 'package:mobile_flutter/data/adapters/hive_adapters.dart';
import 'package:mobile_flutter/data/models/post_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      print('Error clearing boxes: $e');
    }

    // Open boxes with error handling
    try {
      await Hive.openBox<PostModel>('posts_box');
    } catch (e) {
      print('Error opening posts_box: $e');
      // Delete and recreate
      await Hive.deleteBoxFromDisk('posts_box');
      await Hive.openBox<PostModel>('posts_box');
    }

    try {
      await Hive.openBox<Map<String, dynamic>>('draft_posts_box');
    } catch (e) {
      print('Error opening draft_posts_box: $e');
      // Delete and recreate
      await Hive.deleteBoxFromDisk('draft_posts_box');
      await Hive.openBox<Map<String, dynamic>>('draft_posts_box');
    }

    runApp(const SafeZoneApp());
  } catch (e) {
    print('Fatal error in main: $e');
    runApp(const SafeZoneApp());
  }
}