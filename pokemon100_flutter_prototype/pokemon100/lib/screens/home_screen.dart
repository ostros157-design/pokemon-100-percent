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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firstGuide = guidesList.isNotEmpty ? guidesList.first : null;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void openSettings() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon 100%'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ustawienia',
            onPressed: openSettings,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.catching_pokemon,
                      size: 34,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Witaj w Pokémon 100%!',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Kompletny przewodnik, Pokédex i centrum Twoich postępów w świecie Pokémon.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Twoje narzędzia',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _HomeButton(
            icon: Icons.menu_book_rounded,
            title: 'Poradniki',
            subtitle: 'Przejdź do poradnika gry',
            onTap: () {
              if (firstGuide != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuideScreen(guide: firstGuide),
                  ),
                );
              }
            },
          ),
          _HomeButton(
            icon: Icons.map_outlined,
            title: 'Mapy regionów',
            subtitle: 'Przeglądaj mapy regionów Pokémon',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapsScreen()),
            ),
          ),
          _HomeButton(
            icon: Icons.music_note_rounded,
            title: 'Muzyka Pokémon',
            subtitle: 'Otwórz bibliotekę melodii',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PokemonMusicScreen()),
            ),
          ),
          _HomeButton(
            icon: Icons.bolt_rounded,
            title: 'Katalog ruchów',
            subtitle: 'Wyszukuj ruchy, typy i parametry offline',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MoveCatalogScreen()),
            ),
          ),
          _HomeButton(
            icon: Icons.catching_pokemon,
            title: 'Pokédex',
            subtitle: 'Przeglądaj Pokémony i swoją kolekcję',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PokedexScreen()),
            ),
          ),
          _HomeButton(
            icon: Icons.sports_esports_rounded,
            title: 'Wybór gry',
            subtitle: 'Wybierz grę Pokémon',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GameSelectScreen()),
            ),
          ),
          _HomeButton(
            icon: Icons.groups_rounded,
            title: 'Team',
            subtitle: 'Zbuduj swoją drużynę',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeamScreen()),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Twoje postępy',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _HomeButton(
            icon: Icons.emoji_events_rounded,
            title: 'Osiągnięcia',
            subtitle: 'Sprawdź zdobyte osiągnięcia',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            ),
          ),
          _HomeButton(
            icon: Icons.person_outline_rounded,
            title: 'Profil',
            subtitle: 'Twoje statystyki i postęp',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.primaryContainer,
                child: Icon(icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
