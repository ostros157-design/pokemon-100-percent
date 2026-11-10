import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/guides_data.dart';
import '../data/pokemon_data.dart';
import '../data/team_game_availability.dart';

class AchievementProgressSnapshot {
  final String selectedGameId;
  final int globalCaughtCount;
  final int selectedGameCaughtCount;
  final int selectedGamePokemonTotal;
  final int selectedGameCompletedGuideSteps;
  final int selectedGameTotalGuideSteps;
  final int selectedGameProgressPercent;
  final Set<String> automaticallyUnlockedIds;

  const AchievementProgressSnapshot({
    required this.selectedGameId,
    required this.globalCaughtCount,
    required this.selectedGameCaughtCount,
    required this.selectedGamePokemonTotal,
    required this.selectedGameCompletedGuideSteps,
    required this.selectedGameTotalGuideSteps,
    required this.selectedGameProgressPercent,
    required this.automaticallyUnlockedIds,
  });

  bool isAutomaticallyUnlocked(String achievementId) =>
      automaticallyUnlockedIds.contains(achievementId);
}

/// Reads existing saved progress and turns only verifiable signals into
/// automatic achievements. Untracked milestones remain manually unlockable.
class AchievementProgressService {
  static const String _selectedGameKey = 'selected_pokemon_game_id';
  static const String _caughtKeyPrefix = 'caught_pokemon_ids_';
  static const String _legacyCaughtKey = 'caught_pokemon_ids';
  static const String _shinyKeyPrefix = 'shiny_pokemon_ids_';
  static const String _legacyShinyKey = 'shiny_pokemon_ids';
  static const String _savedTeamsKey = 'team_making_saved_teams_v2';
  static const String _legacyTeamKey = 'team_making_saved_team_v1';

