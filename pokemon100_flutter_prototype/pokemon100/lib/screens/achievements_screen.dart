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

  bool _loading = true;
  String _selectedGameId = 'lets_go_pikachu';
  int _caughtCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final preferences = await SharedPreferences.getInstance();
    final gameId =
        preferences.getString(_selectedGameKey) ?? 'lets_go_pikachu';
    final caughtValues = preferences.getStringList('$_caughtKeyPrefix$gameId') ??
        preferences.getStringList('caught_pokemon_ids') ??
        const <String>[];
    final caughtIds = caughtValues.map(int.tryParse).whereType<int>().toSet();
    final caughtCount =
        pokemonList.where((pokemon) => caughtIds.contains(pokemon.id)).length;

    if (!mounted) return;
    setState(() {
      _selectedGameId = gameId;
      _caughtCount = caughtCount;
      _loading = false;
    });
  }

  bool _isUnlocked(Achievement achievement) {
    switch (achievement.id) {
      case 'first_pokemon':
      case 'pokedex_start':
        return _caughtCount >= 1;
      case 'pokedex_25':
        return _caughtCount >= 25;
      case 'pokedex_50':
        return _caughtCount >= 50;
      case 'pokedex_100':
        return _caughtCount >= 100;
      case 'pokedex_complete':
        return _caughtCount >= pokemonList.length;
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
                      title: const Text('Pokédex wybranej gry'),
                      subtitle: Text(
                        '$_caughtCount / ${pokemonList.length} Pokémonów oznaczonych jako złapane · ${_selectedGameId.replaceAll('_', ' ')}',
                      ),
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
