import 'package:flutter/material.dart';

import '../data/guides_data.dart';
import '../screens/guide_screen.dart';
import '../screens/game_select_screen.dart';
import '../screens/pokedex_screen.dart';
import '../screens/move_catalog_screen.dart';
import '../screens/team_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/pokemon_music_screen.dart';
import '../screens/maps_screen.dart';
import '../services/app_appearance.dart';
import '../widgets/pixel_icon.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firstGuide = guidesList.isNotEmpty ? guidesList.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon Guide'),
        actions: [
          IconButton(
            icon: _styleIcon(context, 'settings', Icons.settings),
            tooltip: 'Ustawienia',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pokémon Guide',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Twój kompletny przewodnik po grach Pokémon.',
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _HomeButton(
            icon: Icons.menu_book,
            pixelIcon: 'book',
            title: 'Poradniki',
            subtitle: 'Przejdź do poradnika gry',
            onTap: () {
              if (firstGuide != null) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GuideScreen(guide: firstGuide),
                ));
              }
            },
          ),
          _HomeButton(
            icon: Icons.map,
            pixelIcon: 'map',
            title: 'Mapy regionów',
            subtitle: 'Przeglądaj mapy regionów Pokémon',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const MapsScreen(),
            )),
          ),
          _HomeButton(
            icon: Icons.music_note,
            pixelIcon: 'music',
            title: 'Muzyka Pokémon',
            subtitle: 'Muzyka w tle i sterowanie odtwarzaniem offline',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const PokemonMusicScreen(),
            )),
          ),
          _HomeButton(
            icon: Icons.bolt,
            pixelIcon: 'bolt',
            title: 'Katalog ruchów',
            subtitle: 'Wyszukuj ruchy, typy i parametry offline',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const MoveCatalogScreen(),
            )),
          ),
          _HomeButton(
            icon: Icons.catching_pokemon,
            pixelIcon: 'pokeball',
            title: 'Pokédex',
            subtitle: 'Przeglądaj Pokémony',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const PokedexScreen(),
            )),
          ),
          _HomeButton(
            icon: Icons.sports_esports,
            pixelIcon: 'game',
            title: 'Wybór gry',
            subtitle: 'Wybierz grę Pokémon',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const GameSelectScreen(),
            )),
          ),
          _HomeButton(
            icon: Icons.groups,
            pixelIcon: 'team',
            title: 'Team',
            subtitle: 'Zbuduj swoją drużynę',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const TeamScreen(),
            )),
          ),
          _HomeButton(
            icon: Icons.emoji_events,
            pixelIcon: 'trophy',
            title: 'Osiągnięcia',
            subtitle: 'Sprawdź swoje osiągnięcia',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const AchievementsScreen(),
            )),
          ),
          _HomeButton(
            icon: Icons.person,
            pixelIcon: 'profile',
            title: 'Profil',
            subtitle: 'Twoje statystyki i postęp',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            )),
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String pixelIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.pixelIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: _styleIcon(context, pixelIcon, icon, size: 25),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: _styleIcon(context, 'arrow', Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}

Widget _styleIcon(
  BuildContext context,
  String pixelName,
  IconData fallback, {
  double size = 24,
}) {
  return ValueListenableBuilder<String>(
    valueListenable: AppAppearance.visualStyle,
    builder: (context, style, _) {
      if (style == 'pixel') return PixelIcon(name: pixelName, size: size);
      return Icon(fallback, size: size);
    },
  );
}