  static AchievementProgressSnapshot calculate(
    SharedPreferences preferences,
  ) {
    final selectedGameId =
        preferences.getString(_selectedGameKey) ?? 'lets_go_pikachu';
    final validPokemonIds = pokemonList.map((pokemon) => pokemon.id).toSet();
    final pokemonById = {
      for (final pokemon in pokemonList) pokemon.id: pokemon,
    };

    final caughtByGame = <String, Set<int>>{};
    final caughtKeys = preferences
        .getKeys()
        .where((key) => key.startsWith(_caughtKeyPrefix));
    for (final key in caughtKeys) {
      final gameId = key.substring(_caughtKeyPrefix.length);
      if (gameId.isEmpty) continue;
      final ids = _parseIds(
        preferences.getStringList(key) ?? const <String>[],
      )..retainAll(validPokemonIds);
      caughtByGame[gameId] = ids;
    }
    if (caughtByGame.isEmpty) {
      final legacyIds = preferences.getStringList(_legacyCaughtKey);
      if (legacyIds != null) {
        caughtByGame[selectedGameId] =
            _parseIds(legacyIds)..retainAll(validPokemonIds);
      }
    }

    final allCaughtIds = caughtByGame.values
        .expand((ids) => ids)
        .toSet()
      ..retainAll(validPokemonIds);
    final selectedGameIds =
        Set<int>.from(caughtByGame[selectedGameId] ?? const <int>{});
    final selectedAvailableIds = _availablePokemonIds(selectedGameId);
    final selectedGameCaughtCount =
        selectedGameIds.intersection(selectedAvailableIds).length;

    final shinyIds = <int>{};
    for (final key in preferences.getKeys()) {
      if (!key.startsWith(_shinyKeyPrefix)) continue;
      shinyIds.addAll(
        _parseIds(
          preferences.getStringList(key) ?? const <String>[],
        ),
      );
    }
    shinyIds.addAll(
      _parseIds(
        preferences.getStringList(_legacyShinyKey) ?? const <String>[],
      ),
    );
    shinyIds.retainAll(validPokemonIds);

    final guideTotals = <String, int>{};
    final guideCompleted = <String, int>{};
    final guideStarted = <String, bool>{};
    final guideComplete = <String, bool>{};
    final badgesByGame = <String, Set<String>>{};
    final eliteFourByGame = <String, Set<String>>{};
    final championByGame = <String, bool>{};

    final badgePattern =
        RegExp(r'\b(?:badge|odznak\w*)\b', caseSensitive: false);

    for (final guide in guidesList) {
      final saved = preferences.getStringList(
            'guide_progress_${guide.gameId}_${guide.id}',
          ) ??
          const <String>[];
      final completedIndices = saved
          .map(int.tryParse)
          .whereType<int>()
          .where((index) => index >= 0 && index < guide.steps.length)
          .toSet();

      guideTotals.update(
        guide.gameId,
        (value) => value + guide.steps.length,
        ifAbsent: () => guide.steps.length,
      );
      guideCompleted.update(
        guide.gameId,
        (value) => value + completedIndices.length,
        ifAbsent: () => completedIndices.length,
      );

      final started = preferences.getBool(
            'guide_opened_${guide.gameId}_${guide.id}',
          ) ==
          true;
      if (started || completedIndices.isNotEmpty) {
        guideStarted[guide.gameId] = true;
      }
      if (guide.steps.isNotEmpty &&
          completedIndices.length == guide.steps.length) {
        guideComplete[guide.gameId] = true;
      }

      for (final index in completedIndices) {
        final step = guide.steps[index];
        for (final item in step.items) {
          if (badgePattern.hasMatch(item)) {
            badgesByGame.putIfAbsent(guide.gameId, () => <String>{}).add(
                  item.trim(),
                );
          }
        }

        final title = step.title.toLowerCase();
        final section = (step.section ?? '').toLowerCase();
        if (title.startsWith('pokonaj') &&
            (section.contains('pokémon league') ||
                section.contains('elite four')) &&
            !title.contains('champion')) {
          eliteFourByGame
              .putIfAbsent(guide.gameId, () => <String>{})
              .add(step.title);
        }
        if (title.contains('champion') &&
            (title.contains('hall of fame') ||
                step.description.toLowerCase().contains('hall of fame'))) {
          championByGame[guide.gameId] = true;
        }
      }
    }

    final progressByGame = <String, int>{};
    final candidateGameIds = <String>{
      ...guidesList.map((guide) => guide.gameId),
      ...caughtByGame.keys.where(TeamGameAvailability.supports),
    };
    candidateGameIds.add(selectedGameId);

    for (final gameId in candidateGameIds) {
      final availableIds = _availablePokemonIds(gameId);
      if (availableIds.isEmpty) continue;
      final total = (guideTotals[gameId] ?? 0) + availableIds.length;
      final caughtCount =
          (caughtByGame[gameId] ?? const <int>{})
              .intersection(availableIds)
              .length;
      final completed = (guideCompleted[gameId] ?? 0) + caughtCount;
      progressByGame[gameId] = total == 0
          ? 0
          : (completed * 100 / total).round().clamp(0, 100).toInt();
    }

    final selectedGameTotalGuideSteps = guideTotals[selectedGameId] ?? 0;
    final selectedGameCompletedGuideSteps =
        guideCompleted[selectedGameId] ?? 0;
    final selectedGameProgressPercent =
        progressByGame[selectedGameId] ?? 0;

    final automaticallyUnlocked = <String>{};
    if (allCaughtIds.isNotEmpty) automaticallyUnlocked.add('first_pokemon');
    if (selectedGameCaughtCount > 0) {
      automaticallyUnlocked.add('pokedex_start');
    }
    if (allCaughtIds.length >= 25) automaticallyUnlocked.add('pokedex_25');
    if (allCaughtIds.length >= 50) automaticallyUnlocked.add('pokedex_50');
    if (allCaughtIds.length >= 100) automaticallyUnlocked.add('pokedex_100');
    if (allCaughtIds.length >= pokemonList.length) {
      automaticallyUnlocked.add('pokedex_complete');
    }
    if (shinyIds.isNotEmpty) automaticallyUnlocked.add('shiny');
    if (allCaughtIds.any((id) => pokemonById[id]?.isLegendary == true)) {
      automaticallyUnlocked.add('legendary');
    }
    if (guideStarted[selectedGameId] == true) {
      automaticallyUnlocked.add('guide_start');
    }
    if (guideComplete[selectedGameId] == true) {
      automaticallyUnlocked.add('guide_complete');
    }
    if (badgesByGame.values.any((badges) => badges.isNotEmpty)) {
      automaticallyUnlocked.add('first_badge');
    }
    if (badgesByGame.values.any((badges) => badges.length >= 8)) {
      automaticallyUnlocked.add('eight_badges');
    }
    if (eliteFourByGame.values.any((members) => members.length >= 4)) {
      automaticallyUnlocked.add('elite_four');
    }
    if (championByGame.values.any((completed) => completed)) {
      automaticallyUnlocked.add('champion');
    }
    if (selectedGameProgressPercent >= 25) {
      automaticallyUnlocked.add('speed_progress');
    }
    if (selectedGameProgressPercent >= 50) {
      automaticallyUnlocked.add('half_progress');
    }
    if (selectedGameProgressPercent >= 75) {
      automaticallyUnlocked.add('three_quarters');
    }
    if (progressByGame.values.any((percent) => percent >= 100)) {
      automaticallyUnlocked.add('first_100');
    }
    if (selectedGameProgressPercent >= 100) {
      automaticallyUnlocked.add('game_complete');
    }

    final savedTeams = _readSavedTeamIds(preferences);
    for (final teamIds in savedTeams) {
      final validTeamIds = teamIds
          .where(validPokemonIds.contains)
          .toSet();
      if (validTeamIds.length >= 6) {
        automaticallyUnlocked.add('full_team');
      }
      final teamTypes = validTeamIds
          .expand((id) => pokemonById[id]?.types ?? const <String>[])
          .map((type) => type.toLowerCase())
          .toSet();
      if (teamTypes.length >= 6) {
        automaticallyUnlocked.add('team_types');
      }
    }

    return AchievementProgressSnapshot(
      selectedGameId: selectedGameId,
      globalCaughtCount: allCaughtIds.length,
      selectedGameCaughtCount: selectedGameCaughtCount,
      selectedGamePokemonTotal: selectedAvailableIds.length,
      selectedGameCompletedGuideSteps: selectedGameCompletedGuideSteps,
      selectedGameTotalGuideSteps: selectedGameTotalGuideSteps,
      selectedGameProgressPercent: selectedGameProgressPercent,
      automaticallyUnlockedIds:
          Set<String>.unmodifiable(automaticallyUnlocked),
    );
  }

