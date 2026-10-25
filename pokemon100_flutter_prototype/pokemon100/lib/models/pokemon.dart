/// Dane gatunku Pokémona. Wartości nieznane pozostają null.
class Pokemon {
  final int id;
  final String name;
  final List<String> types;
  final String description;
  final int? hp, attack, defense, specialAttack, specialDefense, speed;
  /// Wzrost w decymetrach, masa w hektogramach.
  final int? height, weight, baseExperience;
  final List<String> abilities, hiddenAbilities;
  /// Dane pochodzące z rekordu gatunku PokéAPI.
  final int? captureRate, baseHappiness, hatchCounter, genderRate;
  final bool isLegendary, isMythical, isBaby;
  final int? generation;

  const Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.description,
    this.hp, this.attack, this.defense, this.specialAttack, this.specialDefense, this.speed,
    this.height, this.weight, this.baseExperience,
    this.abilities = const <String>[],
    this.hiddenAbilities = const <String>[],
    this.captureRate, this.baseHappiness, this.hatchCounter, this.genderRate, this.generation,
    this.isLegendary = false, this.isMythical = false, this.isBaby = false,
  });

  int? get baseStatTotal {
    final values = <int?>[hp, attack, defense, specialAttack, specialDefense, speed];
    if (values.any((value) => value == null)) return null;
    return values.cast<int>().fold<int>(0, (sum, value) => sum + value);
  }

  bool get hasCompleteBaseStats => baseStatTotal != null;
}
