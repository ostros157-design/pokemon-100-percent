
import 'package:flutter/material.dart';

import '../data/guides_data.dart';
import 'guide_screen.dart';

class GameSelectScreen extends StatelessWidget {
const GameSelectScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Wybór gry'),
),
body: guidesList.isEmpty
? const Center(
child: Text(
'Brak dostępnych poradników.',
style: TextStyle(fontSize: 18),
),
)
    : ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: guidesList.length,
itemBuilder: (context, index) {
final guide = guidesList[index];

return Card(
margin: const EdgeInsets.only(bottom: 12),
child: ListTile(
leading: const CircleAvatar(
child: Icon(Icons.sports_esports),
),
title: Text(
guide.title,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
subtitle: Text(guide.description),
trailing: const Icon(
Icons.arrow_forward_ios,
),
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => GuideScreen(
guide: guide,
),
),
);
},
),
);
},
),
);
}
}

