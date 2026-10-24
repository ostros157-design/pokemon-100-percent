
import 'package:flutter/material.dart';

import '../data/achievements_data.dart';
import '../widgets/achievement_card.dart';

class AchievementsScreen extends StatelessWidget {
const AchievementsScreen({super.key});

@override
Widget build(BuildContext context) {
final achievements = achievementsList;

return Scaffold(
appBar: AppBar(
title: const Text('Osiągnięcia'),
),
body: achievements.isEmpty
? const Center(
child: Text(
'Brak dostępnych osiągnięć.',
style: TextStyle(fontSize: 18),
),
)
    : ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: achievements.length,
itemBuilder: (context, index) {
final achievement = achievements[index];

return AchievementCard(
achievement: achievement,
unlocked: false,
);
},
),
);
}
}

