import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/games_data.dart';
import '../data/guides_data.dart';
import '../models/game.dart';
import '../models/guide.dart';
import 'guide_screen.dart';

/// Offline location index built only from locations already present in guides.
/// A decorative region image is not treated as a real map.
class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  int _generation = 1;
  String? _selectedGameId;
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _locationSearchController = TextEditingController();

  @override
  void dispose() {
    _locationSearchController.dispose();
    super.dispose();
  }

  static const Map<int, String> _regions = {
    1: 'Kanto',
    2: 'Johto',
    3: 'Hoenn',
    4: 'Sinnoh',
    5: 'Unova',
    6: 'Kalos',
    7: 'Alola',
    8: 'Galar / Hisui',
    9: 'Paldea',
  };

  @override
  void initState() {
    super.initState();
    _loadSelectedGame();
  }

  Future<void> _loadSelectedGame() async {
    final preferences = await SharedPreferences.getInstance();
    final savedId = preferences.getString('selected_pokemon_game_id');
    Game? savedGame;
    for (final game in gamesList) {
      if (game.id == savedId) {
        savedGame = game;
        break;
      }
    }
    savedGame ??= gamesList.isEmpty ? null : gamesList.first;
    if (!mounted) return;
    setState(() {
      if (savedGame != null) {
        _selectedGameId = savedGame.id;
        _generation = _generationFromLabel(savedGame.generation);
      }
      _loading = false;
    });
  }

  int _generationFromLabel(String label) {
    final match = RegExp(r'Generacja (\d+)').firstMatch(label);
    return match == null ? 1 : int.parse(match.group(1)!);
  }

  String get _regionName => _selectedGameId == 'legends_arceus'
      ? 'Hisui'
      : (_regions[_generation] ?? 'Region Pokémon');

  // Let's Go is Kanto despite being labelled Generation I in the game catalog.
  // Its old overview painter used guessed positions, so it must not be shown
  // as if it were a precise in-game map.
  bool get _isLetsGoKanto =>
      _selectedGameId == 'lets_go_pikachu' ||
      _selectedGameId == 'lets_go_eevee';

  String get _letsGoSourceSlug => _selectedGameId == 'lets_go_eevee'
      ? 'lets-go-eevee'
      : 'lets-go-pikachu';

  List<Game> get _gamesForGeneration => gamesList
      .where((game) => _generationFromLabel(game.generation) == _generation)
      .toList();

  Game? get _selectedGame {
    for (final game in gamesList) {
      if (game.id == _selectedGameId) return game;
    }
    return null;
  }

  List<Guide> get _guidesForGame => guidesList
      .where((guide) => guide.gameId == _selectedGameId)
      .toList();

  Map<String, List<_LocationReference>> get _locations {
    final result = <String, List<_LocationReference>>{};
    for (final guide in _guidesForGame) {
      for (var index = 0; index < guide.steps.length; index++) {
        final step = guide.steps[index];
        final location = step.location?.trim();
        if (location == null || location.isEmpty) continue;
        result.putIfAbsent(location, () => <_LocationReference>[]).add(
          _LocationReference(guide: guide, step: step, stepNumber: index + 1),
        );
      }
    }
    return result;
  }

  Future<void> _selectGame(String? gameId) async {
    if (gameId == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('selected_pokemon_game_id', gameId);
    if (!mounted) return;
    setState(() => _selectedGameId = gameId);
  }

  @override
  Widget build(BuildContext context) {
    final games = _gamesForGeneration;
    final selectedGame = _selectedGame;
    // Preserve first appearance in the guide: this approximates the player's
    // route progression better than alphabetical sorting.
    final allLocationEntries = _locations.entries.toList();
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final locationEntries = allLocationEntries
        .where((entry) => entry.key.toLowerCase().contains(normalizedQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mapy i lokacje')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Regiony Pokémon',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Wybierz generację i grę, aby zobaczyć lokacje znalezione w dostępnych poradnikach. Dane działają offline.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _generation,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Region / generacja',
                    border: OutlineInputBorder(),
                  ),
                  items: _regions.entries
                      .map((entry) => DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(
                              'Generacja ${entry.key} — ${entry.value}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    final generationGames = gamesList
                        .where((game) =>
                            _generationFromLabel(game.generation) == value)
                        .toList();
                    setState(() {
                      _generation = value;
                      if (!generationGames.any(
                          (game) => game.id == _selectedGameId)) {
                        _selectedGameId = generationGames.isEmpty
                            ? null
                            : generationGames.first.id;
                      }
                    });
                    if (_selectedGameId != null) {
                      _selectGame(_selectedGameId);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: games.any((game) => game.id == _selectedGameId)
                      ? _selectedGameId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Gra',
                    border: OutlineInputBorder(),
                  ),
                  items: games
                      .map((game) => DropdownMenuItem<String>(
                            value: game.id,
                            child: Text(game.name,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: _selectGame,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.map_outlined,
                            size: 42,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _regionName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(selectedGame?.name ??
                                  'Brak gry z tej generacji w katalogu aplikacji.'),
                              const SizedBox(height: 8),
                              if (_isLetsGoKanto) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outlineVariant,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.gps_fixed),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Mapa offline Kanto — schemat regionu',
                                              style: TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Poniżej znajduje się schematyczna mapa Kanto rysowana przez aplikację, więc działa bez internetu. Pokazuje główne miasta i ogólny układ regionu — nie jest mapą w skali i nie zawiera jeszcze dokładnych punktów przedmiotów, trenerów ani dzikich Pokémonów.',
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Co działa offline i co wymaga dalszego opracowania',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '• Pallet Town: dom gracza, dom rywala, laboratorium Oaka, Town Map i prezenty fabularne.\n• Route 1: układ trasy, trener Youngster Ronny i dzikie Pokémony.\n• Pozycje na mapie pozostają niezatwierdzone, dopóki nie zostaną przypisane do zweryfikowanego podkładu.',
                                      ),
                                      const SizedBox(height: 12),
                                      _KantoRegionMap(
                                        selectedLocation: _searchQuery,
                                        onLocationSelected: (location) {
                                          _locationSearchController.text = location;
                                          setState(() => _searchQuery = location);
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Legenda mapy',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: const [
                                          Chip(
                                            avatar: Icon(Icons.home_outlined, size: 18),
                                            label: Text('Miasto / budynki'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.catching_pokemon, size: 18),
                                            label: Text('Poké Ball / nagroda'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.spa_outlined, size: 18),
                                            label: Text('Jagoda / przedmiot'),
                                          ),
                                        ],
                                      ),
                                      const Text(
                                        'Ikony przy Route 1 oznaczają informacje przypisane do tej lokacji, a nie dokładne współrzędne przedmiotów. Po wybraniu Route 1 sprawdź opis trasy, spotkania z Pokémonami i nagrodę trenera.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Mapa jest schematyczna i służy do orientacji. Dokładne lokalne mapy poszczególnych lokacji będą dodawane dopiero po weryfikacji.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Źródła online służą teraz do ręcznej weryfikacji. Nie są jeszcze danymi mapy offline aplikacji.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => launchUrl(
                                              Uri.parse(
                                                'https://theroutepedia.com/pokemon-$_letsGoSourceSlug/map/kanto',
                                              ),
                                              mode: LaunchMode.externalApplication,
                                            ),
                                            icon: const Icon(Icons.open_in_new, size: 16),
                                            label: const Text('Mapa całego Kanto'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => launchUrl(
                                              Uri.parse(
                                                'https://theroutepedia.com/pokemon-$_letsGoSourceSlug/pallet-town',
                                              ),
                                              mode: LaunchMode.externalApplication,
                                            ),
                                            icon: const Icon(Icons.home_outlined, size: 16),
                                            label: const Text('Pallet Town'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => launchUrl(
                                              Uri.parse(
                                                'https://theroutepedia.com/pokemon-$_letsGoSourceSlug/route-1',
                                              ),
                                              mode: LaunchMode.externalApplication,
                                            ),
                                            icon: const Icon(Icons.route_outlined, size: 16),
                                            label: const Text('Route 1'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => launchUrl(
                                              Uri.parse('https://altissimo1.github.io/Main-Series/LGPE/berries.html'),
                                              mode: LaunchMode.externalApplication,
                                            ),
                                            icon: const Icon(Icons.inventory_2_outlined, size: 16),
                                            label: const Text('Ukryte jagody'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => launchUrl(
                                              Uri.parse('https://bulbapedia.bulbagarden.net/wiki/Walkthrough:Pok%C3%A9mon:Let%27s_Go,_Pikachu!_and_Let%27s_Go,_Eevee!/Part_1'),
                                              mode: LaunchMode.externalApplication,
                                            ),
                                            icon: const Icon(Icons.menu_book_outlined, size: 16),
                                            label: const Text('Początek poradnika'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (_generation == 1) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Mapa poglądowa Kanto — układ schematyczny, nie mapa w skali. Węzły pokazują główne miasta i wybrane lokacje.',
                                ),
                                const SizedBox(height: 8),
                                _KantoRegionMap(
                                  selectedLocation: _searchQuery,
                                  onLocationSelected: (location) {
                                    final exists = _locations.keys.any(
                                      (name) => name.toLowerCase() == location.toLowerCase(),
                                    );
                                    if (!exists) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$location nie ma jeszcze wpisu w poradniku tej gry.'),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _searchQuery = location;
                                      _locationSearchController.text = location;
                                    });
                                  },
                                ),
                              ] else
                                const Text(
                                  'Mapa graficzna tego regionu nie została jeszcze przygotowana. Indeks poniżej pokazuje wyłącznie lokacje zapisane w poradnikach.',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Szukaj lokacji',
                    hintText: 'Np. Viridian City, Route 1',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  controller: _locationSearchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                if (_isLetsGoKanto) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dane lokacji — Let’s Go Kanto',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            normalizedQuery == 'pallet town'
                                ? 'Pallet Town'
                                : normalizedQuery == 'route 1'
                                    ? 'Route 1'
                                    : 'Wybierz Pallet Town lub Route 1, aby zobaczyć potwierdzone dane z początku gry.',
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.home_outlined, size: 18),
                                label: const Text('Pallet Town'),
                                onPressed: () {
                                  _locationSearchController.text = 'Pallet Town';
                                  setState(() => _searchQuery = 'Pallet Town');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 1'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 1';
                                  setState(() => _searchQuery = 'Route 1');
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (normalizedQuery == 'pallet town') ...[
                            const Text(
                              'Ważne miejsca',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const Text('• Dom gracza i dom rywala\n• Laboratorium Profesora Oaka'),
                            const SizedBox(height: 8),
                            const Text(
                              'Początek gry',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              '• Town Map — od mamy gracza\n'
                              '• Pokédex — od Profesora Oaka po wydarzeniu z partnerem\n'
                              '• Sportswear — od siostry rywala przy wyjściu na Route 1\n'
                              '• Razz Berries — po dostarczeniu Oak’s Parcel',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedGameId == 'lets_go_eevee'
                                  ? 'Partner: Eevee Lv. 5 • rywal: Pikachu Lv. 6'
                                  : 'Partner: Pikachu Lv. 5 • rywal: Eevee Lv. 6',
                            ),
                          ] else if (normalizedQuery == 'route 1') ...[
                            const Text(
                              'Dzikie Pokémony w trawie (poziomy 3–4)',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              _selectedGameId == 'lets_go_eevee'
                                  ? '• Pidgey — 40%\n• Rattata — 30%\n• Bellsprout — 30%'
                                  : '• Pidgey — 40%\n• Rattata — 30%\n• Oddish — 30%',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Trener: Youngster Ronny — Rattata Lv. 3; nagroda: 3 Poké Balle i ₽60.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ukryty przedmiot: Razz Berry w krzaku w północno-wschodniej części trasy. Partner musi zainteresować się krzakiem. Dokładna pozycja na mapie nie została potwierdzona.',
                            ),
                          ] else
                            const Text(
                              'Dane obejmują początek przygody: budynki i wydarzenia w Pallet Town oraz spotkania, trenera i przedmiot na Route 1. Nie pokazujemy pinezek przedmiotów, dopóki ich pozycje nie zostaną potwierdzone na podkładzie mapy.',
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Dane tekstowe offline; pozycje pikselowe przedmiotów nie są jeszcze zweryfikowane.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Schemat podróży',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Numery pokazują kolejność lokacji w poradniku, a nie ich położenie geograficzne.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Lokacje z poradników',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Chip(label: Text('${locationEntries.length}/${allLocationEntries.length}')),
                  ],
                ),
                if (selectedGame == null || games.isEmpty)
                  const _EmptyState(
                    message:
                        'W katalogu nie ma jeszcze gry przypisanej do tej generacji.',
                  )
                else if (_guidesForGame.isEmpty)
                  const _EmptyState(
                    message:
                        'Nie ma jeszcze poradnika z danymi lokacji dla tej gry. Gdy poradnik zostanie uzupełniony, lokacje pojawią się tutaj automatycznie.',
                  )
                else if (allLocationEntries.isEmpty)
                  const _EmptyState(
                    message:
                        'Poradniki tej gry nie zawierają jeszcze nazw lokacji.',
                  )
                else if (locationEntries.isEmpty)
                  const _EmptyState(
                    message:
                        'Nie znaleziono lokacji pasującej do wyszukiwania.',
                  )
                else
                  ...locationEntries.asMap().entries.map((indexedEntry) {
                    final locationIndex = indexedEntry.key;
                    final entry = indexedEntry.value;
                    final references = entry.value;
                    final first = references.first;
                    final pokemon = <String>{};
                    final items = <String>{};
                    for (final reference in references) {
                      pokemon.addAll(reference.step.pokemon);
                      items.addAll(reference.step.items);
                    }

                    return Card(
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          child: Text('${locationIndex + 1}'),
                        ),
                        title: Text(entry.key),
                        subtitle: Text(
                          '${references.length} ${references.length == 1 ? 'krok poradnika' : 'kroki poradnika'}',
                        ),
                        children: [
                          if (pokemon.isNotEmpty || items.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  ...pokemon.map((name) => Chip(
                                        avatar: const Icon(Icons.catching_pokemon,
                                            size: 16),
                                        label: Text(name),
                                      )),
                                  ...items.map((name) => Chip(
                                        avatar: const Icon(Icons.inventory_2_outlined,
                                            size: 16),
                                        label: Text(name),
                                      )),
                                ],
                              ),
                            ),
                          ...references.map((reference) => ListTile(
                                title: Text(
                                    'Krok ${reference.stepNumber}: ${reference.step.title}'),
                                subtitle: Text(reference.guide.title),
                                trailing:
                                    const Icon(Icons.open_in_new, size: 18),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => GuideScreen(
                                      guide: reference.guide,
                                    ),
                                  ),
                                ),
                              )),
                          if (first.step.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(first.step.description),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _LocationReference {
  final Guide guide;
  final GuideStep step;
  final int stepNumber;

  const _LocationReference({
    required this.guide,
    required this.step,
    required this.stepNumber,
  });
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.explore_off_outlined, size: 42),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      );
}


/// Pierwsza offline mapa poglądowa Kanto. Położenia są schematyczne;
/// nie udają dokładnej mapy gry ani nie wyznaczają niepotwierdzonych tras.
class _KantoRegionMap extends StatefulWidget {
  final String selectedLocation;
  final ValueChanged<String> onLocationSelected;

  const _KantoRegionMap({
    required this.selectedLocation,
    required this.onLocationSelected,
  });

  @override
  State<_KantoRegionMap> createState() => _KantoRegionMapState();
}

class _KantoRegionMapState extends State<_KantoRegionMap> {
  static const double _mapSize = 900;
  static const double _nearbyRadius = 95;
  final TransformationController _transformController =
      TransformationController();
  Timer? _hideLocationTimer;
  String? _visibleLocation;
  bool _initialPositionSet = false;

  @override
  void dispose() {
    _hideLocationTimer?.cancel();
    _transformController.dispose();
    super.dispose();
  }

  void _centeredLocation(Size viewportSize) {
    final sceneCenter = _transformController.toScene(
      Offset(viewportSize.width / 2, viewportSize.height / 2),
    );
    _MapPlace? nearest;
    var nearestDistance = double.infinity;
    for (final place in _KantoMapPainter.places) {
      final dx = sceneCenter.dx - place.x * _mapSize;
      final dy = sceneCenter.dy - place.y * _mapSize;
      final distance = dx * dx + dy * dy;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = place;
      }
    }
    final nextLocation =
        nearest != null && nearestDistance <= _nearbyRadius * _nearbyRadius
            ? nearest.name
            : null;
    if (nextLocation == _visibleLocation) return;
    setState(() => _visibleLocation = nextLocation);
    _hideLocationTimer?.cancel();
    if (nextLocation != null) {
      _hideLocationTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _visibleLocation = null);
      });
    }
  }

  void _selectTappedPlace(Offset tap) {
    _MapPlace? nearest;
    var nearestDistance = double.infinity;
    for (final place in _KantoMapPainter.places) {
      final dx = tap.dx - place.x * _mapSize;
      final dy = tap.dy - place.y * _mapSize;
      final distance = dx * dx + dy * dy;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = place;
      }
    }
    if (nearest != null && nearestDistance < 38 * 38) {
      _showLocation(nearest.name);
      widget.onLocationSelected(nearest.name);
    }
  }

  void _showLocation(String name) {
    _hideLocationTimer?.cancel();
    setState(() => _visibleLocation = name);
    _hideLocationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _visibleLocation = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: screenWidth < 500 ? 0.82 : 1.25,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!_initialPositionSet) {
              _initialPositionSet = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _transformController.value = Matrix4.identity()
                  ..translate(
                    (constraints.maxWidth - _mapSize) / 2,
                    (constraints.maxHeight - _mapSize) / 2,
                  );
              });
            }
            return Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    constrained: false,
                    minScale: 0.55,
                    maxScale: 4,
                    boundaryMargin: const EdgeInsets.all(160),
                    onInteractionUpdate: (_) =>
                        _centeredLocation(constraints.biggest),
                    onInteractionEnd: (_) =>
                        _centeredLocation(constraints.biggest),
                    child: SizedBox(
                      width: _mapSize,
                      height: _mapSize,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) =>
                            _selectTappedPlace(details.localPosition),
                        child: CustomPaint(
                          painter: _KantoMapPainter(
                            land: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            route: Theme.of(context).colorScheme.primary,
                            label: Theme.of(context).colorScheme.onSurface,
                            water: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.45),
                            selectedLocation: widget.selectedLocation,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _visibleLocation == null
                          ? const SizedBox(
                              key: ValueKey('map-location-empty'),
                              height: 0,
                            )
                          : Container(
                              key: ValueKey(_visibleLocation),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface
                                    .withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 12,
                                    color: Colors.black26,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                _visibleLocation!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onInverseSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        'Przesuń • przybliż',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KantoMapPainter extends CustomPainter {
  final Color land;
  final Color route;
  final Color label;
  final Color water;
  final String selectedLocation;

  const _KantoMapPainter({
    required this.land,
    required this.route,
    required this.label,
    required this.water,
    required this.selectedLocation,
  });

  static const places = <_MapPlace>[
    _MapPlace('Pallet Town', 0.22, 0.82),
    _MapPlace('Route 1', 0.25, 0.75),
    _MapPlace('Viridian City', 0.28, 0.68),
    _MapPlace('Pewter City', 0.25, 0.43),
    _MapPlace('Cerulean City', 0.63, 0.35),
    _MapPlace('Vermilion City', 0.57, 0.65),
    _MapPlace('Lavender Town', 0.78, 0.48),
    _MapPlace('Celadon City', 0.43, 0.52),
    _MapPlace('Saffron City', 0.59, 0.49),
    _MapPlace('Fuchsia City', 0.65, 0.82),
    _MapPlace('Cinnabar Island', 0.12, 0.94),
    _MapPlace('Indigo Plateau', 0.10, 0.23),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = water);
    final p = (double x, double y) => Offset(x * size.width, y * size.height);

    final coast = Path()
      ..moveTo(size.width * .08, size.height * .18)
      ..cubicTo(size.width * .18, size.height * .06, size.width * .42, size.height * .08, size.width * .53, size.height * .16)
      ..cubicTo(size.width * .69, size.height * .12, size.width * .87, size.height * .24, size.width * .87, size.height * .39)
      ..cubicTo(size.width * .96, size.height * .52, size.width * .83, size.height * .67, size.width * .79, size.height * .78)
      ..cubicTo(size.width * .74, size.height * .92, size.width * .51, size.height * .91, size.width * .42, size.height * .84)
      ..cubicTo(size.width * .29, size.height * .91, size.width * .16, size.height * .83, size.width * .18, size.height * .70)
      ..cubicTo(size.width * .08, size.height * .57, size.width * .12, size.height * .40, size.width * .08, size.height * .18)
      ..close();
    canvas.drawPath(coast, Paint()..color = land);
    canvas.drawPath(coast, Paint()
      ..color = route.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Approximate route network for orientation, not a scale-accurate game map.
    const links = <(int, int)>[
      (0, 1), (1, 2), (2, 3), (3, 4), (4, 8), (8, 5),
      (5, 9), (2, 7), (7, 8), (8, 6), (3, 11), (5, 10),
    ];
    final roadPaint = Paint()
      ..color = route.withValues(alpha: .72)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final link in links) {
      final a = places[link.$1];
      final b = places[link.$2];
      canvas.drawLine(p(a.x, a.y), p(b.x, b.y), roadPaint);
    }

    for (final place in places) {
      final point = p(place.x, place.y);
      final isSelected = place.name.toLowerCase() == selectedLocation.toLowerCase();
      if (isSelected) {
        canvas.drawCircle(point, 13, Paint()..color = route.withValues(alpha: .24));
      }
      if (place.name == 'Pallet Town') {
        _drawHouse(canvas, point + const Offset(0, -16), route);
      } else if (place.name == 'Route 1') {
        // A berry and Poké Ball indicate guide information for this route.
        // They are area markers only; they do not claim exact item coordinates.
        _drawBerry(canvas, point + const Offset(13, -15));
        _drawPokeball(canvas, point + const Offset(-12, -15));
      }
      canvas.drawCircle(point, isSelected ? 8 : 7, Paint()..color = route);
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
      final text = TextPainter(
        text: TextSpan(
          text: place.name,
          style: TextStyle(
            color: label,
            fontSize: size.width < 360 ? 9 : 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: size.width * .42);
      var dx = point.dx + 9;
      if (dx + text.width > size.width - 4) dx = point.dx - text.width - 9;
      var dy = point.dy - text.height / 2;
      dy = dy.clamp(4.0, size.height - text.height - 4);
      text.paint(canvas, Offset(dx, dy));
    }

    final title = TextPainter(
      text: TextSpan(
        text: 'KANTO',
        style: TextStyle(
          color: route,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(canvas, Offset(size.width - title.width - 14, 12));
  }

  void _drawPokeball(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 7, Paint()..color = Colors.white);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 7),
      3.14159,
      3.14159,
      true,
      Paint()..color = Colors.red.shade600,
    );
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      center + const Offset(-6.5, 0),
      center + const Offset(6.5, 0),
      Paint()..color = Colors.black87..strokeWidth = 1.5,
    );
    canvas.drawCircle(center, 2.2, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      2.2,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawBerry(Canvas canvas, Offset center) {
    final berryPaint = Paint()..color = Colors.pink.shade400;
    canvas.drawCircle(center + const Offset(-3, 1), 4, berryPaint);
    canvas.drawCircle(center + const Offset(3, 1), 4, berryPaint);
    canvas.drawCircle(center + const Offset(0, 4), 4, berryPaint);
    canvas.drawLine(
      center + const Offset(0, -1),
      center + const Offset(1, -7),
      Paint()
        ..color = Colors.green.shade700
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 8, Paint()..color = Colors.white.withValues(alpha: .75)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawHouse(Canvas canvas, Offset center, Color color) {
    final roof = Path()
      ..moveTo(center.dx - 9, center.dy)
      ..lineTo(center.dx, center.dy - 8)
      ..lineTo(center.dx + 9, center.dy)
      ..close();
    canvas.drawPath(roof, Paint()..color = Colors.brown.shade500);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 7, center.dy, 14, 10),
      Paint()..color = Colors.orange.shade100,
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 2, center.dy + 3, 4, 7),
      Paint()..color = color,
    );
    canvas.drawPath(
      roof,
      Paint()..color = Colors.black45..style = PaintingStyle.stroke..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _KantoMapPainter oldDelegate) =>
      land != oldDelegate.land ||
      route != oldDelegate.route ||
      label != oldDelegate.label ||
      water != oldDelegate.water ||
      selectedLocation != oldDelegate.selectedLocation;
}

class _MapPlace {
  final String name;
  final double x;
  final double y;

  const _MapPlace(this.name, this.x, this.y);
}
