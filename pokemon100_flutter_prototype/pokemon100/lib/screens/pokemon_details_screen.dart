import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pokemon.dart';
import '../data/pokemon_data.dart';
import '../data/evolution_data.dart';
import '../data/type_effectiveness.dart';

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

  Widget _buildEvolutionTree(BuildContext context, Pokemon pokemon) {
    final familyIds = evolutionFamilies[pokemon.id];
    if (familyIds == null || familyIds.length < 2) {
      return const SizedBox.shrink();
    }
    final family = familyIds
        .map((id) => pokemonList.where((item) => item.id == id))
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toList();
    if (family.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Drzewko ewolucji',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < family.length; i++) ...[
                  if (i > 0)
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                  ActionChip(
                    avatar: CachedNetworkImage(
                      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${family[i].id}.png',
                      width: 38,
                      height: 38,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.catching_pokemon),
                    ),
                    label: Text(family[i].name),
                    tooltip: family[i].id == pokemon.id
                        ? 'Aktualny Pokémon'
                        : 'Otwórz ${family[i].name}',
                    onPressed: family[i].id == pokemon.id
                        ? null
                        : () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => PokemonDetailsScreen(
                                  pokemon: family[i],
                                ),
                              ),
                            ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeMatchups(Pokemon pokemon) {
    const attackTypes = <String>[
      'Normal', 'Fire', 'Water', 'Electric', 'Grass', 'Ice', 'Fighting',
      'Poison', 'Ground', 'Flying', 'Psychic', 'Bug', 'Rock', 'Ghost',
      'Dragon', 'Dark', 'Steel', 'Fairy',
    ];
    final weaknesses = <String>[];
    final resistances = <String>[];
    final immunities = <String>[];
    for (final attackType in attackTypes) {
      final multiplier = effectivenessAgainst(attackType, pokemon.types);
      if (multiplier == 0) {
        immunities.add(attackType);
      } else if (multiplier > 1) {
        weaknesses.add('$attackType ×${multiplier.toStringAsFixed(multiplier == multiplier.roundToDouble() ? 0 : 2)}');
      } else if (multiplier < 1) {
        resistances.add('$attackType ×${multiplier.toStringAsFixed(multiplier == multiplier.roundToDouble() ? 0 : 2)}');
      }
    }

    Widget group(String title, IconData icon, List<String> values) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (values.isEmpty)
            const Text('Brak', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: values.map((value) => Chip(
                avatar: Icon(icon, size: 16),
                label: Text(value),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Słabości i odporności',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                group('Słabości (obrażenia zwiększone)', Icons.warning_amber, weaknesses),
                group('Odporności (obrażenia zmniejszone)', Icons.shield, resistances),
                group('Immunitety (0× obrażeń)', Icons.block, immunities),
                const Text(
                  'Obliczenia uwzględniają oba typy Pokémona i standardową tabelę typów generacji VI+. Nie uwzględniają zdolności, przedmiotów ani zmian zasad konkretnej gry.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: CachedNetworkImage(
                  imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png',
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.catching_pokemon,
                    size: 120,
                  ),
                ),
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
            _buildTypeMatchups(pokemon),
            const SizedBox(height: 24),
            const Text('Informacje', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(pokemon.description, style: const TextStyle(fontSize: 16, height: 1.5)),
              ),
            ),
            _buildEvolutionTree(context, pokemon),
            const SizedBox(height: 24),
            const Text('Spotkanie i łapanie', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text('Szansa pojawienia się'),
                    subtitle: Text('Procent musi zależeć od wybranej gry, lokacji, metody spotkania i warunków. Te dane nie są jeszcze dostępne — nie pokazujemy zmyślonej wartości.'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.auto_awesome),
                    title: Text('Szansa złapania'),
                    subtitle: Text('Zależy m.in. od gry, aktualnego HP, statusu, Poké Balla i parametrów spotkania. Kalkulator wymaga tych danych, więc procent nie jest jeszcze wyliczany.'),
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
