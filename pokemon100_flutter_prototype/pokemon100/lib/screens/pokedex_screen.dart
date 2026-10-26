import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final Set<String> _selectedTypes = <String>{};
  String _selectedGame = 'all';
  final Set<int> _shinyPokemonIds = <int>{};
  final Set<int> _caughtPokemonIds = <int>{};
  bool _onlyCaught = false;
  String _sortMode = 'number';
  String _activeGameId = 'lets_go_pikachu';
  static const String _selectedGameKey = 'selected_pokemon_game_id';
  static const Set<int> _letsGoPikachuUnavailable = {
    15, 23, 24, 37, 38, 52, 69, 70, 71, 109, 110, 127, 151,
  };
  static const List<String> _pokemonTypes = <String>[
    'Normal', 'Fire', 'Water', 'Electric', 'Grass', 'Ice', 'Fighting',
    'Poison', 'Ground', 'Flying', 'Psychic', 'Bug', 'Rock', 'Ghost',
    'Dragon', 'Dark', 'Steel', 'Fairy',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedState();

    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.toLowerCase();
      });
    });
  }

  String _collectionKey(String base, String gameId) => '${base}_$gameId';

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGame = prefs.getString(_selectedGameKey);
    final gameId = (savedGame != null && savedGame.trim().isNotEmpty)
        ? savedGame
        : 'lets_go_pikachu';
    final caughtKey = _collectionKey('caught_pokemon_ids', gameId);
    final shinyKey = _collectionKey('shiny_pokemon_ids', gameId);

    // Migrate the old global collection once into the currently selected game,
    // but keep the original keys so existing data is never deleted.
    if (!prefs.containsKey(caughtKey)) {
      final legacyCaught = prefs.getStringList('caught_pokemon_ids');
      if (legacyCaught != null) await prefs.setStringList(caughtKey, legacyCaught);
    }
    if (!prefs.containsKey(shinyKey)) {
      final legacyShiny = prefs.getStringList('shiny_pokemon_ids');
      if (legacyShiny != null) await prefs.setStringList(shinyKey, legacyShiny);
    }

    final caught = (prefs.getStringList(caughtKey) ?? const <String>[])
        .map(int.tryParse).whereType<int>().toSet();
    final shiny = (prefs.getStringList(shinyKey) ?? const <String>[])
        .map(int.tryParse).whereType<int>().toSet();
    if (!mounted) return;
    setState(() {
      _activeGameId = gameId;
      _caughtPokemonIds..clear()..addAll(caught);
      _shinyPokemonIds..clear()..addAll(shiny);
    });
  }

  Future<void> _saveIds(String base, Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _collectionKey(base, _activeGameId),
      ids.map((id) => id.toString()).toList(),
    );
  }

  Future<void> _toggleCaught(int id) async {
    setState(() { if (!_caughtPokemonIds.add(id)) _caughtPokemonIds.remove(id); });
    await _saveIds('caught_pokemon_ids', _caughtPokemonIds);
  }

  String _imageUrl(int id, {bool shiny = false}) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${shiny ? 'shiny/' : ''}$id.png';

  void _toggleShiny(int id) {
    setState(() { if (!_shinyPokemonIds.add(id)) _shinyPokemonIds.remove(id); });
    _saveIds('shiny_pokemon_ids', _shinyPokemonIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Pokemon> get _filteredPokemon {
    return pokemonList.where((pokemon) {
      final matchesSearch = _search.isEmpty ||
          pokemon.name.toLowerCase().contains(_search) ||
          pokemon.id.toString().contains(_search);
      final normalizedTypes = pokemon.types.map((type) => type.toLowerCase()).toSet();
      final matchesTypes = _selectedTypes.isEmpty ||
          _selectedTypes.any((type) => normalizedTypes.contains(type.toLowerCase()));
      final matchesGame = _selectedGame == 'all' ||
          (_selectedGame == 'lets_go_pikachu' &&
              pokemon.id >= 1 &&
              pokemon.id <= 151 &&
              !_letsGoPikachuUnavailable.contains(pokemon.id));
      final matchesCaught = !_onlyCaught || _caughtPokemonIds.contains(pokemon.id);
      return matchesSearch && matchesTypes && matchesGame && matchesCaught;
    }).toList()..sort((a, b) {
      if (_sortMode == 'name') return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (_sortMode == 'reverse') return b.id.compareTo(a.id);
      return a.id.compareTo(b.id);
    });
  }

  Future<void> _showTypeFilters() async {
    final draft = Set<String>.from(_selectedTypes);
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Filtruj według typu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () => setSheetState(() => draft.clear()),
                      child: const Text('Wyczyść'),
                    ),
                  ],
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Wybierz jeden lub kilka typów. Pokémon pasujący do dowolnego z nich zostanie pokazany.'),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _pokemonTypes.map((type) {
                        final isSelected = draft.contains(type);
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (value) => setSheetState(() {
                            if (value) {
                              draft.add(type);
                            } else {
                              draft.remove(type);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, draft),
                    child: const Text('Zastosuj filtry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedTypes
          ..clear()
          ..addAll(selected);
      });
    }
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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showTypeFilters,
                    icon: const Icon(Icons.filter_list),
                    label: Text(_selectedTypes.isEmpty
                        ? 'Filtry typów'
                        : 'Typy: ${_selectedTypes.length}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Gra',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGame,
                        isExpanded: true,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Wszystkie', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem(
                            value: 'lets_go_pikachu',
                            child: Text("Let's Go, Pikachu!", overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedGame = value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                if (_selectedTypes.isNotEmpty)
                  IconButton(
                    tooltip: 'Wyczyść filtry typów',
                    onPressed: () => setState(() => _selectedTypes.clear()),
                    icon: const Icon(Icons.filter_list_off),
                  ),
              ],
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
                const Text('National Pokédex • 1025 Pokémon'),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [Expanded(child: FilterChip(avatar: const Icon(Icons.check_circle_outline, size: 18), label: const Text('Tylko złapane'), selected: _onlyCaught, onSelected: (value) => setState(() => _onlyCaught = value))), const SizedBox(width: 8), Text('Złapane: ${_caughtPokemonIds.length}/${pokemonList.length} • ${_activeGameId.replaceAll('_', ' ')}') ])),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                const Text('Sortuj:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortMode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'number', child: Text('Numer rosnąco')),
                      DropdownMenuItem(value: 'reverse', child: Text('Numer malejąco')),
                      DropdownMenuItem(value: 'name', child: Text('Nazwa A–Z')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _sortMode = value);
                    },
                  ),
                ),
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
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      // Three compact columns show more Pokémon at once.
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: pokemon.length,
                    itemBuilder: (context, index) {
                      final currentPokemon = pokemon[index];

                      return _PokemonCard(
                        pokemon: currentPokemon,
                        shiny: _shinyPokemonIds.contains(currentPokemon.id),
                        caught: _caughtPokemonIds.contains(currentPokemon.id),
                        onToggleCaught: () => _toggleCaught(currentPokemon.id),
                        onToggleShiny: () => _toggleShiny(currentPokemon.id),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PokemonDetailsScreen(
                                pokemon: currentPokemon,
                                gameId: _activeGameId,
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
  final bool shiny;
  final bool caught;
  final VoidCallback onToggleCaught;
  final VoidCallback onToggleShiny;
  final VoidCallback onTap;

  const _PokemonCard({
    required this.pokemon,
    required this.shiny,
    required this.caught,
    required this.onToggleCaught,
    required this.onToggleShiny,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity;
          if (velocity != null && velocity.abs() > 80) onToggleShiny();
        },
        child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: GestureDetector(
                  onTap: onToggleShiny,
                  child: CachedNetworkImage(
                    imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${shiny ? 'shiny/' : ''}${pokemon.id}.png',
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.catching_pokemon, size: 42),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (shiny)
                const Text('✨ Shiny', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text(
                pokemon.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(caught ? Icons.check_circle : Icons.add_circle_outline, size: 16, color: caught ? Colors.green : null), const SizedBox(width: 3), Text(caught ? 'Złapany' : 'Nie złapany', style: const TextStyle(fontSize: 10)), IconButton(tooltip: caught ? 'Oznacz jako niezłapany' : 'Oznacz jako złapany', onPressed: onToggleCaught, visualDensity: VisualDensity.compact, constraints: const BoxConstraints(minWidth: 28, minHeight: 28), padding: EdgeInsets.zero, icon: Icon(caught ? Icons.check_circle : Icons.add_circle_outline, size: 16))]),
              const SizedBox(height: 2),
              Wrap(
                spacing: 3,
                runSpacing: 0,
                alignment: WrapAlignment.center,
                children: pokemon.types.map((type) {
                  return Chip(
                    label: Text(type, style: const TextStyle(fontSize: 9)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
        ),
    );
  }
}
