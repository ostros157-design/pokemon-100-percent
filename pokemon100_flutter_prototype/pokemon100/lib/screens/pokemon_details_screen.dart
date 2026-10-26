import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pokemon.dart';
import '../data/pokemon_data.dart';
import '../data/evolution_data.dart';
import '../data/type_effectiveness.dart';
import '../data/move_data.dart';
import '../data/pokemon_learnset_data.dart';

class PokemonDetailsScreen extends StatefulWidget {
  final Pokemon pokemon;
  final String? gameId;

  const PokemonDetailsScreen({super.key, required this.pokemon, this.gameId});

  @override
  State<PokemonDetailsScreen> createState() => _PokemonDetailsScreenState();
}

class _PokemonDetailsScreenState extends State<PokemonDetailsScreen> {
  bool _caught = false;
  bool _shiny = false;
  String _activeGameId = 'lets_go_pikachu';

  String get _caughtPokemonKey => 'caught_pokemon_ids_${_activeGameId}';
  bool _loadingCaught = true;
  String? _selectedLearnsetVersion;

  @override
  void initState() {
    super.initState();
    _loadCaughtStatus();
  }

  Future<void> _loadCaughtStatus() async {
    final preferences = await SharedPreferences.getInstance();
    _activeGameId = widget.gameId ??
        preferences.getString('selected_pokemon_game_id') ??
        'lets_go_pikachu';
    // Preserve the legacy global collection and copy it only when this game's
    // collection has not been initialized yet.
    if (!preferences.containsKey(_caughtPokemonKey)) {
      final legacyIds = preferences.getStringList('caught_pokemon_ids');
      if (legacyIds != null) {
        await preferences.setStringList(_caughtPokemonKey, legacyIds);
      }
    }
    final ids = (preferences.getStringList(_caughtPokemonKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    final shinyKey = 'shiny_pokemon_ids_' + _activeGameId;
    if (!preferences.containsKey(shinyKey)) {
      final legacyShiny = preferences.getStringList('shiny_pokemon_ids');
      if (legacyShiny != null) await preferences.setStringList(shinyKey, legacyShiny);
    }
    final shinyIds = (preferences.getStringList(shinyKey) ?? const <String>[])
        .map(int.tryParse).whereType<int>().toSet();
    if (!mounted) return;
    setState(() {
      _caught = ids.contains(widget.pokemon.id);
      _shiny = shinyIds.contains(widget.pokemon.id);
      _loadingCaught = false;
    });
  }

  Future<void> _toggleShiny() async {
    final preferences = await SharedPreferences.getInstance();
    final key = 'shiny_pokemon_ids_' + _activeGameId;
    final ids = (preferences.getStringList(key) ?? const <String>[])
        .map(int.tryParse).whereType<int>().toSet();
    if (_shiny) { ids.remove(widget.pokemon.id); } else { ids.add(widget.pokemon.id); }
    await preferences.setStringList(key, ids.map((id) => id.toString()).toList());
    if (mounted) setState(() => _shiny = !_shiny);
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
                                  gameId: widget.gameId ?? _activeGameId,
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

  Widget _buildBaseStats(Pokemon pokemon) {
    final stats = <(String, int?)>[
      ('HP', pokemon.hp),
      ('Atak', pokemon.attack),
      ('Obrona', pokemon.defense),
      ('Atak specjalny', pokemon.specialAttack),
      ('Obrona specjalna', pokemon.specialDefense),
      ('Szybkość', pokemon.speed),
    ];
    final complete = pokemon.hasCompleteBaseStats;
    final maxStat = stats.map((entry) => entry.$2 ?? 0).fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Statystyki bazowe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final stat in stats)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(width: 132, child: Text(stat.$1)),
                        Expanded(
                          child: stat.$2 == null
                              ? const Text('Brak danych')
                              : LinearProgressIndicator(
                                  value: (stat.$2! / maxStat).clamp(0.0, 1.0),
                                  minHeight: 8,
                                ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 34,
                          child: Text(
                            stat.$2?.toString() ?? '—',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Suma statystyk bazowych',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(pokemon.baseStatTotal?.toString() ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (!complete)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Brak zweryfikowanych statystyk w lokalnym zbiorze danych. Wartości nie są zgadywane.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSpeciesData(Pokemon pokemon) {
    String heightText(int? value) =>
        value == null ? 'Brak danych' : '${(value / 10).toStringAsFixed(1)} m';
    String weightText(int? value) =>
        value == null ? 'Brak danych' : '${(value / 10).toStringAsFixed(1)} kg';

    Widget valueRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dane gatunku',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                valueRow('Wzrost', heightText(pokemon.height)),
                valueRow('Masa', weightText(pokemon.weight)),
                valueRow('Bazowe doświadczenie', pokemon.baseExperience?.toString() ?? 'Brak danych'),
                valueRow('Współczynnik łapania', pokemon.captureRate?.toString() ?? 'Brak danych'),
                valueRow('Bazowa przyjaźń', pokemon.baseHappiness?.toString() ?? 'Brak danych'),
                valueRow('Cykl wykluwania', pokemon.hatchCounter?.toString() ?? 'Brak danych'),
                valueRow('Generacja', pokemon.generation?.toString() ?? 'Brak danych'),
                valueRow('Płeć', pokemon.genderRate == null
                    ? 'Brak danych'
                    : pokemon.genderRate == -1
                        ? 'Brak płci'
                        : 'Samce: ${((8 - pokemon.genderRate!) / 8 * 100).round()}%, samice: ${(pokemon.genderRate! / 8 * 100).round()}%'),
                if (pokemon.isLegendary || pokemon.isMythical || pokemon.isBaby)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (pokemon.isLegendary) const Chip(label: Text('Legendarny')),
                        if (pokemon.isMythical) const Chip(label: Text('Mityczny')),
                        if (pokemon.isBaby) const Chip(label: Text('Baby Pokémon')),
                      ],
                    ),
                  ),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    pokemon.abilities.isEmpty
                        ? 'Umiejętności: brak danych w lokalnym zbiorze'
                        : 'Umiejętności: ${pokemon.abilities.join(', ')}',
                  ),
                ),
                if (pokemon.hiddenAbilities.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Umiejętności ukryte: ${pokemon.hiddenAbilities.join(', ')}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }


  Widget _buildLearnset(Pokemon pokemon) {
    return FutureBuilder<List<PokemonLearnsetEntry>>(
      future: PokemonLearnsetData.forPokemon(pokemon.id),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <PokemonLearnsetEntry>[];
        final versionGroups = entries.map((e) => e.versionGroup).toSet().toList()..sort();
        final selected = versionGroups.contains(_selectedLearnsetVersion)
            ? _selectedLearnsetVersion
            : (versionGroups.isNotEmpty ? versionGroups.first : null);
        final visible = entries.where((e) => e.versionGroup == selected).toList()
          ..sort((a, b) {
            final method = a.methodId.compareTo(b.methodId);
            if (method != 0) return method;
            final level = a.level.compareTo(b.level);
            if (level != 0) return level;
            return (a.order ?? 999).compareTo(b.order ?? 999);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ruchy i ataki', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: snapshot.connectionState != ConnectionState.done
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ))
                    : entries.isEmpty
                        ? const Text(
                            'Dane nauki ruchów nie zostały jeszcze zaimportowane. Po wygenerowaniu pliku pokemon_learnsets.json ta sekcja pokaże ruchy tego Pokémona z podziałem na gry, poziomy i metody nauki.',
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: selected,
                                decoration: const InputDecoration(labelText: 'Grupa wersji gry'),
                                items: versionGroups.map((group) => DropdownMenuItem(
                                  value: group,
                                  child: Text(group.replaceAll('-', ' ')),
                                )).toList(),
                                onChanged: (value) => setState(() => _selectedLearnsetVersion = value),
                              ),
                              const SizedBox(height: 8),
                              ...visible.map((entry) {
                                final move = moveById(entry.moveId);
                                final detail = move == null
                                    ? 'Ruch #${entry.moveId}'
                                    : '${move.name} • ${move.type} • ${move.category}'
                                      '${move.power == null ? '' : ' • Moc ${move.power}'}';
                                final method = entry.methodId == 1 && entry.level > 0
                                    ? 'Poziom ${entry.level}'
                                    : entry.methodLabel;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(detail),
                                  subtitle: Text(method),
                                );
                              }),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = widget.pokemon;
    return Scaffold(
      appBar: AppBar(title: Text(pokemon.name), centerTitle: true, actions: [IconButton(tooltip: _shiny ? 'Pokaż zwykłą formę' : 'Pokaż Shiny', onPressed: _toggleShiny, icon: Icon(_shiny ? Icons.auto_awesome : Icons.auto_awesome_outlined))]),
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
                  imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${_shiny ? 'shiny/' : ''}${pokemon.id}.png',
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
            _buildBaseStats(pokemon),
            _buildSpeciesData(pokemon),
            _buildLearnset(pokemon),
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
