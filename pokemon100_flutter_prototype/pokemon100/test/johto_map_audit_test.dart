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

}
