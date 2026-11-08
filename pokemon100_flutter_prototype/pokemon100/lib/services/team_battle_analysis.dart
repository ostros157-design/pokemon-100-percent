import '../data/move_data.dart';
import '../models/pokemon.dart';

class TeamBattleProfile {
  final Map<String, int> weaknesses, resistances, immunities;
  final Map<String, List<String>> moveCoverage;
  final List<String> uncoveredTypes, unknownMoves, synergyHints;
  final int configuredMoveSets, damagingMoveCount, stabMoveCount;

  const TeamBattleProfile({
    required this.weaknesses,
    required this.resistances,
    required this.immunities,
    required this.moveCoverage,
    required this.uncoveredTypes,
    required this.unknownMoves,
    required this.synergyHints,
    required this.configuredMoveSets,
    required this.damagingMoveCount,
    required this.stabMoveCount,
  });

  Set<String> get coveredTypes => moveCoverage.keys.toSet();
}

/// Shared type-chart, move-coverage and ability-synergy calculations.
class TeamBattleAnalysis {
  static const Map<String, Set<String>> _strongAgainst = {
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
    'Normal': {'Ghost'}, 'Ground': {'Electric'}, 'Flying': {'Ground'},
    'Ghost': {'Normal', 'Fighting'}, 'Dark': {'Psychic'},
    'Steel': {'Poison'}, 'Fairy': {'Dragon'},
  };
  static const Map<String, String> _types = {
    'normal': 'Normal', 'fire': 'Fire', 'water': 'Water', 'electric': 'Electric',
    'grass': 'Grass', 'ice': 'Ice', 'fighting': 'Fighting', 'poison': 'Poison',
    'ground': 'Ground', 'flying': 'Flying', 'psychic': 'Psychic', 'bug': 'Bug',
    'rock': 'Rock', 'ghost': 'Ghost', 'dragon': 'Dragon', 'dark': 'Dark',
    'steel': 'Steel', 'fairy': 'Fairy',
  };
  static const Map<String, Set<String>> _defensiveAbilities = {
    'levitate': {'Ground'}, 'flash fire': {'Fire'},
    'water absorb': {'Water'}, 'storm drain': {'Water'}, 'dry skin': {'Water'},
    'volt absorb': {'Electric'}, 'motor drive': {'Electric'},
    'lightning rod': {'Electric'}, 'sap sipper': {'Grass'},
    'thick fat': {'Fire', 'Ice'}, 'heatproof': {'Fire'},
  };
  static const Set<String> _punches = {
    'fire punch', 'ice punch', 'thunder punch', 'drain punch', 'dynamic punch',
    'focus punch', 'hammer arm', 'ice hammer', 'mach punch', 'mega punch',
    'meteor mash', 'shadow punch', 'sky uppercut', 'power-up punch',
    'bullet punch', 'plasma fists', 'surging strikes', 'wicked blow',
  };
  static const Set<String> _bites = {
    'bite', 'crunch', 'fire fang', 'ice fang', 'thunder fang',
    'poison fang', 'hyper fang', 'psychic fangs',
  };
  static const Set<String> _pulses = {
    'aura sphere', 'dark pulse', 'dragon pulse', 'heal pulse',
    'origin pulse', 'terrain pulse', 'water pulse',
  };
  static const Set<String> _blades = {
    'aerial ace', 'aqua cutter', 'bitter blade', 'ceaseless edge', 'cut',
    'fury cutter', 'leaf blade', 'night slash', 'psycho cut', 'razor leaf',
    'sacred sword', 'secret sword', 'shadow claw', 'slash', 'solar blade',
    'stone axe', 'x-scissor', 'kowtow cleave',
  };
  static const Set<String> _soundMoves = {
    'boomburst', 'disarming voice', 'echoed voice', 'hyper voice',
    'overdrive', 'round', 'relic song', 'snarl', 'sparkling aria', 'uproar',
  };
  static const Set<String> _multiHitMoves = {
    'arm thrust', 'barrage', 'bone rush', 'bullet seed', 'double slap',
    'fury attack', 'fury swipes', 'icicle spear', 'pin missile',
    'rock blast', 'spike cannon', 'tail slap', 'water shuriken',
    'scale shot', 'population bomb',
  };
  static const Set<String> _recoilMoves = {
    'brave bird', 'double-edge', 'flare blitz', 'head charge',
    'head smash', 'submission', 'take down', 'volt tackle',
    'wild charge', 'wood hammer', 'wave crash', 'chloroblast',
  };

  static double effectiveness(String attackType, List<String> defendingTypes) {
    var multiplier = 1.0;
    for (final raw in defendingTypes) {
      final defense = _types[raw.toLowerCase()] ?? raw;
      if (_immune[defense]?.contains(attackType) ?? false) return 0;
      if (_strongAgainst[attackType]?.contains(defense) ?? false) {
        multiplier *= 2;
      } else if (_resists[defense]?.contains(attackType) ?? false) {
        multiplier *= 0.5;
      }
    }
    return multiplier;
  }

