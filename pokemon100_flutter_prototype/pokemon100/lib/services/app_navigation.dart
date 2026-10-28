import 'package:flutter/material.dart';

/// Shared navigator key used by app-wide update and notification prompts.
class AppNavigation {
  AppNavigation._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}
