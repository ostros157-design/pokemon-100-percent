import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/app_appearance.dart';
import 'pixel_icon.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final bool manuallyUnlocked;
  final bool canManuallyUnlock;
  final VoidCallback onManualToggle;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.unlocked,
    required this.manuallyUnlocked,
    required this.canManuallyUnlock,
    required this.onManualToggle,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedColor = Theme.of(context).colorScheme.primary;
    final pixel = AppAppearance.visualStyle.value == 'pixel';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: unlocked
              ? unlockedColor.withValues(alpha: 0.14)
              : null,
          child: pixel
              ? PixelIcon(
                  name: unlocked ? 'trophy' : 'settings',
                  color: unlocked ? unlockedColor : Theme.of(context).disabledColor,
                  size: 23,
                )
              : Icon(
                  unlocked ? Icons.emoji_events : Icons.lock_outline,
                  color: unlocked ? unlockedColor : null,
                ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: unlocked ? unlockedColor : Colors.grey,
          ),
        ),
        subtitle: Text(
          achievement.description,
          style: TextStyle(
            color: unlocked ? null : Colors.grey,
          ),
        ),
        trailing: canManuallyUnlock
            ? IconButton(
                tooltip: manuallyUnlocked
                    ? 'Cofnij ręczne oznaczenie'
                    : 'Oznacz jako zdobyte',
                onPressed: onManualToggle,
                icon: pixel
                    ? PixelIcon(
                        name: 'check',
                        color: manuallyUnlocked ? unlockedColor : null,
                      )
                    : Icon(
                        manuallyUnlocked
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: manuallyUnlocked ? unlockedColor : null,
                      ),
              )
            : pixel
                ? PixelIcon(
                    name: unlocked ? 'check' : 'settings',
                    color: unlocked ? unlockedColor : Theme.of(context).disabledColor,
                  )
                : Icon(
                    unlocked ? Icons.check_circle : Icons.lock,
                    color: unlocked ? unlockedColor : null,
                  ),
      ),
    );
  }
}
