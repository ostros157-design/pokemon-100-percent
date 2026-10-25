import 'package:cached_network_image/cached_network_image.dart';
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
  final Set<String> _selectedTypes = <String>{};
  String _selectedGame = 'all';
  final Set<int> _shinyPokemonIds = <int>{};
  static const Set<int> _letsGoPikachuUnavailable = {
    15, 23, 24, 37, 38, 52, 69, 70, 71, 109, 110, 127, 151,
  };
  static const List<String> _pokemonTypes = <String>[
    'Normal', 'Fire', 'Water', 'Electric', 'Grass', 'Ice', 'Fighting',
    'Poison', 'Ground', 'Flying', 'Psychic', 'Bug', 'Rock', 'Ghost',
    'Dragon', 'Dark', 'Steel', 'Fairy',
  ];
  int _imagesCached = 0;
  bool _cacheFinished = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _cachePokemonImages());
  }

  Future<void> _cachePokemonImages() async {
    // Download in small batches so the first visit does not issue 1025
    // simultaneous requests or block the UI for one long sequential loop.
    const batchSize = 12;
    for (var start = 0; start < pokemonList.length; start += batchSize) {
      if (!mounted) return;
      final batch = pokemonList.skip(start).take(batchSize);
      await Future.wait(batch.map((pokemon) async {
        try {
          await precacheImage(
            CachedNetworkImageProvider(_imageUrl(pokemon.id)),
            context,
          );
        } catch (_) {
          // Failed downloads can be retried when the image is displayed.
        }
        if (mounted) setState(() => _imagesCached++);
      }));
    }
    if (!mounted) return;
    setState(() => _cacheFinished = true);
  }

  String _imageUrl(int id, {bool shiny = false}) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${shiny ? 'shiny/' : ''}$id.png';

  void _toggleShiny(int id) {
    setState(() {
      if (!_shinyPokemonIds.add(id)) {
        _shinyPokemonIds.remove(id);
      }
    });
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
      return matchesSearch && matchesTypes && matchesGame;
    }).toList();
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
          if (!_cacheFinished)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zapisywanie zdjęć Pokémonów: $_imagesCached/${pokemonList.length}'),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: pokemonList.isEmpty ? 1 : _imagesCached / pokemonList.length),
                  const SizedBox(height: 4),
                  const Text('Po pobraniu dostępne będą również bez internetu.', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
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
                        ? 'Filtry'
                        : 'Filtry: ${_selectedTypes.length}'),
                  ),
                ),
                const SizedBox(width: 8),
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
                        onToggleShiny: () => _toggleShiny(currentPokemon.id),
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
  final bool shiny;
  final VoidCallback onToggleShiny;
  final VoidCallback onTap;

  const _PokemonCard({
    required this.pokemon,
    required this.shiny,
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
