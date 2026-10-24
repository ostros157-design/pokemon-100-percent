
class StorageService {
static double _progress = 0.0;
static List<String> _achievements = [];
static String? _selectedGame;

// =========================
// POSTĘP
// =========================

static Future<void> saveProgress(double progress) async {
_progress = progress.clamp(0.0, 1.0);
}

static Future<double> getProgress() async {
return _progress;
}

// =========================
// OSIĄGNIĘCIA
// =========================

static Future<void> saveAchievements(
List<String> achievements,
) async {
_achievements = List<String>.from(achievements);
}

static Future<List<String>> getAchievements() async {
return List<String>.from(_achievements);
}

// =========================
// WYBRANA GRA
// =========================

static Future<void> saveSelectedGame(
String game,
) async {
_selectedGame = game;
}

static Future<String?> getSelectedGame() async {
return _selectedGame;
}

// =========================
// USUWANIE ZAPISU
// =========================

static Future<void> clearProgress() async {
_progress = 0.0;
_achievements = [];
_selectedGame = null;
}
}

