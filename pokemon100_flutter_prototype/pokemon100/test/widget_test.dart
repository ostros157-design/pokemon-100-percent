import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokemon_guide/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StorageService', () {
    test('saves and restores progress from local preferences', () async {
      await StorageService.saveProgress(0.65);

      expect(await StorageService.getProgress(), 0.65);
    });

    test('clamps progress to the supported range', () async {
      await StorageService.saveProgress(1.5);
      expect(await StorageService.getProgress(), 1.0);

      await StorageService.saveProgress(-0.5);
      expect(await StorageService.getProgress(), 0.0);
    });

    test('saves and restores achievements without exposing mutable storage', () async {
      final achievements = <String>['first-step', 'first-catch'];
      await StorageService.saveAchievements(achievements);
      achievements.add('later-change');

      final restored = await StorageService.getAchievements();
      expect(restored, <String>['first-step', 'first-catch']);

      restored.add('caller-change');
      expect(
        await StorageService.getAchievements(),
        <String>['first-step', 'first-catch'],
      );
    });

    test('saves and restores the selected game', () async {
      await StorageService.saveSelectedGame('pokemon_red');

      expect(await StorageService.getSelectedGame(), 'pokemon_red');
    });

    test('clearProgress removes only StorageService data', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(
        'guide_progress_red_guide',
        <String>['0', '2'],
      );
      await StorageService.saveProgress(0.8);
      await StorageService.saveAchievements(<String>['first-catch']);
      await StorageService.saveSelectedGame('pokemon_red');

      await StorageService.clearProgress();

      expect(await StorageService.getProgress(), 0.0);
      expect(await StorageService.getAchievements(), isEmpty);
      expect(await StorageService.getSelectedGame(), isNull);
      expect(
        preferences.getStringList('guide_progress_red_guide'),
        <String>['0', '2'],
      );
    });
  });
}
