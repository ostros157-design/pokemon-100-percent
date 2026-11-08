import '../data/pokemon_data.dart';
import '../data/team_game_availability.dart';
import '../models/pokemon.dart';

/// Recommendations combine type coverage with the existing Pokédex base stats and abilities.
class TeamRecommendation {
  final Pokemon pokemon;
  final int score;
  final List<String> reasons;
  const TeamRecommendation({required this.pokemon, required this.score, required this.reasons});
}

class TeamRecommendationService {
  // Game availability is sourced from regional-dex data. Lists are conservative
  // and do not guarantee every post-game encounter or event distribution.
  static const String supportedGameId = 'lets_go_pikachu';

  static bool isSupportedGame(String gameId) =>
      gameId == supportedGameId || TeamGameAvailability.supports(gameId);

  static bool isAvailableInGame(Pokemon pokemon, String gameId) {
    if (gameId == supportedGameId) {
      const unavailable = {15, 23, 24, 37, 38, 52, 69, 70, 71, 109, 110, 127, 151};
      return pokemon.id >= 1 && pokemon.id <= 151 &&
          !unavailable.contains(pokemon.id);
    }
    return TeamGameAvailability.contains(gameId, pokemon.id);
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
    if (team.isEmpty || !isSupportedGame(gameId)) return const [];
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
    final teamAverages = <String, double>{};
    final statGetters = <String, int? Function(Pokemon)>{
      'HP': (p) => p.hp,
      'Atak': (p) => p.attack,
      'Obrona': (p) => p.defense,
      'Atak specjalny': (p) => p.specialAttack,
      'Obrona specjalna': (p) => p.specialDefense,
      'Szybkość': (p) => p.speed,
    };
    for (final entry in statGetters.entries) {
      final values = team.map(entry.value).whereType<int>().toList();
      if (values.isNotEmpty) {
        teamAverages[entry.key] = values.reduce((a, b) => a + b) / values.length;
      }
    }

    final candidates = pokemonList.where((candidate) =>
      isAvailableInGame(candidate, gameId) &&
      !team.any((member) => member.id == candidate.id) &&
      !(candidate.name == 'Gengar' && team.any((member) => member.name == 'Haunter')));
    final ranked = <TeamRecommendation>[];
    for (final candidate in candidates) {
      final reasons = <String>[];
      var score = 0;

      // Defensive typing: reward candidates that resist or are immune to
      // attack types that currently threaten multiple team members.
      for (final entry in weakCounts.entries) {
        final covered = candidate.types.any((type) =>
          (_resists[type]?.contains(entry.key) ?? false) ||
          (_immune[type]?.contains(entry.key) ?? false));
        if (covered) {
          score += entry.value * 3;
          reasons.add('Chroni przed typem ${entry.key} (${entry.value} podatnych członków)');
        }
      }

      // Base-stat profile: reward standout stats that improve a team-wide gap.
      // Missing values are ignored rather than treated as zero.
      for (final entry in statGetters.entries) {
        final candidateValue = entry.value(candidate);
        final average = teamAverages[entry.key];
        if (candidateValue == null || average == null) continue;
        final difference = candidateValue - average;
        if (difference >= 25) {
          final points = (difference / 15).floor().clamp(1, 4);
          score += points;
          reasons.add('Wysoki parametr: ${entry.key} ${candidateValue} (średnia drużyny: ${average.round()})');
        }
      }

      // Recognized ability effects can cover specific weaknesses even when
      // the Pokémon's own typing does not. Only explicit, well-known effects
      // are scored; all other ability names remain neutral.
      final candidateAbilities = <String>{
        ...candidate.abilities,
        ...candidate.hiddenAbilities,
      }.map((ability) => ability.trim().toLowerCase()).toSet();
      const abilityCoverage = <String, Set<String>>{
        'levitate': {'Ground'},
        'flash fire': {'Fire'},
        'water absorb': {'Water'},
        'storm drain': {'Water'},
        'dry skin': {'Water'},
        'volt absorb': {'Electric'},
        'motor drive': {'Electric'},
        'lightning rod': {'Electric'},
        'sap sipper': {'Grass'},
        'thick fat': {'Fire', 'Ice'},
        'heatproof': {'Fire'},
      };
      for (final ability in candidateAbilities) {
        final coveredTypes = abilityCoverage[ability];
        if (coveredTypes == null) continue;
        for (final type in coveredTypes) {
          final threatened = weakCounts[type] ?? 0;
          if (threatened > 0) {
            score += threatened * 2;
            reasons.add('Umiejętność ${ability[0].toUpperCase()}${ability.substring(1)} pomaga przeciwko typowi ${type}');
          }
        }
      }

      if (score > 0) {
        ranked.add(TeamRecommendation(pokemon: candidate, score: score, reasons: reasons));
      }
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
