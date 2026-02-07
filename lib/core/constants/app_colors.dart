import 'package:flutter/material.dart';

/// App-wide color constants
/// These colors are synchronized with the web admin interface
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // === SEVERITY/RISK LEVEL COLORS ===
  // Synchronized with web admin SEVERITY_COLORS
  
  /// Low severity/risk - Green
  static const Color severityLow = Color(0xFF2ca02c);
  
  /// Medium severity/risk - Orange
  static const Color severityMedium = Color(0xFFff7f0e);
  
  /// High severity/risk - Red
  static const Color severityHigh = Color(0xFFd62728);

  // === DISEASE TYPE COLORS ===
  // Can be customized per disease type in the future
  
  static const Color covid19 = Color(0xFF1f77b4);
  static const Color dengue = Color(0xFFff7f0e);
  static const Color influenza = Color(0xFF2ca02c);
  static const Color handFootMouth = Color(0xFFd62728);
  static const Color cholera = Color(0xFF9467bd);
  static const Color unknown = Color(0xFF7f7f7f);

  // === STATUS COLORS ===
  
  static const Color statusActive = Color(0xFFff7043);
  static const Color statusRecovered = Color(0xFF66bb6a);
  static const Color statusDeath = Color(0xFFef5350);
  static const Color statusUnknown = Color(0xFF90a4ae);
}
