import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pokemon_guide/data/achievements_data.dart';
import 'package:pokemon_guide/data/guides_data.dart';
import 'package:pokemon_guide/data/pokemon_data.dart';
import 'package:pokemon_guide/data/team_game_availability.dart';
import 'package:pokemon_guide/screens/achievements_screen.dart';
import 'package:pokemon_guide/services/achievement_progress_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('all achievements are visible and have unique ids', () {
    expect(achievementsList, isNotEmpty);
    expect(
        achievementsList.every((achievement) => !achievement.hidden), isTrue);
    expect(
      achievementsList.map((achievement) => achievement.id).toSet().length,
      achievementsList.length,
    );
  });

  test('guide completion automatically unlocks badge and league milestones',
      () async {
    final guide = guidesList.firstWhere(
      (candidate) => candidate.gameId == 'emerald',
    );
    final preferences = await SharedPreferences.getInstance();
    final completed = List.generate(
      guide.steps.length,
      (index) => index.toString(),
    );

    await preferences.setString('selected_pokemon_game_id', 'emerald');
    await preferences.setBool(
      'guide_opened_${guide.gameId}_${guide.id}',
      true,
    );
    await preferences.setStringList(
      'guide_progress_${guide.gameId}_${guide.id}',
      completed,
    );

    final progress = AchievementProgressService.calculate(preferences);

    for (final id in [
      'guide_start',
      'guide_complete',
      'first_badge',
      'eight_badges',
      'elite_four',
      'champion',
    ]) {
      expect(
        progress.automaticallyUnlockedIds,
        contains(id),
        reason: 'Expected $id after all Emerald guide steps were completed.',
      );
    }
    expect(
        progress.automaticallyUnlockedIds, isNot(contains('first_evolution')));
    expect(
        progress.automaticallyUnlockedIds, isNot(contains('trade_evolution')));
    expect(
        progress.automaticallyUnlockedIds, isNot(contains('games_complete')));
    expect(progress.automaticallyUnlockedIds, isNot(contains('all_games')));
  });

  test('Pokédex milestones, shiny and legendary achievements are automatic',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final caughtIds = [
      ...List.generate(100, (index) => index + 1),
      150,
    ];

    await preferences.setString('selected_pokemon_game_id', 'lets_go_pikachu');
    await preferences.setStringList(
      'caught_pokemon_ids_lets_go_pikachu',
      caughtIds.map((id) => id.toString()).toList(),
    );
    await preferences.setStringList(
      'shiny_pokemon_ids_lets_go_pikachu',
      ['25'],
    );

    final progress = AchievementProgressService.calculate(preferences);

    for (final id in [
      'first_pokemon',
      'pokedex_start',
      'pokedex_25',
      'pokedex_50',
      'pokedex_100',
      'legendary',
      'shiny',
    ]) {
      expect(progress.automaticallyUnlockedIds, contains(id));
    }
    expect(progress.globalCaughtCount, 101);
    expect(progress.selectedGamePokemonTotal, 153);
    expect(
        progress.automaticallyUnlockedIds, isNot(contains('pokedex_complete')));
  });

  test('a completed game uses its verified availability list for 100%',
      () async {
    final guide = guidesList.firstWhere(
      (candidate) => candidate.gameId == 'lets_go_pikachu',
    );
    final preferences = await SharedPreferences.getInstance();
    final availableIds = pokemonList
        .where((pokemon) {
          final availability = TeamGameAvailability.forPokemon(
            'lets_go_pikachu',
            pokemon.id,
          );
          return availability.canBeAdded ||
              availability.canBeRecommended ||
              availability.kind == TeamAvailabilityKind.specialAccess;
        })
        .map((pokemon) => pokemon.id)
        .toList();
    final completedSteps = List.generate(
      guide.steps.length,
      (index) => index.toString(),
    );

    await preferences.setString('selected_pokemon_game_id', 'lets_go_pikachu');
    await preferences.setStringList(
      'caught_pokemon_ids_lets_go_pikachu',
      availableIds.map((id) => id.toString()).toList(),
    );
    await preferences.setStringList(
      'guide_progress_${guide.gameId}_${guide.id}',
      completedSteps,
    );

    final progress = AchievementProgressService.calculate(preferences);

    expect(availableIds.length, 153);
    expect(progress.selectedGamePokemonTotal, 153);
    expect(progress.selectedGameProgressPercent, 100);
    expect(progress.automaticallyUnlockedIds, contains('first_100'));
    expect(progress.automaticallyUnlockedIds, contains('game_complete'));
    expect(progress.automaticallyUnlockedIds, contains('guide_complete'));
  });

  test('a saved six-Pokémon team unlocks team achievements', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'team_making_saved_teams_v2',
      jsonEncode([
        {
          'id': 'test-team',
          'name': 'Test team',
          'gameId': 'emerald',
          'pokemonIds': [1, 4, 7, 25, 66, 16],
          'movesByPokemon': <String, dynamic>{},
        },
      ]),
    );

    final progress = AchievementProgressService.calculate(preferences);

    expect(progress.automaticallyUnlockedIds, contains('full_team'));
    expect(progress.automaticallyUnlockedIds, contains('team_types'));
  });

  testWidgets('manual achievement unlock persists after screen recreation',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AchievementsScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pierwszy Pokémon'), findsOneWidget);
    await tester.tap(find.byTooltip('Oznacz jako zdobyte').first);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('manual_achievement_ids'),
      contains('first_pokemon'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const MaterialApp(home: AchievementsScreen()),
    );
    await tester.pumpAndSettle();

    expect(
      preferences.getStringList('manual_achievement_ids'),
      contains('first_pokemon'),
    );
    expect(find.byTooltip('Cofnij ręczne oznaczenie'), findsWidgets);
  });
}
