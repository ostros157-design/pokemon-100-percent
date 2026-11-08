import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_guide/data/team_game_availability.dart';
import 'package:pokemon_guide/models/pokemon.dart';
import 'package:pokemon_guide/services/team_recommendation_service.dart';

void main() {
  group('TeamGameAvailability', () {
    test('distinguishes selectable games from verified availability data', () {
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
      expect(TeamRecommendationService.isSupportedGame('lets_go_eevee'), isTrue);
      expect(TeamRecommendationService.isSupportedGame('sword'), isTrue);
      expect(TeamRecommendationService.hasVerifiedAvailabilityData('sword'), isFalse);
      expect(TeamRecommendationService.isSupportedGame('leafgreen'), isTrue);
      expect(TeamRecommendationService.isSupportedGame('unknown'), isFalse);
    });

    test('Let’s Go version exclusives are trade-only rather than silently treated as absent', () {
      expect(TeamGameAvailability.forPokemon('lets_go_pikachu', 27).kind, TeamAvailabilityKind.inGame);
      expect(TeamGameAvailability.forPokemon('lets_go_pikachu', 23).kind, TeamAvailabilityKind.tradeRequired);
      expect(TeamGameAvailability.forPokemon('lets_go_eevee', 23).kind, TeamAvailabilityKind.inGame);
      expect(TeamGameAvailability.forPokemon('lets_go_eevee', 27).kind, TeamAvailabilityKind.tradeRequired);
      expect(TeamGameAvailability.forPokemon('leafgreen', 27).kind, TeamAvailabilityKind.inGame);
      expect(TeamGameAvailability.forPokemon('leafgreen', 23).kind, TeamAvailabilityKind.tradeRequired);
      expect(TeamGameAvailability.forPokemon('lets_go_pikachu', 151).kind, TeamAvailabilityKind.specialAccess);
      expect(TeamGameAvailability.forPokemon('lets_go_pikachu', 808).kind, TeamAvailabilityKind.specialAccess);
      expect(TeamGameAvailability.forPokemon('lets_go_pikachu', 809).kind, TeamAvailabilityKind.specialAccess);
    });

    test('FireRed distinguishes LeafGreen trades, post-game, breeding and events', () {
      expect(TeamGameAvailability.forPokemon('firered', 23).kind, TeamAvailabilityKind.inGame);
      expect(TeamGameAvailability.forPokemon('firered', 27).kind, TeamAvailabilityKind.tradeRequired);
      expect(TeamGameAvailability.forPokemon('firered', 194).kind, TeamAvailabilityKind.postGame);
      expect(TeamGameAvailability.forPokemon('firered', 239).kind, TeamAvailabilityKind.breedingRequired);
      expect(TeamGameAvailability.forPokemon('firered', 212).kind, TeamAvailabilityKind.tradeRequired);
      expect(TeamGameAvailability.forPokemon('firered', 386).kind, TeamAvailabilityKind.specialAccess);
    });

    test('regional dex entries are not mislabelled as fully verified encounter methods', () {
      expect(TeamGameAvailability.forPokemon('emerald', 252).kind, TeamAvailabilityKind.regionalDex);
      expect(TeamGameAvailability.forPokemon('emerald', 252).canBeAdded, isTrue);
    });

    test('regional dex omissions are labelled unknown rather than impossible', () {
      expect(TeamGameAvailability.forPokemon('emerald', 1).kind, TeamAvailabilityKind.outsideRegionalDex);
      expect(TeamGameAvailability.forPokemon('sword', 25).kind, TeamAvailabilityKind.unknown);
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
        gameId: 'emerald',
      );
      expect(recommendations.any((entry) => entry.pokemon.name == 'Gengar'), isFalse);
    });
  });
}
