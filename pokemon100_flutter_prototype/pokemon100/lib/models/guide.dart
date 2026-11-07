
class GuideStep {
final String title;
final String description;
final String? location;
final String? section;
final List<String> pokemon;
/// Trainer names explicitly listed for this step when available.
final List<String> trainers;
/// Verified encounter percentages for each Pokémon at this guide step/location.
/// Keys must match Pokémon names; values are percentages from 0 to 100.
final Map<String, double> encounterRatesPercent;
/// Pokémon without a verified wild encounter rate are treated as trainer Pokémon.
List<String> get trainerPokemon => pokemon
    .where((name) => !encounterRatesPercent.keys.any(
          (wildName) => wildName.toLowerCase() == name.toLowerCase(),
        ))
    .toList(growable: false);

/// Pokémon with a verified encounter percentage at this location.
List<String> get wildPokemon => pokemon
    .where((name) => encounterRatesPercent.keys.any(
          (wildName) => wildName.toLowerCase() == name.toLowerCase(),
        ))
    .toList(growable: false);

final List<String> items;
final bool optional;

const GuideStep({
required this.title,
required this.description,
this.location,
this.section,
this.pokemon = const [],
this.trainers = const [],
this.encounterRatesPercent = const {},
this.items = const [],
this.optional = false,
});
}

class Guide {
final String id;
final String gameId;
final String title;
final String description;
final List<String> sections;
final List<GuideStep> steps;

const Guide({
required this.id,
required this.gameId,
required this.title,
required this.description,
this.sections = const [],
this.steps = const [],
});
}
