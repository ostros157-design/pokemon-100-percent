
import 'package:flutter/material.dart';
import '../data/pokemon_data.dart';
import '../models/pokemon.dart';
import 'pokemon_details_screen.dart';

class PokedexScreen extends StatefulWidget {
const PokedexScreen({super.key});

@override
State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
final TextEditingController _searchController = TextEditingController();

String _search = '';

@override
void initState() {
super.initState();

_searchController.addListener(() {
setState(() {
_search = _searchController.text.toLowerCase();
});
});
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

List<Pokemon> get _filteredPokemon {
if (_search.isEmpty) {
return pokemonList;
}

return pokemonList.where((pokemon) {
return pokemon.name.toLowerCase().contains(_search) ||
pokemon.id.toString().contains(_search);
}).toList();
}

@override
Widget build(BuildContext context) {
final pokemon = _filteredPokemon;

return Scaffold(
appBar: AppBar(
title: const Text('Pokédex'),
centerTitle: true,
),
body: Column(
children: [
Padding(
padding: const EdgeInsets.all(12),
child: TextField(
controller: _searchController,
decoration: InputDecoration(
hintText: 'Szukaj Pokémona lub numeru...',
prefixIcon: const Icon(Icons.search),
suffixIcon: _search.isNotEmpty
? IconButton(
icon: const Icon(Icons.clear),
onPressed: () {
_searchController.clear();
},
)
    : null,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(16),
),
),
),
),

Padding(
padding: const EdgeInsets.symmetric(horizontal: 16),
child: Row(
children: [
Text(
'Znaleziono: ${pokemon.length}',
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
const Spacer(),
const Text('Gen I • 151 Pokémon'),
],
),
),

const SizedBox(height: 8),

Expanded(
child: pokemon.isEmpty
? const Center(
child: Text(
'Nie znaleziono Pokémona.',
style: TextStyle(fontSize: 18),
),
)
    : GridView.builder(
padding: const EdgeInsets.all(12),
gridDelegate:
const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
crossAxisSpacing: 12,
mainAxisSpacing: 12,
childAspectRatio: 0.9,
),
itemCount: pokemon.length,
itemBuilder: (context, index) {
final currentPokemon = pokemon[index];

return _PokemonCard(
pokemon: currentPokemon,
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => PokemonDetailsScreen(
pokemon: currentPokemon,
),
),
);
},
);
},
),
),
],
),
);
}
}

class _PokemonCard extends StatelessWidget {
final Pokemon pokemon;
final VoidCallback onTap;

const _PokemonCard({
required this.pokemon,
required this.onTap,
});

@override
Widget build(BuildContext context) {
return Card(
elevation: 3,
clipBehavior: Clip.antiAlias,
child: InkWell(
onTap: onTap,
child: Padding(
padding: const EdgeInsets.all(12),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
CircleAvatar(
radius: 42,
child: Text(
'#${pokemon.id}',
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
),

const SizedBox(height: 10),

Text(
pokemon.name,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 6),

Wrap(
spacing: 4,
runSpacing: 4,
alignment: WrapAlignment.center,
children: pokemon.types.map((type) {
return Chip(
label: Text(
type,
style: const TextStyle(fontSize: 11),
),
visualDensity: VisualDensity.compact,
);
}).toList(),
),
],
),
),
),
);
}
}
