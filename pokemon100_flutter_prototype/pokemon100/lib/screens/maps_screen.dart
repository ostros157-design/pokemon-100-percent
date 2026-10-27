import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final locationEntries = _locations.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

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
                              const Text(
                                'Pełna mapa graficzna nie jest jeszcze dostępna. Poniższy indeks pokazuje wyłącznie lokacje zapisane w poradnikach — nie dopisuje fikcyjnych tras ani przedmiotów.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Lokacje z poradników',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Chip(label: Text('${locationEntries.length}')),
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
                else if (locationEntries.isEmpty)
                  const _EmptyState(
                    message:
                        'Poradniki tej gry nie zawierają jeszcze nazw lokacji.',
                  )
                else
                  ...locationEntries.map((entry) {
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
                        leading: const Icon(Icons.place_outlined),
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
