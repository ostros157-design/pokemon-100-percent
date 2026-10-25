/// Dane gatunku Pokémona. Pola rozszerzone są nullable, aby brakujące
/// źródłowe dane nie były zastępowane zmyślonymi wartościami.
class Pokemon {
  final int id;
  final String name;
  final List<String> types;
  final String description;

  /// Statystyki bazowe w kolejności używanej w grach głównej serii.
  final int? hp;
  final int? attack;
  final int? defense;
  final int? specialAttack;
  final int? specialDefense;
  final int? speed;

  /// Wzrost w decymetrach i masa w hektogramach (jednostki PokéAPI).
  final int? height;
  final int? weight;
  final int? baseExperience;

  /// Nazwy umiejętności; hiddenAbilities oznacza umiejętności ukryte.
  final List<String> abilities;
  final List<String> hiddenAbilities;

  const Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.description,
    this.hp,
    this.attack,
    this.defense,
    this.specialAttack,
    this.specialDefense,
    this.speed,
    this.height,
    this.weight,
    this.baseExperience,
    this.abilities = const <String>[],
    this.hiddenAbilities = const <String>[],
  });

  int? get baseStatTotal {
    final values = <int?>[hp, attack, defense, specialAttack, specialDefense, speed];
    if (values.any((value) => value == null)) return null;
    return values.cast<int>().fold<int>(0, (sum, value) => sum + value);
  }

  bool get hasCompleteBaseStats => baseStatTotal != null;
}
