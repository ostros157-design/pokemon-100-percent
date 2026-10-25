import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pokemon_guide/models/guide.dart';
import 'package:pokemon_guide/screens/guide_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const redGuide = Guide(
    id: 'starter-route',
    gameId: 'pokemon_red',
    title: 'Red — trasa początkowa',
    description: 'Testowy poradnik',
    steps: [
      GuideStep(
        title: 'Pierwszy krok',
        description: 'Ukończ ten krok.',
      ),
    ],
  );

  const blueGuide = Guide(
    id: 'starter-route',
    gameId: 'pokemon_blue',
    title: 'Blue — trasa początkowa',
    description: 'Testowy poradnik',
    steps: [
      GuideStep(
        title: 'Pierwszy krok',
        description: 'Ukończ ten krok.',
      ),
    ],
  );

  testWidgets('restores guide progress after the screen is recreated',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GuideScreen(guide: redGuide)),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 / 1 kroków ukończonych'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.text('1 / 1 kroków ukończonych'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const MaterialApp(home: GuideScreen(guide: redGuide)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 1 kroków ukończonych'), findsOneWidget);
  });

  testWidgets('keeps progress separate for different games with the same guide id',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      'guide_progress_${redGuide.gameId}_${redGuide.id}',
      <String>['0'],
    );

    await tester.pumpWidget(
      const MaterialApp(home: GuideScreen(guide: blueGuide)),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 / 1 kroków ukończonych'), findsOneWidget);
  });
}
