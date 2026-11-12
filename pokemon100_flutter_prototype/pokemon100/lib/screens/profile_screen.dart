import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/guides_data.dart';
import '../data/pokemon_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _selectedGameKey = 'selected_pokemon_game_id';
  static const _legacyCaughtPokemonKey = 'caught_pokemon_ids';

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

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final preferences = await SharedPreferences.getInstance();
    final selectedGameId =
        preferences.getString(_selectedGameKey) ?? 'lets_go_pikachu';
    final gameGuides =
        guidesList.where((guide) => guide.gameId == selectedGameId);

    var completedSteps = 0;
    var totalSteps = 0;
    for (final guide in gameGuides) {
      totalSteps += guide.steps.length;
      final saved = preferences.getStringList(
            'guide_progress_${guide.gameId}_${guide.id}',
          ) ??
          const <String>[];
      completedSteps += saved
          .map(int.tryParse)
          .whereType<int>()
          .where((index) => index >= 0 && index < guide.steps.length)
          .toSet()
          .length;
    }

    final gameCaughtKey = '${_legacyCaughtPokemonKey}_${selectedGameId}';
    // The old global key is only a fallback for users who have not opened
    // the Pokédex since per-game collections were introduced.
    final hasAnyPerGameCollection = preferences
        .getKeys()
        .any((key) => key.startsWith('${_legacyCaughtPokemonKey}_'));
    final caughtValues = preferences.getStringList(gameCaughtKey) ??
        (!hasAnyPerGameCollection
            ? preferences.getStringList(_legacyCaughtPokemonKey)
            : null) ??
        const <String>[];
    final caughtIds = caughtValues.map(int.tryParse).whereType<int>().toSet();
    final validCaughtCount =
        pokemonList.where((pokemon) => caughtIds.contains(pokemon.id)).length;

    if (!mounted) return;
    setState(() {
      _selectedGameId = selectedGameId;
      _completedGuideSteps = completedSteps;
      _totalGuideSteps = totalSteps;
      _caughtPokemon = validCaughtCount;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalObjectives = _totalGuideSteps + pokemonList.length;
    final completedObjectives = _completedGuideSteps + _caughtPokemon;
    final percent = totalObjectives == 0
        ? 0
        : (completedObjectives * 100 / totalObjectives).round();
    final gameName = _gameNames[_selectedGameId] ?? _selectedGameId;
    final colors = Theme.of(context).colorScheme;
    final safeProgress = (percent / 100).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 42,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 46,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Postęp całkowity',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '$percent%',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: safeProgress,
                            minHeight: 10,
                            color: colors.primary,
                            backgroundColor: colors.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$completedObjectives / $totalObjectives celów ukończonych',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                    subtitle: Text('$percent% — poradniki i Pokédex dla wybranej gry'),
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
                    subtitle: Text('$_caughtPokemon / ${pokemonList.length}'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline, color: colors.primary),
                    title: const Text('Jak liczymy postęp?'),
                    subtitle: const Text(
                      'Liczymy ukończone kroki poradników i Pokémony oznaczone '
                      'jako złapane dla aktualnie wybranej gry. Zapis każdej '
                      'gry jest oddzielny; wynik obejmuje dane dostępne w aplikacji.',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.emoji_events, color: colors.primary),
                    title: const Text('Osiągnięcia'),
                    subtitle: const Text(
                      'Osiągnięcia są osobną sekcją i nie są jeszcze automatycznie '
                      'wyliczane na podstawie postępu profilu.',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
