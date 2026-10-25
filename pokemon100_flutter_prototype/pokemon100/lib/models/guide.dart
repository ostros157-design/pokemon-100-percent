
class GuideStep {
final String title;
final String description;
final String? location;
final List<String> pokemon;
/// Verified encounter percentages for each Pokémon at this guide step/location.
/// Keys must match Pokémon names; values are percentages from 0 to 100.
final Map<String, double> encounterRatesPercent;
final List<String> items;
final bool optional;

const GuideStep({
required this.title,
required this.description,
this.location,
this.pokemon = const [],
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
