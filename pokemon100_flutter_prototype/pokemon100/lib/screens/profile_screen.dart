import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/achievement_progress_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Map<String, String> _gameNames = {
    'red_blue': 'Pokémon Red / Blue',
    'yellow': 'Pokémon Yellow',
    'fire_red_leaf_green': 'Pokémon FireRed / LeafGreen',
    'gold_silver': 'Pokémon Gold / Silver',
    'crystal': 'Pokémon Crystal',
    'heart_gold_soul_silver': 'Pokémon HeartGold / SoulSilver',
    'ruby_sapphire': 'Pokémon Ruby / Sapphire',
    'emerald': 'Pokémon Emerald',
    'diamond_pearl': 'Pokémon Diamond / Pearl',
    'platinum': 'Pokémon Platinum',
    'black_white': 'Pokémon Black / White',
    'black_2_white_2': 'Pokémon Black 2 / White 2',
    'x_y': 'Pokémon X / Y',
    'omega_ruby_alpha_sapphire': 'Pokémon Omega Ruby / Alpha Sapphire',
    'sun_moon': 'Pokémon Sun / Moon',
    'ultra_sun_ultra_moon': 'Pokémon Ultra Sun / Ultra Moon',
    'lets_go_pikachu': "Pokémon: Let's Go, Pikachu!",
    'lets_go_eevee': "Pokémon: Let's Go, Eevee!",
    'sword_shield': 'Pokémon Sword / Shield',
    'brilliant_diamond_shining_pearl': 'Pokémon Brilliant Diamond / Shining Pearl',
    'legends_arceus': 'Pokémon Legends: Arceus',
    'scarlet_violet': 'Pokémon Scarlet / Violet',
  };

  bool _loading = true;
  String _selectedGameId = 'lets_go_pikachu';
  int _completedGuideSteps = 0;
  int _totalGuideSteps = 0;
  int _caughtPokemon = 0;
  int _totalGamePokemon = 0;
  int _progressPercent = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final preferences = await SharedPreferences.getInstance();
    final progress = AchievementProgressService.calculate(preferences);

    if (!mounted) return;
    setState(() {
      _selectedGameId = progress.selectedGameId;
      _completedGuideSteps = progress.selectedGameCompletedGuideSteps;
      _totalGuideSteps = progress.selectedGameTotalGuideSteps;
      _caughtPokemon = progress.selectedGameCaughtCount;
      _totalGamePokemon = progress.selectedGamePokemonTotal;
      _progressPercent = progress.selectedGameProgressPercent;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameName = _gameNames[_selectedGameId] ?? _selectedGameId;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 55),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.videogame_asset),
                    title: const Text('Postęp wybranej gry'),
                    subtitle: Text(gameName),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.track_changes),
                    title: const Text('Postęp Pokémon 100%'),
                    subtitle: Text('$_progressPercent% — poradniki i Pokédex dla wybranej gry'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text('Kroki poradników ukończone'),
                    subtitle: Text('$_completedGuideSteps / $_totalGuideSteps'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.catching_pokemon),
                    title: const Text('Pokémony oznaczone jako złapane'),
                    subtitle: Text('$_caughtPokemon / $_totalGamePokemon'),
                  ),
                ),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Jak liczymy postęp?'),
                    subtitle: Text(
                      'Liczymy ukończone kroki poradników i Pokémony dostępne w wybranej grze '
                      'według indeksu dostępności. Zapis każdej gry jest oddzielny; '
                      'gatunki spoza tej gry nie zwiększają jej wyniku.',
                    ),
                  ),
                ),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.emoji_events),
                    title: Text('Osiągnięcia'),
                    subtitle: Text(
                      'Osiągnięcia są wyliczane z zapisanych danych Pokédexu, poradników, '
                      'odznak i drużyn; nieśledzone zdarzenia można oznaczać ręcznie.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
