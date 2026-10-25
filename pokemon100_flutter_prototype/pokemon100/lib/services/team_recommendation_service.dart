import '../data/pokemon_data.dart';
import '../models/pokemon.dart';

/// Recommendations use the types in the local Pokédex only. The current
/// Pokemon model does not contain game availability, moves, abilities, or stats.
class TeamRecommendation {
  final Pokemon pokemon;
  final int score;
  final List<String> reasons;
  const TeamRecommendation({required this.pokemon, required this.score, required this.reasons});
}

class TeamRecommendationService {
  // Confirmed conservative species filter for Let's Go, Pikachu!: the 151
  // Kanto species, excluding Eevee-version exclusives and Mythicals that are
  // not normally obtainable in-game. Trade evolutions remain available via trade.
  static const String supportedGameId = 'lets_go_pikachu';
  static const Set<int> _letsGoPikachuUnavailable = {
    15, 23, 24, 37, 38, 52, 69, 70, 71, 109, 110, 127, 151,
  };

  static bool isAvailableInGame(Pokemon pokemon, String gameId) {
    if (gameId != supportedGameId) return false;
    return pokemon.id >= 1 && pokemon.id <= 151 &&
        !_letsGoPikachuUnavailable.contains(pokemon.id);
  }
  static const Map<String, Set<String>> _superEffectiveAgainst = {
    'Normal': {}, 'Fire': {'Grass', 'Ice', 'Bug', 'Steel'},
    'Water': {'Fire', 'Ground', 'Rock'}, 'Electric': {'Water', 'Flying'},
    'Grass': {'Water', 'Ground', 'Rock'}, 'Ice': {'Grass', 'Ground', 'Flying', 'Dragon'},
    'Fighting': {'Normal', 'Ice', 'Rock', 'Dark', 'Steel'}, 'Poison': {'Grass', 'Fairy'},
    'Ground': {'Fire', 'Electric', 'Poison', 'Rock', 'Steel'}, 'Flying': {'Grass', 'Fighting', 'Bug'},
    'Psychic': {'Fighting', 'Poison'}, 'Bug': {'Grass', 'Psychic', 'Dark'},
    'Rock': {'Fire', 'Ice', 'Flying', 'Bug'}, 'Ghost': {'Psychic', 'Ghost'},
    'Dragon': {'Dragon'}, 'Dark': {'Psychic', 'Ghost'},
    'Steel': {'Ice', 'Rock', 'Fairy'}, 'Fairy': {'Fighting', 'Dragon', 'Dark'},
  };
  static const Map<String, Set<String>> _resists = {
    'Normal': {}, 'Fire': {'Fire', 'Grass', 'Ice', 'Bug', 'Steel', 'Fairy'},
    'Water': {'Fire', 'Water', 'Ice', 'Steel'}, 'Electric': {'Electric', 'Flying', 'Steel'},
    'Grass': {'Water', 'Electric', 'Grass', 'Ground'}, 'Ice': {'Ice'},
    'Fighting': {'Bug', 'Rock', 'Dark'}, 'Poison': {'Grass', 'Fighting', 'Poison', 'Bug', 'Fairy'},
    'Ground': {'Poison', 'Rock'}, 'Flying': {'Fighting', 'Bug', 'Grass'},
    'Psychic': {'Fighting', 'Psychic'}, 'Bug': {'Fighting', 'Ground', 'Grass'},
    'Rock': {'Normal', 'Fire', 'Poison', 'Flying'}, 'Ghost': {'Poison', 'Bug'},
    'Dragon': {'Fire', 'Water', 'Electric', 'Grass'}, 'Dark': {'Ghost', 'Dark'},
    'Steel': {'Normal', 'Grass', 'Ice', 'Flying', 'Psychic', 'Bug', 'Rock', 'Dragon', 'Steel', 'Fairy'},
    'Fairy': {'Fighting', 'Bug', 'Dark'},
  };
  static const Map<String, Set<String>> _immune = {
    'Normal': {'Ghost'}, 'Electric': {}, 'Ground': {'Electric'}, 'Flying': {'Ground'},
    'Ghost': {'Normal', 'Fighting'}, 'Dark': {'Psychic'}, 'Steel': {'Poison'}, 'Fairy': {'Dragon'},
  };

  static List<TeamRecommendation> recommend(List<Pokemon> team, {String gameId = supportedGameId, int limit = 5}) {
    if (team.isEmpty || gameId != supportedGameId) return const [];
    final weakCounts = <String, int>{};
    for (final attackType in _superEffectiveAgainst.keys) {
      final count = team.where((member) {
        var multiplier = 1.0;
        for (final defenseType in member.types) {
          if (_immune[defenseType]?.contains(attackType) ?? false) { multiplier = 0; break; }
          if (_superEffectiveAgainst[attackType]!.contains(defenseType)) multiplier *= 2;
          if (_resists[defenseType]?.contains(attackType) ?? false) multiplier *= 0.5;
        }
        return multiplier > 1;
      }).length;
      if (count > 0) weakCounts[attackType] = count;
    }
    final candidates = pokemonList.where((candidate) =>
      isAvailableInGame(candidate, gameId) &&
      !team.any((member) => member.id == candidate.id) &&
      !(candidate.name == 'Gengar' && team.any((member) => member.name == 'Haunter')));
    final ranked = <TeamRecommendation>[];
    for (final candidate in candidates) {
      final reasons = <String>[];
      var score = 0;
      for (final entry in weakCounts.entries) {
        final covered = candidate.types.any((type) =>
          (_resists[type]?.contains(entry.key) ?? false) ||
          (_immune[type]?.contains(entry.key) ?? false));
        if (covered) {
          score += entry.value;
          reasons.add('Pomaga przeciwko typowi ${entry.key} (${entry.value} podatnych członków drużyny)');
        }
      }
      if (score > 0) ranked.add(TeamRecommendation(pokemon: candidate, score: score, reasons: reasons));
    }
    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byTypes = b.pokemon.types.length.compareTo(a.pokemon.types.length);
      return byTypes != 0 ? byTypes : a.pokemon.id.compareTo(b.pokemon.id);
    });
    return ranked.take(limit).toList();
  }
}
