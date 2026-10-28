import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import 'app_navigation.dart';

/// Google Play in-app updates. This API works only for eligible builds
/// installed from Google Play (including a testing track), not sideloaded APKs.
class AppUpdateService {
  AppUpdateService._();

  static Timer? _dailyTimer;
  static bool _checkInProgress = false;
  static bool _dialogVisible = false;

  static void startDailyChecks() {
    // Initial check after the first frame, then repeat every 24 hours while
    // the app process remains alive. A new launch always checks again.
    unawaited(checkForUpdate());
    _dailyTimer?.cancel();
    _dailyTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => unawaited(checkForUpdate()),
    );
  }

  static Future<void> checkForUpdate({
    BuildContext? context,
    bool showStatusWhenUnavailable = false,
  }) async {
    if (!Platform.isAndroid || _checkInProgress) return;

    _checkInProgress = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await _showUpdatePrompt();
      } else if (showStatusWhenUnavailable && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie znaleziono nowej wersji w Google Play.')),
        );
      }
    } catch (_) {
      if (showStatusWhenUnavailable && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nie udało się sprawdzić aktualizacji. Sprawdź, czy aplikacja '
              'została zainstalowana z Google Play (kanał testowy).',
            ),
          ),
        );
      }
      // A missing Play Store release, sideloaded build, or offline device must
      // not prevent the rest of the app from starting.
    } finally {
      _checkInProgress = false;
    }
  }

  static Future<void> _showUpdatePrompt() async {
    final context = AppNavigation.navigatorKey.currentContext;
    if (context == null || _dialogVisible) return;

    _dialogVisible = true;
    try {
      final shouldUpdate = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Dostępna aktualizacja'),
          content: const Text(
            'W Google Play jest dostępna nowsza wersja Pokémon 100%. '
            'Możesz rozpocząć aktualizację bez ręcznego szukania pliku APK.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Później'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Aktualizuj teraz'),
            ),
          ],
        ),
      );

      if (shouldUpdate == true) {
        try {
          await InAppUpdate.performImmediateUpdate();
        } catch (_) {
          final currentContext = AppNavigation.navigatorKey.currentContext;
          if (currentContext != null) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              const SnackBar(
                content: Text(
                  'Google Play nie mogło rozpocząć aktualizacji. Spróbuj ponownie później.',
                ),
              ),
            );
          }
        }
      }
    } finally {
      _dialogVisible = false;
    }
  }
}
