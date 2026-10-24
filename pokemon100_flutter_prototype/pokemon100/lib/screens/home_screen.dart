
import 'package:flutter/material.dart';

import '../data/guides_data.dart';
import '../screens/guide_screen.dart';
import '../screens/game_select_screen.dart';
import '../screens/pokedex_screen.dart';
import '../screens/team_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatelessWidget {
const HomeScreen({super.key});

@override
Widget build(BuildContext context) {
final firstGuide = guidesList.isNotEmpty ? guidesList.first : null;

return Scaffold(
appBar: AppBar(
title: const Text('Pokémon Guide'),
actions: [
IconButton(
icon: const Icon(Icons.settings),
tooltip: 'Ustawienia',
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const SettingsScreen(),
),
);
},
),
],
),
body: ListView(
padding: const EdgeInsets.all(16),
children: [
const Text(
'Pokémon Guide',
style: TextStyle(
fontSize: 30,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Text(
'Twój kompletny przewodnik po grach Pokémon.',
style: TextStyle(
fontSize: 16,
color: Colors.grey.shade700,
),
),

const SizedBox(height: 24),

_HomeButton(
icon: Icons.menu_book,
title: 'Poradniki',
subtitle: 'Przejdź do poradnika gry',
onTap: () {
if (firstGuide != null) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => GuideScreen(
guide: firstGuide,
),
),
);
}
},
),

_HomeButton(
icon: Icons.catching_pokemon,
title: 'Pokédex',
subtitle: 'Przeglądaj Pokémony',
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const PokedexScreen(),
),
);
},
),

_HomeButton(
icon: Icons.sports_esports,
title: 'Wybór gry',
subtitle: 'Wybierz grę Pokémon',
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const GameSelectScreen(),
),
);
},
),

_HomeButton(
icon: Icons.groups,
title: 'Team',
subtitle: 'Zbuduj swoją drużynę',
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const TeamScreen(),
),
);
},
),

_HomeButton(
icon: Icons.emoji_events,
title: 'Osiągnięcia',
subtitle: 'Sprawdź swoje osiągnięcia',
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const AchievementsScreen(),
),
);
},
),

_HomeButton(
icon: Icons.person,
title: 'Profil',
subtitle: 'Twoje statystyki i postęp',
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const ProfileScreen(),
),
);
},
),
],
),
);
}
}

class _HomeButton extends StatelessWidget {
final IconData icon;
final String title;
final String subtitle;
final VoidCallback onTap;

const _HomeButton({
required this.icon,
required this.title,
required this.subtitle,
required this.onTap,
});

@override
Widget build(BuildContext context) {
return Card(
margin: const EdgeInsets.only(bottom: 12),
child: ListTile(
leading: CircleAvatar(
child: Icon(icon),
),
title: Text(
title,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
subtitle: Text(subtitle),
trailing: const Icon(Icons.arrow_forward_ios),
onTap: onTap,
),
);
}
}