  static TeamBattleProfile analyze(
    List<Pokemon> team,
    Map<int, List<String>> movesByPokemon, {
    String gameId = 'lets_go_pikachu',
  }) {
    final hasFairyType = !{'emerald', 'firered', 'soulsilver'}.contains(gameId);
    final usesTypeBasedPhysicalSpecial = {'emerald', 'firered'}.contains(gameId);
    final weaknesses = <String, int>{};
    final resistances = <String, int>{};
    final immunities = <String, int>{};
    for (final attackType in _types.values.where((type) => hasFairyType || type != 'Fairy')) {
      var weak = 0, resist = 0, immune = 0;
      for (final pokemon in team) {
        final value = effectiveness(attackType, pokemon.types);
        if (value > 1) weak++;
        if (value > 0 && value < 1) resist++;
        if (value == 0) immune++;
      }
      if (weak > 0) weaknesses[attackType] = weak;
      if (resist > 0) resistances[attackType] = resist;
      if (immune > 0) immunities[attackType] = immune;
    }

    final catalogue = <String, MoveData>{
      for (final move in moveCatalogue) move.name.trim().toLowerCase(): move,
    };
    final coverage = <String, List<String>>{};
    final unknown = <String>[];
    final hints = <String>[];
    var damaging = 0, stab = 0, configured = 0;
    final targets = _strongAgainst.values.expand((values) => values)
        .where((type) => hasFairyType || type != 'Fairy').toSet();
    const genThreePhysicalTypes = {
      'normal', 'fighting', 'flying', 'poison', 'ground', 'rock', 'bug', 'ghost', 'steel',
    };

    for (final pokemon in team) {
      final assigned = movesByPokemon[pokemon.id] ?? const <String>[];
      if (assigned.isNotEmpty) configured++;
      final abilities = <String>{...pokemon.abilities, ...pokemon.hiddenAbilities}
          .map((value) => value.trim().toLowerCase()).toSet();
      var physical = 0, special = 0, lowPower = 0;
      var punches = 0, bites = 0, pulses = 0, blades = 0, sounds = 0, pokemonStab = 0;
      var multiHit = 0, recoil = 0;
      final moveTypeCounts = <String, int>{};
      final physicalNames = <String>[], specialNames = <String>[];

      for (final rawName in assigned) {
        final name = rawName.trim().toLowerCase();
        final move = catalogue[name];
        if (move == null) {
          if (rawName.trim().isNotEmpty) unknown.add(pokemon.name + ': ' + rawName);
          continue;
        }
        if (move.category == 'status' || (move.power ?? 0) <= 0) continue;
        damaging++;
        final type = _types[move.type.toLowerCase()];
        if (type == null || (!hasFairyType && type == 'Fairy')) continue;
        if (pokemon.types.any((value) => value.toLowerCase() == type.toLowerCase())) {
          stab++;
          pokemonStab++;
        }
        moveTypeCounts[type] = (moveTypeCounts[type] ?? 0) + 1;
        for (final target in targets) {
          if (effectiveness(type, [target]) > 1) {
            final label = pokemon.name + ' — ' + move.name;
            coverage.putIfAbsent(target, () => <String>[]);
            if (!coverage[target]!.contains(label)) coverage[target]!.add(label);
          }
        }
        final category = usesTypeBasedPhysicalSpecial
            ? (genThreePhysicalTypes.contains(move.type.toLowerCase()) ? 'physical' : 'special')
            : move.category;
        if (category == 'physical') {
          physical++;
          physicalNames.add(move.name);
        } else if (category == 'special') {
          special++;
          specialNames.add(move.name);
        }
        if ((move.power ?? 999) <= 60) lowPower++;
        if (_punches.contains(name)) punches++;
        if (_bites.contains(name)) bites++;
        if (_pulses.contains(name)) pulses++;
        if (_blades.contains(name)) blades++;
        if (_soundMoves.contains(name)) sounds++;
        if (_multiHitMoves.contains(name)) multiHit++;
        if (_recoilMoves.contains(name)) recoil++;
      }

      if (pokemonStab > 0) {
        hints.add(pokemon.name + ': ' + pokemonStab.toString() + ' ruchów STAB zgodnych z typem Pokémona.');
      }
      if (pokemon.attack != null && pokemon.specialAttack != null &&
          pokemon.specialAttack! - pokemon.attack! >= 20 && physical > 0) {
        hints.add(pokemon.name + ': ma wyższy Atak specjalny niż Atak, ale ustawiono ruchy fizyczne (' + physicalNames.join(', ') + ').');
      } else if (pokemon.attack != null && pokemon.specialAttack != null &&
          pokemon.attack! - pokemon.specialAttack! >= 20 && special > 0) {
        hints.add(pokemon.name + ': ma wyższy Atak niż Atak specjalny, ale ustawiono ruchy specjalne (' + specialNames.join(', ') + ').');
      }
      if (abilities.contains('adaptability') && pokemonStab > 0) {
        hints.add(pokemon.name + ': Adaptability wzmacnia jego ruchy STAB.');
      }
      if (abilities.contains('technician') && lowPower > 0) {
        hints.add(pokemon.name + ': Technician może wzmacniać ' + lowPower.toString() + ' ustawionych ruchów o mocy bazowej do 60.');
      }
      if (abilities.contains('iron fist') && punches > 0) {
        hints.add(pokemon.name + ': Iron Fist współgra z ' + punches.toString() + ' ruchami pięści.');
      }
      if (abilities.contains('strong jaw') && bites > 0) {
        hints.add(pokemon.name + ': Strong Jaw współgra z ' + bites.toString() + ' ruchami gryzącymi.');
      }
      if (abilities.contains('mega launcher') && pulses > 0) {
        hints.add(pokemon.name + ': Mega Launcher współgra z ' + pulses.toString() + ' ruchami typu pulse.');
      }
      if (abilities.contains('sharpness') && blades > 0) {
        hints.add(pokemon.name + ': Sharpness współgra z ' + blades.toString() + ' ruchami tnącymi.');
      }
      if (abilities.contains('punk rock') && sounds > 0) {
        hints.add(pokemon.name + ': Punk Rock współgra z ' + sounds.toString() + ' ruchami dźwiękowymi.');
      }
      if ((abilities.contains('huge power') || abilities.contains('pure power')) && physical > 0) {
        hints.add(pokemon.name + ': ' + (abilities.contains('huge power') ? 'Huge Power' : 'Pure Power') + ' wzmacnia Atak fizyczny używany przez ustawione ruchy.');
      }
      if (abilities.contains('flash fire') && (moveTypeCounts['Fire'] ?? 0) > 0) {
        hints.add(pokemon.name + ': Flash Fire może dodatkowo wzmacniać ustawione ruchy ogniste po przyjęciu ataku Fire.');
      }
      if ((abilities.contains('storm drain') || abilities.contains('lightning rod')) && special > 0) {
        hints.add(pokemon.name + ': ' + (abilities.contains('storm drain') ? 'Storm Drain' : 'Lightning Rod') + ' może zwiększyć Atak specjalny, z którego korzystają ustawione ruchy specjalne.');
      }
      if (abilities.contains('sap sipper') && physical > 0) {
        hints.add(pokemon.name + ': Sap Sipper może zwiększyć Atak przed użyciem ustawionych ruchów fizycznych.');
      }
      if (abilities.contains('skill link') && multiHit > 0) {
        hints.add(pokemon.name + ': Skill Link współgra z ' + multiHit.toString() + ' ustawionymi ruchami wielokrotnego trafienia.');
      }
      if (abilities.contains('reckless') && recoil > 0) {
        hints.add(pokemon.name + ': Reckless wzmacnia ' + recoil.toString() + ' ustawionych ruchów z obrażeniami odrzutu.');
      }
      if (abilities.contains('dry skin')) {
        hints.add(pokemon.name + ': uwaga — Dry Skin pomaga przeciwko Water, ale zwiększa otrzymywane obrażenia od Fire.');
      }
    }

    for (final pokemon in team) {
      final abilities = <String>{...pokemon.abilities, ...pokemon.hiddenAbilities}
          .map((value) => value.trim().toLowerCase()).toSet();
      for (final ability in abilities) {
        for (final type in _defensiveAbilities[ability] ?? const <String>{}) {
          if ((weaknesses[type] ?? 0) > 0) {
            hints.add(pokemon.name + ' (' + ability + '): może pomóc drużynie przeciwko typowi ' + type + ' dzięki swojej umiejętności.');
          }
        }
      }
    }

    final uncovered = targets.where((type) => !coverage.containsKey(type)).toList()..sort();
    return TeamBattleProfile(
      weaknesses: Map.unmodifiable(weaknesses),
      resistances: Map.unmodifiable(resistances),
      immunities: Map.unmodifiable(immunities),
      moveCoverage: Map.unmodifiable({
        for (final entry in coverage.entries) entry.key: List<String>.unmodifiable(entry.value),
      }),
      uncoveredTypes: List.unmodifiable(uncovered),
      unknownMoves: List.unmodifiable(unknown),
      synergyHints: List.unmodifiable(hints),
      configuredMoveSets: configured,
      damagingMoveCount: damaging,
      stabMoveCount: stab,
    );
  }
}
