import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_guide/data/team_game_availability.dart';
import 'package:pokemon_guide/models/pokemon.dart';
import 'package:pokemon_guide/services/team_recommendation_service.dart';

void main() {
  group('TeamGameAvailability', () {
    test('only games with data are marked as supported', () {
      for (final game in [
        'lets_go_pikachu',
        'emerald',
        'firered',
        'soulsilver',
        'xy',
        'legends_arceus',
      ]) {
        expect(TeamRecommendationService.isSupportedGame(game), isTrue,
            reason: '$game should be supported');
      }
      expect(TeamRecommendationService.isSupportedGame('sword'), isFalse);
      expect(TeamRecommendationService.isSupportedGame('unknown'), isFalse);
    });

    test('regional dex membership handles included and excluded species', () {
      expect(TeamGameAvailability.contains('emerald', 252), isTrue);
      expect(TeamGameAvailability.contains('emerald', 1), isFalse);
      expect(TeamGameAvailability.contains('legends_arceus', 899), isTrue);
      expect(TeamGameAvailability.contains('legends_arceus', 25), isTrue);
      expect(TeamGameAvailability.contains('unknown', 25), isFalse);
    });

    test('XY availability is the union of the X and Y datasets', () {
      expect(TeamGameAvailability.contains('xy', 650), isTrue);
      expect(TeamGameAvailability.contains('xy', 719), isFalse);
    });
  });

  group('TeamRecommendationService', () {
    const pikachu = Pokemon(
      id: 25,
      name: 'Pikachu',
      types: ['Electric'],
      description: '',
    );
    const unavailableInLetsGo = Pokemon(
      id: 151,
      name: 'Mew',
      types: ['Psychic'],
      description: '',
    );

    test('Let’s Go availability excludes Mew and accepts Pikachu', () {
      expect(TeamRecommendationService.isAvailableInGame(pikachu, 'lets_go_pikachu'), isTrue);
      expect(TeamRecommendationService.isAvailableInGame(unavailableInLetsGo, 'lets_go_pikachu'), isFalse);
    });

    test('unsupported game returns no recommendations', () {
      expect(TeamRecommendationService.recommend([pikachu], gameId: 'sword'), isEmpty);
    });

    test('Haunter preference prevents recommending Gengar', () {
      const haunter = Pokemon(
        id: 93,
        name: 'Haunter',
        types: ['Ghost', 'Poison'],
        description: '',
      );
      final recommendations = TeamRecommendationService.recommend(
        [haunter],
        gameId: 'lets_go_pikachu',
      );
      expect(recommendations.any((entry) => entry.pokemon.name == 'Gengar'), isFalse);
    });
  });
}
