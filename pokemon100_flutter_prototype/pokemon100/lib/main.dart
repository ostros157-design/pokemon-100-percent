import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_appearance.dart';

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
                    ),
                    listTileTheme: ListTileThemeData(textColor: foreground),
                    cardTheme: CardThemeData(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8),
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
