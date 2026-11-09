import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> audit;

  setUpAll(() async {
    final json = await rootBundle.loadString(
      'assets/data/maps/lets_go_kanto_audit.json',
    );
    audit = jsonDecode(json) as Map<String, dynamic>;
  });

  test('Kanto audit remains research-only until map positions are verified', () {
    expect(audit['status'], 'research_only_no_coordinates');
    expect(
      audit['policy'],
      contains('Do not render these records as positioned map pins'),
    );
    expect(audit['locations'], isA<List<dynamic>>());
  });

  test('every location feature follows the structured audit schema', () {
    final locations = audit['locations'] as List<dynamic>;
    final sources = audit['sources'] as List<dynamic>;
    final knownSourceIds = sources
        .map((source) => (source as Map<String, dynamic>)['id'] as String)
        .toSet();

    expect(locations, isNotEmpty);

    for (final locationValue in locations) {
      final location = locationValue as Map<String, dynamic>;
      final features = location['features'] as List<dynamic>? ?? const [];

      for (final featureValue in features) {
        final feature = featureValue as Map<String, dynamic>;
        expect(feature['id'], isA<String>());
        expect((feature['id'] as String).trim(), isNotEmpty);
        expect(feature['name'], isA<String>());
        expect((feature['name'] as String).trim(), isNotEmpty);
        expect(feature['category'], isA<String>());
        expect(feature['status'], anyOf(
          'text_verified',
          'text_verified_positions_not_mapped',
        ));
        expect(feature['sourceIds'], isA<List<dynamic>>());

        for (final sourceId in feature['sourceIds'] as List<dynamic>) {
          expect(knownSourceIds, contains(sourceId));
        }
      }
    }
  });

  test('the audit contains no legacy string-only feature entries', () {
    final locations = audit['locations'] as List<dynamic>;

    for (final locationValue in locations) {
      final location = locationValue as Map<String, dynamic>;
      final features = location['features'] as List<dynamic>? ?? const [];
      expect(features, everyElement(isA<Map<String, dynamic>>()));
    }
  });
}
