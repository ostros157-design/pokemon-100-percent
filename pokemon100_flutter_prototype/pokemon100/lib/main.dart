import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_appearance.dart';
import 'services/app_navigation.dart';
import 'services/app_update_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppAppearance.load();
  runApp(const PokemonGuideApp());
}

class PokemonGuideApp extends StatefulWidget {
  const PokemonGuideApp({super.key});

  @override
  State<PokemonGuideApp> createState() => _PokemonGuideAppState();
}

class _PokemonGuideAppState extends State<PokemonGuideApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.initialize());
      AppUpdateService.startDailyChecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppAppearance.darkBackground,
      builder: (context, isDark, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: AppAppearance.textColor,
          builder: (context, textColor, _) {
            return ValueListenableBuilder<Color>(
              valueListenable: AppAppearance.badgeColor,
              builder: (context, badgeColor, _) {
                final background = isDark ? const Color(0xFF121212) : Colors.white;
                final foreground = isDark && textColor == const Color(0xFF202124)
                    ? Colors.white
                    : textColor;
                final scheme = ColorScheme.fromSeed(
                  seedColor: badgeColor,
                  brightness: isDark ? Brightness.dark : Brightness.light,
                  surface: background,
                );
                return MaterialApp(
                  navigatorKey: AppNavigation.navigatorKey,
                  debugShowCheckedModeBanner: false,
                  title: 'Pokémon Guide',
                  theme: ThemeData(
                    useMaterial3: true,
                    colorScheme: scheme,
                    scaffoldBackgroundColor: background,
                    canvasColor: background,
                    appBarTheme: AppBarTheme(
                      centerTitle: true,
                      elevation: 0,
                      backgroundColor: background,
                      foregroundColor: foreground,
                    ),
                    textTheme: ThemeData(
                      brightness: isDark ? Brightness.dark : Brightness.light,
                    ).textTheme.apply(
                      bodyColor: foreground,
                      displayColor: foreground,
                    ),
                    chipTheme: ChipThemeData(
                      backgroundColor: badgeColor.withOpacity(0.14),
                      labelStyle: TextStyle(color: foreground),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: badgeColor.withOpacity(0.22)),
                      ),
                    ),
                    listTileTheme: ListTileThemeData(
                      textColor: foreground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    cardTheme: CardThemeData(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: badgeColor.withOpacity(0.18)),
                      ),
                    ),
                    dialogTheme: DialogThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    bottomSheetTheme: const BottomSheetThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: badgeColor.withOpacity(0.35)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: badgeColor, width: 2),
                      ),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    outlinedButtonTheme: OutlinedButtonThemeData(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  home: const HomeScreen(),
                );
              },
            );
          },
        );
      },
    );
  }
}
