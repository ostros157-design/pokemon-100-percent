import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> audit;

  setUpAll(() async {
    final json = await rootBundle.loadString(
      'assets/data/maps/johto_audit.json',
    );
    audit = jsonDecode(json) as Map<String, dynamic>;
  });

  test('Johto audit contains the expected regional location index', () {
    final locations = audit['locations'] as List<dynamic>;
    expect(audit['region'], 'Johto');
    expect(locations, hasLength(64));
    expect(
      locations.where((value) {
        final location = value as Map<String, dynamic>;
        return (location['id'] as String).startsWith('route_');
      }),
      hasLength(23),
    );
  });

  test('all Johto connections point to known locations in this index', () {
    final locations = audit['locations'] as List<dynamic>;
    final ids = locations
        .map((value) =>
            (value as Map<String, dynamic>)['id'] as String)
        .toSet();

    for (final value in locations) {
      final location = value as Map<String, dynamic>;
      final connections =
          location['connectsTo'] as List<dynamic>? ?? const [];
      for (final target in connections) {
        expect(
          ids,
          contains(target),
          reason: '${location['id']} references unknown Johto location $target',
        );
      }
    }
  });

  test('original Silver map does not claim unverified image coordinates', () {
    final locations = audit['locations'] as List<dynamic>;

    for (final value in locations) {
      final location = value as Map<String, dynamic>;
      expect(location['coordinateStatus'], 'unverified');
      expect(location['localMapAsset'], isNull);
    }
  });

  test('remake-only locations are explicitly limited to HeartGold/SoulSilver',
      () {
    final locations = audit['locations'] as List<dynamic>;
    final remakeOnly = locations.where((value) {
      return (value as Map<String, dynamic>)['availableIn'] != null;
    }).map((value) => (value as Map<String, dynamic>)['id']).toSet();

    expect(
      remakeOnly,
      <String>{
        'route_47',
        'route_48',
        'cliff_cave',
        'safari_zone_gate',
        'safari_zone',
        'cliff_edge_gate',
      },
    );

    for (final value in locations) {
      final location = value as Map<String, dynamic>;
      if (remakeOnly.contains(location['id'])) {
        expect(
          location['availableIn'],
          <String>['heart_gold_soul_silver'],
        );
      }
    }
  });
  
  test('shared map marker legend defines all requested marker categories', () async {
    final json = await rootBundle.loadString(
      'assets/data/maps/map_marker_legend.json',
    );
    final legend = jsonDecode(json) as Map<String, dynamic>;
    final markers = (legend['markers'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final ids = markers.map((marker) => marker['id']).toSet();

    expect(ids, containsAll(<String>{
      'berry_plant',
      'spray_bottle',
      'pokeball_item',
      'trainer',
    }));

    for (final marker in markers) {
      expect(marker['label'], isA<String>());
      expect(marker['visual'], isA<String>());
      expect(marker['appliesTo'], isA<List<dynamic>>());
    }
  });


  test('Silver Johto berry trees are source-tracked without guessed coordinates', () {
    final locations = audit['locations'] as List<dynamic>;
    final trees = <Map<String, dynamic>>[];

    for (final value in locations) {
      final location = value as Map<String, dynamic>;
      final rawTrees = location['berryTrees'] as List<dynamic>? ?? const [];
      for (final tree in rawTrees) {
        trees.add(tree as Map<String, dynamic>);
        expect(tree['coordinateStatus'], 'unverified');
        expect(tree['sourceIds'], contains('bulbapedia-berry-tree-generation-ii'));
        expect(tree['availableIn'], contains('gold_silver'));
      }
    }

    expect(trees, hasLength(16));
    expect(
      locations.where((value) =>
          ((value as Map<String, dynamic>)['berryTrees'] as List?)?.isNotEmpty ??
          false),
      hasLength(13),
    );
  });

  test('Silver item pickups are source-tracked and not assigned guessed coordinates', () {
    final locations = audit['locations'] as List<dynamic>;
    final pickups = <Map<String, dynamic>>[];

    for (final value in locations) {
      final location = value as Map<String, dynamic>;
      final rawItems = location['items'] as List<dynamic>? ?? const [];
      for (final item in rawItems) {
        final entry = item as Map<String, dynamic>;
        pickups.add(entry);
        expect(entry['coordinateStatus'], 'unverified');
        expect(entry['sourceIds'], isNotEmpty);
        expect(entry['availableIn'], contains('gold_silver'));
      }
    }

    expect(pickups, hasLength(167));
    expect(
      locations.where((value) =>
          ((value as Map<String, dynamic>)['items'] as List?)?.isNotEmpty ?? false),
      hasLength(30),
    );
  });

  test('Silver trainer rosters are source-tracked and have no guessed coordinates', () {
    final locations = audit['locations'] as List<dynamic>;
    final trainers = <Map<String, dynamic>>[];

    for (final value in locations) {
      final location = value as Map<String, dynamic>;
      final rawTrainers = location['trainers'] as List<dynamic>? ?? const [];
      for (final trainer in rawTrainers) {
        final entry = trainer as Map<String, dynamic>;
        trainers.add(entry);
        expect(entry['coordinateStatus'], 'unverified');
        expect(entry['sourceIds'], isNotEmpty);
        expect(entry['availableIn'], contains('gold_silver'));
        expect(entry['team'], isA<List<dynamic>>());
      }
    }

    expect(trainers, hasLength(185));
    expect(
      locations.where((value) =>
          ((value as Map<String, dynamic>)['trainers'] as List?)?.isNotEmpty ?? false),
      hasLength(31),
    );
  });



  test('Silver Route 33 and Slowpoke Well encounter groups are sourced and sum to 100%', () {
    final locations = audit['locations'] as List<dynamic>;
    const expectedSources = <String, String>{
      'route_33': 'serebii-gs-route33',
      'slowpoke_well': 'serebii-gs-slowpoke-well',
    };
    for (final expected in expectedSources.entries) {
      final location = locations.cast<Map<String, dynamic>>().firstWhere(
        (value) => value['id'] == expected.key,
      );
      expect(location['wildPokemonSourceIds'], contains(expected.value));
      final groups = location['wildPokemonDetails'] as Map<String, dynamic>;
      for (final group in groups.entries) {
        final entries = group.value as List<dynamic>;
        expect(
          entries.fold<int>(0, (sum, value) =>
              sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()),
          100,
          reason: '${expected.key}/${group.key} must total 100%',
        );
      }
    }
    final well = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'slowpoke_well',
    );
    expect(well['trainers'], hasLength(4));
    expect(well['items'], hasLength(1));
  });

  test('Silver Sprout Tower encounter tables, trainers and item pickups are source-tracked', () {
    final locations = audit['locations'] as List<dynamic>;
    final tower = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'sprout_tower',
    );
    expect(tower['wildPokemonSourceIds'], contains('serebii-gs-sprout-tower'));
    final groups = tower['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(6));
    for (final group in groups.entries) {
      final entries = group.value as List<dynamic>;
      expect(
        entries.fold<int>(0, (sum, value) =>
            sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()),
        100,
        reason: 'sprout_tower/${group.key} must total 100%',
      );
    }
    expect(tower['trainers'], hasLength(7));
    expect(tower['items'], hasLength(4));
    for (final entry in [...tower['trainers'], ...tower['items']]) {
      expect(entry['sourceIds'], contains('serebii-gs-sprout-tower'));
      expect(entry['coordinateStatus'], 'unverified');
      expect(entry['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver wild encounter tables are sourced and each rate group totals 100%', () {
    final locations = audit['locations'] as List<dynamic>;
    const expectedSources = <String, String>{
      'route_29': 'rotomlabs-gs-route29',
      'route_30': 'rotomlabs-gs-route30',
      'route_31': 'rotomlabs-gs-route31',
      'route_32': 'serebii-gs-route32',
      'union_cave': 'serebii-gs-union-cave',
    };
    for (final expected in expectedSources.entries) {
      final location = locations.cast<Map<String, dynamic>>().firstWhere(
        (value) => value['id'] == expected.key,
      );
      expect(location['wildPokemonStatus'], 'verified_gen2_silver_rates_and_levels');
      expect(location['wildPokemonSourceIds'], contains(expected.value));
      final tables = location['wildPokemonDetails'] as Map<String, dynamic>;
      expect(tables, isNotEmpty);
      for (final table in tables.entries) {
        final entries = table.value as List<dynamic>;
        expect(entries, isNotEmpty);
        expect(
          entries.fold<int>(0, (sum, value) =>
              sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()),
          100,
          reason: '${expected.key}/${table.key} must total 100%',
        );
        for (final value in entries) {
          final entry = value as Map<String, dynamic>;
          expect(entry['name'], isA<String>());
          expect(entry['levelRange'], hasLength(2));
          expect(entry['method'], isA<String>());
        }
      }
    }
    expect(expectedSources, hasLength(5));
  });


  test('Silver Ruins of Alph encounters, puzzle chambers and special reward are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final ruins = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'ruins_of_alph',
    );
    expect(ruins['wildPokemonSourceIds'], contains('serebii-gs-ruins-of-alph'));
    final groups = ruins['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(6));
    for (final group in groups.entries) {
      final entries = group.value as List<dynamic>;
      expect(
        entries.fold<int>(0, (sum, value) =>
            sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()),
        100,
        reason: 'ruins_of_alph/${group.key} must total 100%',
      );
    }
    expect(ruins['trainers'], hasLength(1));
    final nathan = (ruins['trainers'] as List).single as Map<String, dynamic>;
    expect(nathan['name'], 'Psychic Nathan');
    expect(nathan['team'].single['level'], 26);
    expect(nathan['note'], contains('Serebii'));
    expect(ruins['puzzleChambers'], hasLength(4));
    expect(ruins['specialRewards'].single['name'], 'Unown Mode');
    expect(ruins['specialRewards'].single['coordinateStatus'], 'not_a_map_pickup');
    expect(ruins['coordinateStatus'], 'unverified');
    expect(ruins['localMapAsset'], isNull);
  });


  test('Silver Route 34 encounter tables, trainers and pickups are source-tracked', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'route_34',
    );
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route34'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(11));
    for (final group in groups.entries) {
      final entries = group.value as List<dynamic>;
      expect(
        entries.fold<int>(0, (sum, value) =>
            sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()),
        100,
        reason: 'route_34/${group.key} must total 100%',
      );
    }
    expect(route['trainers'], hasLength(9));
    expect(route['items'], hasLength(3));
    for (final entry in [...route['trainers'], ...route['items']]) {
      expect(entry['sourceIds'], contains('serebii-gs-route34'));
      expect(entry['availableIn'], contains('gold_silver'));
      expect(entry['coordinateStatus'], 'unverified');
    }
  });

  test('Silver Goldenrod City Gym and main-area rewards are source-tracked', () {
    final locations = audit['locations'] as List<dynamic>;
    final city = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'goldenrod_city',
    );
    expect(city['dataStatus'], 'partial_gen2_silver_main_area_and_gym_data');
    expect(city['trainers'], hasLength(5));
    expect(city['items'], hasLength(6));
    final whitney = (city['trainers'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((value) => value['name'] == 'Gym Leader Whitney');
    expect(whitney['team'], hasLength(2));
    expect(whitney['team'][1]['name'], 'Miltank');
    expect(whitney['team'][1]['level'], 20);
    for (final entry in [...city['trainers'], ...city['items']]) {
      expect(entry['sourceIds'], contains('serebii-gs-goldenrod-city'));
      expect(entry['availableIn'], contains('gold_silver'));
    }
  });


  test('Silver Goldenrod Underground trainer rosters and item pickups are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final underground = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'goldenrod_tunnel',
    );
    expect(underground['dataStatus'], 'verified_gen2_silver_trainers_and_items_1f_3f');
    expect(underground['trainers'], hasLength(16));
    expect(underground['items'], hasLength(15));
    for (final entry in [...underground['trainers'], ...underground['items']]) {
      expect(entry['sourceIds'], contains('serebii-gs-goldenrod-underground'));
      expect(entry['availableIn'], contains('gold_silver'));
      expect(entry['coordinateStatus'], 'unverified');
    }
    final rivalVariants = (underground['trainers'] as List)
        .where((value) => (value as Map<String, dynamic>)['name'].toString().startsWith('Rival Silver'))
        .toList();
    expect(rivalVariants, hasLength(3));
  });

  test('Silver Radio Tower Rocket takeover trainers and rewards are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final tower = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'radio_tower',
    );
    expect(tower['dataStatus'], 'verified_gen2_silver_rocket_takeover_trainers_and_rewards');
    expect(tower['trainers'], hasLength(16));
    expect(tower['items'], hasLength(3));
    for (final entry in [...tower['trainers'], ...tower['items']]) {
      expect(entry['sourceIds'], contains('serebii-gs-radio-tower'));
      expect(entry['availableIn'], contains('gold_silver'));
      expect(entry['coordinateStatus'], 'unverified');
    }
    expect((tower['items'] as List).map((value) => value['name']),
      containsAll(['TM11 — Sunny Day', 'Pink Bow', 'Basement Key']));
  });


  test('Silver Goldenrod Game Corner games and prize tables are version-specific', () {
    final locations = audit['locations'] as List<dynamic>;
    final corner = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'goldenrod_game_corner',
    );
    expect(corner['dataStatus'], 'verified_gen2_silver_games_and_prizes');
    expect(corner['specialServices'], hasLength(4));
    expect(corner['items'], hasLength(6));
    final prizes = (corner['items'] as List).cast<Map<String, dynamic>>();
    expect(prizes.map((value) => value['name']),
      containsAll(['TM25 — Thunder', 'TM14 — Blizzard', 'TM38 — Fire Blast', 'Abra Lv. 10', 'Sandshrew Lv. 10', 'Dratini Lv. 10']));
    final sandshrew = prizes.firstWhere((value) => value['name'] == 'Sandshrew Lv. 10');
    expect(sandshrew['availableIn'], contains('gold_silver'));
    for (final value in [...corner['specialServices'], ...prizes]) {
      expect(value['sourceIds'], contains('serebii-gs-game-corner'));
    }
  });

  test('Silver Goldenrod Department Store has Generation II stock and basement pickups', () {
    final locations = audit['locations'] as List<dynamic>;
    final store = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'goldenrod_department_store',
    );
    expect(store['dataStatus'], 'verified_gen2_silver_store_floors_2f_6f');
    expect(store['items'], hasLength(35));
    expect(store['basementItems'], hasLength(3));
    expect(store['specialServices'], hasLength(4));
    for (final value in [...store['items'], ...store['basementItems'], ...store['specialServices']]) {
      expect(value['sourceIds'], contains('bulbapedia-gs-department-store'));
      expect(value['availableIn'], contains('gold_silver'));
    }
    final shopStock = (store['items'] as List).cast<Map<String, dynamic>>();
    expect(shopStock.where((value) => value['floor'] == '3F'), hasLength(7));
    expect(shopStock.where((value) => value['floor'] == '4F'), hasLength(5));
    expect(shopStock.where((value) => value['floor'] == '5F'), hasLength(5));
    expect(shopStock.where((value) => value['floor'] == '6F'), hasLength(3));
  });

  test('Silver Goldenrod trade list excludes the Crystal-only Abra trade', () {
    final locations = audit['locations'] as List<dynamic>;
    final city = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'goldenrod_city',
    );
    expect((city['items'] as List).map((value) => value['id']),
      isNot(contains('goldenrod_gold_berry_trade_abra')));
    expect((city['items'] as List).where((value) => value['id'] == 'goldenrod_gold_berry_trade_drowzee'),
      hasLength(1));
  });


  test('Silver Route 35 encounter tables and trainers are fully source-tracked', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'route_35',
    );
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route35'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(9));
    for (final group in groups.entries) {
      final entries = group.value as List<dynamic>;
      expect(entries.fold<int>(0, (sum, value) =>
        sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()),
        100, reason: 'route_35/${group.key} must total 100%');
    }
    expect(route['trainers'], hasLength(9));
    expect(route['specialServices'].single['name'], contains('Spearow'));
    for (final entry in [...route['trainers'], ...route['specialServices']]) {
      expect(entry['sourceIds'], contains('serebii-gs-route35'));
      expect(entry['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver National Park main encounters, contest, trainers and items are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final park = locations.cast<Map<String, dynamic>>().firstWhere(
      (value) => value['id'] == 'national_park',
    );
    expect(park['wildPokemonSourceIds'], contains('serebii-gs-national-park'));
    final groups = park['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(4));
    for (final group in groups.entries) {
      final entries = group.value as List<dynamic>;
      expect(entries.fold<int>(0, (sum, value) =>
        sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()),
        100, reason: 'national_park/${group.key} must total 100%');
    }
    expect(groups['bug_catching_contest'], hasLength(10));
    expect(park['trainers'], hasLength(4));
    expect(park['items'], hasLength(4));
    expect(park['specialServices'].single['prizes'], hasLength(4));
    for (final entry in [...park['trainers'], ...park['items'], ...park['specialServices']]) {
      expect(entry['sourceIds'], contains('serebii-gs-national-park'));
      expect(entry['availableIn'], contains('gold_silver'));
    }
  });


  test('Silver Route 36 encounters, Sudowoodo, trainers and items are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'route_36');
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route36'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(5));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(route['trainers'], hasLength(2));
    expect(route['items'], hasLength(2));
    expect(route['specialServices'].single['name'], 'Sudowoodo Lv. 20');
    for (final value in [...route['trainers'], ...route['items'], ...route['specialServices']]) {
      expect(value['sourceIds'], contains('serebii-gs-route36'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Route 37 encounters, trainers and items are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'route_37');
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route37'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(5));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(route['trainers'], hasLength(2));
    expect(route['items'], hasLength(5));
    for (final value in [...route['trainers'], ...route['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-route37'));
      expect(value['availableIn'], contains('gold_silver'));
      expect(value['coordinateStatus'], 'unverified');
    }
  });


  test('Silver Ecruteak City fishing, Kimono Girls and Gym teams are source-tracked', () {
    final locations = audit['locations'] as List<dynamic>;
    final city = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'ecruteak_city');
    expect(city['wildPokemonSourceIds'], contains('serebii-gs-ecruteak-city'));
    final groups = city['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(4));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(city['trainers'], hasLength(10));
    expect(city['items'], hasLength(4));
    final morty = (city['trainers'] as List).cast<Map<String, dynamic>>().firstWhere((value) => value['name'] == 'Gym Leader Morty');
    expect(morty['team'], hasLength(4));
    expect(morty['team'][2]['name'], 'Gengar');
    for (final value in [...city['trainers'], ...city['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-ecruteak-city'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Burned Tower 1F and B1F encounters, rival variants and items are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final tower = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'burned_tower');
    expect(tower['wildPokemonSourceIds'], contains('serebii-gs-burned-tower'));
    final groups = tower['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(4));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(tower['trainers'], hasLength(5));
    expect(tower['items'], hasLength(4));
    expect(tower['specialServices'].single['category'], 'story_event');
    final rivals = (tower['trainers'] as List).where((value) => (value as Map<String, dynamic>)['name'].toString().startsWith('Rival Silver'));
    expect(rivals, hasLength(3));
    for (final value in [...tower['trainers'], ...tower['items'], ...tower['specialServices']]) {
      expect(value['sourceIds'], contains('serebii-gs-burned-tower'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });


  test('Silver Route 38 encounters and trainer teams are source-tracked', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'route_38');
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route38'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(5));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(route['trainers'], hasLength(5));
    for (final value in route['trainers']) {
      expect(value['sourceIds'], contains('serebii-gs-route38'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Route 39 encounters, MooMoo Farm reward and trainers are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'route_39');
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route39'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(5));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(route['trainers'], hasLength(4));
    expect(route['items'], hasLength(2));
    expect(route['items'].first['name'], 'TM13 — Snore');
    for (final value in [...route['trainers'], ...route['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-route39'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });


  test('Silver Olivine City encounter tables, Jasmine and gifts are source-tracked', () {
    final locations = audit['locations'] as List<dynamic>;
    final city = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'olivine_city');
    expect(city['wildPokemonSourceIds'], contains('serebii-gs-olivine-city'));
    final groups = city['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(9));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(city['trainers'], hasLength(1));
    expect(city['trainers'].single['name'], 'Gym Leader Jasmine');
    expect(city['trainers'].single['team'], hasLength(3));
    expect(city['items'], hasLength(3));
    for (final value in [...city['trainers'], ...city['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-olivine-city'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Olivine Lighthouse floors, trainers and items are source-tracked', () {
    final locations = audit['locations'] as List<dynamic>;
    final lighthouse = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'olivine_lighthouse');
    expect(lighthouse['sourceIds'], contains('serebii-gs-shining-lighthouse'));
    expect(lighthouse['trainers'], hasLength(9));
    expect(lighthouse['items'], hasLength(6));
    expect(lighthouse['specialServices'].single['category'], 'story_event');
    final floors = (lighthouse['trainers'] as List).map((value) => (value as Map<String, dynamic>)['note'].toString().split(' · ').first).toSet();
    expect(floors, containsAll(['2F', '3F', '4F', '5F']));
    for (final value in [...lighthouse['trainers'], ...lighthouse['items'], ...lighthouse['specialServices']]) {
      expect(value['sourceIds'], contains('serebii-gs-shining-lighthouse'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });


  test('Silver Route 40 sea encounters, Rock Smash, trainers and items are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'route_40');
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route40'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(9));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(route['trainers'], hasLength(4));
    expect(route['items'], hasLength(3));
    for (final value in [...route['trainers'], ...route['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-route40'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Route 41 sea encounter rates and all swimmer teams are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'route_41');
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route41'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(8));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(route['trainers'], hasLength(10));
    for (final value in route['trainers']) {
      expect(value['sourceIds'], contains('serebii-gs-route41'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Cianwood City fishing, Rock Smash, Chuck Gym and gifts are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final city = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'cianwood_city');
    expect(city['wildPokemonSourceIds'], contains('serebii-gs-cianwood-city'));
    final groups = city['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(9));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(city['trainers'], hasLength(5));
    expect(city['items'], hasLength(6));
    final chuck = (city['trainers'] as List).cast<Map<String, dynamic>>().firstWhere((value) => value['name'] == 'Gym Leader Chuck');
    expect(chuck['team'], hasLength(2));
    expect(chuck['team'][1]['name'], 'Poliwrath');
    for (final value in [...city['trainers'], ...city['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-cianwood-city'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });


  test('Silver Whirl Islands sections, encounters, items and Lugia are source-tracked', () {
    final locations = audit['locations'] as List<dynamic>;
    final island = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'whirl_islands');
    expect(island['wildPokemonSourceIds'], contains('serebii-gs-whirl-islands'));
    final groups = island['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(20));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(island['items'], hasLength(8));
    expect(island['specialServices'].first['name'], 'Lugia Lv. 40');
    expect(island['specialServices'].first['category'], 'legendary_encounter');
    for (final value in [...island['items'], ...island['specialServices']]) {
      expect(value['sourceIds'], contains('serebii-gs-whirl-islands'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });


  test('Silver Route 42 encounters, Headbutt, trainers and items are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'route_42');
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route42'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(9));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(route['trainers'], hasLength(3));
    expect(route['items'], hasLength(6));
    for (final value in [...route['trainers'], ...route['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-route42'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Mt. Mortar sections, encounters, trainers and items are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final mountain = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'mt_mortar');
    expect(mountain['wildPokemonSourceIds'], contains('serebii-gs-mt-mortar'));
    final groups = mountain['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(7));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(mountain['trainers'], hasLength(3));
    expect(mountain['items'], hasLength(8));
    for (final value in [...mountain['trainers'], ...mountain['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-mt-mortar'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });


  test('Silver Route 43 encounters, trainers, tree and items are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'route_43');
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route43'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(6));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(route['trainers'], hasLength(6));
    expect(route['items'], hasLength(2));
    expect(route['berryTrees'], hasLength(1));
    for (final value in [...route['trainers'], ...route['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-route43'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Lake of Rage water, Headbutt, Red Gyarados, trainers and items are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final lake = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'lake_of_rage');
    expect(lake['wildPokemonSourceIds'], contains('serebii-gs-lake-of-rage'));
    final groups = lake['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(6));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(lake['trainers'], hasLength(4));
    expect(lake['items'], hasLength(9));
    expect(lake['specialServices'].first['name'], 'Red Gyarados Lv. 30');
    for (final value in [...lake['trainers'], ...lake['items'], ...lake['specialServices']]) {
      expect(value['sourceIds'], contains('serebii-gs-lake-of-rage'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Mahogany Town Gym, story item and shop phases are separated', () {
    final locations = audit['locations'] as List<dynamic>;
    final town = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'mahogany_town');
    expect(town['trainers'], hasLength(6));
    expect(town['items'], hasLength(2));
    expect(town['shopStock'], hasLength(13));
    expect((town['shopStock'] as List).where((value) => value['phase'] == 'before_team_rocket_defeated'), hasLength(4));
    expect((town['shopStock'] as List).where((value) => value['phase'] == 'after_team_rocket_defeated'), hasLength(9));
    final pryce = (town['trainers'] as List).cast<Map<String, dynamic>>().firstWhere((value) => value['name'] == 'Gym Leader Pryce');
    expect(pryce['team'].last['name'], 'Piloswine');
    for (final value in [...town['trainers'], ...town['items'], ...town['shopStock']]) {
      expect(value['sourceIds'], contains('bulbapedia-gs-mahogany-town'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });


  test('Silver Route 44 encounters, Headbutt, trainers and items are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final route = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'route_44');
    expect(route['wildPokemonSourceIds'], contains('serebii-gs-route44'));
    final groups = route['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(7));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(route['trainers'], hasLength(7));
    expect(route['items'], hasLength(3));
    for (final value in [...route['trainers'], ...route['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-route44'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Ice Path floors have distinct encounter rates and sourced items', () {
    final locations = audit['locations'] as List<dynamic>;
    final cave = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'ice_path');
    expect(cave['wildPokemonSourceIds'], contains('serebii-gs-ice-path'));
    final groups = cave['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(15));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
      expect(group.value, isNotEmpty);
    }
    expect(cave['items'], hasLength(9));
    expect(cave['trainers'], isNull);
    for (final value in cave['items']) {
      expect(value['sourceIds'], contains('serebii-gs-ice-path'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

  test('Silver Blackthorn City fishing, Gym teams and Saturday gift are sourced', () {
    final locations = audit['locations'] as List<dynamic>;
    final city = locations.cast<Map<String, dynamic>>().firstWhere((value) => value['id'] == 'blackthorn_city');
    expect(city['wildPokemonSourceIds'], contains('serebii-gs-blackthorn-city'));
    final groups = city['wildPokemonDetails'] as Map<String, dynamic>;
    expect(groups, hasLength(4));
    for (final group in groups.entries) {
      expect((group.value as List).fold<int>(0, (sum, value) => sum + ((value as Map<String, dynamic>)['ratePercent'] as num).toInt()), 100);
    }
    expect(city['trainers'], hasLength(6));
    expect(city['items'], hasLength(1));
    final clair = (city['trainers'] as List).cast<Map<String, dynamic>>().firstWhere((value) => value['name'] == 'Gym Leader Clair');
    expect(clair['team'].last['name'], 'Kingdra');
    expect(clair['team'].last['level'], 40);
    for (final value in [...city['trainers'], ...city['items']]) {
      expect(value['sourceIds'], contains('serebii-gs-blackthorn-city'));
      expect(value['availableIn'], contains('gold_silver'));
    }
  });

}
