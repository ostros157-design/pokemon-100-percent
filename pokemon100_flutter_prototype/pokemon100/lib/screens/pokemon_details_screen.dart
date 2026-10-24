
import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonDetailsScreen extends StatelessWidget {
final Pokemon pokemon;

const PokemonDetailsScreen({
super.key,
required this.pokemon,
});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(pokemon.name),
centerTitle: true,
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// NUMER POKÉDEXU
Text(
'#${pokemon.id.toString().padLeft(3, '0')}',
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
color: Colors.grey,
),
),

const SizedBox(height: 8),

// NAZWA
Text(
pokemon.name,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 32,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 20),

// OBRAZEK
CircleAvatar(
radius: 90,
child: Text(
'#${pokemon.id}',
style: const TextStyle(
fontSize: 28,
fontWeight: FontWeight.bold,
),
),
),

const SizedBox(height: 24),

// TYPY
const Text(
'Typ',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Wrap(
spacing: 8,
runSpacing: 8,
children: pokemon.types.map((type) {
return Chip(
label: Text(
type,
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
);
}).toList(),
),

const SizedBox(height: 24),

// INFORMACJE
const Text(
'Informacje',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Card(
child: Padding(
padding: const EdgeInsets.all(16),
child: Text(
pokemon.description,
style: const TextStyle(
fontSize: 16,
height: 1.5,
),
),
),
),

const SizedBox(height: 24),

// PRZYSZŁE FUNKCJE
const Text(
'W przyszłości',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Card(
child: Column(
children: const [
ListTile(
leading: Icon(Icons.location_on),
title: Text('Lokacje'),
subtitle: Text(
'Tutaj później znajdą się miejsca, w których można zdobyć tego Pokémona.',
),
),
Divider(),
ListTile(
leading: Icon(Icons.auto_awesome),
title: Text('Ewolucje'),
subtitle: Text(
'Tutaj później pojawią się informacje o ewolucjach.',
),
),
Divider(),
ListTile(
leading: Icon(Icons.sports_martial_arts),
title: Text('Ataki'),
subtitle: Text(
'Tutaj później znajdzie się lista dostępnych ataków.',
),
),
Divider(),
ListTile(
leading: Icon(Icons.bar_chart),
title: Text('Statystyki'),
subtitle: Text(
'Tutaj później będą wyświetlane statystyki Pokémona.',
),
),
],
),
),
],
),
),
);
}
}

