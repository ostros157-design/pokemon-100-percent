import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokemon_guide/screens/maps_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> audit;

  setUpAll(() async {
    final decoded = jsonDecode(
      await rootBundle.loadString('assets/data/maps/lets_go_kanto_audit.json'),
    );
    audit = decoded as Map<String, dynamic>;
  });

  Map<String, dynamic> location(String id) {
    return (audit['locations'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['id'] == id);
  }

  group('Let’s Go Kanto map audit data', () {
    test('Route 2 and Route 23 contain their complete post-game Master Trainers', () {
      final route2 = location('route_2');
      final route23 = location('route_23');

      expect(route2['trainerCount'], 2);
      expect(route2['trainers'], hasLength(2));
      expect(
        (route2['trainers'] as List).join('\n'),
        allOf(contains('Bird Keeper Louey'), contains('Bug Catcher Hans')),
      );

      expect(route23['trainerCount'], 5);
      expect(route23['trainers'], hasLength(5));
      expect(
        (route23['trainers'] as List).join('\n'),
        allOf(
          contains('Lass Sal'),
          contains('Ace Trainer Edmund'),
          contains('Ace Trainer Percy'),
          contains('Ace Trainer Carlton'),
          contains('Ace Trainer Jirard'),
        ),
      );
      expect(route23['items'], hasLength(6));
    });

    test('the 153 Master Trainer species and all 19 Coach Trainers are represented', () {
      final locations = (audit['locations'] as List)
          .cast<Map<String, dynamic>>();
      final trainerEntries = locations
          .expand((entry) => (entry['trainers'] as List? ?? const <dynamic>[]))
          .whereType<String>()
          .toList();

      final masterTrainers = trainerEntries
          .where((entry) => entry.startsWith('Master Trainer'))
          .toList();
      final masterSpecies = masterTrainers.map((entry) {
        final separator = entry.indexOf('—');
        expect(separator, greaterThan(0), reason: entry);
        final detail = entry.substring(separator + 1).trim();
        final cutoff = RegExp(r'\s+(?:Lv\.?\s*\d+|\()').firstMatch(detail);
        return cutoff == null ? detail : detail.substring(0, cutoff.start).trim();
      }).toSet();

      final coachTrainers = trainerEntries
          .where((entry) => entry.startsWith('Coach Trainer'))
          .toList();

      expect(masterTrainers, hasLength(153));
      expect(masterSpecies, hasLength(153));
      expect(coachTrainers, hasLength(19));
    });

    test('Route 2 Light Up is a technique reward, not a pickup item', () {
      final route2 = location('route_2');
      expect(
        (route2['items'] as List).where((item) => item.toString().startsWith('Light Up')),
        isEmpty,
      );
      expect(
        (route2['events'] as List).where(
          (event) => event is Map && event['id'] == 'light_up_secret_technique',
        ),
        hasLength(1),
      );
    });

    test('Coach Trainer rewards and levels are source-checked', () {
      final route3 = location('route_3');
      final kareem = (route3['trainers'] as List)
          .cast<String>()
          .firstWhere((entry) => entry.contains('Coach Trainer Kareem'));
      expect(kareem, contains('nagroda: Revive'));

      final seafoam = location('seafoam_islands');
      final yas = (seafoam['trainers'] as List)
          .cast<String>()
          .firstWhere((entry) => entry.contains('Coach Trainer Yas'));
      expect(yas, contains('Vaporeon Lv. 46'));
    });

    test('every declared trainer count and source reference resolves', () {
      final locations = (audit['locations'] as List)
          .cast<Map<String, dynamic>>();
      final sources = (audit['sources'] as List)
          .cast<Map<String, dynamic>>()
          .map((source) => source['id'] as String)
          .toSet();

      expect(
        locations.map((entry) => entry['id']).toSet(),
        hasLength(locations.length),
      );

      for (final entry in locations) {
        final trainers = entry['trainers'];
        if (entry['trainerCount'] is num && trainers is List) {
          expect(
            (entry['trainerCount'] as num).toInt(),
            trainers.length,
            reason: 'Trainer count mismatch in ${entry['id']}',
          );
        }
        for (final sourceId in (entry['sourceIds'] as List? ?? const <dynamic>[])) {
          expect(sources, contains(sourceId), reason: '${entry['id']} -> $sourceId');
        }
        for (final event in (entry['events'] as List? ?? const <dynamic>[])) {
          if (event is Map) {
            for (final sourceId in (event['sourceIds'] as List? ?? const <dynamic>[])) {
              expect(sources, contains(sourceId), reason: '${entry['id']} event -> $sourceId');
            }
          }
        }
      }
    });

    test('event-only reception gate retains its event data', () {
      final gate = location('pokemon_league_reception_gate');
      expect(gate['events'], isNotEmpty);
      expect(gate['items'], isEmpty);
      expect(gate['trainers'], isEmpty);
    });
  });

  group('Let’s Go map screen rendering', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'selected_pokemon_game_id': 'lets_go_pikachu',
      });
    });

    Future<void> openMap(WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MapsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Otwórz mapę'));
      await tester.pumpAndSettle();
    }

    Future<void> selectLocation(WidgetTester tester, String name) async {
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, name);
      await tester.pumpAndSettle();
      final result = find.widgetWithText(ListTile, name);
      await tester.ensureVisible(result);
      await tester.tap(result);
      await tester.pumpAndSettle();
    }

    testWidgets('shows the complete Route 23 trainer and item lists', (tester) async {
      await openMap(tester);
      await selectLocation(tester, 'Route 23');

      final trainersTile = find.text('Trenerzy i ich drużyny (5)');
      await tester.ensureVisible(trainersTile);
      await tester.tap(trainersTile);
      await tester.pumpAndSettle();

      expect(find.textContaining('Master Trainer Lass Sal'), findsOneWidget);
      expect(find.textContaining('Master Trainer Ace Trainer Edmund'), findsOneWidget);
      expect(find.textContaining('Master Trainer Ace Trainer Percy'), findsOneWidget);
      expect(find.textContaining('Master Trainer Ace Trainer Carlton'), findsOneWidget);
      expect(find.textContaining('Master Trainer Ace Trainer Jirard'), findsOneWidget);

      final itemsTile = find.text('Przedmioty (6)');
      await tester.ensureVisible(itemsTile);
      await tester.tap(itemsTile);
      await tester.pumpAndSettle();

      expect(find.textContaining('Golden Razz Berry ×3'), findsWidgets);
      expect(find.textContaining('Golden Pinap Berry ×5'), findsOneWidget);
    });

    testWidgets('shows events even when a location has no items or trainers', (tester) async {
      await openMap(tester);
      await selectLocation(tester, 'Pokémon League Reception Gate');

      final eventsTile = find.text('Wydarzenia, prezenty i spotkania (1)');
      await tester.ensureVisible(eventsTile);
      expect(eventsTile, findsOneWidget);
      await tester.tap(eventsTile);
      await tester.pumpAndSettle();

      final eventName = (location('pokemon_league_reception_gate')['events'] as List)
          .cast<Map<String, dynamic>>()
          .single['name'] as String;
      expect(find.textContaining(eventName), findsOneWidget);
    });
  });
}
