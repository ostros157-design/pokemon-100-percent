import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/achievements_data.dart';
import '../data/pokemon_data.dart';
import '../data/guides_data.dart';
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
  static const _manualUnlockedKey = 'manual_achievement_ids';

  bool _loading = true;
  String _selectedGameId = 'lets_go_pikachu';
  int _globalCaughtCount = 0;
  int _selectedGameCaughtCount = 0;
  bool _hasStartedGuide = false;
  bool _hasCompletedGuide = false;
  bool _hasShiny = false;
  bool _hasLegendary = false;
  int _selectedGameProgressPercent = 0;
  Set<String> _manualUnlockedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final preferences = await SharedPreferences.getInstance();
    final gameId =
        preferences.getString(_selectedGameKey) ?? 'lets_go_pikachu';
    final manualUnlockedIds = (preferences.getStringList(_manualUnlockedKey) ?? const <String>[]).toSet();

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

    final shinyIds = <int>{};
    for (final key in preferences.getKeys()) {
      if (!key.startsWith('shiny_pokemon_ids_')) continue;
      shinyIds.addAll(
        (preferences.getStringList(key) ?? const <String>[])
            .map(int.tryParse)
            .whereType<int>(),
      );
    }
    shinyIds.addAll(
      (preferences.getStringList('shiny_pokemon_ids') ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>(),
    );
    final hasShiny = shinyIds.isNotEmpty;
    final hasLegendary = allCaughtIds.any((id) =>
        pokemonList.any((pokemon) => pokemon.id == id && pokemon.isLegendary));

    final selectedGuides = guidesList.where((guide) => guide.gameId == gameId).toList();
    var guideCompleted = 0;
    var guideTotal = 0;
    var hasStartedGuide = false;
    var hasCompletedGuide = false;
    for (final guide in selectedGuides) {
      guideTotal += guide.steps.length;
      final saved = preferences.getStringList(
            'guide_progress_${guide.gameId}_${guide.id}',
          ) ?? const <String>[];
      final completed = saved
          .map(int.tryParse)
          .whereType<int>()
          .where((index) => index >= 0 && index < guide.steps.length)
          .toSet()
          .length;
      guideCompleted += completed;
      if (preferences.getBool(
            'guide_opened_${guide.gameId}_${guide.id}',
          ) == true || completed > 0) {
        hasStartedGuide = true;
      }
      if (guide.steps.isNotEmpty && completed == guide.steps.length) {
        hasCompletedGuide = true;
      }
    }
    final totalObjectives = guideTotal + pokemonList.length;
    final completedObjectives = guideCompleted + selectedGameIds.length;
    final progressPercent = totalObjectives == 0
        ? 0
        : (completedObjectives * 100 / totalObjectives).round();

    if (!mounted) return;
    setState(() {
      _selectedGameId = gameId;
      _globalCaughtCount = allCaughtIds.length;
      _selectedGameCaughtCount = selectedGameIds.length;
      _hasStartedGuide = hasStartedGuide;
      _hasCompletedGuide = hasCompletedGuide;
      _hasShiny = hasShiny;
      _hasLegendary = hasLegendary;
      _selectedGameProgressPercent = progressPercent;
      _manualUnlockedIds = manualUnlockedIds;
      _loading = false;
    });
  }

  bool _isAutomaticallyUnlocked(Achievement achievement) {
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
      case 'shiny':
        return _hasShiny;
      case 'legendary':
        return _hasLegendary;
      case 'guide_start':
        return _hasStartedGuide;
      case 'guide_complete':
        return _hasCompletedGuide;
      case 'speed_progress':
        return _selectedGameProgressPercent >= 25;
      case 'half_progress':
        return _selectedGameProgressPercent >= 50;
      case 'three_quarters':
        return _selectedGameProgressPercent >= 75;
      case 'first_100':
        return _selectedGameProgressPercent >= 100;
      case 'game_complete':
        return _selectedGameProgressPercent >= 100;
      default:
        // Do not unlock achievements until their real completion signals
        // (badges, battles, evolutions, team composition, etc.) are tracked.
        return false;
    }
  }

  bool _isUnlocked(Achievement achievement) =>
      _manualUnlockedIds.contains(achievement.id) ||
      _isAutomaticallyUnlocked(achievement);

  Future<void> _toggleManualUnlock(String achievementId) async {
    final updated = Set<String>.from(_manualUnlockedIds);
    if (!updated.add(achievementId)) updated.remove(achievementId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_manualUnlockedKey, updated.toList()..sort());
    if (!mounted) return;
    setState(() => _manualUnlockedIds = updated);
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
                      '$_selectedGameCaughtCount złapanych · postęp $_selectedGameProgressPercent%',
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
                              manuallyUnlocked: _manualUnlockedIds.contains(achievement.id),
                              canManuallyUnlock: !_isAutomaticallyUnlocked(achievement),
                              onManualToggle: () => _toggleManualUnlock(achievement.id),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
