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
  bool _mythicalCaught = false;
  bool _hiddenTeamRocketDefeated = false;
  bool _hiddenCompletionReached = false;
  bool _anyGuideOpened = false;
  Map<String, bool> _hiddenAchievementUnlocks = <String, bool>{};

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
    final caughtPokemon = pokemonList.where((pokemon) => allCaughtIds.contains(pokemon.id)).toList();
    final caughtTypes = caughtPokemon.expand((pokemon) => pokemon.types).toSet();
    final caughtBabies = caughtPokemon.where((pokemon) => pokemon.isBaby).length;
    final caughtHighStats = caughtPokemon.where((pokemon) => (pokemon.baseStatTotal ?? 0) >= 600).length;
    final caughtCompleteStats = caughtPokemon.where((pokemon) => pokemon.hasCompleteBaseStats).length;
    final legendaryCaught = pokemonList.any((pokemon) =>
        allCaughtIds.contains(pokemon.id) &&
        (pokemon.isLegendary || pokemon.isMythical));
    // Keep the secret mythical milestone distinct from the public legendary one.
    final mythicalCaught = pokemonList.any((pokemon) =>
        allCaughtIds.contains(pokemon.id) && pokemon.isMythical);
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
    var hiddenTeamRocketDefeated = false;
    final completedGuideText = <String>[];
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
        final step = guide.steps[index];
        final searchableStep = '${step.title} ${step.description}'.toLowerCase();
        completedGuideText.add(searchableStep);
        if (searchableStep.contains('pokonaj brocka')) {
          firstBadgeStepComplete = true;
        }
        // Future guide chapters can unlock this secret by recording a completed
        // Team Rocket/Giovanni encounter; merely visiting the location is not enough.
        if (searchableStep.contains('team rocket') ||
            searchableStep.contains('giovanni')) {
          hiddenTeamRocketDefeated = true;
        }
      }
    }
    final totalObjectives = totalGuideSteps + pokemonList.length;
    final completedObjectives = completedGuideSteps + selectedGameIds.length;
    final gameProgressPercent = totalObjectives == 0
        ? 0
        : (completedObjectives * 100 / totalObjectives).round();
    final hiddenAchievementUnlocks = <String, bool>{
      'hidden_extra_01': allCaughtIds.length >= 5,
      'hidden_extra_02': allCaughtIds.length >= 10,
      'hidden_extra_03': allCaughtIds.length >= 20,
      'hidden_extra_04': allCaughtIds.length >= 30,
      'hidden_extra_05': allCaughtIds.length >= 40,
      'hidden_extra_06': allCaughtIds.length >= 75,
      'hidden_extra_07': allCaughtIds.length >= 150,
      'hidden_extra_08': caughtTypes.length >= 3,
      'hidden_extra_09': caughtTypes.length >= 6,
      'hidden_extra_10': caughtTypes.length >= 10,
      'hidden_extra_11': caughtTypes.length >= 15,
      'hidden_extra_12': caughtPokemon.any((pokemon) => pokemon.types.contains('Fire')),
      'hidden_extra_13': caughtPokemon.any((pokemon) => pokemon.types.contains('Water')),
      'hidden_extra_14': caughtPokemon.any((pokemon) => pokemon.types.contains('Grass')),
      'hidden_extra_15': caughtPokemon.any((pokemon) => pokemon.types.contains('Electric')),
      'hidden_extra_16': caughtPokemon.any((pokemon) => pokemon.types.contains('Psychic')),
      'hidden_extra_17': caughtPokemon.any((pokemon) => pokemon.types.contains('Dragon')),
      'hidden_extra_18': caughtPokemon.any((pokemon) => pokemon.types.contains('Ghost')),
      'hidden_extra_19': caughtPokemon.any((pokemon) => pokemon.types.contains('Steel')),
      'hidden_extra_20': caughtPokemon.any((pokemon) => pokemon.types.contains('Fairy')),
      'hidden_extra_21': caughtBabies >= 1,
      'hidden_extra_22': caughtBabies >= 3,
      'hidden_extra_23': caughtPokemon.any((pokemon) => pokemon.generation == 1),
      'hidden_extra_24': caughtPokemon.any((pokemon) => pokemon.generation == 2),
      'hidden_extra_25': caughtPokemon.any((pokemon) => pokemon.generation == 3),
      'hidden_extra_26': caughtPokemon.any((pokemon) => pokemon.generation == 4),
      'hidden_extra_27': caughtPokemon.any((pokemon) => pokemon.generation == 5),
      'hidden_extra_28': caughtPokemon.any((pokemon) => pokemon.generation == 6),
      'hidden_extra_29': caughtPokemon.any((pokemon) => pokemon.generation == 7),
      'hidden_extra_30': caughtPokemon.any((pokemon) => pokemon.generation == 8),
      'hidden_extra_31': caughtPokemon.any((pokemon) => pokemon.generation == 9),
      'hidden_extra_32': caughtHighStats >= 1,
      'hidden_extra_33': caughtHighStats >= 3,
      'hidden_extra_34': caughtCompleteStats >= 10,
      'hidden_extra_35': teamTypes.length >= 3,
      'hidden_extra_36': teamTypes.length >= 6,
      'hidden_extra_37': completedGuideSteps >= 3,
      'hidden_extra_38': completedGuideSteps >= 6,
      'hidden_extra_39': completedGuideText.any((step) => step.contains('forest') || step.contains('las')),
      'hidden_extra_40': completedGuideText.any((step) => step.contains('gym')),
      'hidden_extra_41': completedGuideText.any((step) => step.contains('route')),
      'hidden_extra_42': completedGuideText.any((step) => step.contains('profesor') || step.contains('professor')),
      'hidden_extra_43': gameProgressPercent >= 10,
      'hidden_extra_44': gameProgressPercent >= 90,
      'hidden_extra_45': caughtPokemon.any((pokemon) => pokemon.isLegendary) && caughtPokemon.any((pokemon) => pokemon.isMythical),
      'hidden_extra_46': caughtPokemon.any((pokemon) => pokemon.hiddenAbilities.isNotEmpty),
      'hidden_extra_47': caughtPokemon.any((pokemon) => pokemon.captureRate != null && pokemon.captureRate! <= 45),
    };

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
      _mythicalCaught = mythicalCaught;
      _hiddenTeamRocketDefeated = hiddenTeamRocketDefeated;
      _hiddenCompletionReached = gameProgressPercent >= 100 && guideComplete;
      _anyGuideOpened = anyGuideOpened;
      _hiddenAchievementUnlocks = hiddenAchievementUnlocks;
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
        return _legendaryCaught;
      case 'hidden_legend':
        return _mythicalCaught;
      case 'hidden_team_rocket':
        return _hiddenTeamRocketDefeated;
      case 'hidden_complete':
        return _hiddenCompletionReached;
      case 'hidden_extra_01':
      case 'hidden_extra_02':
      case 'hidden_extra_03':
      case 'hidden_extra_04':
      case 'hidden_extra_05':
      case 'hidden_extra_06':
      case 'hidden_extra_07':
      case 'hidden_extra_08':
      case 'hidden_extra_09':
      case 'hidden_extra_10':
      case 'hidden_extra_11':
      case 'hidden_extra_12':
      case 'hidden_extra_13':
      case 'hidden_extra_14':
      case 'hidden_extra_15':
      case 'hidden_extra_16':
      case 'hidden_extra_17':
      case 'hidden_extra_18':
      case 'hidden_extra_19':
      case 'hidden_extra_20':
      case 'hidden_extra_21':
      case 'hidden_extra_22':
      case 'hidden_extra_23':
      case 'hidden_extra_24':
      case 'hidden_extra_25':
      case 'hidden_extra_26':
      case 'hidden_extra_27':
      case 'hidden_extra_28':
      case 'hidden_extra_29':
      case 'hidden_extra_30':
      case 'hidden_extra_31':
      case 'hidden_extra_32':
      case 'hidden_extra_33':
      case 'hidden_extra_34':
      case 'hidden_extra_35':
      case 'hidden_extra_36':
      case 'hidden_extra_37':
      case 'hidden_extra_38':
      case 'hidden_extra_39':
      case 'hidden_extra_40':
      case 'hidden_extra_41':
      case 'hidden_extra_42':
      case 'hidden_extra_43':
      case 'hidden_extra_44':
      case 'hidden_extra_45':
      case 'hidden_extra_46':
      case 'hidden_extra_47':
        return _hiddenAchievementUnlocks[achievement.id] ?? false;
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
