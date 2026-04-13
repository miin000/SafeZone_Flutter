import 'package:flutter/material.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get state => navigatorKey.currentState;
  static BuildContext? get context => navigatorKey.currentContext;
}
