import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pokemon.dart';

class PokemonDetailsScreen extends StatefulWidget {
  final Pokemon pokemon;

  const PokemonDetailsScreen({super.key, required this.pokemon});

  @override
  State<PokemonDetailsScreen> createState() => _PokemonDetailsScreenState();
}

class _PokemonDetailsScreenState extends State<PokemonDetailsScreen> {
  static const _caughtPokemonKey = 'caught_pokemon_ids';
  bool _caught = false;
  bool _loadingCaught = true;

  @override
  void initState() {
    super.initState();
    _loadCaughtStatus();
  }

  Future<void> _loadCaughtStatus() async {
    final preferences = await SharedPreferences.getInstance();
    final ids = (preferences.getStringList(_caughtPokemonKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    if (!mounted) return;
    setState(() {
      _caught = ids.contains(widget.pokemon.id);
      _loadingCaught = false;
    });
  }

  Future<void> _toggleCaught() async {
    final preferences = await SharedPreferences.getInstance();
    final ids = (preferences.getStringList(_caughtPokemonKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();

    setState(() {
      if (_caught) {
        ids.remove(widget.pokemon.id);
        _caught = false;
      } else {
        ids.add(widget.pokemon.id);
        _caught = true;
      }
    });
    await preferences.setStringList(
      _caughtPokemonKey,
      ids.map((id) => id.toString()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = widget.pokemon;
    return Scaffold(
      appBar: AppBar(title: Text(pokemon.name), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Text(
              pokemon.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 90,
              child: Text(
                '#${pokemon.id}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadingCaught ? null : _toggleCaught,
              icon: Icon(_caught ? Icons.check_circle : Icons.catching_pokemon),
              label: Text(_loadingCaught
                  ? 'Ładowanie statusu...'
                  : _caught
                      ? 'Oznacz jako niezłapany'
                      : 'Oznacz jako złapany'),
            ),
            const SizedBox(height: 24),
            const Text('Typ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pokemon.types.map((type) => Chip(
                label: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
              )).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Informacje', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(pokemon.description, style: const TextStyle(fontSize: 16, height: 1.5)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('W przyszłości', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text('Lokacje'),
                    subtitle: Text('Tutaj później znajdą się miejsca, w których można zdobyć tego Pokémona.'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.auto_awesome),
                    title: Text('Ewolucje'),
                    subtitle: Text('Tutaj później pojawią się informacje o ewolucjach.'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.sports_martial_arts),
                    title: Text('Ataki'),
                    subtitle: Text('Tutaj później znajdzie się lista dostępnych ataków.'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.bar_chart),
                    title: Text('Statystyki'),
                    subtitle: Text('Tutaj później będą wyświetlane statystyki Pokémona.'),
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
