import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _progressKey = 'storage_service_progress';
  static const String _achievementsKey = 'storage_service_achievements';
  static const String _selectedGameKey = 'storage_service_selected_game';

  // =========================
  // POSTĘP
  // =========================

  static Future<void> saveProgress(double progress) async {
    final preferences = await SharedPreferences.getInstance();
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();
    await preferences.setDouble(_progressKey, normalizedProgress);
  }

  static Future<double> getProgress() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getDouble(_progressKey) ?? 0.0;
  }

  // =========================
  // OSIĄGNIĘCIA
  // =========================

  static Future<void> saveAchievements(List<String> achievements) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _achievementsKey,
      List<String>.from(achievements),
    );
  }

  static Future<List<String>> getAchievements() async {
    final preferences = await SharedPreferences.getInstance();
    return List<String>.from(
      preferences.getStringList(_achievementsKey) ?? const <String>[],
    );
  }

  // =========================
  // WYBRANA GRA
  // =========================

  static Future<void> saveSelectedGame(String game) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_selectedGameKey, game);
  }

  static Future<String?> getSelectedGame() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_selectedGameKey);
  }

  // =========================
  // USUWANIE DANYCH TEJ USŁUGI
  // =========================

  static Future<void> clearProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_progressKey);
    await preferences.remove(_achievementsKey);
    await preferences.remove(_selectedGameKey);
  }
}
