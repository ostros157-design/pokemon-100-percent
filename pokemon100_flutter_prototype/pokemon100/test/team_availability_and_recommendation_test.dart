import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_guide/data/team_game_availability.dart';
import 'package:pokemon_guide/models/pokemon.dart';
import 'package:pokemon_guide/services/team_recommendation_service.dart';

Pokemon species(int id, String name, List<String> types) => Pokemon(
      id: id,
      name: name,
      types: types,
      description: '',
    );

void main() {
  group('TeamGameAvailability', () {
    test('only advertises games with availability data', () {
      for (final game in [
        'emerald',
        'firered',
        'soulsilver',
        'xy',
        'legends_arceus',
      ]) {
        expect(TeamGameAvailability.supports(game), isTrue, reason: game);
      }
      expect(TeamGameAvailability.supports('sword'), isFalse);
      expect(TeamGameAvailability.supports('unknown'), isFalse);
    });

    test('checks representative species against sourced regional dex ranges', () {
      expect(TeamGameAvailability.contains('emerald', 252), isTrue);
      expect(TeamGameAvailability.contains('emerald', 1), isFalse);
      expect(TeamGameAvailability.contains('firered', 150), isTrue);
      expect(TeamGameAvailability.contains('firered', 151), isFalse);
      expect(TeamGameAvailability.contains('xy', 650), isTrue);
      expect(TeamGameAvailability.contains('xy', 899), isFalse);
      expect(TeamGameAvailability.contains('legends_arceus', 905), isTrue);
      expect(TeamGameAvailability.contains('sword', 25), isFalse);
    });
  });

  group('TeamRecommendationService availability', () {
    test('filters species outside the Let’s Go Pokédex range and exclusions', () {
      expect(
        TeamRecommendationService.isAvailableInGame(
          species(25, 'Pikachu', ['Electric']),
          'lets_go_pikachu',
        ),
        isTrue,
      );
      expect(
        TeamRecommendationService.isAvailableInGame(
          species(151, 'Mew', ['Psychic']),
          'lets_go_pikachu',
        ),
        isFalse,
      );
      expect(
        TeamRecommendationService.isAvailableInGame(
          species(152, 'Chikorita', ['Grass']),
          'lets_go_pikachu',
        ),
        isFalse,
      );
    });

    test('returns no recommendations for a game without data', () {
      expect(
        TeamRecommendationService.recommend(
          [species(25, 'Pikachu', ['Electric'])],
          gameId: 'sword',
        ),
        isEmpty,
      );
    });

    test('does not recommend Gengar when Haunter is already on the team', () {
      final team = [species(93, 'Haunter', ['Ghost', 'Poison'])];
      final recommendations = TeamRecommendationService.recommend(
        team,
        gameId: 'lets_go_pikachu',
      );
      expect(
        recommendations.any((entry) => entry.pokemon.name == 'Gengar'),
        isFalse,
      );
    });
  });
}
