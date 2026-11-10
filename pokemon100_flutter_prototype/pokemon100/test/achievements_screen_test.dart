import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pokemon_guide/data/achievements_data.dart';
import 'package:pokemon_guide/screens/achievements_screen.dart';
import 'package:pokemon_guide/widgets/achievement_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('the achievement catalogue has unique IDs and no hidden entries', () {
    expect(achievementsList, isNotEmpty);
    expect(
      achievementsList.map((achievement) => achievement.id).toSet(),
      hasLength(achievementsList.length),
    );
    expect(achievementsList.every((achievement) => !achievement.hidden), isTrue);
  });

  testWidgets('every catalogue achievement can be reached in the visible list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
    await tester.pumpAndSettle();

    for (final achievement in achievementsList) {
      await tester.scrollUntilVisible(
        find.text(achievement.title),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(achievement.title), findsOneWidget);
    }
  });

  testWidgets('manual unlock is saved and restored after recreating the screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
    await tester.pumpAndSettle();

    final card = find.ancestor(
      of: find.text('Pierwsza odznaka'),
      matching: find.byType(AchievementCard),
    );
    final unlockButton = find.descendant(
      of: card,
      matching: find.byTooltip('Oznacz jako zdobyte'),
    );
    expect(unlockButton, findsOneWidget);

    await tester.tap(unlockButton);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList('manual_achievement_ids'),
      contains('first_badge'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
    await tester.pumpAndSettle();

    final restoredCard = find.ancestor(
      of: find.text('Pierwsza odznaka'),
      matching: find.byType(AchievementCard),
    );
    expect(
      find.descendant(
        of: restoredCard,
        matching: find.byTooltip('Cofnij ręczne oznaczenie'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Pokédex milestones unlock automatically from saved caught IDs', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_pokemon_game_id': 'lets_go_pikachu',
      'caught_pokemon_ids_lets_go_pikachu':
          List<String>.generate(25, (index) => (index + 1).toString()),
    });

    await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
    await tester.pumpAndSettle();

    for (final title in ['Pierwszy Pokémon', 'Początek Pokédexu', '25 Pokémonów']) {
      final card = find.ancestor(
        of: find.text(title),
        matching: find.byType(AchievementCard),
      );
      expect(
        find.descendant(of: card, matching: find.byIcon(Icons.check_circle)),
        findsOneWidget,
        reason: '$title should be automatically unlocked',
      );
    }
  });

  testWidgets('the first 100 percent achievement checks every game, not only the selected one', (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_pokemon_game_id': 'lets_go_pikachu',
      'caught_pokemon_ids_lets_go_eevee':
          List<String>.generate(1025, (index) => (index + 1).toString()),
    });

    await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
    await tester.pumpAndSettle();

    final firstHundredCard = find.ancestor(
      of: find.text('100%'),
      matching: find.byType(AchievementCard),
    );
    await tester.ensureVisible(find.text('100%'));
    expect(
      find.descendant(
        of: firstHundredCard,
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );

    final selectedGameCard = find.ancestor(
      of: find.text('Gra ukończona'),
      matching: find.byType(AchievementCard),
    );
    expect(
      find.descendant(
        of: selectedGameCard,
        matching: find.byIcon(Icons.lock),
      ),
      findsOneWidget,
    );
  });
}
