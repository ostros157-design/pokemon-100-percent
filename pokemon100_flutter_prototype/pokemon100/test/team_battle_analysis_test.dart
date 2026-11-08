import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_guide/models/pokemon.dart';
import 'package:pokemon_guide/services/team_battle_analysis.dart';

void main() {
  group('TeamBattleAnalysis', () {
    test('calculates weaknesses, resistances and immunities for dual types', () {
      const pikachu = Pokemon(
        id: 25, name: 'Pikachu', types: ['Electric'], description: '',
      );
      const charizard = Pokemon(
        id: 6, name: 'Charizard', types: ['Fire', 'Flying'], description: '',
      );
      final profile = TeamBattleAnalysis.analyze([pikachu, charizard], const {});
      expect(profile.weaknesses['Ground'], 1);
      expect(profile.immunities['Ground'], 1);
      expect(profile.resistances['Fire'], 1);
    });

    test('tracks STAB, super-effective coverage and recognized ability synergies', () {
      const raichu = Pokemon(
        id: 26,
        name: 'Raichu',
        types: ['Electric'],
        description: '',
        attack: 40,
        specialAttack: 100,
        abilities: ['Adaptability', 'Technician'],
      );
      final profile = TeamBattleAnalysis.analyze(
        [raichu],
        const {26: ['Thunderbolt', 'Quick Attack']},
      );
      expect(profile.damagingMoveCount, 2);
      expect(profile.stabMoveCount, 1);
      expect(profile.coveredTypes, containsAll(['Water', 'Flying']));
      expect(profile.synergyHints.any((hint) => hint.contains('Adaptability')), isTrue);
      expect(profile.synergyHints.any((hint) => hint.contains('Technician')), isTrue);
      expect(profile.synergyHints.any((hint) => hint.contains('Atak specjalny')), isTrue);
    });

    test('recognizes curated ability synergies with assigned moves', () {
      const hitmonlee = Pokemon(
        id: 106,
        name: 'Hitmonlee',
        types: ['Fighting'],
        description: '',
        attack: 120,
        specialAttack: 30,
        abilities: [
          'Iron Fist', 'Strong Jaw', 'Mega Launcher', 'Sharpness',
          'Punk Rock', 'Huge Power', 'Skill Link', 'Reckless',
        ],
      );
      final profile = TeamBattleAnalysis.analyze(
        [hitmonlee],
        const {
          106: [
            'Fire Punch', 'Crunch', 'Aura Sphere', 'Leaf Blade',
            'Hyper Voice', 'Bullet Seed', 'Flare Blitz',
          ],
        },
      );
      for (final ability in [
        'Iron Fist', 'Strong Jaw', 'Mega Launcher', 'Sharpness',
        'Punk Rock', 'Huge Power', 'Skill Link', 'Reckless',
      ]) {
        expect(profile.synergyHints.any((hint) => hint.contains(ability)), isTrue, reason: ability);
      }
    });

    test('uses generation-specific Fairy type and physical/special rules', () {
      const houndoom = Pokemon(
        id: 229,
        name: 'Houndoom',
        types: ['Dark', 'Fire'],
        description: '',
        attack: 30,
        specialAttack: 100,
      );
      final genThree = TeamBattleAnalysis.analyze(
        [houndoom],
        const {229: ['Bite']},
        gameId: 'emerald',
      );
      final modern = TeamBattleAnalysis.analyze(
        [houndoom],
        const {229: ['Bite']},
        gameId: 'lets_go_pikachu',
      );
      expect(genThree.uncoveredTypes, isNot(contains('Fairy')));
      expect(genThree.synergyHints.any((hint) => hint.contains('Atak specjalny')), isFalse);
      expect(modern.synergyHints.any((hint) => hint.contains('Atak specjalny')), isTrue);
    });

    test('does not report unknown move names as valid coverage', () {
      const pokemon = Pokemon(
        id: 25, name: 'Pikachu', types: ['Electric'], description: '',
      );
      final profile = TeamBattleAnalysis.analyze(
        [pokemon],
        const {25: ['Thunderbolt', 'Not A Real Move']},
      );
      expect(profile.unknownMoves, contains('Pikachu: Not A Real Move'));
      expect(profile.coveredTypes, contains('Water'));
    });

    test('reports missing targets across the modern type chart', () {
      const pokemon = Pokemon(
        id: 25, name: 'Pikachu', types: ['Electric'], description: '',
      );
      final profile = TeamBattleAnalysis.analyze(
        [pokemon],
        const {25: ['Thunderbolt']},
      );
      expect(profile.uncoveredTypes, contains('Normal'));
      expect(profile.uncoveredTypes, isNot(contains('Water')));
    });
  });
}
