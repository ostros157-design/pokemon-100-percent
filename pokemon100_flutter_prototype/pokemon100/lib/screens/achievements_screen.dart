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
  Map<String, bool> _additionalAchievementUnlocks = <String, bool>{};

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
    // Separate mythical Pokémon from the broader legendary milestone.
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
        // A completed step mentioning Team Rocket/Giovanni counts as progress.
        if (searchableStep.contains('team rocket') ||
            searchableStep.contains('giovanni')) {
          hiddenTeamRocketDefeated = true;
        }
      }
    }
    final gameProgressPercent = totalGuideSteps == 0
        ? 0
        : (completedGuideSteps * 100 / totalGuideSteps).round();
    final additionalAchievementUnlocks = <String, bool>{
      'achievement_extra_01': allCaughtIds.length >= 5,
      'achievement_extra_02': allCaughtIds.length >= 10,
      'achievement_extra_03': allCaughtIds.length >= 20,
      'achievement_extra_04': allCaughtIds.length >= 30,
      'achievement_extra_05': allCaughtIds.length >= 40,
      'achievement_extra_06': allCaughtIds.length >= 75,
      'achievement_extra_07': allCaughtIds.length >= 150,
      'achievement_extra_08': caughtTypes.length >= 3,
      'achievement_extra_09': caughtTypes.length >= 6,
      'achievement_extra_10': caughtTypes.length >= 10,
      'achievement_extra_11': caughtTypes.length >= 15,
      'achievement_extra_12': caughtPokemon.any((pokemon) => pokemon.types.contains('Fire')),
      'achievement_extra_13': caughtPokemon.any((pokemon) => pokemon.types.contains('Water')),
      'achievement_extra_14': caughtPokemon.any((pokemon) => pokemon.types.contains('Grass')),
      'achievement_extra_15': caughtPokemon.any((pokemon) => pokemon.types.contains('Electric')),
      'achievement_extra_16': caughtPokemon.any((pokemon) => pokemon.types.contains('Psychic')),
      'achievement_extra_17': caughtPokemon.any((pokemon) => pokemon.types.contains('Dragon')),
      'achievement_extra_18': caughtPokemon.any((pokemon) => pokemon.types.contains('Ghost')),
      'achievement_extra_19': caughtPokemon.any((pokemon) => pokemon.types.contains('Steel')),
      'achievement_extra_20': caughtPokemon.any((pokemon) => pokemon.types.contains('Fairy')),
      'achievement_extra_21': caughtBabies >= 1,
      'achievement_extra_22': caughtBabies >= 3,
      'achievement_extra_23': caughtPokemon.any((pokemon) => pokemon.generation == 1),
      'achievement_extra_24': caughtPokemon.any((pokemon) => pokemon.generation == 2),
      'achievement_extra_25': caughtPokemon.any((pokemon) => pokemon.generation == 3),
      'achievement_extra_26': caughtPokemon.any((pokemon) => pokemon.generation == 4),
      'achievement_extra_27': caughtPokemon.any((pokemon) => pokemon.generation == 5),
      'achievement_extra_28': caughtPokemon.any((pokemon) => pokemon.generation == 6),
      'achievement_extra_29': caughtPokemon.any((pokemon) => pokemon.generation == 7),
      'achievement_extra_30': caughtPokemon.any((pokemon) => pokemon.generation == 8),
      'achievement_extra_31': caughtPokemon.any((pokemon) => pokemon.generation == 9),
      'achievement_extra_32': caughtHighStats >= 1,
      'achievement_extra_33': caughtHighStats >= 3,
      'achievement_extra_34': caughtCompleteStats >= 10,
      'achievement_extra_35': teamTypes.length >= 3,
      'achievement_extra_36': teamTypes.length >= 6,
      'achievement_extra_37': completedGuideSteps >= 3,
      'achievement_extra_38': completedGuideSteps >= 6,
      'achievement_extra_39': completedGuideText.any((step) => step.contains('forest') || step.contains('las')),
      'achievement_extra_40': completedGuideText.any((step) => step.contains('gym')),
      'achievement_extra_41': completedGuideText.any((step) => step.contains('route')),
      'achievement_extra_42': completedGuideText.any((step) => step.contains('profesor') || step.contains('professor')),
      'achievement_extra_43': gameProgressPercent >= 10,
      'achievement_extra_44': gameProgressPercent >= 90,
      'achievement_extra_45': caughtPokemon.any((pokemon) => pokemon.isLegendary) && caughtPokemon.any((pokemon) => pokemon.isMythical),
      'achievement_extra_46': caughtPokemon.any((pokemon) => pokemon.hiddenAbilities.isNotEmpty),
      'achievement_extra_47': caughtPokemon.any((pokemon) => pokemon.captureRate != null && pokemon.captureRate! <= 45),
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
      _additionalAchievementUnlocks = additionalAchievementUnlocks;
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
        return _hiddenCompletionReached && _globalCaughtCount > 0;
      case 'achievement_extra_01':
      case 'achievement_extra_02':
      case 'achievement_extra_03':
      case 'achievement_extra_04':
      case 'achievement_extra_05':
      case 'achievement_extra_06':
      case 'achievement_extra_07':
      case 'achievement_extra_08':
      case 'achievement_extra_09':
      case 'achievement_extra_10':
      case 'achievement_extra_11':
      case 'achievement_extra_12':
      case 'achievement_extra_13':
      case 'achievement_extra_14':
      case 'achievement_extra_15':
      case 'achievement_extra_16':
      case 'achievement_extra_17':
      case 'achievement_extra_18':
      case 'achievement_extra_19':
      case 'achievement_extra_20':
      case 'achievement_extra_21':
      case 'achievement_extra_22':
      case 'achievement_extra_23':
      case 'achievement_extra_24':
      case 'achievement_extra_25':
      case 'achievement_extra_26':
      case 'achievement_extra_27':
      case 'achievement_extra_28':
      case 'achievement_extra_29':
      case 'achievement_extra_30':
      case 'achievement_extra_31':
      case 'achievement_extra_32':
      case 'achievement_extra_33':
      case 'achievement_extra_34':
      case 'achievement_extra_35':
      case 'achievement_extra_36':
      case 'achievement_extra_37':
      case 'achievement_extra_38':
      case 'achievement_extra_39':
      case 'achievement_extra_40':
      case 'achievement_extra_41':
      case 'achievement_extra_42':
      case 'achievement_extra_43':
      case 'achievement_extra_44':
      case 'achievement_extra_45':
      case 'achievement_extra_46':
      case 'achievement_extra_47':
        return _additionalAchievementUnlocks[achievement.id] ?? false;
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
