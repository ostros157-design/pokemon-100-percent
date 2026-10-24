
import 'package:flutter/material.dart';

import '../models/achievement.dart';

class AchievementCard extends StatelessWidget {
final Achievement achievement;
final bool unlocked;

const AchievementCard({
super.key,
required this.achievement,
required this.unlocked,
});

@override
Widget build(BuildContext context) {
final bool hiddenLocked = achievement.hidden && !unlocked;

return Card(
margin: const EdgeInsets.only(bottom: 12),
child: ListTile(
leading: CircleAvatar(
child: Icon(
unlocked
? Icons.emoji_events
    : hiddenLocked
? Icons.help_outline
    : Icons.lock_outline,
),
),
title: Text(
hiddenLocked ? '???' : achievement.title,
style: TextStyle(
fontWeight: FontWeight.bold,
color: unlocked ? null : Colors.grey,
),
),
subtitle: Text(
hiddenLocked
? 'Ukryte osiągnięcie'
    : achievement.description,
style: TextStyle(
color: unlocked ? null : Colors.grey,
),
),
trailing: Icon(
unlocked
? Icons.check_circle
    : Icons.lock,
),
),
);
}
}