  static Set<int> _availablePokemonIds(String gameId) {
    return pokemonList
        .where((pokemon) {
          final availability =
              TeamGameAvailability.forPokemon(gameId, pokemon.id);
          return availability.canBeAdded ||
              availability.canBeRecommended ||
              availability.kind == TeamAvailabilityKind.specialAccess;
        })
        .map((pokemon) => pokemon.id)
        .toSet();
  }

  static Set<int> _parseIds(List<String> values) => values
      .map(int.tryParse)
      .whereType<int>()
      .toSet();

  static List<Set<int>> _readSavedTeamIds(
    SharedPreferences preferences,
  ) {
    final teams = <Set<int>>[];
    final encoded = preferences.getString(_savedTeamsKey);
    if (encoded != null) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is List) {
          for (final value in decoded) {
            if (value is! Map) continue;
            final rawIds = value['pokemonIds'];
            if (rawIds is! List) continue;
            final ids = <int>{};
            for (final rawId in rawIds) {
              if (rawId is num) {
                ids.add(rawId.toInt());
              } else {
                final parsed = int.tryParse(rawId.toString());
                if (parsed != null) ids.add(parsed);
              }
            }
            if (ids.isNotEmpty) teams.add(ids);
          }
        }
      } catch (_) {
        // Keep the legacy save available if the newer JSON is damaged.
      }
    }

    if (teams.isEmpty) {
      final legacyIds =
          preferences.getStringList(_legacyTeamKey) ?? const <String>[];
      final parsedLegacy = _parseIds(legacyIds);
      if (parsedLegacy.isNotEmpty) teams.add(parsedLegacy);
    }
    return teams;
  }
}
