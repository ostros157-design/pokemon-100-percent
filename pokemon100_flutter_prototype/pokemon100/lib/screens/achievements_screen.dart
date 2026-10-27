import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/achievements_data.dart';
import '../data/pokemon_data.dart';
import '../models/achievement.dart';
import '../widgets/achievement_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const _selectedGameKey = 'selected_pokemon_game_id';
  static const _caughtKeyPrefix = 'caught_pokemon_ids_';
  static const _legacyCaughtKey = 'caught_pokemon_ids';

  bool _loading = true;
  String _selectedGameId = 'lets_go_pikachu';
  int _globalCaughtCount = 0;
  int _selectedGameCaughtCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final preferences = await SharedPreferences.getInstance();
    final gameId =
        preferences.getString(_selectedGameKey) ?? 'lets_go_pikachu';

    final hasPerGameCollections = preferences
        .getKeys()
        .any((key) => key.startsWith(_caughtKeyPrefix));
    final allCaughtIds = <int>{};
    if (hasPerGameCollections) {
      for (final key in preferences.getKeys()) {
        if (!key.startsWith(_caughtKeyPrefix)) continue;
        allCaughtIds.addAll(
          (preferences.getStringList(key) ?? const <String>[])
              .map(int.tryParse)
              .whereType<int>(),
        );
      }
    } else {
      // Older versions used one global list; keep it available for migration.
      allCaughtIds.addAll(
        (preferences.getStringList(_legacyCaughtKey) ?? const <String>[])
            .map(int.tryParse)
            .whereType<int>(),
      );
    }

    final selectedGameKey = '$_caughtKeyPrefix$gameId';
    final selectedGameIds = (preferences.getStringList(selectedGameKey) ??
            (!hasPerGameCollections
                ? preferences.getStringList(_legacyCaughtKey)
                : null) ??
            const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();

    final validPokemonIds = pokemonList.map((pokemon) => pokemon.id).toSet();
    allCaughtIds.retainAll(validPokemonIds);
    selectedGameIds.retainAll(validPokemonIds);

    if (!mounted) return;
    setState(() {
      _selectedGameId = gameId;
      _globalCaughtCount = allCaughtIds.length;
      _selectedGameCaughtCount = selectedGameIds.length;
      _loading = false;
    });
  }

  bool _isUnlocked(Achievement achievement) {
    switch (achievement.id) {
      case 'first_pokemon':
      case 'pokedex_start':
        return _globalCaughtCount >= 1;
      case 'pokedex_25':
        return _globalCaughtCount >= 25;
      case 'pokedex_50':
        return _globalCaughtCount >= 50;
      case 'pokedex_100':
        return _globalCaughtCount >= 100;
      case 'pokedex_complete':
        // This is a global database milestone, not a per-game regional dex.
        return _globalCaughtCount >= pokemonList.length;
      default:
        // Do not unlock achievements until their real completion signals
        // (badges, battles, evolutions, team composition, etc.) are tracked.
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievements = achievementsList;

    return Scaffold(
      appBar: AppBar(title: const Text('Osiągnięcia')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.catching_pokemon),
                      title: const Text('Kolekcja ze wszystkich gier'),
                      subtitle: Text(
                        '$_globalCaughtCount różnych Pokémonów zarejestrowanych łącznie',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Wybrana gra: ${_selectedGameId.replaceAll('_', ' ')} · '
                      '$_selectedGameCaughtCount złapanych',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Expanded(
                  child: achievements.isEmpty
                      ? const Center(child: Text('Brak dostępnych osiągnięć.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: achievements.length,
                          itemBuilder: (context, index) {
                            final achievement = achievements[index];
                            return AchievementCard(
                              achievement: achievement,
                              unlocked: _isUnlocked(achievement),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
