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
    expect(locations, hasLength(62));
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

    expect(trees, hasLength(15));
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
        expect(entry['sourceIds'], contains('bulbapedia-gs-walkthrough-parts-1-4'));
        expect(entry['availableIn'], contains('gold_silver'));
      }
    }

    expect(pickups, hasLength(9));
    expect(
      locations.where((value) =>
          ((value as Map<String, dynamic>)['items'] as List?)?.isNotEmpty ?? false),
      hasLength(3),
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
        expect(entry['sourceIds'], contains('bulbapedia-gs-walkthrough-parts-3-4'));
        expect(entry['availableIn'], contains('gold_silver'));
        expect(entry['team'], isA<List<dynamic>>());
      }
    }

    expect(trainers, hasLength(26));
    expect(
      locations.where((value) =>
          ((value as Map<String, dynamic>)['trainers'] as List?)?.isNotEmpty ?? false),
      hasLength(4),
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

}
