import 'dart:convert';

import 'package:flutter/services.dart';

/// One Pokémon–move–game learnset row imported from PokéAPI.
class PokemonLearnsetEntry {
  final int pokemonId;
  final int moveId;
  final int versionGroupId;
  final String versionGroup;
  final int methodId;
  final int level;
  final int? order;

  const PokemonLearnsetEntry({
    required this.pokemonId,
    required this.moveId,
    required this.versionGroupId,
    required this.versionGroup,
    required this.methodId,
    required this.level,
    this.order,
  });

  factory PokemonLearnsetEntry.fromJson(Map<String, dynamic> json) {
    return PokemonLearnsetEntry(
      pokemonId: (json['pokemonId'] as num).toInt(),
      moveId: (json['moveId'] as num).toInt(),
      versionGroupId: (json['versionGroupId'] as num).toInt(),
      versionGroup: json['versionGroup'] as String? ?? 'unknown',
      methodId: (json['methodId'] as num).toInt(),
      level: (json['level'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt(),
    );
  }

  String get methodLabel => switch (methodId) {
        1 => 'Poziom',
        2 => 'Jajko',
        3 => 'Tutor',
        4 => 'Maszyna (TM/HM)',
        5 => 'Specjalny ruch Pikachu',
        6 => 'Jajko z Light Ball',
        7 => 'Oczyszczenie (Colosseum)',
        8 => 'Oczyszczenie (XD)',
        9 => 'Zmiana formy',
        10 => 'Przypomnienie ruchu',
        11 => 'Ponowne nauczenie ruchu',
        _ => 'Metoda #$methodId',
      };
}

/// Offline reader for the generated PokéAPI learnset asset.
/// Missing asset is treated as "not imported yet", not as an app crash.
class PokemonLearnsetData {
  static const assetPath = 'assets/data/pokemon_learnsets.json';
  static Future<List<PokemonLearnsetEntry>>? _cache;

  static Future<List<PokemonLearnsetEntry>> load() {
    return _cache ??= _load();
  }

  static Future<List<PokemonLearnsetEntry>> _load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PokemonLearnsetEntry.fromJson)
          .toList(growable: false);
    } on FlutterError {
      return const <PokemonLearnsetEntry>[];
    } on FormatException {
      return const <PokemonLearnsetEntry>[];
    } on TypeError {
      return const <PokemonLearnsetEntry>[];
    }
  }

  static Future<List<PokemonLearnsetEntry>> forPokemon(int pokemonId) async {
    final all = await load();
    return all.where((entry) => entry.pokemonId == pokemonId).toList(growable: false);
  }

  /// Available game groups for a Pokémon, in a stable display order.
  static Future<List<String>> versionGroupsForPokemon(int pokemonId) async {
    final entries = await forPokemon(pokemonId);
    final groups = entries.map((entry) => entry.versionGroup).toSet().toList();
    groups.sort();
    return groups;
  }

  /// Look up all learnset rows for one game group.
  static Future<List<PokemonLearnsetEntry>> forPokemonAndVersion(
    int pokemonId,
    String versionGroup,
  ) async {
    final entries = await forPokemon(pokemonId);
    return entries
        .where((entry) => entry.versionGroup == versionGroup)
        .toList(growable: false);
  }
}
