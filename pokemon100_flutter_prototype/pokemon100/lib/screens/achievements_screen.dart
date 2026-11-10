import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/achievements_data.dart';
import '../models/achievement.dart';
import '../services/achievement_progress_service.dart';
import '../widgets/achievement_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const _manualUnlockedKey = 'manual_achievement_ids';

  bool _loading = true;
  AchievementProgressSnapshot? _progress;
  Set<String> _manualUnlockedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final preferences = await SharedPreferences.getInstance();
    final manualUnlockedIds =
        (preferences.getStringList(_manualUnlockedKey) ?? const <String>[])
            .toSet();
    final progress = AchievementProgressService.calculate(preferences);

    if (!mounted) return;
    setState(() {
      _progress = progress;
      _manualUnlockedIds = manualUnlockedIds;
      _loading = false;
    });
  }

  bool _isAutomaticallyUnlocked(Achievement achievement) =>
      _progress?.isAutomaticallyUnlocked(achievement.id) ?? false;

  bool _isUnlocked(Achievement achievement) =>
      _manualUnlockedIds.contains(achievement.id) ||
      _isAutomaticallyUnlocked(achievement);

  Future<void> _toggleManualUnlock(String achievementId) async {
    final updated = Set<String>.from(_manualUnlockedIds);
    if (!updated.add(achievementId)) updated.remove(achievementId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
        _manualUnlockedKey, updated.toList()..sort());
    if (!mounted) return;
    setState(() => _manualUnlockedIds = updated);
  }

  @override
  Widget build(BuildContext context) {
    final achievements = achievementsList;
    final progress = _progress;

    return Scaffold(
      appBar: AppBar(title: const Text('Osiągnięcia')),
      body: _loading || progress == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.catching_pokemon),
                      title: const Text('Kolekcja ze wszystkich gier'),
                      subtitle: Text(
                        '${progress.globalCaughtCount} różnych Pokémonów zarejestrowanych łącznie',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Wybrana gra: ${progress.selectedGameId.replaceAll('_', ' ')} · '
                      '${progress.selectedGameCaughtCount}/${progress.selectedGamePokemonTotal} Pokémonów · '
                      '${progress.selectedGameCompletedGuideSteps}/${progress.selectedGameTotalGuideSteps} kroków poradnika · '
                      'postęp ${progress.selectedGameProgressPercent}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Expanded(
                  child: achievements.isEmpty
                      ? const Center(child: Text('Brak dostępnych osiągnięć.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: achievements.length,
                          itemBuilder: (context, index) {
                            final achievement = achievements[index];
                            return AchievementCard(
                              achievement: achievement,
                              unlocked: _isUnlocked(achievement),
                              manuallyUnlocked:
                                  _manualUnlockedIds.contains(achievement.id),
                              canManuallyUnlock:
                                  !_isAutomaticallyUnlocked(achievement),
                              onManualToggle: () =>
                                  _toggleManualUnlock(achievement.id),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
