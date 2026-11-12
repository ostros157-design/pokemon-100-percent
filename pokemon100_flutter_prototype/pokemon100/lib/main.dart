import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_appearance.dart';
import 'services/app_navigation.dart';
import 'services/app_update_service.dart';
import 'services/notification_service.dart';
import 'services/pokemon_music_service.dart';

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
      unawaited(PokemonMusicService.instance.startIfEnabled());
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
                return ValueListenableBuilder<String>(
                  valueListenable: AppAppearance.visualStyle,
                  builder: (context, visualStyle, _) {
                final isRetro = visualStyle == 'retro';
                final isPixel = visualStyle == 'pixel';
                final isPixelStyled = isRetro || isPixel;
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
                    fontFamily: isPixel ? 'monospace' : null,
                    textTheme: ThemeData(
                      brightness: isDark ? Brightness.dark : Brightness.light,
                    ).textTheme.apply(
                      bodyColor: foreground,
                      displayColor: foreground,
                    ),
                    chipTheme: ChipThemeData(
                      backgroundColor: badgeColor.withOpacity(0.14),
                      labelStyle: TextStyle(color: foreground),
                      shape: AppAppearance.componentShape(
                        badgeColor,
                        pixel: isPixel,
                        retro: isRetro,
                        width: 1.5,
                      ),
                    ),
                    listTileTheme: ListTileThemeData(
                      textColor: foreground,
                      shape: AppAppearance.componentShape(
                        badgeColor,
                        pixel: isPixel,
                        retro: isRetro,
                      ),
                    ),
                    cardTheme: CardThemeData(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8),
                      elevation: isPixelStyled ? 0 : 1,
                      shape: isPixelStyled
                          ? AppAppearance.componentShape(
                              badgeColor,
                              pixel: isPixel,
                        retro: isRetro,
                              width: isPixel ? 2 : 1.5,
                            )
                          : RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                    ),
                    dialogTheme: DialogThemeData(
                      shape: AppAppearance.componentShape(
                        badgeColor,
                        pixel: isPixel,
                        retro: isRetro,
                        width: 2,
                      ),
                    ),
                    bottomSheetTheme: BottomSheetThemeData(
                      shape: AppAppearance.componentShape(
                        badgeColor,
                        pixel: isPixel,
                        retro: isRetro,
                        width: 2,
                      ),
                    ),
                    snackBarTheme: SnackBarThemeData(
                      shape: AppAppearance.componentShape(
                        badgeColor,
                        pixel: isPixel,
                        retro: isRetro,
                        width: 1.5,
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                    floatingActionButtonTheme: FloatingActionButtonThemeData(
                      shape: AppAppearance.componentShape(
                        badgeColor,
                        pixel: isPixel,
                        retro: isRetro,
                        width: 2,
                      ),
                    ),
                    dividerTheme: DividerThemeData(
                      thickness: isPixelStyled ? 2 : 1,
                      color: isPixelStyled ? badgeColor.withOpacity(0.55) : null,
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: isPixelStyled ? badgeColor : scheme.outline,
                          width: isPixel ? 2 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: isPixelStyled ? badgeColor.withOpacity(0.65) : scheme.outline,
                          width: isPixel ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: badgeColor, width: isPixel ? 3 : 2),
                      ),
                    ),
                    popupMenuTheme: PopupMenuThemeData(
                      shape: AppAppearance.componentShape(
                        badgeColor,
                        pixel: isPixel,
                        retro: isRetro,
                        width: isPixel ? 2 : 1.5,
                      ),
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        shape: AppAppearance.componentShape(
                          badgeColor,
                          pixel: isPixel,
                        retro: isRetro,
                          width: isPixel ? 2 : 1,
                        ),
                      ),
                    ),
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        shape: AppAppearance.componentShape(
                          badgeColor,
                          pixel: isPixel,
                        retro: isRetro,
                          width: isPixel ? 2 : 1.5,
                        ),
                        elevation: isPixelStyled ? 0 : 1,
                      ),
                    ),
                    outlinedButtonTheme: OutlinedButtonThemeData(
                      style: OutlinedButton.styleFrom(
                        shape: AppAppearance.componentShape(
                          badgeColor,
                          pixel: isPixel,
                        retro: isRetro,
                          width: isPixel ? 2 : 1.5,
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
