import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/achievements_data.dart';
import '../data/guides_data.dart';
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
  int _globalShinyCount = 0;
  int _teamTypeCount = 0;
  int _gameProgressPercent = 0;
  List<int> _savedTeamIds = <int>[];
  bool _guideStarted = false;
  bool _guideComplete = false;
  bool _firstBadgeStepComplete = false;
  bool _legendaryCaught = false;
  bool _anyGuideOpened = false;

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
    final legendaryCaught = pokemonList.any((pokemon) =>
        allCaughtIds.contains(pokemon.id) &&
        (pokemon.isLegendary || pokemon.isMythical));
    final anyGuideOpened = preferences.getKeys().any(
      (key) => key.startsWith('guide_opened_') && preferences.getBool(key) == true,
    );

    final shinyIds = <int>{};
    for (final key in preferences.getKeys()) {
      if (!key.startsWith('shiny_pokemon_ids_')) continue;
      shinyIds.addAll(
        (preferences.getStringList(key) ?? const <String>[])
            .map(int.tryParse)
            .whereType<int>(),
      );
    }
    shinyIds.retainAll(validPokemonIds);

    final teamIds = (preferences.getStringList('team_making_saved_team_v1') ??
            const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet()
        .intersection(validPokemonIds);
    final teamTypes = <String>{};
    for (final id in teamIds) {
      final matches = pokemonList.where((pokemon) => pokemon.id == id);
      if (matches.isNotEmpty) teamTypes.addAll(matches.first.types);
    }

    final gameGuides = guidesList.where((guide) => guide.gameId == gameId);
    var totalGuideSteps = 0;
    var completedGuideSteps = 0;
    var guideStarted = false;
    var guideComplete = false;
    var firstBadgeStepComplete = false;
    for (final guide in gameGuides) {
      totalGuideSteps += guide.steps.length;
      final completed = (preferences.getStringList(
                'guide_progress_${guide.gameId}_${guide.id}',
              ) ??
              const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .where((index) => index >= 0 && index < guide.steps.length)
          .toSet();
      completedGuideSteps += completed.length;
      if (completed.isNotEmpty) guideStarted = true;
      if (guide.steps.isNotEmpty && completed.length == guide.steps.length) {
        guideComplete = true;
      }
      for (final index in completed) {
        if (guide.steps[index].title.toLowerCase().contains('pokonaj brocka')) {
          firstBadgeStepComplete = true;
        }
      }
    }
    final totalObjectives = totalGuideSteps + pokemonList.length;
    final completedObjectives = completedGuideSteps + selectedGameIds.length;
    final gameProgressPercent = totalObjectives == 0
        ? 0
        : (completedObjectives * 100 / totalObjectives).round();

    if (!mounted) return;
    setState(() {
      _selectedGameId = gameId;
      _globalCaughtCount = allCaughtIds.length;
      _selectedGameCaughtCount = selectedGameIds.length;
      _globalShinyCount = shinyIds.length;
      _savedTeamIds = teamIds.toList();
      _teamTypeCount = teamTypes.length;
      _gameProgressPercent = gameProgressPercent;
      _guideStarted = guideStarted;
      _guideComplete = guideComplete;
      _firstBadgeStepComplete = firstBadgeStepComplete;
      _legendaryCaught = legendaryCaught;
      _anyGuideOpened = anyGuideOpened;
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
      case 'first_badge':
        // The achievement is tied to the player checking off the Brock battle
        // in the guide, rather than opening the step alone.
        return _firstBadgeStepComplete;
      case 'shiny':
        return _globalShinyCount > 0;
      case 'legendary':
      case 'hidden_legend':
        return _legendaryCaught;
      case 'guide_start':
        return _anyGuideOpened;
      case 'full_team':
        return _savedTeamIds.length == 6;
      case 'team_types':
        return _teamTypeCount >= 6;
      case 'guide_complete':
        return _guideComplete;
      case 'game_complete':
      case 'first_100':
        return _gameProgressPercent >= 100;
      case 'speed_progress':
        return _gameProgressPercent >= 25;
      case 'half_progress':
        return _gameProgressPercent >= 50;
      case 'three_quarters':
        return _gameProgressPercent >= 75;
      default:
        // Keep achievements locked when the app does not yet track their
        // real completion signal (e.g. Elite Four, evolutions or trades).
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievements = achievementsList;
    final unlockedCount = achievements.where(_isUnlocked).length;
    final achievementProgress = achievements.isEmpty
        ? 0.0
        : unlockedCount / achievements.length;

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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_globalCaughtCount różnych Pokémonów zarejestrowanych łącznie',
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: achievementProgress,
                            minHeight: 6,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$unlockedCount z ${achievements.length} osiągnięć odblokowanych',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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
