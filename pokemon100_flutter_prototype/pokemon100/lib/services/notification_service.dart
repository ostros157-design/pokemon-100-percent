import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app_navigation.dart';

/// Optional FCM integration. It safely stays inactive until Firebase's Android
/// configuration and Google Services Gradle plugin are added to the project.
class NotificationService {
  NotificationService._();

  static bool isConfigured = false;
  static bool _initializing = false;

  static Future<bool> initialize() async {
    if (isConfigured) return true;
    if (_initializing) return false;

    _initializing = true;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setAutoInitEnabled(true);

      FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_showForegroundMessage);
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _showForegroundMessage(initialMessage);
      }

      isConfigured = true;
      return true;
    } catch (_) {
      // Firebase configuration is intentionally not committed to this private
      // source tree. Until setup is completed, push notifications remain off.
      return false;
    } finally {
      _initializing = false;
    }
  }

  static void _showForegroundMessage(RemoteMessage message) {
    final context = AppNavigation.navigatorKey.currentContext;
    if (context == null) return;

    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title?.isNotEmpty == true ? title! : 'Pokémon 100%'),
        content: Text(body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }
}
