import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pokemon_guide/screens/maps_screen.dart';

late Map<String, dynamic> _audit;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final json = await rootBundle.loadString(
      'assets/data/maps/lets_go_kanto_audit.json',
    );
    _audit = jsonDecode(json) as Map<String, dynamic>;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'selected_pokemon_game_id': 'lets_go_pikachu',
    });
  });

  test('Kanto index has consistent trainer counts and valid source references',
      () {
    final locations = _audit['locations'] as List<dynamic>;
    final sources = _audit['sources'] as List<dynamic>;
    final sourceIds = sources
        .map((source) => (source as Map<String, dynamic>)['id'].toString())
        .toSet();

    for (final rawLocation in locations) {
      final location = rawLocation as Map<String, dynamic>;
      final trainers = location['trainers'];
      if (trainers is List) {
        expect(
          location['trainerCount'],
          trainers.length,
          reason: 'Trainer count mismatch in ${location['id']}',
        );
      }

      for (final sourceId in (location['sourceIds'] as List? ?? const [])) {
        expect(
          sourceIds,
          contains(sourceId),
          reason: 'Missing source $sourceId in ${location['id']}',
        );
      }

      for (final event in (location['events'] as List? ?? const [])) {
        if (event is! Map) continue;
        for (final sourceId in (event['sourceIds'] as List? ?? const [])) {
          expect(
            sourceIds,
            contains(sourceId),
            reason: 'Missing event source $sourceId in ${location['id']}',
          );
        }
      }
    }
  });

  test('Route 2 and Route 23 contain all confirmed postgame Master Trainers',
      () {
    final locations = _audit['locations'] as List<dynamic>;
    Map<String, dynamic> location(String id) => locations
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['id'] == id);

    final route2 = location('route_2');
    final route2Trainers = (route2['trainers'] as List).join('\n');
    expect(route2['trainerCount'], 3);
    expect(route2Trainers, contains('Bird Keeper Louey'));
    expect(route2Trainers, contains('Bug Catcher Hans'));
    expect(route2Trainers, contains('Bug Catcher Bobby'));
    expect(
      (route2['items'] as List).length,
      3,
      reason: 'Light Up is a Secret Technique, not a pickup item.',
    );
    expect(
      (route2['events'] as List).any(
        (event) => event.toString().contains('Light Up'),
      ),
      isTrue,
    );

    final route23 = location('route_23');
    final route23Trainers = (route23['trainers'] as List).join('\n');
    expect(route23['trainerCount'], 5);
    for (final trainer in [
      'Lass Sal',
      'Ace Trainer Edmund',
      'Ace Trainer Percy',
      'Ace Trainer Carlton',
      'Ace Trainer Jirard',
    ]) {
      expect(route23Trainers, contains(trainer));
    }

    final masterTrainers = locations
        .expand((raw) => (raw as Map<String, dynamic>)['trainers'] as List? ?? [])
        .where(
          (trainer) =>
              trainer is String && trainer.startsWith('Master Trainer'),
        )
        .toList();
    expect(masterTrainers.length, 153);
  });

  testWidgets('Kanto map displays complete Route 2 and Route 23 trainer lists',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openLocation(tester, 'Route 2');
    final route2Title = find.text('Trenerzy i ich drużyny (3)');
    await tester.ensureVisible(route2Title);
    await tester.tap(route2Title);
    await tester.pumpAndSettle();
    expect(find.textContaining('Bug Catcher Bobby'), findsOneWidget);
    expect(find.textContaining('Bug Catcher Hans'), findsOneWidget);
    expect(find.textContaining('Bird Keeper Louey'), findsOneWidget);

    final route2Items = find.text('Przedmioty (3)');
    await tester.ensureVisible(route2Items);
    await tester.tap(route2Items);
    await tester.pumpAndSettle();
    expect(find.textContaining('Great Ball ×5'), findsOneWidget);

    final route2Events = find.text('Wydarzenia, prezenty i spotkania (1)');
    await tester.ensureVisible(route2Events);
    await tester.tap(route2Events);
    await tester.pumpAndSettle();
    expect(find.textContaining('Secret Technique Light Up'), findsOneWidget);

    await _openLocation(tester, 'Route 23');
    final route23Title = find.text('Trenerzy i ich drużyny (5)');
    await tester.ensureVisible(route23Title);
    await tester.tap(route23Title);
    await tester.pumpAndSettle();
    expect(find.textContaining('Ace Trainer Jirard'), findsOneWidget);
    expect(find.textContaining('Lass Sal'), findsOneWidget);
  });

  testWidgets('Kanto map displays all fixed and hidden Mansion items',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _openLocation(tester, 'Pokémon Mansion');

    final fixedItems = find.text('Przedmioty (20)');
    await tester.ensureVisible(fixedItems);
    await tester.tap(fixedItems);
    await tester.pumpAndSettle();
    expect(find.textContaining('Secret Key'), findsOneWidget);

    final hiddenItems = find.text('Ukryte przedmioty (8)');
    await tester.ensureVisible(hiddenItems);
    await tester.tap(hiddenItems);
    await tester.pumpAndSettle();
    expect(find.textContaining('losowy typ Candy'), findsOneWidget);
  });
}

Future<void> _openLocation(
  WidgetTester tester,
  String locationName,
) async {
  await tester.pumpWidget(const MaterialApp(home: MapsScreen()));
  await tester.pumpAndSettle();
  final openMapButton = find.text('Otwórz mapę');
  if (openMapButton.evaluate().isNotEmpty) {
    await tester.tap(openMapButton);
    await tester.pumpAndSettle();
  }

  final search = find.byType(TextField).first;
  await tester.enterText(search, locationName);
  await tester.pumpAndSettle();
}
