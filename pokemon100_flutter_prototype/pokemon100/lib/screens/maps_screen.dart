import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/games_data.dart';
import '../data/guides_data.dart';
import '../data/pokemon_data.dart';
import '../models/game.dart';
import '../models/guide.dart';
import 'guide_screen.dart';
import 'pokemon_details_screen.dart';

/// Offline regional location indexes are loaded from bundled, source-tracked JSON.
/// A schematic or decorative view is never presented as a scale-accurate game map.
class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  int _generation = 1;
  String? _selectedGameId;
  String? _selectedMapRegionOverride;
  bool _loading = true;
  String _searchQuery = '';
  final Set<String> _completedStepKeys = <String>{};
  final TextEditingController _locationSearchController = TextEditingController();
  final Map<String, Map<String, dynamic>> _mapIndexes = <String, Map<String, dynamic>>{};
  bool _mapIndexesLoading = true;

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
    _loadMapIndexes();
  }

  Future<void> _loadMapIndexes() async {
    const assets = <String>[
      'assets/data/maps/lets_go_kanto_audit.json',
      'assets/data/maps/kanto_audit.json',
      'assets/data/maps/sevii_islands_audit.json',
      'assets/data/maps/johto_audit.json',
      'assets/data/maps/hoenn_audit.json',
      'assets/data/maps/sinnoh_audit.json',
      'assets/data/maps/unova_audit.json',
      'assets/data/maps/kalos_audit.json',
      'assets/data/maps/alola_audit.json',
      'assets/data/maps/galar_audit.json',
      'assets/data/maps/hisui_audit.json',
      'assets/data/maps/paldea_audit.json',
    ];
    final loaded = <String, Map<String, dynamic>>{};
    for (final asset in assets) {
      try {
        final decoded = jsonDecode(await rootBundle.loadString(asset));
        if (decoded is Map<String, dynamic> &&
            decoded['region'] is String &&
            decoded['locations'] is List) {
          loaded[decoded['region'] as String] = decoded;
        }
      } catch (_) {
        // A missing regional file should not prevent the map screen opening.
      }
    }
    if (!mounted) return;
    setState(() {
      _mapIndexes
        ..clear()
        ..addAll(loaded);
      _mapIndexesLoading = false;
    });
  }

  String get _defaultMapIndexRegionName {
    final gameId = _selectedGameId;
    if (_isLetsGoKanto) return "Kanto (Let's Go)";
    if (gameId == 'legends_arceus') return 'Hisui';
    if ({'red', 'blue', 'yellow', 'fire_red', 'leaf_green'}
        .contains(gameId)) return 'Kanto';
    if ({'gold', 'silver', 'crystal'}.contains(gameId)) return 'Johto';
    if ({'ruby', 'sapphire', 'emerald', 'omega_ruby', 'alpha_sapphire'}
        .contains(gameId)) return 'Hoenn';
    if ({'brilliant_diamond', 'shining_pearl'}.contains(gameId)) return 'Sinnoh';
    if ({'x', 'y'}.contains(gameId)) return 'Kalos';
    if ({'sun', 'moon', 'ultra_sun', 'ultra_moon'}.contains(gameId)) {
      return 'Alola';
    }
    if ({'sword', 'shield'}.contains(gameId)) return 'Galar';
    if ({'scarlet', 'violet'}.contains(gameId)) return 'Paldea + DLC';
    return _regionName;
  }

  String get _mapIndexRegionName =>
      _selectedMapRegionOverride ?? _defaultMapIndexRegionName;

  List<String> get _availableMapRegionsForSelectedGame {
    if ({'gold', 'silver', 'crystal'}.contains(_selectedGameId)) {
      return const <String>['Johto', 'Kanto'];
    }
    if ({'fire_red', 'leaf_green'}.contains(_selectedGameId)) {
      return const <String>['Kanto', 'Sevii Islands'];
    }
    return <String>[_defaultMapIndexRegionName];
  }

  Map<String, dynamic>? get _activeMapIndex =>
      _mapIndexes[_mapIndexRegionName];

  List<Map<String, dynamic>> get _activeMapIndexLocations {
    final raw = _activeMapIndex?['locations'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  bool _matchesMapLocation(
    Map<String, dynamic> location,
    String query,
  ) {
    if (query.isEmpty) return true;
    final features = location['features'] as List?;
    final connections = location['connectsTo'] as List?;
    final searchable = <String>[
      location['name'] as String? ?? '',
      location['id'] as String? ?? '',
      location['kind'] as String? ?? '',
      location['notes'] as String? ?? '',
      location['dataStatus'] as String? ?? '',
      location['parentRegion'] as String? ?? '',
      location['province'] as String? ?? '',
      if (features != null) ...features.whereType<String>(),
      if (connections != null) ...connections.whereType<String>(),
    ];
    return searchable.any((value) => value.toLowerCase().contains(query));
  }

  String _normalizePokemonName(String name) => name
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('‘', "'");

  Widget _buildLetsGoEncounterPanel(
    BuildContext context,
    String locationName,
  ) {
    final index = _mapIndexes["Kanto (Let's Go)"];
    final rawLocations = index?['locations'];
    if (rawLocations is! List) return const SizedBox.shrink();

    Map<String, dynamic>? location;
    for (final candidate in rawLocations.whereType<Map<String, dynamic>>()) {
      final name = candidate['name'] as String? ?? '';
      if (name.toLowerCase() == locationName.toLowerCase()) {
        location = candidate;
        break;
      }
    }
    if (location == null) return const SizedBox.shrink();

    final encounterSource =
        location['wildPokemonDetails'] ?? location['encounters'];
    final encounters = _mapWildPokemonEntries(encounterSource);
    final notableEntries = <String>[
      ...((location['notablePokemon'] as List?)
              ?.map((value) => value.toString()) ??
          const <String>[]),
      if (location['rareEncounter'] is Map &&
          (location['rareEncounter'] as Map)['name'] != null)
        (location['rareEncounter'] as Map)['name'].toString(),
    ].where((name) => name.trim().isNotEmpty).toSet().toList();
    final notablePokemon = notableEntries.where((name) {
      return pokemonList.any((candidate) =>
          _normalizePokemonName(candidate.name) ==
          _normalizePokemonName(name));
    }).toList();
    final notableNotes = notableEntries
        .where((name) => !notablePokemon.contains(name))
        .toList();
    final items = (location['items'] as List?)
            ?.map((value) => value.toString())
            .where((value) => value.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    final locationNotes = location['notes']?.toString().trim() ?? '';
    final trainerCount = location['trainerCount'] is num
        ? (location['trainerCount'] as num).toInt()
        : int.tryParse(location['trainerCount']?.toString() ?? '');
    final hiddenItemCount = location['hiddenItemCount'] is num
        ? (location['hiddenItemCount'] as num).toInt()
        : int.tryParse(location['hiddenItemCount']?.toString() ?? '');
    final dataStatus = location['dataStatus']?.toString() ?? '';
    if (encounters.isEmpty &&
        notablePokemon.isEmpty &&
        notableNotes.isEmpty &&
        items.isEmpty &&
        locationNotes.isEmpty &&
        trainerCount == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pokémony i spotkania — $locationName',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Dane spotkań dla tej lokacji nie są jeszcze kompletne w indeksie offline. Nie pokazujemy zgadywanych Pokémonów.',
              ),
            ],
          ),
        ),
      );
    }

    Widget pokemonChip(String name, {String? details}) {
      final matches = pokemonList.where(
        (candidate) =>
            _normalizePokemonName(candidate.name) ==
            _normalizePokemonName(name),
      );
      final pokemon = matches.isEmpty ? null : matches.first;
      return ActionChip(
        avatar: const Icon(Icons.catching_pokemon, size: 18),
        label: Text(details == null || details.isEmpty
            ? name
            : '$name • $details'),
        onPressed: pokemon == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PokemonDetailsScreen(
                      pokemon: pokemon,
                      gameId: _selectedGameId,
                    ),
                  ),
                ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pokémony i spotkania — $locationName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (encounters.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: encounters.map((entry) {
                  final details = <String>[
                    if (entry['levels'] != null) 'Lv. ${entry['levels']}',
                    if (entry['rate'] != null) '${entry['rate']}%',
                    if (entry['method'] != null) entry['method']!,
                  ];
                  return pokemonChip(
                    entry['name']!,
                    details: details.join(' • '),
                  );
                }).toList(),
              ),
            ],
            if (notablePokemon.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Ważne / specjalne Pokémony',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: notablePokemon.map((name) {
                  return pokemonChip(name, details: 'specjalny');
                }).toList(),
              ),
            ],
            if (notableNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                notableNotes.join('\n'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (locationNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                locationNotes,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (trainerCount != null || hiddenItemCount != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (trainerCount != null)
                    Chip(
                      avatar: const Icon(Icons.sports_martial_arts, size: 16),
                      label: Text('Trenerzy: $trainerCount'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (hiddenItemCount != null)
                    Chip(
                      avatar: const Icon(Icons.search, size: 16),
                      label: Text('Ukryte przedmioty: $hiddenItemCount'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            if (items.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text('Przedmioty (' + items.length.toString() + ')'),
                subtitle: const Text(
                  'Lista tekstowa — bez niepotwierdzonych pinezek',
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(items.map((item) => '• $item').join('\n')),
                  ),
                ],
              ),
            if (dataStatus.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Status danych: ' + dataStatus.replaceAll('_', ' '),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Dotknij nazwy Pokémona, aby otworzyć Pokédex. Listy przedmiotów i trenerów są informacyjne; pinezki pojawią się dopiero po potwierdzeniu ich pozycji na mapie.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _mapWildPokemonEntries(dynamic raw) {
    if (raw is! Map) return const <Map<String, String>>[];
    final variantKey = _selectedGameId == 'lets_go_eevee'
        ? 'lets_go_eevee'
        : 'lets_go_pikachu';
    final globalRange = raw['levels'];
    final globalLevels = globalRange is List && globalRange.length >= 2
        ? '${globalRange[0]}–${globalRange[1]}'
        : '';
    final result = <Map<String, String>>[];

    void addEntries(dynamic entries, {String? method}) {
      if (entries is! List) return;
      for (final entry in entries) {
        if (entry is Map) {
          final name = entry['name']?.toString() ?? '';
          if (name.isEmpty) continue;
          final range = entry['levelRange'];
          final levels = range is List && range.length >= 2
              ? '${range[0]}–${range[1]}'
              : (entry['level'] != null
                  ? entry['level'].toString()
                  : globalLevels);
          result.add(<String, String>{
            'name': name,
            if (levels.isNotEmpty) 'levels': levels,
            if (entry['ratePercent'] != null)
              'rate': entry['ratePercent'].toString(),
            if ((entry['method'] ?? method) != null)
              'method': (entry['method'] ?? method).toString(),
          });
        } else if (entry is List && entry.isNotEmpty) {
          final name = entry[0].toString();
          if (name.isEmpty) continue;
          result.add(<String, String>{
            'name': name,
            if (globalLevels.isNotEmpty) 'levels': globalLevels,
            if (entry.length > 1 && entry[1] != null)
              'rate': entry[1].toString(),
            if (method != null) 'method': method,
          });
        } else if (entry is String && entry.isNotEmpty) {
          result.add(<String, String>{
            'name': entry,
            if (globalLevels.isNotEmpty) 'levels': globalLevels,
            if (method != null) 'method': method,
          });
        }
      }
    }

    final selected = raw[variantKey];
    if (selected is List) {
      addEntries(selected);
      return result;
    }
    if (selected is Map) {
      for (final entry in selected.entries) {
        final value = entry.value;
        if (value is Map) {
          addEntries([value], method: entry.key.toString());
        }
      }
      return result;
    }

    // Cave encounter data is grouped by floor (for example 1F/B1F/B2F),
    // while route data is grouped by game version. Do not fall back to the
    // other version's list if the selected game has no verified entry.
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      if (key == 'levels' ||
          key == 'status' ||
          key == 'sourceIds' ||
          key == 'rareEncounter' ||
          key.startsWith('lets_go_')) {
        continue;
      }
      if (entry.value is List) addEntries(entry.value, method: key);
    }
    return result;
  }

  String _mapWildPokemonSummary(dynamic raw) {
    if (raw is! Map) return '';
    final variantKey = _selectedGameId == 'lets_go_eevee'
        ? 'lets_go_eevee'
        : 'lets_go_pikachu';
    final levelRange = raw['levels'];
    final globalLevels = levelRange is List && levelRange.length >= 2
        ? '${levelRange[0]}–${levelRange[1]}'
        : '';

    String formatEntry(dynamic entry) {
      if (entry is Map) {
        final name = entry['name']?.toString() ?? '';
        if (name.isEmpty) return '';
        final range = entry['levelRange'];
        final levels = range is List && range.length >= 2
            ? ' Lv. ${range[0]}–${range[1]}'
            : globalLevels.isNotEmpty
                ? ' Lv. $globalLevels'
                : '';
        final rate = entry['ratePercent'];
        final rateText = rate == null ? '' : ' • $rate%';
        final method = entry['method'] as String?;
        final methodText = method == null ? '' : ' • $method';
        return '$name$levels$rateText$methodText';
      }
      if (entry is List && entry.isNotEmpty) {
        final name = entry[0].toString();
        final rate = entry.length > 1 ? entry[1] : null;
        final levels = globalLevels.isEmpty ? '' : ' Lv. $globalLevels';
        return '$name$levels${rate == null ? '' : ' • $rate%'}';
      }
      return '';
    }

    final selected = raw[variantKey];
    final lines = <String>[];
    if (selected is List) {
      lines.addAll(selected.map(formatEntry).where((line) => line.isNotEmpty));
    } else {
      for (final key in raw.keys) {
        if (key == 'levels' || key == 'status' || key == 'sourceIds') continue;
        final entries = raw[key];
        if (entries is! List) continue;
        final formatted = entries.map(formatEntry).where((line) => line.isNotEmpty).toList();
        if (formatted.isNotEmpty) {
          lines.add('${key.toString()}: ${formatted.join(' • ')}');
        }
      }
    }
    return lines.join('\n');
  }

  String _mapItemsSummary(dynamic raw) {
    if (raw is! List) return '';
    final lines = <String>[];
    for (final item in raw) {
      if (item is String) {
        lines.add(item);
      } else if (item is Map) {
        final name = item['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        final quantity = item['quantity'];
        final amount = quantity is num && quantity > 1 ? ' ×$quantity' : '';
        final location = item['locationDescription'] as String?;
        lines.add('$name$amount${location == null ? '' : ' — $location'}');
      }
    }
    return lines.take(20).join('\n');
  }

  String _mapTrainersSummary(dynamic raw) {
    if (raw is! List) return '';
    final lines = <String>[];
    for (final trainer in raw) {
      if (trainer is String) {
        lines.add(trainer);
      } else if (trainer is Map) {
        final name = trainer['name']?.toString() ?? 'Trener';
        final team = trainer['team'];
        final teamSummary = team is List
            ? team.whereType<Map>().map((member) {
                final pokemon = member['name']?.toString() ?? '';
                final level = member['level'];
                return pokemon.isEmpty ? '' : '$pokemon${level == null ? '' : ' Lv. $level'}';
              }).where((line) => line.isNotEmpty).join(', ')
            : '';
        final reward = trainer['reward'];
        final rewardSummary = reward is Map
            ? reward.entries.map((entry) => '${entry.key}: ${entry.value}').join(', ')
            : '';
        lines.add('$name${teamSummary.isEmpty ? '' : ' — $teamSummary'}${rewardSummary.isEmpty ? '' : ' • $rewardSummary'}');
      }
    }
    return lines.take(20).join('\n');
  }

  String _mapEventsSummary(dynamic raw) {
    if (raw is! List) return '';
    return raw.whereType<Map>().map((event) {
      final name = event['name']?.toString() ?? '';
      final note = event['note']?.toString() ?? '';
      if (name.isEmpty) return '';
      return '$name${note.isEmpty ? '' : ' — $note'}';
    }).where((line) => line.isNotEmpty).take(12).join('\n');
  }

  Map<String, dynamic>? get _selectedMapIndexLocation {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return null;
    for (final location in _activeMapIndexLocations) {
      if ((location['name'] as String? ?? '').toLowerCase() == query) {
        return location;
      }
    }
    return null;
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
    await _loadCompletedSteps();
  }

  Future<void> _loadCompletedSteps() async {
    final preferences = await SharedPreferences.getInstance();
    final completed = <String>{};
    for (final guide in _guidesForGame) {
      final saved = preferences.getStringList(
            'guide_progress_${guide.gameId}_${guide.id}',
          ) ??
          const <String>[];
      for (final rawIndex in saved) {
        final index = int.tryParse(rawIndex);
        if (index != null && index >= 0 && index < guide.steps.length) {
          completed.add('${guide.id}:$index');
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _completedStepKeys
        ..clear()
        ..addAll(completed);
    });
  }

  int _completedCount(List<_LocationReference> references) =>
      references.where((reference) =>
          _completedStepKeys.contains(
            '${reference.guide.id}:${reference.stepNumber - 1}',
          )).length;

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
    setState(() {
      _selectedGameId = gameId;
      _selectedMapRegionOverride = null;
    });
    await _loadCompletedSteps();
  }

  @override
  Widget build(BuildContext context) {
    final games = _gamesForGeneration;
    final selectedGame = _selectedGame;
    // Preserve first appearance in the guide: this approximates the player's
    // route progression better than alphabetical sorting.
    final allLocationEntries = _locations.entries.toList();
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    // Every named node on the full Kanto schematic can be selected, not
    // only the first few tutorial locations.
    final localSchematicLocations = _KantoMapPainter.places
        .map((place) => place.name)
        .toList(growable: false);
    String? selectedLocalLocation;
    for (final location in localSchematicLocations) {
      if (location.toLowerCase() == normalizedQuery) {
        selectedLocalLocation = location;
        break;
      }
    }
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
                  'Wybierz grę i region, aby przeglądać offline indeks lokacji. Dokładne mapy, wnętrza i pinezki są uzupełniane etapami.',
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
                if (_availableMapRegionsForSelectedGame.length > 1) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _availableMapRegionsForSelectedGame.contains(_mapIndexRegionName)
                        ? _mapIndexRegionName
                        : _defaultMapIndexRegionName,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Region do wyświetlenia',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableMapRegionsForSelectedGame
                        .map((region) => DropdownMenuItem<String>(
                              value: region,
                              child: Text(region),
                            ))
                        .toList(),
                    onChanged: (region) {
                      if (region == null) return;
                      setState(() {
                        _selectedMapRegionOverride =
                            region == _defaultMapIndexRegionName ? null : region;
                        _searchQuery = '';
                        _locationSearchController.clear();
                      });
                    },
                  ),
                ],
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
                              if (!_isLetsGoKanto && _selectedMapIndexLocation != null)
                  Builder(
                    builder: (context) {
                      final location = _selectedMapIndexLocation!;
                      final locationName = location['name'] as String? ?? 'Lokacja';
                      final kind = location['kind'] as String? ?? 'lokacja';
                      final status = (location['dataStatus'] as String? ?? 'status nieznany')
                          .replaceAll('_', ' ');
                      final notes = location['notes'] as String?;
                      final features = (location['features'] as List?)
                              ?.whereType<String>()
                              .toList() ??
                          const <String>[];
                      final wildSummary =
                          _mapWildPokemonSummary(location['wildPokemonDetails']);
                      final itemsSummary = _mapItemsSummary(location['items']);
                      final trainersSummary = _mapTrainersSummary(location['trainers']);
                      final eventsSummary = _mapEventsSummary(location['events']);
                      final connectedLocations = (location['connectsTo'] as List?)
                              ?.whereType<String>()
                              .map((id) => _activeMapIndexLocations.firstWhere(
                                    (candidate) => candidate['id'] == id,
                                    orElse: () => <String, dynamic>{'id': id, 'name': id},
                                  ))
                              .toList() ??
                          const <Map<String, dynamic>>[];
                      final sourceIds = (location['sourceIds'] as List?)
                              ?.whereType<String>()
                              .toSet() ??
                          <String>{};
                      final sourceRecords = (_activeMapIndex?['sources'] as List?)
                              ?.whereType<Map<String, dynamic>>()
                              .where((source) => sourceIds.contains(source['id']))
                              .toList() ??
                          const <Map<String, dynamic>>[];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(locationName, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text('Typ: $kind • Status: $status'),
                              if (notes != null && notes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(notes),
                              ],
                              if (features.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('Ważne miejsca', style: TextStyle(fontWeight: FontWeight.w700)),
                                Text(features.join(' • ')),
                              ],
                              if (wildSummary.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('Pokémony do złapania', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _mapWildPokemonEntries(
                                    location['wildPokemonDetails'],
                                  ).map((entry) {
                                    final name = entry['name']!;
                                    final pokemon = pokemonList.cast<dynamic>().firstWhere(
                                      (candidate) => _normalizePokemonName(candidate.name) == _normalizePokemonName(name),
                                      orElse: () => null,
                                    );
                                    final details = <String>[
                                      if (entry['levels'] != null) 'Lv. ${entry['levels']}',
                                      if (entry['rate'] != null) '${entry['rate']}%',
                                      if (entry['method'] != null) entry['method']!,
                                    ];
                                    return ActionChip(
                                      avatar: const Icon(Icons.catching_pokemon, size: 18),
                                      label: Text(
                                        details.isEmpty ? name : '$name • ${details.join(' • ')}',
                                      ),
                                      onPressed: pokemon == null
                                          ? null
                                          : () => Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => PokemonDetailsScreen(
                                                    pokemon: pokemon,
                                                    gameId: _selectedGameId,
                                                  ),
                                                ),
                                              ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Wybierz nazwę, aby otworzyć wpis Pokédexu. Szanse spotkania pokazujemy tylko tam, gdzie są zapisane w danych.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                              if (itemsSummary.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('Przedmioty', style: TextStyle(fontWeight: FontWeight.w700)),
                                Text(itemsSummary),
                              ],
                              if (trainersSummary.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('Trenerzy i walki', style: TextStyle(fontWeight: FontWeight.w700)),
                                Text(trainersSummary),
                              ],
                              if (eventsSummary.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('Wydarzenia i nagrody', style: TextStyle(fontWeight: FontWeight.w700)),
                                Text(eventsSummary),
                              ],
                              if (location['province'] is String) ...[
                                const SizedBox(height: 8),
                                Text('Prowincja: ${location['province']}'),
                              ],
                              if (location['parentRegion'] is String) ...[
                                const SizedBox(height: 8),
                                Text('Obszar nadrzędny: ${location['parentRegion']}'),
                              ],
                              if (connectedLocations.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('Połączenia / dostęp', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: connectedLocations.map((connected) {
                                    final connectedName =
                                        connected['name'] as String? ?? 'Lokacja';
                                    return ActionChip(
                                      avatar: const Icon(Icons.place_outlined, size: 16),
                                      label: Text(connectedName),
                                      onPressed: () {
                                        _locationSearchController.text = connectedName;
                                        setState(() => _searchQuery = connectedName);
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                              if (sourceRecords.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('Źródła do sprawdzenia', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: sourceRecords.map((source) {
                                    final sourceId = source['id'] as String? ?? 'Źródło';
                                    final sourceUrl = source['url'] as String? ?? '';
                                    final sourceLabel = source['scope'] as String? ?? sourceId;
                                    return ActionChip(
                                      avatar: const Icon(Icons.open_in_new, size: 16),
                                      label: Text(sourceLabel, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      onPressed: () async {
                                        final uri = Uri.tryParse(sourceUrl);
                                        if (uri != null &&
                                            (uri.scheme == 'https' || uri.scheme == 'http')) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                              const SizedBox(height: 8),
                              const Text('Dokładne pozycje na mapie i pinezki wymagają osobnej weryfikacji dla wybranej wersji gry.'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
                                        '• Schematy lokalne są dostępne dla Pallet Town, Route 1, Viridian City, Route 2, Viridian Forest, Pewter City i Pewter Gym.\n• Symbole pokazują wyłącznie orientacyjny układ i informacje opisane w poradniku. Nie oznaczają dokładnych współrzędnych ani potwierdzonych pozycji przedmiotów.',
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
                                        'Legenda i warstwy danych',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: const [
                                          Chip(
                                            avatar: Icon(Icons.location_city_outlined, size: 18),
                                            label: Text('Miasta'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.alt_route, size: 18),
                                            label: Text('Trasy'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.catching_pokemon, size: 18),
                                            label: Text('Pokémony'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.inventory_2_outlined, size: 18),
                                            label: Text('Przedmioty'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.sports_martial_arts_outlined, size: 18),
                                            label: Text('Trenerzy / walki'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.checklist_outlined, size: 18),
                                            label: Text('Znajdźki 100%'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Miasta i trasy są pokazane schematycznie. Pokémony, przedmioty, trenerzy i znajdźki są kategoriami danych do uzupełnienia z poradników; na tej mapie nie mają jeszcze dokładnych pinezek. Nie traktuj ich położenia jako zweryfikowanego.',
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
                                  'Dokładna mapa graficzna tego regionu nie została jeszcze przygotowana. Poniższy indeks offline pochodzi z pliku regionalnego; połączenia, wnętrza i pinezki wymagają dalszej weryfikacji dla wybranej wersji gry.',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_mapIndexRegionName == 'Kanto' && !_isLetsGoKanto) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mapa offline Kanto — schemat orientacyjny',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Schemat pokazuje ogólny układ Kanto. Nie jest mapą w skali i nie oznacza dokładnych pozycji przedmiotów, trenerów ani Pokémonów dla wybranej wersji.',
                          ),
                          const SizedBox(height: 8),
                          _KantoRegionMap(
                            selectedLocation: _searchQuery,
                            onLocationSelected: (location) {
                              _locationSearchController.text = location;
                              setState(() => _searchQuery = location);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
                if (_mapIndexesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  )
                else if (_activeMapIndex != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Indeks mapy offline — ${_activeMapIndex!['region']}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_activeMapIndexLocations.length} lokacji w katalogu. To indeks źródłowy, nie gotowa mapa w skali; pozycje pinezek wymagają dalszej weryfikacji.',
                          ),
                          const SizedBox(height: 8),
                          ..._activeMapIndexLocations
                              .where((location) => _matchesMapLocation(location, normalizedQuery))
                              .take(normalizedQuery.isEmpty ? 8 : 15)
                              .map((location) {
                            final name = location['name'] as String? ?? 'Lokacja';
                            final kind = location['kind'] as String? ?? 'lokacja';
                            final status = (location['dataStatus'] as String? ?? 'status nieznany')
                                .replaceAll('_', ' ');
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.place_outlined),
                              title: Text(name),
                              subtitle: Text('$kind • $status'),
                              onTap: () {
                                _locationSearchController.text = name;
                                setState(() => _searchQuery = name);
                              },
                            );
                          }),
                          if (_activeMapIndexLocations
                              .where((location) => _matchesMapLocation(location, normalizedQuery))
                              .isEmpty)
                            const Text('Brak lokacji o tej nazwie w indeksie regionu.'),
                        ],
                      ),
                    ),
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
                              ActionChip(
                                avatar: const Icon(Icons.location_city_outlined, size: 18),
                                label: const Text('Viridian City'),
                                onPressed: () {
                                  _locationSearchController.text = 'Viridian City';
                                  setState(() => _searchQuery = 'Viridian City');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.forest_outlined, size: 18),
                                label: const Text('Viridian Forest'),
                                onPressed: () {
                                  _locationSearchController.text = 'Viridian Forest';
                                  setState(() => _searchQuery = 'Viridian Forest');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.location_city_outlined, size: 18),
                                label: const Text('Pewter City'),
                                onPressed: () {
                                  _locationSearchController.text = 'Pewter City';
                                  setState(() => _searchQuery = 'Pewter City');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 3'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 3';
                                  setState(() => _searchQuery = 'Route 3');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.terrain_outlined, size: 18),
                                label: const Text('Mt. Moon'),
                                onPressed: () {
                                  _locationSearchController.text = 'Mt. Moon';
                                  setState(() => _searchQuery = 'Mt. Moon');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 4'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 4';
                                  setState(() => _searchQuery = 'Route 4');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.location_city_outlined, size: 18),
                                label: const Text('Cerulean City'),
                                onPressed: () {
                                  _locationSearchController.text = 'Cerulean City';
                                  setState(() => _searchQuery = 'Cerulean City');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 5'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 5';
                                  setState(() => _searchQuery = 'Route 5');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 6'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 6';
                                  setState(() => _searchQuery = 'Route 6');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 7'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 7';
                                  setState(() => _searchQuery = 'Route 7');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 8'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 8';
                                  setState(() => _searchQuery = 'Route 8');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 9'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 9';
                                  setState(() => _searchQuery = 'Route 9');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 10'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 10';
                                  setState(() => _searchQuery = 'Route 10');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.location_city_outlined, size: 18),
                                label: const Text('Lavender Town'),
                                onPressed: () {
                                  _locationSearchController.text = 'Lavender Town';
                                  setState(() => _searchQuery = 'Lavender Town');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 11'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 11';
                                  setState(() => _searchQuery = 'Route 11');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 12'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 12';
                                  setState(() => _searchQuery = 'Route 12');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.location_city_outlined, size: 18),
                                label: const Text('Fuchsia City'),
                                onPressed: () {
                                  _locationSearchController.text = 'Fuchsia City';
                                  setState(() => _searchQuery = 'Fuchsia City');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.location_city_outlined, size: 18),
                                label: const Text('Celadon City'),
                                onPressed: () {
                                  _locationSearchController.text = 'Celadon City';
                                  setState(() => _searchQuery = 'Celadon City');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.location_city_outlined, size: 18),
                                label: const Text('Saffron City'),
                                onPressed: () {
                                  _locationSearchController.text = 'Saffron City';
                                  setState(() => _searchQuery = 'Saffron City');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 15'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 15';
                                  setState(() => _searchQuery = 'Route 15');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 16'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 16';
                                  setState(() => _searchQuery = 'Route 16');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 17'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 17';
                                  setState(() => _searchQuery = 'Route 17');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 18'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 18';
                                  setState(() => _searchQuery = 'Route 18');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.water_drop_outlined, size: 18),
                                label: const Text('Route 19'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 19';
                                  setState(() => _searchQuery = 'Route 19');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.water, size: 18),
                                label: const Text('Route 20'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 20';
                                  setState(() => _searchQuery = 'Route 20');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.terrain_outlined, size: 18),
                                label: const Text('Seafoam Islands'),
                                onPressed: () {
                                  _locationSearchController.text = 'Seafoam Islands';
                                  setState(() => _searchQuery = 'Seafoam Islands');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.location_city_outlined, size: 18),
                                label: const Text('Cinnabar Island'),
                                onPressed: () {
                                  _locationSearchController.text = 'Cinnabar Island';
                                  setState(() => _searchQuery = 'Cinnabar Island');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.water, size: 18),
                                label: const Text('Route 21'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 21';
                                  setState(() => _searchQuery = 'Route 21');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 22'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 22';
                                  setState(() => _searchQuery = 'Route 22');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Route 23'),
                                onPressed: () {
                                  _locationSearchController.text = 'Route 23';
                                  setState(() => _searchQuery = 'Route 23');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.terrain_outlined, size: 18),
                                label: const Text('Victory Road'),
                                onPressed: () {
                                  _locationSearchController.text = 'Victory Road';
                                  setState(() => _searchQuery = 'Victory Road');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.emoji_events_outlined, size: 18),
                                label: const Text('Indigo Plateau'),
                                onPressed: () {
                                  _locationSearchController.text = 'Indigo Plateau';
                                  setState(() => _searchQuery = 'Indigo Plateau');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.terrain_outlined, size: 18),
                                label: const Text('Cerulean Cave'),
                                onPressed: () {
                                  _locationSearchController.text = 'Cerulean Cave';
                                  setState(() => _searchQuery = 'Cerulean Cave');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.directions_boat_outlined, size: 18),
                                label: const Text('S.S. Anne'),
                                onPressed: () {
                                  _locationSearchController.text = 'S.S. Anne';
                                  setState(() => _searchQuery = 'S.S. Anne');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.bolt_outlined, size: 18),
                                label: const Text('Power Plant'),
                                onPressed: () {
                                  _locationSearchController.text = 'Power Plant';
                                  setState(() => _searchQuery = 'Power Plant');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.domain_outlined, size: 18),
                                label: const Text('Pokémon Tower'),
                                onPressed: () {
                                  _locationSearchController.text = 'Pokémon Tower';
                                  setState(() => _searchQuery = 'Pokémon Tower');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.security_outlined, size: 18),
                                label: const Text('Rocket Hideout'),
                                onPressed: () {
                                  _locationSearchController.text = 'Rocket Hideout';
                                  setState(() => _searchQuery = 'Rocket Hideout');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.business_outlined, size: 18),
                                label: const Text('Silph Co.'),
                                onPressed: () {
                                  _locationSearchController.text = 'Silph Co.';
                                  setState(() => _searchQuery = 'Silph Co.');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.home_work_outlined, size: 18),
                                label: const Text('Pokémon Mansion'),
                                onPressed: () {
                                  _locationSearchController.text = 'Pokémon Mansion';
                                  setState(() => _searchQuery = 'Pokémon Mansion');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.park_outlined, size: 18),
                                label: const Text('Safari Zone'),
                                onPressed: () {
                                  _locationSearchController.text = 'Safari Zone';
                                  setState(() => _searchQuery = 'Safari Zone');
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.sports_martial_arts_outlined, size: 18),
                                label: const Text('Viridian Gym'),
                                onPressed: () {
                                  _locationSearchController.text = 'Viridian Gym';
                                  setState(() => _searchQuery = 'Viridian Gym');
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
                          ] else if (normalizedQuery == 'viridian city') ...[
                            const Text(
                              'Potwierdzone miejsca i wydarzenia',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              '• Pokémon Center — miejsce leczenia drużyny.\n'
                              '• Poké Mart — sprzedawca przekazuje Oak’s Parcel do dostarczenia Profesorowi Oakowi.\n'
                              '• Podczas pierwszej wizyty droga na północ jest blokowana; najpierw zbadaj miasto.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Połączenia lokacji',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              '• Na południe: Route 1.\n'
                              '• Na północ: Route 2.\n'
                              '• Na zachód: Route 22.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ukryty przedmiot: Potion w pobliżu północnego wyjścia, na zachód od małego drzewa (pojawia się jako codzienny przedmiot). Położenie opisano tekstowo — pinezka nie jest jeszcze zweryfikowana.',
                            ),
                          ] else if (normalizedQuery == 'viridian forest') ...[
                            const Text(
                              'Dzikie Pokémony w trawie (poziomy 3–6)',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              _selectedGameId == 'lets_go_eevee'
                                  ? '• Weedle — 25%\\n• Caterpie — 24%\\n• Pidgey — 15%\\n• Metapod — 10%\\n• Kakuna — 10%\\n• Bellsprout — 10%\\n• Pikachu — 5%\\n• Beedrill — 1%'
                                  : '• Caterpie — 25%\\n• Weedle — 24%\\n• Pidgey — 15%\\n• Metapod — 10%\\n• Kakuna — 10%\\n• Oddish — 10%\\n• Pikachu — 5%\\n• Butterfree — 1%',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Dodatkowe spotkanie rzadkie: Bulbasaur (po użyciu Lure). Poziomy spotkań: 3–6.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Przedmioty opisane w poradnikach: 5 Poké Balli, Tiny Mushroom, Antidote, 3 Razz Berries, 2 Potions oraz Lure. Dokładne pozycje nie są oznaczone pinezkami.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Trenerzy: Lass Joana (Rattata Lv. 4), Bug Catcher Brian (Weedle Lv. 3), Bug Catcher Rick (Caterpie Lv. 3), Lass Brittany (Nidoran♀ Lv. 4), Bug Catcher Doug (Kakuna Lv. 3), Lass Jocelyn (Pidgey Lv. 4) i Bug Catcher Sammy (Metapod Lv. 3).',
                            ),
                          ] else if (normalizedQuery == 'pewter city') ...[
                            const Text(
                              'Ważne miejsca',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              '• Pokémon Center i Poké Mart.\\n'
                              '• Pewter Museum of Science po północnej stronie miasta.\\n'
                              '• Pewter Gym — sala Brocka.\\n'
                              '• Miasto łączy się z Route 2 i Route 3.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Po wejściu do miasta Trace daje 5 Potion. Po pokonaniu Brocka otrzymasz Boulder Badge i TM01 Headbutt; Blue przekazuje też 5 Great Balls.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Drużyna Brocka: Geodude Lv. 11 i Onix Lv. 12. Za Pokémon Center znajduje się X Defense; dokładna pinezka nie jest jeszcze zweryfikowana.',
                            ),
                          ] else if (normalizedQuery == 'route 3') ...[
                            const Text(
                              'Dzikie Pokémony w trawie (poziomy 3–8)',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              _selectedGameId == 'lets_go_eevee'
                                  ? '• Spearow — 40%\\n• Rattata — 40%\\n• Ekans — 20%'
                                  : '• Spearow — 30%\\n• Rattata — 30%\\n• Mankey — 20%\\n• Sandshrew — 20%',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Trenerzy fabularni: Lass Janice (Oddish Lv. 6), Youngster Ben (Rattata Lv. 6), Bug Catcher Greg (Kakuna Lv. 5), Youngster Calvin (Spearow Lv. 6), Camper Victor (Nidoran♂ Lv. 7), Picnicker Robin (Nidoran♀ Lv. 7), Coach Trainer Kareem (Bulbasaur Lv. 11).',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Przedmioty: Potion, Revive, Lure, 3 Poké Balle, Razz Berry oraz nagrody za walki (m.in. Poké Balle, Great Balle i Revive). Część źródeł klasyfikuje nagrody trenerskie oddzielnie od przedmiotów leżących na ziemi.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Połączenia: na zachód Pewter City, na wschód Route 4 przy wejściu do Mt. Moon. Pozycje przedmiotów i trenerów są opisane tekstowo — nie mają zweryfikowanych pinezek.',
                            ),
                          ] else if (normalizedQuery == 'mt. moon' || normalizedQuery == 'mt moon') ...[
                            const Text(
                              'Dzikie Pokémony — poziomy 5–10',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const Text(
                              '• Zubat — 40%\\n• Geodude — 40% (na B2F: 34%)\\n• Paras — 15%\\n• Clefairy — 4% (na B2F: 9%)\\n• Onix — 1%\\n• Clefable — 1% na B2F',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Jaskinia ma trzy poziomy: 1F, B1F i B2F. Występuje 17 trenerów łącznie, w tym trenerzy fabularni oraz spotkania zależne od postępu gry; ich dokładne pozycje nie są obecnie mapowane.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Przedmioty: Repel, Potion, Awakening, Pearl, Ether, 5 Great Balli, Rare Candy, Nugget, Revive (kilka), Stardust, Big Mushroom i 2 Moon Stones. Cztery przedmioty są ukryte.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Mt. Moon łączy Route 3 z Route 4. Lista spotkań i przedmiotów jest dostępna offline, ale nie jest jeszcze odwzorowaniem korytarzy ani dokładnych pozycji na piętrach.',
                            ),
                          ] else if (normalizedQuery == 'route 5') ...[
                            const Text('Spotkania na Route 5 (poziomy 11–16)', style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(_selectedGameId == 'lets_go_eevee'
                                ? '• Rattata — 30%\\n• Pidgey — 20%\\n• Vulpix — 20%\\n• Jigglypuff — 15%\\n• Pidgeotto — 10%\\n• Abra — 5%'
                                : '• Rattata — 30%\\n• Pidgey — 20%\\n• Growlithe — 20%\\n• Jigglypuff — 15%\\n• Pidgeotto — 10%\\n• Abra — 5%'),
                            const SizedBox(height: 8),
                            const Text('Ważne: Day Care oraz wejście do Underground Path (Routes 5–6). Przedmioty: 3 Great Balls, Ether, 3 Nanab Berries i 3 ukryte Razz Berries. Dokładne pozycje nie są pinezkami.'),
                          ] else if (normalizedQuery == 'underground path (routes 5–6)' || normalizedQuery == 'underground path') ...[
                            const Text('Przejście pod Saffron City', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Łączy Route 5 z Route 6. Brak dzikich Pokémonów. Przedmioty: Repel, Lure i pięć codziennych/losowych ukrytych przedmiotów. Po odblokowaniu Master Trainers: Scientist Murray (Magnemite Lv. 70) i Scientist Julian (Magneton Lv. 75).'),
                          ] else if (normalizedQuery == 'route 6') ...[
                            const Text('Spotkania na Route 6 (poziomy 11–16)', style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(_selectedGameId == 'lets_go_eevee'
                                ? '• Pidgey — 20%\\n• Rattata — 20%\\n• Vulpix — 20%\\n• Jigglypuff — 15%\\n• Psyduck — 10%\\n• Pidgeotto — 10%\\n• Abra — 5%'
                                : '• Pidgey — 20%\\n• Rattata — 20%\\n• Growlithe — 20%\\n• Jigglypuff — 15%\\n• Psyduck — 10%\\n• Pidgeotto — 10%\\n• Abra — 5%'),
                            const SizedBox(height: 8),
                            const Text('Trenerzy fabularni: Camper Ricky, Camper Jeff, Gentleman Edward, Picnicker Nancy, Picnicker Isabelle i Sailor Elijah. Przedmioty: Super Potion, Paralyze Heal, Guard Spec. i ukryty Rare Candy. Południowe wyjście prowadzi do Vermilion City.'),
                          ] else if (normalizedQuery == 'vermilion city') ...[
                            const Text('Ważne miejsca', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('• Pokémon Center i Poké Mart\\n• Pokémon Fan Club\\n• Vermilion Gym — Lt. Surge\\n• Port i statek S.S. Anne'),
                            const SizedBox(height: 8),
                            const Text('Drużyna Lt. Surge’a: Voltorb Lv. 25, Magnemite Lv. 25 i Raichu Lv. 26. Squirtle Lv. 16 może zostać podarowany. W zależności od wersji dostępny jest gift Arcanine lub Persian. Przedmioty i wejścia nie mają jeszcze zweryfikowanych pinezek.'),
                          ] else if (normalizedQuery == 'route 4') ...[
                            const Text('Route 4 — przejście przez góry', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Zachodnia część zawiera Pokémon Center i wejście do Mt. Moon; wschodnia schodzi w stronę Cerulean City. Dzikie spotkania w trawie występują na poziomach 7–12, a skład zależy od wersji.'),
                            const SizedBox(height: 8),
                            const Text('Przedmioty opisane w źródłach: Escape Rope, 5 Poké Balls, Paralyze Heal, PP Max, 3 Great Balls, Repel oraz ukryty PP Up. W Pokémon Center można kupić Magikarp Lv. 5 za 500. Pinezki nie zostały jeszcze zweryfikowane.'),
                          ] else if (normalizedQuery == 'cerulean city') ...[
                            const Text('Ważne miejsca', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('• Pokémon Center i Poké Mart\\n• Cerulean Gym\\n• Bicycle Shop i Herb Shop\\n• Dom z północnym wyjściem oraz dom złodzieja'),
                            const SizedBox(height: 8),
                            const Text('Połączenia: Route 4, Route 5, Route 9 i Route 24. Przedmioty: Rare Candy i Burn Heal. Bulbasaur Lv. 12 może zostać podarowany; możliwa jest też wymiana Rattata na Alolan Rattata. Dokładne pozycje nie są zweryfikowanymi pinezkami.'),
                          ] else if (normalizedQuery == 'route 24') ...[
                            const Text('Dzikie Pokémony (poziomy 7–12)', style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(_selectedGameId == 'lets_go_eevee'
                                ? '• Pidgey — 20%\\n• Venonat — 20%\\n• Bellsprout — 20%\\n• Meowth — 20%\\n• Psyduck — 20%'
                                : '• Pidgey — 30%\\n• Venonat — 30%\\n• Oddish — 20%\\n• Psyduck — 20%'),
                            const SizedBox(height: 8),
                            const Text('Nugget Bridge i trenerzy: Bug Catcher Cale, Lass Ali, Youngster Timmy, Lass Reli, Camper Kevin, Team Rocket Grunt i Camper Shane. Przedmioty: X Sp. Def, 3 Razz Berries i 3 ukryte Pinap Berries. Charmander Lv. 14 jako gift. Trasa łączy Cerulean City z Route 25.'),
                          ] else if (normalizedQuery == 'route 25') ...[
                            const Text('Dzikie Pokémony (poziomy 9–14)', style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(_selectedGameId == 'lets_go_eevee'
                                ? '• Pidgey — 20%\\n• Venonat — 20%\\n• Bellsprout — 20%\\n• Meowth — 20%\\n• Psyduck — 20%'
                                : '• Pidgey — 30%\\n• Venonat — 30%\\n• Oddish — 20%\\n• Psyduck — 20%'),
                            const SizedBox(height: 8),
                            const Text('Trenerzy fabularni: Hiker Franklin, Fisherman Wayne, Bird Keeper Joey, Youngster Dan, Picnicker Kelsey, Camper Dustin, Hiker Nob, Youngster Chad, Lass Haley i Coach Trainer Amala. Przedmioty: TM16, Lure, Super Potion, Ether i ukryta Nanab Berry. Na końcu trasy znajduje się Bill’s House.'),
                          ] else if (normalizedQuery == 'route 11') ...[
                            const Text('Route 11 — spotkania i przedmioty', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Spotkania w Let’s Go Pikachu (poziomy 13–18): Pidgey 25%, Rattata 25%, Drowzee 25%, Pidgeotto 10%, Raticate 10% i Mr. Mime 5%. Przy trasie znajduje się Route 11 Gate. Źródła wymieniają 5 Great Balls, Super Potion, X Defense, Lure, Super Repel i ukryty Revive.'),
                            const SizedBox(height: 8),
                            const Text('Trasa prowadzi od Vermilion City w stronę wschodniego wejścia do Diglett’s Cave. Spotkania i przedmioty nie mają jeszcze zweryfikowanych pinezek.'),
                          ] else if (normalizedQuery == 'digletts cave' || normalizedQuery == "diglett's cave") ...[
                            const Text('Diglett’s Cave', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Tunel łączy okolice Route 11 z wschodnią częścią Route 2. W Let’s Go Pikachu występują Diglett (85%), Zubat (10%) i Dugtrio (5%); rzadszym spotkaniem może być Chansey. Pozycje wyjść i spotkań nie są naniesione na dokładny plan jaskini.'),
                          ] else if (normalizedQuery == 'route 12') ...[
                            const Text('Route 12 — Silence Bridge i Snorlax', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Długa trasa wędkarska na południe od Lavender Town. Snorlax Lv. 34 blokuje przejście do czasu wydarzenia fabularnego. Przedmioty z listy źródłowej: TM24, Water Stone, 3 Ultra Balls, Lure, Repel, Awakening, Max Lure i 5 ukrytych Silver Pinap Berries. Dokładne pozycje nie są jeszcze pinezkami.'),
                          ] else if (normalizedQuery == 'route 13') ...[
                            const Text('Route 13 — labirynt ogrodzeń', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Wąska trasa z licznymi ogrodzeniami łącząca Route 12 z Route 14. Układ przejść, trenerzy i przedmioty wymagają jeszcze osobnej weryfikacji przed dodaniem pinezek.'),
                          ] else if (normalizedQuery == 'route 14') ...[
                            const Text('Route 14', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Trasa łączy Route 13 z Route 15. Szczegóły trenerów, przedmiotów i spotkań zostaną pokazane po ich weryfikacji; obecnie nie ma dokładnych pinezek.'),
                          ] else if (normalizedQuery == 'route 15') ...[
                            const Text('Route 15 — zachodnie wejście do Fuchsia City', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Połączenie Route 14 z Fuchsia City. Lista przedmiotów obejmuje Super Potion, 3 Great Balls, Rare Candy i 5 ukrytych Razz Berries. Szczegółowe położenie przedmiotów i trenerów nie jest jeszcze odwzorowane na pinezkach.'),
                          ] else if (normalizedQuery == 'fuchsia city') ...[
                            const Text('Ważne miejsca', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('• Pokémon Center i Poké Mart\\n• Fuchsia Gym — Koga\\n• GO Park i brama Safari Zone\\n• Pokój Warden'),
                            const SizedBox(height: 8),
                            const Text('Drużyna Kogi: Weezing Lv. 43, Muk Lv. 43, Golbat Lv. 43 i Venomoth Lv. 44. Połączenia: Route 15, Route 18 i Route 19. Szczegółowe położenie przedmiotów i wejść nie jest jeszcze zweryfikowane na mapie.'),
                          ] else if (normalizedQuery == 'celadon city') ...[
                            const Text('Ważne miejsca w Celadon City', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('• Celadon Department Store\\n• Celadon Game Corner i Rocket Hideout\\n• Celadon Gym\\n• Pokémon Center i Poké Mart\\n• Celadon Restaurant'),
                            const SizedBox(height: 8),
                            const Text('Połączenia: Route 7 i Route 16. Budynki mają wiele pięter i osobne wnętrza — obecny widok pokazuje tylko indeks lokacji, nie ich dokładne plany.'),
                          ] else if (normalizedQuery == 'saffron city') ...[
                            const Text('Ważne miejsca w Saffron City', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('• Silph Co.\\n• Saffron Gym\\n• Fighting Dojo\\n• Pokémon Center i Poké Mart'),
                            const SizedBox(height: 8),
                            const Text('Połączenia drogowe: Route 7 i Route 8. Silph Co. oraz sale walk wymagają osobnych map wnętrz; nie przedstawiamy ich jeszcze jako gotowych planów.'),
                          ] else if (normalizedQuery == 'route 16') ...[
                            const Text('Route 16 — zachodnia trasa rowerowa', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Łączy Celadon City z Route 17. Północny odcinek wymaga Chop Down. Przedmioty opisane w źródle: 3 Poké Balls, Super Potion, Lure i ukryty Rare Candy.'),
                          ] else if (normalizedQuery == 'route 17') ...[
                            const Text('Route 17 — Pokémon Road', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Długa trasa rowerowa między Route 16 i Route 18. Dokładny układ trenerów, przedmiotów i dzikich spotkań nie jest jeszcze odwzorowany w pinezkach.'),
                          ] else if (normalizedQuery == 'route 18') ...[
                            const Text('Route 18', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Połączenie Route 17 z Fuchsia City; przy trasie znajduje się Route 18 Gate. Szczegółowe wnętrza bramy nie są jeszcze mapowane.'),
                          ] else if (normalizedQuery == 'route 19') ...[
                            const Text('Route 19 — morska trasa', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Wymaga Sea Skim. Spotkania na wodzie, poziomy 37–42: Tentacool 45%, Magikarp 45%, Tentacruel 5% i Gyarados 5%. Łączy Fuchsia City z Route 20.'),
                          ] else if (normalizedQuery == 'route 20') ...[
                            const Text('Route 20 — morze i Seafoam Islands', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Wymaga Sea Skim. Spotkania na wodzie, poziomy 37–42: Magikarp 45%, Tentacool 45%, Tentacruel 5% i Gyarados 5%. Seafoam Islands dzielą trasę na część wschodnią i zachodnią.'),
                          ] else if (normalizedQuery == 'seafoam islands') ...[
                            const Text('Seafoam Islands', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Jaskinia ma piętra B1F–B4F i znajduje się na Route 20. Wewnątrz można rozwiązać zagadkę z głazami; legendarne Pokémony: Articuno. Dokładny plan pięter i pozycje przedmiotów wymagają osobnego odwzorowania.'),
                          ] else if (normalizedQuery == 'cinnabar island') ...[
                            const Text('Ważne miejsca na Cinnabar Island', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('• Pokémon Center i Poké Mart\\n• Pokémon Lab — wskrzeszanie skamielin\\n• Pokémon Mansion\\n• Cinnabar Gym — Blaine'),
                            const SizedBox(height: 8),
                            const Text('Połączenia: Route 20 i Route 21. Pokémon Mansion ma własny wielopoziomowy układ; nie jest jeszcze dostępny jako dokładna mapa wnętrza.'),
                          ] else if (normalizedQuery == 'route 21') ...[
                            const Text('Route 21 — południowe wybrzeże Kanto', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Łączy Pallet Town z Cinnabar Island. Spotkania w trawie na poziomach 37–42 obejmują Raticate 20%, Pidgeotto 20%, Tangela 15%, Gloom 14%, Rattata 10%, Pidgey 10%, Oddish 10% i Vileplume 1%.'),
                          ] else if (normalizedQuery == 'route 22') ...[
                            const Text('Route 22 — droga do Ligi', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Trasa od Viridian City w kierunku Route 23 i Pokémon League. To także miejsce pierwszej walki z rywalem. Pełna lista spotkań i przedmiotów wymaga dalszego uzupełnienia.'),
                          ] else if (normalizedQuery == 'route 23') ...[
                            const Text('Route 23 — bramy odznak', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Droga do Indigo Plateau z kontrolami odznak. Połączenie z Route 22 i Victory Road. Przedmioty i spotkania nie są jeszcze odwzorowane na pinezkach.'),
                          ] else if (normalizedQuery == 'victory road') ...[
                            const Text('Victory Road', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Jaskinia prowadząca z Route 23 do Indigo Plateau; trzy piętra. W tej lokacji znajduje się Moltres. Dokładny plan przejść, głazów, trenerów i przedmiotów wymaga osobnego opracowania.'),
                          ] else if (normalizedQuery == 'indigo plateau') ...[
                            const Text('Indigo Plateau — Pokémon League', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Kompleks Ligi Pokémon: Elite Four i walka z Championem. Jest końcem głównej trasy przez Victory Road; dokładne wnętrza nie są jeszcze mapowane.'),
                          ] else if (normalizedQuery == 'cerulean cave') ...[
                            const Text('Cerulean Cave — lokacja postgame', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Jaskinia odblokowywana po ukończeniu głównej historii, dostępna z okolic Cerulean City. Ma piętra 1F, 2F i B1F; Mewtwo znajduje się w jej głębi. Dokładne piętra i pinezki wymagają osobnego opracowania.'),
                          ] else if (normalizedQuery == 's.s. anne' || normalizedQuery == 'ss anne') ...[
                            const Text('S.S. Anne — statek w porcie Vermilion', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Statek fabularny dostępny z portu Vermilion City. Ma pokład, kabiny, jadalnię i mostek. Po zdobyciu Cut i zakończeniu wydarzeń statek odpływa; wnętrza oraz przedmioty nie mają jeszcze szczegółowych pinezek.'),
                          ] else if (normalizedQuery == 'power plant') ...[
                            const Text('Power Plant', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Elektrownia dostępna z Route 10. Można tu spotkać legendarnego Zapdosa. To osobna lokacja wymagająca własnego planu wnętrza; dokładne pozycje przedmiotów i spotkań nie są jeszcze naniesione.'),
                          ] else if (normalizedQuery == 'pokémon tower' || normalizedQuery == 'pokemon tower') ...[
                            const Text('Pokémon Tower — Lavender Town', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Wieża ma siedem pięter. Wydarzenia fabularne wymagają Silph Scope; w wieży odnajduje się Mr. Fuji. Każde piętro powinno dostać osobny, zweryfikowany plan przed dodaniem pinezek.'),
                          ] else if (normalizedQuery == 'rocket hideout' || normalizedQuery == 'team rocket hideout') ...[
                            const Text('Team Rocket Hideout', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Podziemna kryjówka pod Celadon Game Corner, obejmująca poziomy B1F–B4F i walkę z Giovannim. Wymaga osobnej mapy pięter; nie pokazujemy jeszcze dokładnych pozycji przełączników, trenerów ani przedmiotów.'),
                          ] else if (normalizedQuery == 'silph co' || normalizedQuery == 'silph co.') ...[
                            const Text('Silph Co. — Saffron City', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Budynek biurowy z 11 piętrami, teleportami i wydarzeniem ratowania prezesa. To osobny kompleks; dokładny układ teleportów, trenerów i przedmiotów nie jest jeszcze odwzorowany.'),
                          ] else if (normalizedQuery == 'pokémon mansion' || normalizedQuery == 'pokemon mansion') ...[
                            const Text('Pokémon Mansion — Cinnabar Island', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Opuszczona posiadłość z piętrami 1F–3F i B1F. Dzienniki wyjaśniają historię Mewtwo; klucz do Cinnabar Gym jest związany z tą lokacją. Mewtwo znajduje się jednak w Cerulean Cave, nie w Mansion.'),
                          ] else if (normalizedQuery == 'safari zone') ...[
                            const Text('Safari Zone — Fuchsia City', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Strefa dostępna przez bramę w Fuchsia City; w środku znajduje się m.in. Gold Teeth Warden’a. Dokładne strefy, przedmioty i spotkania wymagają osobnych danych, więc nie dodano fałszywych pinezek.'),
                          ] else if (normalizedQuery == 'viridian gym') ...[
                            const Text('Viridian Gym', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Sala Giovanni’ego w Viridian City. W Let’s Go Pikachu/Eevee jest to ostatnia sala przed Pokémon League. Dokładny plan sali i pełna drużyna lidera wymagają dalszego sprawdzenia.'),
                          ] else if (normalizedQuery == 'pewter gym') ...[
                            const Text('Pewter Gym — Brock', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Drużyna Brock’a: Geodude Lv. 11 i Onix Lv. 12. Nagroda za zwycięstwo: Boulder Badge i TM01 Headbutt. Dokładny układ sali nie jest jeszcze odwzorowany na pinezkach.'),
                          ] else if (normalizedQuery == 'cerulean gym') ...[
                            const Text('Cerulean Gym — Misty', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Sala wodna w Cerulean City. Dokładna drużyna liderki oraz układ przeszkód wymagają weryfikacji przed pokazaniem szczegółów; nie dodano niepotwierdzonych pinezek.'),
                          ] else if (normalizedQuery == 'vermilion gym') ...[
                            const Text('Vermilion Gym — Lt. Surge', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Drużyna: Voltorb Lv. 25, Magnemite Lv. 25 i Raichu Lv. 26. Sala ma zagadkę z przełącznikami; ich dokładne pozycje nie są jeszcze odwzorowane.'),
                          ] else if (normalizedQuery == 'celadon gym') ...[
                            const Text('Celadon Gym — Erika', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Sala trawiasta w Celadon City. Dokładny skład drużyny Eriki i układ przeszkód wymagają jeszcze weryfikacji; brak zweryfikowanych pinezek.'),
                          ] else if (normalizedQuery == 'saffron gym') ...[
                            const Text('Saffron Gym — Sabrina', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Sala psychiczna w Saffron City. Dokładny układ teleportów i drużyna liderki wymagają osobnego sprawdzenia; nie dodano niepotwierdzonych pinezek.'),
                          ] else if (normalizedQuery == 'fuchsia gym') ...[
                            const Text('Fuchsia Gym — Koga', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Drużyna Kogi: Weezing Lv. 43, Muk Lv. 43, Golbat Lv. 43 i Venomoth Lv. 44. Sala wykorzystuje niewidzialne ściany; ich plan nie jest jeszcze odwzorowany.'),
                          ] else if (normalizedQuery == 'cinnabar gym') ...[
                            const Text('Cinnabar Gym — Blaine', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Sala z pytaniami i przełącznikami na Cinnabar Island. Dokładna drużyna Blaine’a oraz układ sali wymagają weryfikacji przed dodaniem pinezek.'),
                          ] else if (normalizedQuery == "bill's house" || normalizedQuery == 'bills house') ...[
                            const Text('Bill’s House — Route 25', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Dom Billa znajduje się na końcu Route 25. Po wydarzeniu z Billem otrzymuje się S.S. Ticket, potrzebny do wejścia na S.S. Anne. Dokładne wnętrze domu nie ma jeszcze pinezek.'),
                          ] else if (normalizedQuery == 'pewter museum' || normalizedQuery == 'pewter museum of science') ...[
                            const Text('Pewter Museum of Science', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Muzeum w Pewter City z wystawami skamielin i piętrem laboratoryjnym. Szczegółowy układ eksponatów i wejść nie jest jeszcze odwzorowany.'),
                          ] else if (normalizedQuery == 'pokemon fan club' || normalizedQuery == 'pokémon fan club') ...[
                            const Text('Pokémon Fan Club — Vermilion City', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Budynek w Vermilion City. Po wysłuchaniu przewodniczącego klubu można odebrać nagrodę fabularną. Dokładne wnętrze nie ma jeszcze pinezek.'),
                          ] else if (normalizedQuery == 'day care' || normalizedQuery == 'pokémon day care' || normalizedQuery == 'pokemon day care') ...[
                            const Text('Pokémon Day Care — Route 5', style: TextStyle(fontWeight: FontWeight.w700)),
                            const Text('Placówka przy Route 5. W Let’s Go nie ma standardowej hodowli jaj; miejsce służy przede wszystkim do pozostawienia Pokémonów i podniesienia ich poziomu.'),
                          ] else if (normalizedQuery == 'route 2') ...[
                            const Text(
                              'Dzikie Pokémony w trawie (poziomy 3–4)',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              _selectedGameId == 'lets_go_eevee'
                                  ? '• Pidgey — 30%\n• Rattata — 20%\n• Bellsprout — 20%\n• Caterpie — 15%\n• Weedle — 15%'
                                  : '• Pidgey — 30%\n• Rattata — 20%\n• Oddish — 20%\n• Caterpie — 15%\n• Weedle — 15%',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Poziomy spotkań: 3–4. Route 2 ma część południową i północną, a Viridian Forest znajduje się pomiędzy nimi. Źródła opisują też wschodnią ścieżkę w stronę Diglett’s Cave.',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Dokładne pozycje trawy, przejść, przedmiotów i trenerów nie są jeszcze odwzorowane pinezkami. Dane spotkań są tekstowe i nie określają współrzędnych.',
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
                              'Wybierz lokację z mapy albo wpisz jej dokładną nazwę, aby zobaczyć schemat lokalny i informacje powiązane z poradnikiem. Nie pokazujemy dokładnych pinezek przedmiotów bez zweryfikowanych współrzędnych.',
                            ),
                          const SizedBox(height: 12),
                          if (_isLetsGoKanto && selectedLocalLocation != null)
                            _buildLetsGoEncounterPanel(
                              context,
                              selectedLocalLocation,
                            ),
                          _KantoLocalAreaPanel(
                            location: selectedLocalLocation,
                            references: selectedLocalLocation == null
                                ? const <_LocationReference>[]
                                : _locations[selectedLocalLocation] ??
                                    const <_LocationReference>[],
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
                    final completedCount = _completedCount(references);
                    final allComplete = references.isNotEmpty &&
                        completedCount == references.length;
                    final pokemon = <String>{};
                    final items = <String>{};
                    for (final reference in references) {
                      pokemon.addAll(reference.step.pokemon);
                      items.addAll(reference.step.items);
                    }

                    return Card(
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: allComplete
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: allComplete
                              ? const Icon(Icons.check_circle_outline)
                              : Text('${locationIndex + 1}'),
                        ),
                        title: Text(entry.key),
                        subtitle: Text(
                          '$completedCount/${references.length} kroków ukończonych · '
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
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => GuideScreen(
                                        guide: reference.guide,
                                        initialStepNumber: reference.stepNumber,
                                      ),
                                    ),
                                  );
                                  await _loadCompletedSteps();
                                },
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


/// Mały schemat lokacji wybranej na mapie regionu. Układ punktów jest
/// celowo poglądowy — nie przedstawia dokładnych współrzędnych z gry.
class _KantoLocalAreaPanel extends StatefulWidget {
  final String? location;
  final List<_LocationReference> references;

  const _KantoLocalAreaPanel({
    required this.location,
    required this.references,
  });

  @override
  State<_KantoLocalAreaPanel> createState() => _KantoLocalAreaPanelState();
}

class _KantoLocalAreaPanelState extends State<_KantoLocalAreaPanel> {
  String? _selectedFeature;

  static const _featuresByLocation = <String, Map<String, String>>{
    'Pallet Town': {
      'Dom gracza': 'Dom gracza — miejsce rozpoczęcia przygody.',
      'Dom rywala': 'Dom rywala — punkt związany z początkiem historii.',
      'Laboratorium Oaka': 'Laboratorium Profesora Oaka — wydarzenia fabularne i otrzymanie Pokédexu.',
    },
    'Route 1': {
      'Kierunek Pallet Town': 'Południowy koniec Route 1 prowadzi w stronę Pallet Town. Schemat nie pokazuje dokładnego przebiegu drogi.',
      'Obszar spotkań': 'Poradnik wymienia Pidgey i Rattata jako Pokémony możliwe do złapania na Route 1. Obszar na rysunku jest poglądowy.',
      'Kierunek Viridian City': 'Route 1 łączy Pallet Town z Viridian City. Symbol wskazuje kierunek, nie współrzędne wejścia.',
    },
    'Viridian City': {
      'Pokémon Center': 'Poradnik zaleca odwiedzić Pokémon Center w Viridian City, aby przygotować drużynę.',
      'Poké Mart': 'W poradniku pracownik Poké Martu przekazuje przesyłkę dla Profesora Oaka.',
      'Kierunek Route 1': 'Route 1 prowadzi z powrotem na południe do Pallet Town.',
    },
    'Route 2': {
      'Kierunek północny': 'Poradnik prowadzi Route 2 na północ, przed wejściem do Viridian Forest.',
      'Kierunek Viridian Forest': 'Viridian Forest jest następną lokacją wskazaną w poradniku.',
    },
    'Viridian Forest': {
      'Obszar leśny': 'Poradnik zaleca przejść przez las i szukać Pokémonów oraz przedmiotów. Nie oznaczamy niepotwierdzonych pozycji.',
      'Kierunek Pewter City': 'Po wyjściu z Viridian Forest poradnik prowadzi dalej do Pewter City.',
    },
    'Pewter City': {
      'Miasto Pewter': 'Pewter City jest lokacją po wyjściu z Viridian Forest.',
      'Kierunek Pewter Gym': 'Poradnik wskazuje przygotowanie drużyny przed pierwszym Gymem.',
    },
    'Pewter Gym': {
      'Gym Brocka': 'To miejsce walki z Brockiem o pierwszą odznakę Gym.',
      'Brock': 'Poradnik wymienia Geodude i Onixa w kontekście walki z Brockiem. Schemat nie odwzorowuje dokładnego wnętrza Gymu.',
    },
  };

  @override
  void didUpdateWidget(covariant _KantoLocalAreaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _selectedFeature = null;
  }

  Future<void> _showExpandedMap(BuildContext context, String location) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: MediaQuery.sizeOf(dialogContext).width * 0.9,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Powiększony schemat: $location',
                  style: Theme.of(dialogContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1.25,
                  child: CustomPaint(
                    painter: _KantoLocalAreaPainter(
                      location: location,
                      land: Theme.of(dialogContext).colorScheme.surfaceContainerHighest,
                      route: Theme.of(dialogContext).colorScheme.primary,
                      label: Theme.of(dialogContext).colorScheme.onSurface,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Schemat poglądowy offline — nie przedstawia dokładnej skali ani współrzędnych z gry.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Zamknij'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _featureIcon(String feature) {
    final normalized = feature.toLowerCase();
    if (normalized.contains('dom') ||
        normalized.contains('laboratorium') ||
        normalized.contains('center') ||
        normalized.contains('mart') ||
        normalized.contains('gym')) {
      return Icons.home_work_outlined;
    }
    if (normalized.contains('spotkań') || normalized.contains('leśny')) {
      return Icons.grass;
    }
    if (normalized.contains('brock')) return Icons.person_outline;
    return Icons.route_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    if (location == null) return const SizedBox.shrink();
    final features = _featuresByLocation[location];
    if (features == null) return const SizedBox.shrink();

    final selected = _selectedFeature;
    final availablePokemon = widget.references
        .expand((reference) => reference.step.pokemon)
        .toSet()
        .toList()
      ..sort();
    final availableItems = widget.references
        .expand((reference) => reference.step.items)
        .toSet()
        .toList()
      ..sort();
    final optionalSteps = widget.references
        .where((reference) => reference.step.optional)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schemat lokacji: $location',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        const Text(
          'Widok poglądowy offline. Rozmieszczenie symboli nie przedstawia dokładnych współrzędnych, skali ani wiernej mapy z gry.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: 'Dotknij, aby powiększyć schemat',
          child: GestureDetector(
            onTap: () => _showExpandedMap(context, location),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: CustomPaint(
                  painter: _KantoLocalAreaPainter(
                    location: location,
                    land: Theme.of(context).colorScheme.surfaceContainerHighest,
                    route: Theme.of(context).colorScheme.primary,
                    label: Theme.of(context).colorScheme.onSurface,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: features.keys.map((feature) {
            return ChoiceChip(
              avatar: Icon(_featureIcon(feature), size: 16),
              label: Text(feature),
              selected: selected == feature,
              onSelected: (_) => setState(() => _selectedFeature = feature),
            );
          }).toList(),
        ),
        if (availablePokemon.isNotEmpty ||
            availableItems.isNotEmpty ||
            optionalSteps > 0) ...[
          const SizedBox(height: 12),
          Text(
            'Dane z poradnika',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          if (availablePokemon.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.catching_pokemon),
              title: const Text('Pokémon wymienione w poradniku'),
              subtitle: Text(availablePokemon.join(', ')),
            ),
          if (availableItems.isNotEmpty)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Przedmioty wymienione w poradniku'),
              subtitle: Text(availableItems.join(', ')),
            ),
          if (optionalSteps > 0)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.star_border),
              title: const Text('Kroki opcjonalne'),
              subtitle: Text('$optionalSteps kroków oznaczono jako opcjonalne.'),
            ),
          const Text(
            'Lista pokazuje wpisy z poradnika dla tej lokacji. Nie potwierdza dokładnego miejsca spotkania Pokémonów ani położenia przedmiotów.',
            style: TextStyle(fontSize: 12),
          ),
        ],
        if (selected != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(features[selected]!),
          ),
          const SizedBox(height: 10),
          Text(
            'Powiązane kroki poradnika',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          if (widget.references.isEmpty)
            const Text(
              'Brak kroków poradnika przypisanych do tej lokacji. Możesz nadal korzystać z opisu schematu.',
              style: TextStyle(fontSize: 12),
            )
          else
            ...widget.references.map(
              (reference) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(
                    'Krok ${reference.stepNumber}: ${reference.step.title}',
                  ),
                  subtitle: Text(reference.guide.title),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GuideScreen(
                        guide: reference.guide,
                        initialStepNumber: reference.stepNumber,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _KantoLocalAreaPainter extends CustomPainter {
  final String location;
  final Color land;
  final Color route;
  final Color label;

  const _KantoLocalAreaPainter({
    required this.location,
    required this.land,
    required this.route,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = land);
    final roadPaint = Paint()
      ..color = route.withValues(alpha: 0.42)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final path = Path();

    if (location == 'Pallet Town') {
      path
        ..moveTo(size.width * .12, size.height * .78)
        ..lineTo(size.width * .42, size.height * .78)
        ..lineTo(size.width * .42, size.height * .52)
        ..lineTo(size.width * .72, size.height * .52)
        ..lineTo(size.width * .88, size.height * .25);
    } else if (location == 'Route 1' || location == 'Route 2') {
      path
        ..moveTo(size.width * .12, size.height * .88)
        ..lineTo(size.width * .34, size.height * .72)
        ..lineTo(size.width * .48, size.height * .58)
        ..lineTo(size.width * .62, size.height * .34)
        ..lineTo(size.width * .88, size.height * .12);
    } else if (location == 'Viridian Forest') {
      path
        ..moveTo(size.width * .12, size.height * .86)
        ..quadraticBezierTo(size.width * .42, size.height * .62, size.width * .32, size.height * .42)
        ..quadraticBezierTo(size.width * .50, size.height * .18, size.width * .82, size.height * .12);
    } else {
      path
        ..moveTo(size.width * .14, size.height * .72)
        ..lineTo(size.width * .38, size.height * .72)
        ..lineTo(size.width * .62, size.height * .46)
        ..lineTo(size.width * .86, size.height * .46);
    }
    canvas.drawPath(path, roadPaint);

    final markers = <(String, Offset)>[];
    if (location == 'Pallet Town') {
      markers.addAll([
        ('Dom gracza', Offset(size.width * .22, size.height * .52)),
        ('Dom rywala', Offset(size.width * .58, size.height * .72)),
        ('Laboratorium Oaka', Offset(size.width * .72, size.height * .28)),
      ]);
    } else if (location == 'Route 1') {
      markers.addAll([
        ('Pallet Town', Offset(size.width * .12, size.height * .88)),
        ('Obszar spotkań', Offset(size.width * .48, size.height * .58)),
        ('Viridian City', Offset(size.width * .88, size.height * .12)),
      ]);
    } else if (location == 'Viridian City') {
      markers.addAll([
        ('Pokémon Center', Offset(size.width * .30, size.height * .46)),
        ('Poké Mart', Offset(size.width * .66, size.height * .46)),
        ('Route 1', Offset(size.width * .50, size.height * .80)),
      ]);
    } else if (location == 'Route 2') {
      markers.addAll([
        ('Viridian City', Offset(size.width * .12, size.height * .88)),
        ('Trasa', Offset(size.width * .48, size.height * .58)),
        ('Viridian Forest', Offset(size.width * .88, size.height * .12)),
      ]);
    } else if (location == 'Viridian Forest') {
      markers.addAll([
        ('Wejście', Offset(size.width * .12, size.height * .86)),
        ('Obszar leśny', Offset(size.width * .48, size.height * .48)),
        ('Wyjście', Offset(size.width * .82, size.height * .12)),
      ]);
      for (final point in <Offset>[
        Offset(size.width * .20, size.height * .28),
        Offset(size.width * .38, size.height * .20),
        Offset(size.width * .66, size.height * .28),
        Offset(size.width * .72, size.height * .68),
      ]) {
        canvas.drawCircle(point, 10, Paint()..color = route.withValues(alpha: .18));
        canvas.drawCircle(point, 5, Paint()..color = route.withValues(alpha: .5));
      }
    } else if (location == 'Pewter City') {
      markers.addAll([
        ('Miasto', Offset(size.width * .28, size.height * .46)),
        ('Pewter Gym', Offset(size.width * .68, size.height * .46)),
      ]);
    } else {
      markers.addAll([
        ('Gym', Offset(size.width * .50, size.height * .44)),
        ('Brock', Offset(size.width * .50, size.height * .72)),
      ]);
    }

    for (final marker in markers) {
      final point = marker.$2;
      final isBuilding = marker.$1.contains('Dom') ||
          marker.$1.contains('Laboratorium') ||
          marker.$1.contains('Center') ||
          marker.$1.contains('Mart') ||
          marker.$1.contains('Gym') ||
          marker.$1 == 'Miasto';
      if (isBuilding) {
        final rect = Rect.fromCenter(center: point, width: 18, height: 14);
        canvas.drawRect(rect, Paint()..color = route.withValues(alpha: .65));
        final roof = Path()
          ..moveTo(rect.left - 3, rect.top)
          ..lineTo(point.dx, rect.top - 9)
          ..lineTo(rect.right + 3, rect.top)
          ..close();
        canvas.drawPath(roof, Paint()..color = route);
      } else {
        canvas.drawCircle(point, 7, Paint()..color = route);
        canvas.drawCircle(point, 2.5, Paint()..color = Colors.white);
      }

      final text = TextPainter(
        text: TextSpan(
          text: marker.$1,
          style: TextStyle(
            color: label,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: size.width * .38);
      var dx = point.dx + 10;
      if (dx + text.width > size.width - 4) dx = point.dx - text.width - 10;
      final dy = (point.dy + 8)
          .clamp(2.0, size.height - text.height - 2)
          .toDouble();
      text.paint(canvas, Offset(dx, dy));
    }

    final title = TextPainter(
      text: TextSpan(
        text: location.toUpperCase(),
        style: TextStyle(
          color: route,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 12);
    title.paint(canvas, const Offset(8, 8));
  }

  @override
  bool shouldRepaint(covariant _KantoLocalAreaPainter oldDelegate) =>
      location != oldDelegate.location ||
      land != oldDelegate.land ||
      route != oldDelegate.route ||
      label != oldDelegate.label;
}

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
    // These two symbols sit beside the Route 1 node. Treat them as separate
    // targets so tapping a symbol explains its meaning, not just the town.
    final routeOne = _KantoMapPainter.places.firstWhere(
      (place) => place.name == 'Route 1',
    );
    final routeX = routeOne.x * _mapSize;
    final routeY = routeOne.y * _mapSize;
    final informationCenter = Offset(routeX - 12, routeY - 15);
    final areaCenter = Offset(routeX + 13, routeY - 15);

    if ((tap - informationCenter).distance <= 14) {
      _showLocation('Route 1 • informacje z poradnika');
      widget.onLocationSelected('Route 1');
      return;
    }
    if ((tap - areaCenter).distance <= 14) {
      _showLocation('Route 1 • obszar poglądowy');
      widget.onLocationSelected('Route 1');
      return;
    }

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
                        'Przesuń • przybliż • wybierz lokację',
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
    _MapPlace('Route 2', 0.29, 0.59),
    _MapPlace('Viridian Forest', 0.28, 0.51),
    _MapPlace('Pewter City', 0.25, 0.43),
    _MapPlace('Route 3', 0.35, 0.39),
    _MapPlace('Mt. Moon', 0.45, 0.34),
    _MapPlace('Route 4', 0.54, 0.33),
    _MapPlace('Cerulean City', 0.63, 0.35),
    _MapPlace('Route 24', 0.68, 0.27),
    _MapPlace('Route 25', 0.73, 0.22),
    _MapPlace('Route 5', 0.64, 0.47),
    _MapPlace('Underground Path (Routes 5–6)', 0.68, 0.57),
    _MapPlace('Route 6', 0.61, 0.62),
    _MapPlace('Vermilion City', 0.57, 0.65),
    _MapPlace('Route 7', 0.48, 0.49),
    _MapPlace('Route 8', 0.7, 0.48),
    _MapPlace('Route 9', 0.74, 0.39),
    _MapPlace('Route 10', 0.79, 0.43),
    _MapPlace('Rock Tunnel', 0.86, 0.42),
    _MapPlace('Lavender Town', 0.78, 0.49),
    _MapPlace('Underground Path (Routes 7–8)', 0.57, 0.52),
    _MapPlace('Route 11', 0.43, 0.63),
    _MapPlace('Diglett\'s Cave', 0.34, 0.58),
    _MapPlace('Route 12', 0.8, 0.56),
    _MapPlace('Route 13', 0.82, 0.64),
    _MapPlace('Route 14', 0.79, 0.71),
    _MapPlace('Route 15', 0.73, 0.77),
    _MapPlace('Fuchsia City', 0.65, 0.82),
    _MapPlace('Celadon City', 0.43, 0.52),
    _MapPlace('Saffron City', 0.59, 0.49),
    _MapPlace('Route 16', 0.34, 0.49),
    _MapPlace('Route 17', 0.46, 0.82),
    _MapPlace('Route 18', 0.56, 0.81),
    _MapPlace('Route 19', 0.57, 0.88),
    _MapPlace('Route 20', 0.4, 0.92),
    _MapPlace('Seafoam Islands', 0.27, 0.94),
    _MapPlace('Cinnabar Island', 0.12, 0.94),
    _MapPlace('Route 21', 0.17, 0.87),
    _MapPlace('Route 22', 0.19, 0.61),
    _MapPlace('Route 23', 0.1, 0.34),
    _MapPlace('Victory Road', 0.13, 0.28),
    _MapPlace('Indigo Plateau', 0.1, 0.22),
    _MapPlace('Cerulean Cave', 0.73, 0.3),
    _MapPlace('S.S. Anne', 0.52, 0.72),
    _MapPlace('Power Plant', 0.87, 0.36),
    _MapPlace('Pokémon Tower', 0.82, 0.51),
    _MapPlace('Team Rocket Hideout', 0.4, 0.55),
    _MapPlace('Silph Co.', 0.61, 0.46),
    _MapPlace('Pokémon Mansion', 0.12, 0.88),
    _MapPlace('Safari Zone', 0.68, 0.86),
    _MapPlace('Viridian Gym', 0.24, 0.66),
    _MapPlace('Pewter Gym', 0.31, 0.43),
    _MapPlace('Cerulean Gym', 0.66, 0.38),
    _MapPlace('Vermilion Gym', 0.61, 0.67),
    _MapPlace('Celadon Gym', 0.4, 0.49),
    _MapPlace('Saffron Gym', 0.62, 0.51),
    _MapPlace('Fuchsia Gym', 0.69, 0.81),
    _MapPlace('Cinnabar Gym', 0.1, 0.91),
    _MapPlace('Bill\'s House', 0.81, 0.19),
    _MapPlace('Pewter Museum of Science', 0.2, 0.4),
    _MapPlace('Pokémon Fan Club', 0.54, 0.68),
    _MapPlace('Pokémon Day Care', 0.66, 0.44),
    _MapPlace('Pokémon League Reception Gate', 0.12, 0.25),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final oceanRect = Offset.zero & size;
    canvas.drawRect(
      oceanRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB9E4E7),
            Color(0xFF8FCBD5),
            Color(0xFFA9DDE0),
          ],
        ).createShader(oceanRect),
    );
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
    canvas.drawPath(
      coast.shift(const Offset(0, 5)),
      Paint()..color = const Color(0xFF6FAEB1).withValues(alpha: .25),
    );
    canvas.drawPath(
      coast,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE4E9BD),
            Color(0xFFC9DCA2),
            Color(0xFFB9D38F),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(
      coast,
      Paint()
        ..color = const Color(0xFF719B72).withValues(alpha: .62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    canvas.drawPath(
      coast,
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Soft terrain washes are decorative texture, not verified geographic data.
    final terrainWashes = <(double, double, double, double, Color)>[
      (.25, .28, .17, .10, Color(0xFF9EBE83)),
      (.47, .34, .20, .12, Color(0xFFE8DDA7)),
      (.68, .59, .16, .13, Color(0xFF9FC68F)),
      (.34, .72, .17, .09, Color(0xFFB7D18E)),
      (.59, .78, .12, .07, Color(0xFFE4D8A1)),
    ];
    for (final wash in terrainWashes) {
      final rect = Rect.fromCenter(
        center: p(wash.$1, wash.$2),
        width: size.width * wash.$3,
        height: size.height * wash.$4,
      );
      canvas.drawOval(rect, Paint()..color = wash.$5.withValues(alpha: .45));
      canvas.drawOval(
        rect.deflate(5),
        Paint()
          ..color = Colors.white.withValues(alpha: .18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Decorative illustrated details only. These tree and hill motifs are
    // intentionally not data markers and do not identify real in-game biomes.
    final treeGroups = <(double, double, double)>[
      (.17, .36, 1.0),
      (.36, .22, .8),
      (.73, .34, .9),
      (.73, .70, 1.0),
      (.49, .83, .75),
    ];
    for (final group in treeGroups) {
      final center = p(group.$1, group.$2);
      final scale = group.$3 * size.width / 900;
      final trunkPaint = Paint()..color = const Color(0xFF987C55).withValues(alpha: .65);
      final leafPaint = Paint()..color = const Color(0xFF6FA879).withValues(alpha: .48);
      final leafLight = Paint()..color = const Color(0xFFB5D99B).withValues(alpha: .62);
      for (var tree = 0; tree < 3; tree++) {
        final offset = Offset((tree - 1) * 10 * scale, (tree.isOdd ? 4 : -2) * scale);
        final base = center + offset;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: base + Offset(0, 5 * scale),
              width: 3.5 * scale,
              height: 10 * scale,
            ),
            Radius.circular(2 * scale),
          ),
          trunkPaint,
        );
        canvas.drawCircle(base, 7 * scale, leafPaint);
        canvas.drawCircle(
          base + Offset(-2 * scale, -2 * scale),
          4 * scale,
          leafLight,
        );
      }
    }

    final hillPaint = Paint()
      ..color = const Color(0xFF8AAE78).withValues(alpha: .36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final hill in <(double, double, double)>[
      (.44, .26, .055),
      (.64, .70, .065),
      (.30, .78, .045),
    ]) {
      final center = p(hill.$1, hill.$2);
      final width = size.width * hill.$3;
      final ridge = Path()
        ..moveTo(center.dx - width, center.dy + width * .24)
        ..quadraticBezierTo(
          center.dx - width * .25,
          center.dy - width * .65,
          center.dx + width * .18,
          center.dy - width * .08,
        )
        ..quadraticBezierTo(
          center.dx + width * .62,
          center.dy - width * .34,
          center.dx + width,
          center.dy + width * .22,
        );
      canvas.drawPath(ridge, hillPaint);
      canvas.drawPath(
        ridge.shift(Offset(0, 4 * size.width / 900)),
        Paint()
          ..color = Colors.white.withValues(alpha: .28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Full 65-location Kanto topology from the bundled audit index. Node positions are schematic layout coordinates, not in-game coordinates.
    const links = <(int, int)>[
      (0,1),
      (0,39),
      (1,2),
      (2,3),
      (2,40),
      (2,52),
      (3,5),
      (3,24),
      (3,4),
      (5,6),
      (5,53),
      (5,61),
      (6,7),
      (7,8),
      (8,9),
      (9,12),
      (9,18),
      (9,10),
      (9,54),
      (9,44),
      (10,11),
      (11,60),
      (12,31),
      (12,13),
      (12,63),
      (13,14),
      (14,31),
      (14,15),
      (15,23),
      (15,45),
      (15,62),
      (15,55),
      (16,31),
      (16,30),
      (16,22),
      (17,21),
      (17,31),
      (17,22),
      (18,19),
      (19,21),
      (19,20),
      (19,46),
      (20,21),
      (21,25),
      (21,47),
      (23,24),
      (23,25),
      (25,26),
      (26,27),
      (27,28),
      (28,29),
      (29,34),
      (29,35),
      (29,51),
      (29,58),
      (30,32),
      (30,48),
      (30,56),
      (31,49),
      (31,57),
      (32,33),
      (33,34),
      (35,36),
      (36,37),
      (36,38),
      (38,39),
      (38,50),
      (38,59),
      (40,64),
      (41,64),
      (41,43),
      (41,42),
      (42,43),
      (43,64),
    ];;
    final roadShadow = Paint()
      ..color = const Color(0xFF8B9C73).withValues(alpha: .30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    final roadEdge = Paint()
      ..color = const Color(0xFFFAF1CE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final roadCenter = Paint()
      ..color = const Color(0xFFE5D49B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < links.length; index++) {
      final link = links[index];
      final a = places[link.$1];
      final b = places[link.$2];
      final start = p(a.x, a.y);
      final end = p(b.x, b.y);
      final midpoint = Offset(
        (start.dx + end.dx) / 2 + (index.isEven ? 9 : -9),
        (start.dy + end.dy) / 2 + (index % 3 == 0 ? -8 : 7),
      );
      final road = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(midpoint.dx, midpoint.dy, end.dx, end.dy);
      canvas.drawPath(road, roadShadow);
      canvas.drawPath(road, roadEdge);
      canvas.drawPath(road, roadCenter);
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
            fontSize: size.width < 360 ? 8 : 9.5,
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
