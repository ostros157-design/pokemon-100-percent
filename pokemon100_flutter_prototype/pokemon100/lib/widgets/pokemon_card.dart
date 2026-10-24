
import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonCard extends StatelessWidget {
final Pokemon pokemon;
final VoidCallback? onTap;

const PokemonCard({
super.key,
required this.pokemon,
this.onTap,
});

String get imageUrl =>
'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png';

@override
Widget build(BuildContext context) {
return Card(
elevation: 3,
margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
child: InkWell(
borderRadius: BorderRadius.circular(18),
onTap: onTap,
child: Padding(
padding: const EdgeInsets.all(12),
child: Row(
children: [
Container(
width: 80,
height: 80,
decoration: BoxDecoration(
color: Colors.grey.shade100,
shape: BoxShape.circle,
),
child: Image.network(
imageUrl,
fit: BoxFit.contain,
errorBuilder: (context, error, stackTrace) {
return const Icon(
Icons.catching_pokemon,
size: 45,
);
},
),
),

const SizedBox(width: 15),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'#${pokemon.id.toString().padLeft(3, '0')}',
style: TextStyle(
fontSize: 13,
color: Colors.grey.shade600,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 3),

Text(
pokemon.name,
style: const TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

Wrap(
spacing: 6,
runSpacing: 4,
children: pokemon.types.map((type) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 4,
),
decoration: BoxDecoration(
color: _typeColor(type),
borderRadius: BorderRadius.circular(20),
),
child: Text(
type,
style: const TextStyle(
color: Colors.white,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
);
}).toList(),
),
],
),
),

const Icon(
Icons.arrow_forward_ios,
size: 18,
),
],
),
),
),
);
}

Color _typeColor(String type) {
switch (type.toLowerCase()) {
case 'normal':
return Colors.grey;
case 'fire':
return Colors.red;
case 'water':
return Colors.blue;
case 'electric':
return Colors.amber.shade700;
case 'grass':
return Colors.green;
case 'ice':
return Colors.cyan;
case 'fighting':
return Colors.red.shade900;
case 'poison':
return Colors.purple;
case 'ground':
return Colors.brown;
case 'flying':
return Colors.indigo.shade300;
case 'psychic':
return Colors.pink;
case 'bug':
return Colors.lightGreen.shade700;
case 'rock':
return Colors.brown.shade600;
case 'ghost':
return Colors.deepPurple;
case 'dragon':
return Colors.indigo;
case 'dark':
return Colors.grey.shade900;
case 'steel':
return Colors.blueGrey;
case 'fairy':
return Colors.pinkAccent;
default:
return Colors.grey;
}
}
}

