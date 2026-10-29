import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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

  String _mapDataStatusLabel(String status) {
    switch (status) {
      case 'text_verified_positions_not_mapped':
        return 'Dane opisowe sprawdzone; pinezki niezweryfikowane';
      case 'encounter_rates_verified_from_rotomlabs_positions_not_mapped':
        return 'Szanse spotkań sprawdzone; pinezki niezweryfikowane';
      case 'connection_verified_details_pending':
        return 'Połączenia sprawdzone; szczegóły do uzupełnienia';
      case 'leader_verified_team_needs_review':
        return 'Drużyna lidera wymaga ponownego sprawdzenia';
      case 'schematic_interior_available_exact_layout_pending':
        return 'Schemat wnętrza dostępny; dokładny plan pięter do weryfikacji';
      default:
        return status.replaceAll('_', ' ');
    }
  }

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
      final alreadyInEncounterList = encounters.any((entry) =>
          _normalizePokemonName(entry['name'] ?? '') ==
          _normalizePokemonName(name));
      return !alreadyInEncounterList &&
          pokemonList.any((candidate) =>
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
    final coordinateStatus = location['coordinateStatus']?.toString() ?? 'unverified';
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
              const SizedBox(height: 6),
              Text(
                coordinateStatus == 'verified'
                    ? 'Położenie pinezek: zweryfikowane dla tej lokacji.'
                    : 'Położenie pinezek: niezweryfikowane — mapa jest poglądowa.',
                style: Theme.of(context).textTheme.labelSmall,
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
                'Status danych: ' + _mapDataStatusLabel(dataStatus),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              coordinateStatus == 'verified'
                  ? 'Położenie pinezek: zweryfikowane dla tej lokacji.'
                  : 'Położenie pinezek: niezweryfikowane — mapa jest poglądowa.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
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
                  'Wybierz grę i region, aby przeglądać offline indeks lokacji. Kanto ma wektorową mapę regionu i schematy lokalne; dokładne współrzędne Pokémonów, trenerów i przedmiotów są oznaczane dopiero po weryfikacji.',
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
                                        'Poniżej znajduje się offline’owa, wektorowo rysowana ilustracja Kanto. Zawiera 76 wybieralnych lokacji i 84 połączenia, z malowanymi lasami, górami, miasteczkami, wybrzeżem i wejściami do jaskiń. Kształty terenu i pozycje węzłów są artystycznym schematem, nie mapą w skali ani dokładną kopią map z gry. Wektorowe elementy pozostają gładkie przy powiększaniu.',
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Co działa offline i co wymaga dalszego opracowania',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '• Mapa regionu i wszystkie 76 schematów lokalnych są autorskimi ilustracjami wektorowymi, a nie dokładnymi mapami kafelkowymi z gry.\n• Węzły i strefy pięter są poglądowe; sieć 84 połączeń odpowiada indeksowi lokacji.\n• Dane spotkań i notatki są dostępne offline, ale dokładne pinezki Pokémonów, trenerów i przedmiotów pozostają niezweryfikowane.',
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
                                            avatar: Icon(Icons.waves_outlined, size: 18),
                                            label: Text('Trasy wodne'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.subdirectory_arrow_right, size: 18),
                                            label: Text('Przejścia podziemne'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.park_outlined, size: 18),
                                            label: Text('Ilustrowane lasy'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.landscape_outlined, size: 18),
                                            label: Text('Góry i jaskinie'),
                                          ),
                                          Chip(
                                            avatar: Icon(Icons.home_work_outlined, size: 18),
                                            label: Text('Rysowane budynki'),
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
                                        'Miasta i trasy są pokazane schematycznie. Listy spotkań i notatki z poradników są informacyjne; Pokémony, przedmioty, trenerzy i znajdźki nie mają dokładnych pinezek, dopóki ich położenie nie zostanie zweryfikowane.',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Mapa jest schematyczna i służy do orientacji. Każda lokacja ma już własny schemat lokalny; wierne plany pięter i dokładne pinezki można uzupełnić dopiero po weryfikacji źródłowej.',
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
      'Kierunek północny': 'Północna część Route 2 prowadzi do Viridian Forest i dalej w stronę Pewter City.',
      'Kierunek Viridian Forest': 'Viridian Forest znajduje się pomiędzy południową i północną częścią trasy.',
      "Diglett's Cave (Route 2 entrance)": 'Boczne wejście do Diglett’s Cave; dokładna pozycja nie jest naniesiona.',
      'Pewter City': 'Północny kierunek w stronę Pewter City.',
    },
    'Viridian Forest': {
      'Obszar leśny': 'Poradnik zaleca przejść przez las i szukać Pokémonów oraz przedmiotów. Nie oznaczamy niepotwierdzonych pozycji.',
      'Kierunek Pewter City': 'Po wyjściu z Viridian Forest poradnik prowadzi dalej do Pewter City.',
    },
    'Pewter City': {
      'Miasto Pewter': 'Pewter City jest lokacją po wyjściu z Viridian Forest.',
      'Kierunek Pewter Gym': 'Poradnik wskazuje przygotowanie drużyny przed pierwszym Gymem.',
    },
    'Mt. Moon': {
      'Wejście do jaskini': 'Poglądowy punkt wejścia. Dokładne położenie drabinek i skał wymaga osobnej weryfikacji.',
      'Poziom 1F': 'Warstwa orientacyjna pierwszego poziomu; nie jest wiernym planem kafelków.',
      'Poziom B1F': 'Warstwa orientacyjna niższego poziomu. Nie oznaczono dokładnych pozycji przedmiotów.',
      'Wyjście w stronę Route 4': 'Kierunek wyjścia z jaskini w stronę Route 4.',
    },
    'Rock Tunnel': {
      'Wejście północne': 'Wejście od strony Route 10; symbol nie określa dokładnej kratki.',
      'Poziom 1F': 'Poglądowa warstwa pierwszego poziomu tunelu.',
      'Poziom B1F': 'Poglądowa warstwa podziemna; dokładne przejścia wymagają porównania ze źródłową mapą gry.',
      'Wyjście południowe': 'Kierunek wyjścia w stronę Lavender Town.',
    },
    "Diglett's Cave": {
      'Wejście od Route 2': 'Północne wejście do tunelu, przedstawione schematycznie.',
      'Tunel': 'Długi podziemny korytarz pokazany jako ilustracja, bez dokładnych współrzędnych.',
      'Wyjście przy Route 11': 'Drugie wyjście tunelu; położenie na rysunku jest poglądowe.',
    },
    'Seafoam Islands': {
      'Wejście': 'Wejście do systemu jaskiń; bez dokładnej pinezki.',
      'Poziomy B1F–B2F': 'Poglądowe połączenie poziomów. Nie przedstawia dokładnego układu prądów wodnych.',
      'Poziomy B3F–B4F': 'Dolne poziomy jaskini pokazane jako orientacyjne strefy.',
      'Komnata Articuno': 'Obszar specjalnego spotkania z Articuno; nie oznacza dokładnej kratki.',
    },
    'Cerulean Cave': {
      'Wejście': 'Wejście do jaskini, pokazane schematycznie.',
      'Poziom 1F': 'Orientacyjna strefa pierwszego poziomu.',
      'Poziomy 2F–3F': 'Orientacyjne strefy górnych poziomów.',
      'Komnata Mewtwo': 'Obszar specjalnego spotkania z Mewtwo; pinezka nie jest dokładną pozycją w grze.',
    },
    'Victory Road': {
      'Wejście od Route 23': 'Kierunek wejścia od trasy prowadzącej do Ligi Pokémon.',
      'Poziom 1F': 'Poglądowa strefa pierwszego poziomu.',
      'Poziom 2F': 'Poglądowa strefa środkowego poziomu.',
      'Poziom 3F / wyjście': 'Kierunek wyjścia w stronę Indigo Plateau.',
    },
    'Pokémon Tower': {
      'Piętra 3F–4F': 'Strefa środkowych pięter wieży, pokazana orientacyjnie.',
      'Piętra 5F–6F': 'Strefa wyższych pięter; nie oznaczono dokładnych pozycji trenerów.',
      'Szczyt wieży': 'Obszar wydarzenia fabularnego na górnych piętrach.',
    },
    'Pokémon Mansion': {
      'Parter 1F': 'Poglądowa strefa parteru rezydencji.',
      'Piętra 2F–3F': 'Orientacyjne strefy wyższych pięter.',
      'Piwnica B1F': 'Orientacyjna strefa piwnicy i dokumentów związanych z Mewtwo.',
    },
    'Power Plant': {
      'Wejście': 'Poglądowe wejście do elektrowni.',
      'Hala generatorów': 'Główna strefa obiektu, bez dokładnych pozycji przedmiotów.',
      'Obszar Zapdosa': 'Obszar specjalnego spotkania z Zapdosem; nie jest dokładną pinezką.',
    },
    'S.S. Anne': {
      'Pokład': 'Schematyczna strefa pokładu statku.',
      'Korytarze i kabiny': 'Wnętrze statku przedstawione jako uproszczony układ stref.',
      'Kabina kapitana': 'Obszar wydarzenia z HM Cut; pozycja jest poglądowa.',
    },
    'Cerulean City': {
      'Pokémon Center': 'Punkt leczenia drużyny; budynek pokazany symbolicznie.',
      'Cerulean Gym': 'Gym Misty. Schemat nie odwzorowuje dokładnego wnętrza.',
      'Nugget Bridge / Route 24': 'Północny kierunek wyjścia na Route 24.',
      'Route 5': 'Południowe wyjście w stronę Saffron City przez Route 5.',
    },
    'Vermilion City': {
      'Port': 'Obszar portowy i dostęp do S.S. Anne.',
      'Pokémon Fan Club': 'Budynek klubu fanów Pokémonów.',
      'Vermilion Gym': 'Gym porucznika Surge’a; położenie symboliczne.',
      'Route 11': 'Wschodni kierunek wyjścia na Route 11.',
    },
    'Celadon City': {
      'Department Store': 'Dom towarowy; osobny budynek w mieście.',
      'Game Corner': 'Salon gier Team Rocket.',
      'Celadon Gym': 'Gym Eriki.',
      'Route 16': 'Zachodni kierunek na Route 16.',
    },
    'Saffron City': {
      'Silph Co.': 'Duży budynek korporacji Silph.',
      'Saffron Gym': 'Gym Sabriny.',
      'Fighting Dojo': 'Dojo walki obok Gymu.',
      'Route 6 / Route 8': 'Południowe i zachodnie kierunki wyjścia z miasta.',
    },
    'Lavender Town': {
      'Pokémon Tower': 'Wieża Pokémonów; osobna lokacja z piętrami.',
      'Pokémon Center': 'Punkt leczenia drużyny.',
      'Route 8': 'Zachodni kierunek do Saffron City.',
      'Route 12': 'Południowy kierunek na trasę nadmorską.',
    },
    'Fuchsia City': {
      'Safari Zone': 'Wejście do Safari Zone; nie pokazujemy dokładnych stref wewnętrznych.',
      'Fuchsia Gym': 'Gym Kogi.',
      'GO Park': 'Obiekt Let’s Go związany z przenoszeniem Pokémonów.',
      'Route 15 / Route 18': 'Kierunki na północ i zachód od miasta.',
    },
    'Cinnabar Island': {
      'Pokémon Mansion': 'Ruiny rezydencji z dokumentami o Mewtwo.',
      'Cinnabar Lab': 'Laboratorium na wyspie.',
      'Cinnabar Gym': 'Gym Blaine’a.',
      'Route 21': 'Północny kierunek wodnej trasy do Pallet Town.',
    },
    'Indigo Plateau': {
      'League Reception Gate': 'Wejście do kompleksu Ligi Pokémon.',
      'Victory Road': 'Droga prowadząca do Ligi.',
      'Pokémon Center': 'Punkt przygotowania drużyny przed Ligą.',
    },
    "Player's House": {
      'Pokój gracza': 'Początkowy pokój gracza, pokazany symbolicznie.',
      'Parter': 'Schematyczny obszar domu; układ mebli nie jest dokładną kopią gry.',
      'Wyjście': 'Wyjście prowadzące do Pallet Town.',
    },
    "Professor Oak's Laboratory": {
      'Laboratorium': 'Główna sala laboratorium profesora Oaka.',
      'Stanowisko Oaka': 'Obszar rozmowy fabularnej; bez dokładnych współrzędnych.',
      'Wyjście do Pallet Town': 'Wyjście z laboratorium na zewnątrz.',
    },
    'Celadon Department Store': {
      'Parter': 'Strefa wejścia do domu towarowego.',
      'Piętra sklepowe': 'Uproszczony układ poziomów; dokładne rozmieszczenie stoisk nie jest odwzorowane.',
      'Dach / automat': 'Strefa dachu i automatu z napojami pokazana poglądowo.',
    },
    'Celadon Game Corner': {
      'Sala automatów': 'Główna sala salonu gier.',
      'Posterunek Rocket': 'Ukryte wejście do Team Rocket Hideout jest związane z plakatem; schemat nie podaje dokładnej kratki.',
      'Wyjście': 'Wyjście do Celadon City.',
    },
    'Celadon Condominiums': {
      'Wejście': 'Wejście do budynku mieszkalnego.',
      'Piętra': 'Poglądowe strefy budynku; bez dokładnego planu pomieszczeń.',
      'Pokój twórcy gry': 'W budynku znajduje się znany pokój twórcy gry; położenie jest orientacyjne.',
    },
    'Cinnabar Lab': {
      'Recepcja': 'Strefa wejściowa laboratorium.',
      'Laboratoria badawcze': 'Uproszczone strefy pomieszczeń badawczych.',
      'Wyjście': 'Wyjście na Cinnabar Island.',
    },
    'Fighting Dojo': {
      'Sala treningowa': 'Główna sala dojo.',
      'Trenerzy': 'Obszar walk treningowych; nie oznaczono dokładnych pozycji postaci.',
      'Nagroda': 'Po zwycięstwie można wybrać nagrodę Pokémon; schemat nie wskazuje dokładnej kratki.',
    },
    'GO Park': {
      'Recepcja': 'Wejście do GO Park.',
      'Parki Pokémonów': 'Obszary parku przedstawione symbolicznie.',
      'Wyjście': 'Wyjście do Fuchsia City.',
    },
    'Sea Cottage': {
      'Dom Billa': 'Dom Billa przy Route 25.',
      'Komputer Billa': 'Obszar wydarzenia z teleportacją Billa; pozycja jest poglądowa.',
      'Wyjście na Route 25': 'Droga powrotna w stronę Cerulean City.',
    },
    "Bill's House": {
      'Dom Billa': 'Dom Billa na Route 25, pokazany jako schemat wnętrza.',
      'Terminal': 'Obszar wydarzenia fabularnego; nie oznacza dokładnej kratki.',
      'Wyjście': 'Wyjście w stronę Route 25.',
    },
    'Pewter Museum of Science': {
      'Sala wystawowa': 'Poglądowa sala wystawowa muzeum.',
      'Eksponaty': 'Obszar ekspozycji; nie oznaczono dokładnych pozycji przedmiotów.',
      'Wyjście': 'Wyjście do Pewter City.',
    },
    'Pokémon Fan Club': {
      'Sala klubu': 'Główna sala spotkań klubu.',
      'Przewodniczący': 'Obszar rozmowy i nagrody; bez dokładnej pozycji postaci.',
      'Wyjście': 'Wyjście do Vermilion City.',
    },
    'Pokémon Day Care': {
      'Recepcja': 'Miejsce rozmowy z opiekunem Pokémonów.',
      'Ogród': 'Poglądowy obszar zewnętrzny.',
      'Wyjście': 'Wyjście na trasę.',
    },
    'Team Rocket Hideout': {
      'Wejście w Game Corner': 'Kierunek wejścia ukrytego za plakatem w Celadon Game Corner.',
      'Poziomy podziemne': 'Uproszczone strefy podziemnego kompleksu.',
      'Biuro Giovanniego': 'Obszar walki z Giovannim; bez dokładnych współrzędnych.',
    },
    'Silph Co.': {
      'Hol wejściowy': 'Główna strefa wejściowa budynku.',
      'Piętra biurowe': 'Schematyczne piętra biurowe; układ teleportów i trenerów wymaga osobnej weryfikacji.',
      'Gabinet prezesa': 'Obszar końcowego wydarzenia w budynku.',
    },
    'Viridian Gym': {
      'Sala Gymu': 'Poglądowy plan sali Gymu.',
      'Trenerzy': 'Strefa walk trenerów; bez dokładnych pozycji.',
      'Lider Gymu': 'Obszar walki z Giovannim.',
    },
    'Pewter Gym': {
      'Sala Gymu': 'Poglądowy plan sali Gymu.',
      'Trenerzy': 'Strefa walki przed liderem.',
      'Brock': 'Obszar walki z Brockiem; schemat nie odwzorowuje dokładnych kafelków.',
    },
    'Cerulean Gym': {
      'Sala Gymu': 'Poglądowy plan sali Gymu.',
      'Basen': 'Motyw basenu pokazany dekoracyjnie.',
      'Misty': 'Obszar walki z Misty.',
    },
    'Vermilion Gym': {
      'Sala Gymu': 'Poglądowy plan sali Gymu.',
      'Przełączniki': 'Zagadkę przełączników należy traktować jako opis, nie dokładną mapę koszy.',
      'Lt. Surge': 'Obszar walki z porucznikiem Surge’em.',
    },
    'Celadon Gym': {
      'Sala Gymu': 'Poglądowy plan sali Gymu.',
      'Roślinność': 'Motyw roślinny sali przedstawiony dekoracyjnie.',
      'Erika': 'Obszar walki z Eriką.',
    },
    'Saffron Gym': {
      'Sala Gymu': 'Poglądowy plan sali Gymu.',
      'Teleporty': 'Strefa zagadki teleportów; dokładne połączenia nie są tu odwzorowane.',
      'Sabrina': 'Obszar walki z Sabriną.',
    },
    'Fuchsia Gym': {
      'Sala Gymu': 'Poglądowy plan sali Gymu.',
      'Niewidzialne ściany': 'Motyw zagadki sali pokazany symbolicznie.',
      'Koga': 'Obszar walki z Kogą.',
    },
    'Cinnabar Gym': {
      'Sala Gymu': 'Poglądowy plan sali Gymu.',
      'Pytania quizowe': 'Obszar automatów z pytaniami; bez dokładnych pozycji.',
      'Blaine': 'Obszar walki z Blaine’em.',
    },
    'Route 3': {
      'Pewter City': 'Zachodni koniec trasy przy Pewter City.',
      'Obszar spotkań': 'Poglądowy pas trawy i drogi; nie oznacza dokładnych spawnów.',
      'Mt. Moon': 'Wschodni koniec trasy prowadzi do wejścia Mt. Moon.',
    },
    'Route 4': {
      'Mt. Moon': 'Zachodni koniec przy wyjściu z Mt. Moon.',
      'Odcinek trasy': 'Schematyczny pas drogi; bez dokładnych pozycji przedmiotów.',
      'Cerulean City': 'Wschodni koniec trasy przy Cerulean City.',
    },
    'Route 5': {
      'Cerulean City': 'Północny kierunek trasy.',
      'Pokémon Day Care': 'Obiekt przy trasie; nie pokazujemy dokładnych współrzędnych.',
      'Saffron City': 'Południowy kierunek w stronę Saffron City.',
    },
    'Route 6': {
      'Saffron City': 'Północny koniec trasy.',
      'Obszar spotkań': 'Poglądowy odcinek drogi.',
      'Vermilion City': 'Południowy koniec trasy przy Vermilion City.',
    },
    'Route 7': {
      'Celadon City': 'Zachodni koniec trasy.',
      'Odcinek trasy': 'Krótki korytarz drogowy przedstawiony schematycznie.',
      'Saffron City': 'Wschodni koniec trasy.',
    },
    'Route 8': {
      'Saffron City': 'Wschodni koniec trasy.',
      'Odcinek trasy': 'Poglądowy pas drogi i trawy.',
      'Lavender Town': 'Zachodni koniec trasy.',
    },
    'Route 9': {
      'Cerulean City': 'Zachodni koniec trasy.',
      'Odcinek trasy': 'Poglądowy korytarz drogi w stronę Rock Tunnel.',
      'Route 10': 'Wschodni koniec trasy.',
    },
    'Route 10': {
      'Route 9': 'Północny kierunek trasy.',
      'Power Plant': 'Odgałęzienie prowadzące do elektrowni.',
      'Rock Tunnel / Lavender Town': 'Odcinek przy wejściu do Rock Tunnel i kierunku Lavender Town.',
    },
    'Route 11': {
      'Vermilion City': 'Zachodni koniec trasy.',
      "Diglett's Cave": 'Wejście do Diglett’s Cave znajduje się przy trasie.',
      "Diglett's Cave (Route 11 entrance)": 'Wejście do tunelu znajduje się przy tej trasie.',
    },
    'Route 12': {
      'Lavender Town': 'Północny koniec trasy.',
      'Obszar spotkań': 'Poglądowy długi odcinek przy wodzie; bez dokładnych pinezek.',
      'Route 13': 'Południowy kierunek trasy.',
    },
    'Route 13': {
      'Route 12': 'Północny koniec trasy.',
      'Obszar spotkań': 'Schematyczny odcinek nadmorski.',
      'Route 14': 'Południowy kierunek trasy.',
    },
    'Route 14': {
      'Route 13': 'Północny koniec trasy.',
      'Obszar spotkań': 'Schematyczny odcinek drogi i trawy.',
      'Route 15': 'Południowy kierunek trasy.',
    },
    'Route 15': {
      'Route 14': 'Północny koniec trasy.',
      'Obszar spotkań': 'Schematyczny odcinek w stronę Fuchsia City.',
      'Fuchsia City': 'Południowy koniec trasy.',
    },
    'Route 16': {
      'Celadon City': 'Wschodni kierunek trasy.',
      'Snorlax area': 'Obszar specjalnego spotkania; położenie nie jest pinezką.',
      'Route 17': 'Zachodni kierunek prowadzący do Cycling Road.',
    },
    'Route 17': {
      'Route 16': 'Północny koniec Cycling Road.',
      'Cycling Road': 'Długi korytarz trasy pokazany poglądowo.',
      'Route 18': 'Południowy koniec trasy.',
    },
    'Route 18': {
      'Route 17': 'Północny kierunek Cycling Road.',
      'Fuchsia City': 'Wschodni koniec trasy przy Fuchsia City.',
      'Odcinek trasy': 'Poglądowy korytarz drogi.',
    },
    'Route 19': {
      'Fuchsia City': 'Północny koniec wodnej trasy.',
      'Wodny korytarz': 'Schematyczny przebieg drogi wodnej, nie mapa kafelków.',
      'Route 20': 'Południowy kierunek do Route 20.',
    },
    'Route 20': {
      'Route 19': 'Wschodni koniec trasy wodnej.',
      'Seafoam Islands': 'Wyspy leżą przy trasie wodnej.',
      'Cinnabar Island': 'Zachodni kierunek w stronę Cinnabar Island.',
    },
    'Route 21': {
      'Pallet Town': 'Północny koniec wodnej trasy.',
      'Wodny korytarz': 'Schematyczna trasa wodna bez dokładnych pinezek.',
      'Cinnabar Island': 'Południowy koniec trasy przy wyspie.',
    },
    'Route 22': {
      'Viridian City': 'Wschodni początek trasy.',
      'Obszar spotkań': 'Poglądowy odcinek przed wejściem do Ligi.',
      'Pokémon League Reception Gate': 'Zachodni kierunek w stronę bramy Ligi.',
    },
    'Route 23': {
      'Pokémon League Reception Gate': 'Północny początek trasy.',
      'Victory Road': 'Wejście do Victory Road znajduje się na trasie.',
      'Indigo Plateau': 'Południowy koniec prowadzi do Ligi Pokémon.',
    },
    'Route 24': {
      'Cerulean City': 'Południowy początek trasy i Nugget Bridge.',
      'Most / trenerzy': 'Poglądowy obszar mostu i walk trenerów.',
      'Route 25': 'Północny koniec prowadzący do domu Billa.',
    },
    'Route 25': {
      'Route 24': 'Południowy koniec trasy.',
      'Sea Cottage / Bill’s House': 'Obszar domu Billa; pozycja na schemacie jest orientacyjna.',
      'Ślepy koniec trasy': 'Północno-wschodni koniec drogi.',
    },
    'Underground Path (Routes 5–6)': {
      'Wejście Route 5': 'Jedno z wejść podziemnego przejścia.',
      'Tunel': 'Schematyczny tunel pod powierzchnią.',
      'Wyjście Route 6': 'Drugie wejście/wyjście przejścia.',
    },
    'Underground Path (Routes 7–8)': {
      'Wejście Route 7': 'Jedno z wejść podziemnego przejścia.',
      'Tunel': 'Schematyczny tunel pod powierzchnią.',
      'Wyjście Route 8': 'Drugie wejście/wyjście przejścia.',
    },
    'Safari Zone': {
      'Wejście / recepcja': 'Punkt wejścia do Safari Zone.',
      'Obszary safari': 'Kilka stref pokazanych jako uproszczony plan; nie odwzorowuje dokładnych ścieżek i przedmiotów.',
      'Secret House': 'Obszar nagrody HM Surf; dokładna pozycja nie jest pinezką.',
      'Wyjście do Fuchsia City': 'Powrót do miasta.',
    },
    'Pokémon League Reception Gate': {
      'Wejście od Route 23': 'Południowy kierunek wejścia do bramy Ligi.',
      'Punkty kontroli': 'Strefa kontroli odznak; układ jest schematyczny.',
      'Wyjście do Indigo Plateau': 'Kierunek wejścia do kompleksu Ligi Pokémon.',
    },
    "Diglett's Cave (Route 2 entrance)": {
      'Wejście od Route 2': 'Północne wejście do jaskini; dokładne współrzędne nie są potwierdzone.',
      'Korytarz': 'Schematyczny korytarz łączący wejście z systemem jaskini.',
      "Diglett's Cave": 'Dalsza część systemu jaskini.',
    },
    "Diglett's Cave (Route 11 entrance)": {
      'Wejście od Route 11': 'Wschodnie wejście do jaskini; dokładne współrzędne nie są potwierdzone.',
      'Korytarz': 'Schematyczny korytarz podziemny w stronę głównej jaskini.',
      "Diglett's Cave": 'Dalsza część systemu jaskini.',
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

  static const Map<String, (String, String)> _routeEndpoints = {
    'Route 3': ('Pewter City', 'Mt. Moon'),
    'Route 4': ('Mt. Moon', 'Cerulean City'),
    'Route 5': ('Cerulean City', 'Saffron City'),
    'Route 6': ('Saffron City', 'Vermilion City'),
    'Route 7': ('Celadon City', 'Saffron City'),
    'Route 8': ('Saffron City', 'Lavender Town'),
    'Route 9': ('Cerulean City', 'Route 10'),
    'Route 10': ('Route 9', 'Lavender Town'),
    'Route 11': ('Vermilion City', "Diglett's Cave (Route 11 entrance)"),
    'Route 12': ('Lavender Town', 'Route 13'),
    'Route 13': ('Route 12', 'Route 14'),
    'Route 14': ('Route 13', 'Route 15'),
    'Route 15': ('Route 14', 'Fuchsia City'),
    'Route 16': ('Celadon City', 'Route 17'),
    'Route 17': ('Route 16', 'Route 18'),
    'Route 18': ('Route 17', 'Fuchsia City'),
    'Route 19': ('Fuchsia City', 'Route 20'),
    'Route 20': ('Route 19', 'Cinnabar Island'),
    'Route 21': ('Pallet Town', 'Cinnabar Island'),
    'Route 22': ('Viridian City', 'Pokémon League Reception Gate'),
    'Route 23': ('Pokémon League Reception Gate', 'Indigo Plateau'),
    'Route 24': ('Cerulean City', 'Route 25'),
    'Route 25': ('Route 24', 'Sea Cottage'),
    'Underground Path (Routes 5–6)': ('Route 5', 'Route 6'),
    'Underground Path (Routes 7–8)': ('Route 7', 'Route 8'),
  };

  const _KantoLocalAreaPainter({
    required this.location,
    required this.land,
    required this.route,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..isAntiAlias = true..color = land);
    final zoneFill = Paint()..isAntiAlias = true..color = const Color(0xFFD8D9BD).withValues(alpha: .88);
    final zoneEdge = Paint()..isAntiAlias = true
      ..color = const Color(0xFF788B71).withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    void drawZone(double x, double y, double w, double h) {
      final rect = Rect.fromLTWH(
        size.width * x,
        size.height * y,
        size.width * w,
        size.height * h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        zoneFill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(7)),
        zoneEdge,
      );
    }

    final roadPaint = Paint()..isAntiAlias = true
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
    } else if (location == 'Mt. Moon') {
      drawZone(.08, .26, .25, .28);
      drawZone(.38, .16, .24, .30);
      drawZone(.67, .29, .24, .28);
      path
        ..moveTo(size.width * .12, size.height * .40)
        ..quadraticBezierTo(size.width * .30, size.height * .18, size.width * .49, size.height * .31)
        ..quadraticBezierTo(size.width * .72, size.height * .48, size.width * .87, size.height * .43);
    } else if (location == 'Rock Tunnel') {
      drawZone(.08, .20, .25, .24);
      drawZone(.37, .38, .25, .25);
      drawZone(.67, .18, .24, .25);
      path
        ..moveTo(size.width * .12, size.height * .32)
        ..lineTo(size.width * .39, size.height * .50)
        ..quadraticBezierTo(size.width * .55, size.height * .65, size.width * .73, size.height * .32)
        ..lineTo(size.width * .87, size.height * .30);
    } else if (location == "Diglett's Cave") {
      drawZone(.08, .33, .23, .30);
      drawZone(.37, .39, .27, .18);
      drawZone(.69, .33, .23, .30);
      path
        ..moveTo(size.width * .14, size.height * .48)
        ..quadraticBezierTo(size.width * .50, size.height * .22, size.width * .86, size.height * .48);
    } else if (location == "Diglett's Cave (Route 2 entrance)" ||
        location == "Diglett's Cave (Route 11 entrance)") {
      drawZone(.12, .30, .28, .34);
      drawZone(.48, .38, .38, .20);
      path
        ..moveTo(size.width * .22, size.height * .47)
        ..quadraticBezierTo(size.width * .45, size.height * .27, size.width * .70, size.height * .48);
    } else if (location == 'Seafoam Islands') {
      drawZone(.08, .20, .24, .25);
      drawZone(.38, .38, .24, .25);
      drawZone(.68, .18, .24, .25);
      drawZone(.37, .68, .26, .18);
      path
        ..moveTo(size.width * .19, size.height * .32)
        ..lineTo(size.width * .47, size.height * .49)
        ..lineTo(size.width * .78, size.height * .30)
        ..lineTo(size.width * .50, size.height * .76);
    } else if (location == 'Cerulean Cave') {
      drawZone(.08, .23, .24, .25);
      drawZone(.38, .14, .24, .25);
      drawZone(.68, .25, .24, .25);
      drawZone(.38, .58, .24, .22);
      path
        ..moveTo(size.width * .18, size.height * .35)
        ..lineTo(size.width * .48, size.height * .26)
        ..lineTo(size.width * .78, size.height * .37)
        ..lineTo(size.width * .50, size.height * .68);
    } else if (location == 'Victory Road') {
      drawZone(.08, .22, .23, .24);
      drawZone(.38, .42, .23, .24);
      drawZone(.68, .20, .23, .24);
      path
        ..moveTo(size.width * .13, size.height * .34)
        ..quadraticBezierTo(size.width * .34, size.height * .65, size.width * .50, size.height * .53)
        ..quadraticBezierTo(size.width * .69, size.height * .38, size.width * .86, size.height * .32);
    } else if (location == 'Pokémon Tower') {
      drawZone(.12, .20, .30, .22);
      drawZone(.58, .20, .30, .22);
      drawZone(.12, .54, .30, .22);
      drawZone(.58, .54, .30, .22);
      path
        ..moveTo(size.width * .27, size.height * .31)
        ..lineTo(size.width * .73, size.height * .31)
        ..lineTo(size.width * .73, size.height * .65)
        ..lineTo(size.width * .27, size.height * .65);
    } else if (location == 'Pokémon Mansion') {
      drawZone(.12, .20, .30, .22);
      drawZone(.58, .20, .30, .22);
      drawZone(.12, .54, .30, .22);
      drawZone(.58, .54, .30, .22);
      path
        ..moveTo(size.width * .27, size.height * .31)
        ..lineTo(size.width * .73, size.height * .31)
        ..lineTo(size.width * .73, size.height * .65)
        ..lineTo(size.width * .27, size.height * .65);
    } else if (location == 'Power Plant') {
      drawZone(.08, .26, .24, .28);
      drawZone(.38, .16, .24, .48);
      drawZone(.68, .26, .24, .28);
      path
        ..moveTo(size.width * .18, size.height * .40)
        ..lineTo(size.width * .50, size.height * .40)
        ..lineTo(size.width * .80, size.height * .40);
    } else if (location == 'S.S. Anne') {
      drawZone(.12, .18, .76, .22);
      drawZone(.12, .47, .76, .22);
      drawZone(.37, .75, .26, .12);
      path
        ..moveTo(size.width * .20, size.height * .29)
        ..lineTo(size.width * .80, size.height * .29)
        ..moveTo(size.width * .20, size.height * .58)
        ..lineTo(size.width * .80, size.height * .58)
        ..moveTo(size.width * .50, size.height * .58)
        ..lineTo(size.width * .50, size.height * .80);
    } else if ({
      'Cerulean City',
      'Vermilion City',
      'Celadon City',
      'Saffron City',
      'Lavender Town',
      'Fuchsia City',
      'Cinnabar Island',
      'Indigo Plateau',
    }.contains(location)) {
      drawZone(.10, .20, .25, .22);
      drawZone(.39, .16, .24, .24);
      drawZone(.67, .22, .23, .22);
      drawZone(.22, .55, .25, .22);
      drawZone(.55, .55, .25, .22);
      path
        ..moveTo(size.width * .22, size.height * .31)
        ..lineTo(size.width * .50, size.height * .28)
        ..lineTo(size.width * .79, size.height * .33)
        ..moveTo(size.width * .50, size.height * .28)
        ..lineTo(size.width * .35, size.height * .66)
        ..lineTo(size.width * .68, size.height * .66);
    } else if (location == 'Safari Zone') {
      drawZone(.08, .20, .34, .25);
      drawZone(.56, .16, .34, .25);
      drawZone(.12, .57, .30, .23);
      drawZone(.58, .55, .30, .25);
      path
        ..moveTo(size.width * .24, size.height * .32)
        ..quadraticBezierTo(size.width * .52, size.height * .44, size.width * .72, size.height * .29)
        ..lineTo(size.width * .73, size.height * .66)
        ..lineTo(size.width * .28, size.height * .68);
    } else if (location == 'Pokémon League Reception Gate') {
      drawZone(.10, .25, .25, .30);
      drawZone(.39, .25, .22, .30);
      drawZone(.66, .25, .25, .30);
      path
        ..moveTo(size.width * .12, size.height * .40)
        ..lineTo(size.width * .88, size.height * .40);
    } else if (location.startsWith('Route ') ||
        location.startsWith('Underground Path')) {
      final isWaterRoute = {'Route 19', 'Route 20', 'Route 21'}.contains(location);
      final sidePaint = Paint()..isAntiAlias = true
        ..color = (isWaterRoute
                ? const Color(0xFF8BCBD2)
                : const Color(0xFF9ABF7E))
            .withValues(alpha: .62);
      for (final patch in <Rect>[
        Rect.fromLTWH(size.width * .10, size.height * .18, size.width * .20, size.height * .16),
        Rect.fromLTWH(size.width * .39, size.height * .64, size.width * .22, size.height * .15),
        Rect.fromLTWH(size.width * .70, size.height * .20, size.width * .18, size.height * .17),
      ]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(patch, const Radius.circular(12)),
          sidePaint,
        );
      }
      path
        ..moveTo(size.width * .10, size.height * .80)
        ..cubicTo(size.width * .25, size.height * .62, size.width * .34, size.height * .28, size.width * .52, size.height * .48)
        ..cubicTo(size.width * .66, size.height * .65, size.width * .73, size.height * .30, size.width * .90, size.height * .18);
      if (location.startsWith('Underground Path')) {
        drawZone(.12, .36, .76, .28);
      }
    } else if (location.endsWith('Gym') ||
        {
          "Player's House",
          "Professor Oak's Laboratory",
          'Celadon Department Store',
          'Celadon Game Corner',
          'Celadon Condominiums',
          'Cinnabar Lab',
          'Fighting Dojo',
          'GO Park',
          'Sea Cottage',
          "Bill's House",
          'Pewter Museum of Science',
          'Pokémon Fan Club',
          'Pokémon Day Care',
          'Team Rocket Hideout',
          'Silph Co.',
        }.contains(location)) {
      drawZone(.12, .20, .30, .22);
      drawZone(.58, .20, .30, .22);
      drawZone(.12, .55, .30, .22);
      drawZone(.58, .55, .30, .22);
      path
        ..moveTo(size.width * .27, size.height * .31)
        ..lineTo(size.width * .73, size.height * .31)
        ..lineTo(size.width * .73, size.height * .66)
        ..lineTo(size.width * .27, size.height * .66)
        ..close();
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
        ("Diglett's Cave entrance", Offset(size.width * .39, size.height * .60)),
        ('Viridian Forest', Offset(size.width * .60, size.height * .38)),
        ('Pewter City', Offset(size.width * .88, size.height * .12)),
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
        canvas.drawCircle(point, 10, Paint()..isAntiAlias = true..color = route.withValues(alpha: .18));
        canvas.drawCircle(point, 5, Paint()..isAntiAlias = true..color = route.withValues(alpha: .5));
      }
    } else if (location == 'Mt. Moon') {
      markers.addAll([
        ('Wejście', Offset(size.width * .18, size.height * .40)),
        ('1F', Offset(size.width * .49, size.height * .31)),
        ('B1F', Offset(size.width * .78, size.height * .43)),
        ('Wyjście Route 4', Offset(size.width * .78, size.height * .54)),
      ]);
    } else if (location == 'Rock Tunnel') {
      markers.addAll([
        ('Wejście Route 10', Offset(size.width * .18, size.height * .32)),
        ('1F', Offset(size.width * .48, size.height * .50)),
        ('B1F', Offset(size.width * .77, size.height * .31)),
        ('Wyjście', Offset(size.width * .79, size.height * .48)),
      ]);
    } else if (location == "Diglett's Cave") {
      markers.addAll([
        ('Route 2', Offset(size.width * .18, size.height * .47)),
        ('Tunel', Offset(size.width * .50, size.height * .48)),
        ('Route 11', Offset(size.width * .80, size.height * .47)),
      ]);
    } else if (location == "Diglett's Cave (Route 2 entrance)") {
      markers.addAll([
        ('Route 2', Offset(size.width * .22, size.height * .47)),
        ('Wejście', Offset(size.width * .38, size.height * .46)),
        ("Diglett's Cave", Offset(size.width * .70, size.height * .48)),
      ]);
    } else if (location == "Diglett's Cave (Route 11 entrance)") {
      markers.addAll([
        ('Route 11', Offset(size.width * .22, size.height * .47)),
        ('Wejście', Offset(size.width * .38, size.height * .46)),
        ("Diglett's Cave", Offset(size.width * .70, size.height * .48)),
      ]);
    } else if (location == 'Seafoam Islands') {
      markers.addAll([
        ('Wejście', Offset(size.width * .18, size.height * .30)),
        ('B1F–B2F', Offset(size.width * .49, size.height * .49)),
        ('B3F–B4F', Offset(size.width * .79, size.height * .30)),
        ('Articuno', Offset(size.width * .50, size.height * .76)),
      ]);
    } else if (location == 'Cerulean Cave') {
      markers.addAll([
        ('Wejście', Offset(size.width * .18, size.height * .34)),
        ('1F', Offset(size.width * .49, size.height * .26)),
        ('2F–3F', Offset(size.width * .79, size.height * .36)),
        ('Mewtwo', Offset(size.width * .50, size.height * .68)),
      ]);
    } else if (location == 'Victory Road') {
      markers.addAll([
        ('Route 23', Offset(size.width * .18, size.height * .34)),
        ('1F', Offset(size.width * .49, size.height * .53)),
        ('2F', Offset(size.width * .78, size.height * .32)),
        ('3F / Liga', Offset(size.width * .82, size.height * .48)),
      ]);
    } else if (location == 'Pokémon Tower') {
      markers.addAll([
        ('3F–4F', Offset(size.width * .27, size.height * .31)),
        ('5F–6F', Offset(size.width * .73, size.height * .31)),
        ('5F', Offset(size.width * .27, size.height * .65)),
        ('Szczyt', Offset(size.width * .73, size.height * .65)),
      ]);
    } else if (location == 'Pokémon Mansion') {
      markers.addAll([
        ('1F', Offset(size.width * .27, size.height * .31)),
        ('2F', Offset(size.width * .73, size.height * .31)),
        ('3F', Offset(size.width * .27, size.height * .65)),
        ('B1F', Offset(size.width * .73, size.height * .65)),
      ]);
    } else if (location == 'Power Plant') {
      markers.addAll([
        ('Wejście', Offset(size.width * .18, size.height * .40)),
        ('Generatory', Offset(size.width * .50, size.height * .40)),
        ('Zapdos', Offset(size.width * .80, size.height * .40)),
      ]);
    } else if (location == 'S.S. Anne') {
      markers.addAll([
        ('Pokład', Offset(size.width * .50, size.height * .29)),
        ('Kabiny', Offset(size.width * .50, size.height * .58)),
        ('Kapitan', Offset(size.width * .50, size.height * .80)),
      ]);
    } else if (location == 'Cerulean City') {
      markers.addAll([
        ('Pokémon Center', Offset(size.width * .22, size.height * .31)),
        ('Cerulean Gym', Offset(size.width * .50, size.height * .28)),
        ('Route 24', Offset(size.width * .79, size.height * .33)),
        ('Route 5', Offset(size.width * .35, size.height * .66)),
      ]);
    } else if (location == 'Vermilion City') {
      markers.addAll([
        ('Port / S.S. Anne', Offset(size.width * .22, size.height * .31)),
        ('Fan Club', Offset(size.width * .50, size.height * .28)),
        ('Vermilion Gym', Offset(size.width * .79, size.height * .33)),
        ('Route 11', Offset(size.width * .68, size.height * .66)),
      ]);
    } else if (location == 'Celadon City') {
      markers.addAll([
        ('Department Store', Offset(size.width * .22, size.height * .31)),
        ('Game Corner', Offset(size.width * .50, size.height * .28)),
        ('Celadon Gym', Offset(size.width * .79, size.height * .33)),
        ('Route 16', Offset(size.width * .35, size.height * .66)),
      ]);
    } else if (location == 'Saffron City') {
      markers.addAll([
        ('Silph Co.', Offset(size.width * .22, size.height * .31)),
        ('Saffron Gym', Offset(size.width * .50, size.height * .28)),
        ('Fighting Dojo', Offset(size.width * .79, size.height * .33)),
        ('Route 6 / 8', Offset(size.width * .68, size.height * .66)),
      ]);
    } else if (location == 'Lavender Town') {
      markers.addAll([
        ('Pokémon Tower', Offset(size.width * .22, size.height * .31)),
        ('Pokémon Center', Offset(size.width * .50, size.height * .28)),
        ('Route 8', Offset(size.width * .79, size.height * .33)),
        ('Route 12', Offset(size.width * .68, size.height * .66)),
      ]);
    } else if (location == 'Fuchsia City') {
      markers.addAll([
        ('Safari Zone', Offset(size.width * .22, size.height * .31)),
        ('Fuchsia Gym', Offset(size.width * .50, size.height * .28)),
        ('GO Park', Offset(size.width * .79, size.height * .33)),
        ('Route 15 / 18', Offset(size.width * .68, size.height * .66)),
      ]);
    } else if (location == 'Cinnabar Island') {
      markers.addAll([
        ('Pokémon Mansion', Offset(size.width * .22, size.height * .31)),
        ('Cinnabar Lab', Offset(size.width * .50, size.height * .28)),
        ('Cinnabar Gym', Offset(size.width * .79, size.height * .33)),
        ('Route 21', Offset(size.width * .68, size.height * .66)),
      ]);
    } else if (location == 'Indigo Plateau') {
      markers.addAll([
        ('League Gate', Offset(size.width * .22, size.height * .31)),
        ('Pokémon Center', Offset(size.width * .50, size.height * .28)),
        ('Victory Road', Offset(size.width * .79, size.height * .33)),
      ]);
    } else if (location == 'Safari Zone') {
      markers.addAll([
        ('Wejście', Offset(size.width * .25, size.height * .32)),
        ('Strefa safari', Offset(size.width * .72, size.height * .29)),
        ('Secret House', Offset(size.width * .27, size.height * .68)),
        ('Wyjście', Offset(size.width * .73, size.height * .67)),
      ]);
    } else if (location == 'Pokémon League Reception Gate') {
      markers.addAll([
        ('Route 23', Offset(size.width * .22, size.height * .40)),
        ('Kontrola odznak', Offset(size.width * .50, size.height * .40)),
        ('Indigo Plateau', Offset(size.width * .78, size.height * .40)),
      ]);
    } else if (location.startsWith('Route ') ||
        location.startsWith('Underground Path')) {
      final endpoints = _routeEndpoints[location];
      markers.addAll([
        (endpoints?.$1 ?? 'Początek trasy', Offset(size.width * .15, size.height * .76)),
        ('Odcinek środkowy', Offset(size.width * .52, size.height * .48)),
        (endpoints?.$2 ?? 'Koniec trasy', Offset(size.width * .85, size.height * .22)),
      ]);
    } else if (location.endsWith('Gym')) {
      markers.addAll([
        ('Sala Gymu', Offset(size.width * .27, size.height * .31)),
        ('Trenerzy', Offset(size.width * .73, size.height * .31)),
        ('Lider', Offset(size.width * .27, size.height * .65)),
        ('Wyjście', Offset(size.width * .73, size.height * .65)),
      ]);
    } else if ({
      "Player's House",
      "Professor Oak's Laboratory",
      'Celadon Department Store',
      'Celadon Game Corner',
      'Celadon Condominiums',
      'Cinnabar Lab',
      'Fighting Dojo',
      'GO Park',
      'Sea Cottage',
      "Bill's House",
      'Pewter Museum of Science',
      'Pokémon Fan Club',
      'Pokémon Day Care',
      'Team Rocket Hideout',
      'Silph Co.',
    }.contains(location)) {
      markers.addAll([
        ('Wejście', Offset(size.width * .27, size.height * .31)),
        ('Główna sala', Offset(size.width * .73, size.height * .31)),
        ('Strefa wewnętrzna', Offset(size.width * .27, size.height * .65)),
        ('Wyjście', Offset(size.width * .73, size.height * .65)),
      ]);
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
          marker.$1.contains('Department') ||
          marker.$1.contains('Game Corner') ||
          marker.$1.contains('Silph') ||
          marker.$1.contains('Dojo') ||
          marker.$1.contains('Mansion') ||
          marker.$1.contains('Lab') ||
          marker.$1.contains('Tower') ||
          marker.$1.contains('Center') ||
          marker.$1 == 'Miasto';
      if (isBuilding) {
        final rect = Rect.fromCenter(center: point, width: 18, height: 14);
        canvas.drawRect(rect, Paint()..isAntiAlias = true..color = route.withValues(alpha: .65));
        final roof = Path()
          ..moveTo(rect.left - 3, rect.top)
          ..lineTo(point.dx, rect.top - 9)
          ..lineTo(rect.right + 3, rect.top)
          ..close();
        canvas.drawPath(roof, Paint()..isAntiAlias = true..color = route);
      } else {
        canvas.drawCircle(point, 7, Paint()..isAntiAlias = true..color = route);
        canvas.drawCircle(point, 2.5, Paint()..isAntiAlias = true..color = Colors.white);
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
      final labelRect = Rect.fromLTWH(
        dx - 3,
        dy - 2,
        text.width + 6,
        text.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..isAntiAlias = true..color = const Color(0xFFF8F1D9).withValues(alpha: .88),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..isAntiAlias = true
          ..color = const Color(0xFF78906F).withValues(alpha: .42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
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
  static const double _mapWidth = 900;
  static const double _mapHeight = 660;
  static const double _nearbyRadius = 95;
  final TransformationController _transformController =
      TransformationController();
  Timer? _hideLocationTimer;
  String? _visibleLocation;
  bool _initialPositionSet = false;
  Size? _lastViewportSize;
  bool _hasUserInteracted = false;

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
      final dx = sceneCenter.dx - place.x * _mapWidth;
      final dy = sceneCenter.dy - place.y * _mapHeight;
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

  void _zoomBy(double factor, Size viewport) {
    _hasUserInteracted = true;
    final current = _transformController.value;
    final currentScale = current.getMaxScaleOnAxis().clamp(0.35, 4.0).toDouble();
    final nextScale = (currentScale * factor).clamp(0.35, 4.0).toDouble();
    if ((nextScale - currentScale).abs() < 0.001) return;
    final actualFactor = nextScale / currentScale;
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final zoomAtCenter = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(actualFactor)
      ..translate(-center.dx, -center.dy);
    _transformController.value = zoomAtCenter * current;
  }

  double _fitScale(Size viewport) {
    final horizontalFit = (viewport.width - 20) / _mapWidth;
    final verticalFit = (viewport.height - 20) / _mapHeight;
    return math.min(horizontalFit, verticalFit).clamp(0.35, 2.0).toDouble();
  }

  void _resetMap(Size viewport) {
    _hasUserInteracted = false;
    _lastViewportSize = viewport;
    final scale = _fitScale(viewport);
    _transformController.value = Matrix4.identity()
      ..translate(
        (viewport.width - _mapWidth * scale) / 2,
        (viewport.height - _mapHeight * scale) / 2,
      )
      ..scale(scale);
  }

  void _selectTappedPlace(Offset tap) {
    final scale = _transformController.value.getMaxScaleOnAxis().clamp(0.35, 4.0).toDouble();
    final symbolHitRadius = 14 / scale;
    final locationHitRadius = 38 / scale;
    // These two symbols sit beside the Route 1 node. Treat them as separate
    // targets so tapping a symbol explains its meaning, not just the town.
    final routeOne = _KantoMapPainter.places.firstWhere(
      (place) => place.name == 'Route 1',
    );
    final routeX = routeOne.x * _mapWidth;
    final routeY = routeOne.y * _mapHeight;
    final informationCenter = Offset(routeX - 12, routeY - 15);
    final areaCenter = Offset(routeX + 13, routeY - 15);

    if ((tap - informationCenter).distance <= symbolHitRadius) {
      _showLocation('Route 1 • informacje z poradnika');
      widget.onLocationSelected('Route 1');
      return;
    }
    if ((tap - areaCenter).distance <= symbolHitRadius) {
      _showLocation('Route 1 • obszar poglądowy');
      widget.onLocationSelected('Route 1');
      return;
    }

    _MapPlace? nearest;
    var nearestDistance = double.infinity;
    for (final place in _KantoMapPainter.places) {
      final dx = tap.dx - place.x * _mapWidth;
      final dy = tap.dy - place.y * _mapHeight;
      final distance = dx * dx + dy * dy;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = place;
      }
    }
    if (nearest != null && nearestDistance < locationHitRadius * locationHitRadius) {
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
        aspectRatio: screenWidth < 500 ? 1.18 : 1.35,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportSize = constraints.biggest;
            final viewportChanged = _lastViewportSize != viewportSize;
            if (!_initialPositionSet ||
                (viewportChanged && !_hasUserInteracted)) {
              _initialPositionSet = true;
              _lastViewportSize = viewportSize;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final scale = _fitScale(viewportSize);
                _transformController.value = Matrix4.identity()
                  ..translate(
                    (viewportSize.width - _mapWidth * scale) / 2,
                    (viewportSize.height - _mapHeight * scale) / 2,
                  )
                  ..scale(scale);
              });
            } else if (viewportChanged) {
              _lastViewportSize = viewportSize;
            }
            return Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    constrained: false,
                    minScale: 0.35,
                    maxScale: 4,
                    boundaryMargin: const EdgeInsets.all(160),
                    onInteractionUpdate: (_) {
                      _hasUserInteracted = true;
                      _centeredLocation(constraints.biggest);
                    },
                    onInteractionEnd: (_) =>
                        _centeredLocation(constraints.biggest),
                    child: SizedBox(
                      width: _mapWidth,
                      height: _mapHeight,
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
                  left: 8,
                  bottom: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          color: Colors.black12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Powiększ mapę',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                          padding: EdgeInsets.zero,
                          onPressed: () => _zoomBy(1.25, constraints.biggest),
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          tooltip: 'Pomniejsz mapę',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                          padding: EdgeInsets.zero,
                          onPressed: () => _zoomBy(0.8, constraints.biggest),
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton(
                          tooltip: 'Wyśrodkuj mapę',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                          padding: EdgeInsets.zero,
                          onPressed: () => _resetMap(constraints.biggest),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
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
    _MapPlace('Pallet Town', 0.2, 0.72),
    _MapPlace('Route 1', 0.21, 0.63),
    _MapPlace('Viridian City', 0.22, 0.54),
    _MapPlace('Route 2', 0.22, 0.43),
    _MapPlace('Viridian Forest', 0.22, 0.35),
    _MapPlace('Pewter City', 0.22, 0.24),
    _MapPlace('Route 3', 0.34, 0.2),
    _MapPlace('Mt. Moon', 0.43, 0.14),
    _MapPlace('Route 4', 0.56, 0.13),
    _MapPlace('Cerulean City', 0.68, 0.14),
    _MapPlace('Route 24', 0.74, 0.08),
    _MapPlace('Route 25', 0.84, 0.09),
    _MapPlace('Route 5', 0.65, 0.23),
    _MapPlace('Underground Path (Routes 5–6)', 0.74, 0.4),
    _MapPlace('Route 6', 0.63, 0.44),
    _MapPlace('Vermilion City', 0.62, 0.57),
    _MapPlace('Route 7', 0.55, 0.32),
    _MapPlace('Route 8', 0.77, 0.34),
    _MapPlace('Route 9', 0.82, 0.18),
    _MapPlace('Route 10', 0.89, 0.24),
    _MapPlace('Rock Tunnel', 0.91, 0.27),
    _MapPlace('Lavender Town', 0.84, 0.43),
    _MapPlace('Underground Path (Routes 7–8)', 0.56, 0.4),
    _MapPlace('Route 11', 0.76, 0.56),
    _MapPlace('Diglett\'s Cave', 0.5, 0.49),
    _MapPlace('Route 12', 0.91, 0.49),
    _MapPlace('Route 13', 0.91, 0.6),
    _MapPlace('Route 14', 0.86, 0.68),
    _MapPlace('Route 15', 0.78, 0.74),
    _MapPlace('Fuchsia City', 0.62, 0.75),
    _MapPlace('Celadon City', 0.46, 0.32),
    _MapPlace('Saffron City', 0.63, 0.32),
    _MapPlace('Route 16', 0.36, 0.33),
    _MapPlace('Route 17', 0.38, 0.56),
    _MapPlace('Route 18', 0.5, 0.72),
    _MapPlace('Route 19', 0.5, 0.83),
    _MapPlace('Route 20', 0.36, 0.9),
    _MapPlace('Seafoam Islands', 0.28, 0.86),
    _MapPlace('Cinnabar Island', 0.16, 0.91),
    _MapPlace('Route 21', 0.19, 0.81),
    _MapPlace('Route 22', 0.1, 0.53),
    _MapPlace('Route 23', 0.1, 0.35),
    _MapPlace('Victory Road', 0.12, 0.3),
    _MapPlace('Indigo Plateau', 0.1, 0.23),
    _MapPlace('Cerulean Cave', 0.77, 0.15),
    _MapPlace('S.S. Anne', 0.54, 0.6),
    _MapPlace('Power Plant', 0.93, 0.3),
    _MapPlace('Pokémon Tower', 0.88, 0.45),
    _MapPlace('Team Rocket Hideout', 0.48, 0.38),
    _MapPlace('Silph Co.', 0.63, 0.29),
    _MapPlace('Pokémon Mansion', 0.19, 0.86),
    _MapPlace('Safari Zone', 0.64, 0.79),
    _MapPlace('Viridian Gym', 0.27, 0.57),
    _MapPlace('Pewter Gym', 0.27, 0.27),
    _MapPlace('Cerulean Gym', 0.7, 0.19),
    _MapPlace('Vermilion Gym', 0.65, 0.59),
    _MapPlace('Celadon Gym', 0.4, 0.32),
    _MapPlace('Saffron Gym', 0.69, 0.31),
    _MapPlace('Fuchsia Gym', 0.65, 0.72),
    _MapPlace('Cinnabar Gym', 0.12, 0.93),
    _MapPlace('Bill\'s House', 0.8, 0.13),
    _MapPlace('Pewter Museum of Science', 0.16, 0.21),
    _MapPlace('Pokémon Fan Club', 0.59, 0.63),
    _MapPlace('Pokémon Day Care', 0.67, 0.26),
    _MapPlace('Pokémon League Reception Gate', 0.1, 0.27),
    _MapPlace("Player's House", 0.16, 0.68),
    _MapPlace("Professor Oak's Laboratory", 0.25, 0.77),
    _MapPlace('Celadon Department Store', 0.46, 0.25),
    _MapPlace('Celadon Game Corner', 0.51, 0.35),
    _MapPlace('Celadon Condominiums', 0.39, 0.25),
    _MapPlace('Cinnabar Lab', 0.22, 0.95),
    _MapPlace('Fighting Dojo', 0.68, 0.37),
    _MapPlace('GO Park', 0.7, 0.78),
    _MapPlace('Sea Cottage', 0.89, 0.12),
    _MapPlace("Diglett's Cave (Route 2 entrance)", 0.35, 0.44),
    _MapPlace("Diglett's Cave (Route 11 entrance)", 0.65, 0.53),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final oceanRect = Offset.zero & size;
    canvas.drawRect(
      oceanRect,
      Paint()..isAntiAlias = true
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
      ..moveTo(size.width * .06, size.height * .20)
      ..cubicTo(size.width * .12, size.height * .05, size.width * .39, size.height * .035, size.width * .55, size.height * .09)
      ..cubicTo(size.width * .69, size.height * .035, size.width * .89, size.height * .08, size.width * .93, size.height * .22)
      ..cubicTo(size.width * .98, size.height * .38, size.width * .88, size.height * .56, size.width * .86, size.height * .70)
      ..cubicTo(size.width * .81, size.height * .88, size.width * .62, size.height * .91, size.width * .48, size.height * .85)
      ..cubicTo(size.width * .36, size.height * .94, size.width * .18, size.height * .86, size.width * .18, size.height * .72)
      ..cubicTo(size.width * .06, size.height * .60, size.width * .09, size.height * .39, size.width * .06, size.height * .20)
      ..close();
    canvas.drawPath(
      coast.shift(const Offset(0, 5)),
      Paint()..isAntiAlias = true..color = const Color(0xFF6FAEB1).withValues(alpha: .25),
    );
    canvas.drawPath(
      coast,
      Paint()..isAntiAlias = true
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
      Paint()..isAntiAlias = true
        ..color = const Color(0xFFE7D8A7).withValues(alpha: .92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    canvas.drawPath(
      coast,
      Paint()..isAntiAlias = true
        ..color = const Color(0xFF719B72).withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    canvas.drawPath(
      coast,
      Paint()..isAntiAlias = true
        ..color = Colors.white.withValues(alpha: .58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Fine sea strokes sit only in the ocean, giving the coast a painted atlas
    // texture without putting wave marks over selectable land locations.
    canvas.save();
    canvas.clipPath(coast, clipOp: ClipOp.difference);
    final seaWavePaint = Paint()..isAntiAlias = true
      ..color = const Color(0xFF5CA9B5).withValues(alpha: .46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final wave in <(double, double, double)>[
      (.04, .30, .025),
      (.05, .48, .022),
      (.04, .68, .026),
      (.15, .96, .025),
      (.31, .98, .022),
      (.48, .96, .025),
      (.72, .94, .022),
      (.94, .78, .024),
      (.96, .59, .022),
      (.96, .43, .026),
      (.94, .13, .022),
      (.65, .035, .025),
      (.80, .035, .020),
    ]) {
      final center = p(wave.$1, wave.$2);
      final width = size.width * wave.$3;
      final line = Path()
        ..moveTo(center.dx - width, center.dy)
        ..quadraticBezierTo(
          center.dx - width * .35,
          center.dy - 3.5 * size.width / 900,
          center.dx,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx + width * .55,
          center.dy + 3.5 * size.width / 900,
          center.dx + width,
          center.dy,
        );
      canvas.drawPath(line, seaWavePaint);
    }
    canvas.restore();

    // A small inland bay adds depth to the illustrated region. Its outline is
    // decorative and is not claimed to reproduce the game's exact coastline.
    final bay = Path()
      ..moveTo(size.width * .42, size.height * .46)
      ..cubicTo(size.width * .45, size.height * .42, size.width * .51, size.height * .43, size.width * .54, size.height * .46)
      ..cubicTo(size.width * .58, size.height * .45, size.width * .61, size.height * .48, size.width * .60, size.height * .51)
      ..cubicTo(size.width * .59, size.height * .55, size.width * .54, size.height * .56, size.width * .51, size.height * .54)
      ..cubicTo(size.width * .47, size.height * .56, size.width * .42, size.height * .53, size.width * .41, size.height * .50)
      ..quadraticBezierTo(size.width * .40, size.height * .48, size.width * .42, size.height * .46)
      ..close();
    canvas.drawPath(
      bay,
      Paint()..isAntiAlias = true
        ..color = const Color(0xFFE8D7A0).withValues(alpha: .92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawPath(
      bay,
      Paint()..isAntiAlias = true
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9EDBE0), Color(0xFF6CBAC7), Color(0xFF8CCDD3)],
        ).createShader(Rect.fromLTWH(
          size.width * .40,
          size.height * .42,
          size.width * .22,
          size.height * .15,
        )),
    );
    canvas.drawPath(
      bay,
      Paint()..isAntiAlias = true
        ..color = const Color(0xFF5A9EAB).withValues(alpha: .62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
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
      canvas.drawOval(rect, Paint()..isAntiAlias = true..color = wash.$5.withValues(alpha: .45));
      canvas.drawOval(
        rect.deflate(5),
        Paint()..isAntiAlias = true
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
      final trunkPaint = Paint()..isAntiAlias = true..color = const Color(0xFF987C55).withValues(alpha: .65);
      final leafPaint = Paint()..isAntiAlias = true..color = const Color(0xFF6FA879).withValues(alpha: .48);
      final leafLight = Paint()..isAntiAlias = true..color = const Color(0xFFB5D99B).withValues(alpha: .62);
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

    final hillPaint = Paint()..isAntiAlias = true
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
        Paint()..isAntiAlias = true
          ..color = Colors.white.withValues(alpha: .28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Hand-illustrated terrain layer: soft watercolor washes, contour lines,
    // mountain silhouettes, coves and tiny islands. All motifs are vector paths,
    // so they stay crisp when the user zooms in; they are decorative, not exact
    // in-game terrain or item/Pokémon coordinates.
    final contourPaint = Paint()..isAntiAlias = true
      ..color = const Color(0xFF77966C).withValues(alpha: .30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;
    for (final contour in <(double, double, double, double)>[
      (.18, .30, .10, .035),
      (.21, .32, .075, .025),
      (.70, .31, .11, .035),
      (.73, .33, .075, .022),
      (.34, .75, .10, .028),
      (.37, .77, .07, .018),
      (.63, .72, .08, .025),
    ]) {
      final center = p(contour.$1, contour.$2);
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * contour.$3,
        height: size.height * contour.$4,
      );
      canvas.drawOval(rect, contourPaint);
    }

    void drawMountain(double x, double y, double scale) {
      final center = p(x, y);
      final s = size.width / 900 * scale;
      final silhouette = Path()
        ..moveTo(center.dx - 25 * s, center.dy + 15 * s)
        ..lineTo(center.dx - 8 * s, center.dy - 15 * s)
        ..lineTo(center.dx + 1 * s, center.dy - 2 * s)
        ..lineTo(center.dx + 13 * s, center.dy - 25 * s)
        ..lineTo(center.dx + 31 * s, center.dy + 15 * s)
        ..close();
      canvas.drawPath(
        silhouette.shift(Offset(0, 3 * s)),
        Paint()..isAntiAlias = true..color = const Color(0xFF9A9B7A).withValues(alpha: .35),
      );
      canvas.drawPath(
        silhouette,
        Paint()..isAntiAlias = true
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9E2C9), Color(0xFFB5B89A)],
          ).createShader(Rect.fromCenter(
            center: center,
            width: 64 * s,
            height: 48 * s,
          )),
      );
      final snow = Path()
        ..moveTo(center.dx - 13 * s, center.dy - 5 * s)
        ..lineTo(center.dx - 8 * s, center.dy - 15 * s)
        ..lineTo(center.dx - 2 * s, center.dy - 6 * s)
        ..lineTo(center.dx + 3 * s, center.dy - 14 * s)
        ..lineTo(center.dx + 13 * s, center.dy + 1 * s)
        ..lineTo(center.dx + 5 * s, center.dy - 3 * s)
        ..lineTo(center.dx + 1 * s, center.dy + 2 * s)
        ..lineTo(center.dx - 5 * s, center.dy - 2 * s)
        ..close();
      canvas.drawPath(snow, Paint()..isAntiAlias = true..color = const Color(0xFFF8F4E5));
      canvas.drawPath(
        silhouette,
        Paint()..isAntiAlias = true
          ..color = const Color(0xFF7D8F70).withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * s,
      );
    }

    for (final mountain in <(double, double, double)>[
      (.35, .15, .72),
      (.40, .13, .88),
      (.44, .14, 1.0),
      (.48, .16, .72),
      (.86, .26, .72),
      (.89, .24, .88),
      (.92, .27, .70),
      (.14, .25, .62),
      (.17, .23, .78),
      (.20, .25, .60),
    ]) {
      drawMountain(mountain.$1, mountain.$2, mountain.$3);
    }

    // A quiet, winding stream and pale sand edges give the region a hand-painted
    // atlas feel without asserting that these are game-accurate river pixels.
    final stream = Path()
      ..moveTo(size.width * .76, size.height * .23)
      ..cubicTo(size.width * .73, size.height * .29, size.width * .78, size.height * .34, size.width * .72, size.height * .39)
      ..cubicTo(size.width * .67, size.height * .43, size.width * .63, size.height * .46, size.width * .57, size.height * .48);
    canvas.drawPath(
      stream,
      Paint()..isAntiAlias = true
        ..color = const Color(0xFFF4E5B2).withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * size.width / 900
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      stream,
      Paint()..isAntiAlias = true
        ..color = const Color(0xFF80C8D0).withValues(alpha: .78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * size.width / 900
        ..strokeCap = StrokeCap.round,
    );

    // Tiny offshore islets are drawn as layered, smooth ovals (not pixel art).
    for (final island in <(double, double, double, double)>[
      (.23, .96, .035, .014),
      (.30, .97, .025, .011),
      (.36, .94, .022, .009),
      (.09, .89, .025, .012),
      (.12, .91, .018, .008),
    ]) {
      final center = p(island.$1, island.$2);
      final rect = Rect.fromCenter(
        center: center,
        width: size.width * island.$3,
        height: size.height * island.$4,
      );
      canvas.drawOval(
        rect.inflate(2 * size.width / 900),
        Paint()..isAntiAlias = true..color = const Color(0xFFEADDAA).withValues(alpha: .8),
      );
      canvas.drawOval(
        rect,
        Paint()..isAntiAlias = true
          ..shader = const LinearGradient(
            colors: [Color(0xFFB9D79A), Color(0xFF8FB87E)],
          ).createShader(rect),
      );
      canvas.drawArc(
        rect.deflate(2),
        3.5,
        2.2,
        false,
        Paint()..isAntiAlias = true
          ..color = const Color(0xFF6D9B6F).withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Subtle map-frame and compass ornament, all vector-drawn for clean scaling.
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      Radius.circular(size.width * .018),
    );
    canvas.drawRRect(
      frame,
      Paint()..isAntiAlias = true
        ..color = const Color(0xFF6E8C73).withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Keep the compass in the open-water margin so it cannot compete
    // with the northern route labels or Bill's House / Sea Cottage markers.
    final compass = p(.94, .90);
    canvas.drawCircle(
      compass,
      size.width * .035,
      Paint()..isAntiAlias = true..color = const Color(0xFFF8F1D8).withValues(alpha: .8),
    );
    final compassPath = Path()
      ..moveTo(compass.dx, compass.dy - size.width * .027)
      ..lineTo(compass.dx + size.width * .010, compass.dy)
      ..lineTo(compass.dx, compass.dy + size.width * .027)
      ..lineTo(compass.dx - size.width * .010, compass.dy)
      ..close();
    canvas.drawPath(compassPath, Paint()..isAntiAlias = true..color = const Color(0xFF577B70));
    canvas.drawLine(
      Offset(compass.dx, compass.dy - size.width * .022),
      Offset(compass.dx, compass.dy + size.width * .022),
      Paint()..isAntiAlias = true
        ..color = const Color(0xFF577B70)
        ..strokeWidth = 1,
    );
    final northLabel = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Color(0xFF577B70),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    northLabel.paint(
      canvas,
      Offset(compass.dx - northLabel.width / 2, compass.dy - size.width * .055),
    );

    // Full 76-location Kanto topology from the bundled audit index. Node positions are schematic layout coordinates, not in-game coordinates.
    const links = <(int, int)>[
      (0,1),
      (0,39),
      (1,2),
      (2,3),
      (2,40),
      (2,52),
      (3,5),
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
      (65,0),
      (66,0),
      (67,30),
      (68,30),
      (69,30),
      (70,38),
      (71,31),
      (72,29),
      (73,11),
      (3,74),
      (23,75),
      (74,24),
      (75,24),
    ];
    final roadShadow = Paint()..isAntiAlias = true
      ..color = const Color(0xFF8B9C73).withValues(alpha: .30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    final roadEdge = Paint()..isAntiAlias = true
      ..color = const Color(0xFFFAF1CE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final roadCenter = Paint()..isAntiAlias = true
      ..color = const Color(0xFFE5D49B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final waterRouteEdge = Paint()..isAntiAlias = true
      ..color = const Color(0xFFD6F1E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final waterRouteDash = Paint()..isAntiAlias = true
      ..color = const Color(0xFF4F9DA8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final undergroundEdge = Paint()..isAntiAlias = true
      ..color = const Color(0xFFD7C8A2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final undergroundDash = Paint()..isAntiAlias = true
      ..color = const Color(0xFF8C8068)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
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
      final isWaterLink = <String>{
        'Route 19',
        'Route 20',
        'Route 21',
      }.contains(a.name) || <String>{
        'Route 19',
        'Route 20',
        'Route 21',
      }.contains(b.name);
      final isDiglettTunnel =
          (a.name == "Diglett's Cave" && b.name.startsWith("Diglett's Cave (Route")) ||
          (b.name == "Diglett's Cave" && a.name.startsWith("Diglett's Cave (Route"));
      final isUndergroundLink = isDiglettTunnel ||
          a.name.startsWith('Underground Path') ||
          b.name.startsWith('Underground Path');
      canvas.drawPath(road, roadShadow);
      if (isWaterLink) {
        canvas.drawPath(road, waterRouteEdge);
        for (final metric in road.computeMetrics()) {
          for (var distance = 0.0; distance < metric.length; distance += 14) {
            final dashEnd = math.min(distance + 6, metric.length).toDouble();
            canvas.drawPath(
              metric.extractPath(distance, dashEnd),
              waterRouteDash,
            );
          }
        }
      } else if (isUndergroundLink) {
        canvas.drawPath(road, undergroundEdge);
        for (final metric in road.computeMetrics()) {
          for (var distance = 0.0; distance < metric.length; distance += 12) {
            final dashEnd = math.min(distance + 5, metric.length).toDouble();
            canvas.drawPath(
              metric.extractPath(distance, dashEnd),
              undergroundDash,
            );
          }
        }
      } else {
        canvas.drawPath(road, roadEdge);
        canvas.drawPath(road, roadCenter);
      }
    }

    // Small illustrated landmarks make the region read as a hand-drawn
    // world map rather than a diagram. Their positions are illustrative only.
    void drawForest(double x, double y, double radius, int seed) {
      final center = p(x, y);
      final scale = size.width / 900;
      final canopy = Paint()..isAntiAlias = true..color = const Color(0xFF659B72).withValues(alpha: .76);
      final canopyLight = Paint()..isAntiAlias = true..color = const Color(0xFF9BC68A).withValues(alpha: .88);
      final shadow = Paint()..isAntiAlias = true..color = const Color(0xFF547E63).withValues(alpha: .28);
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(2 * scale, 5 * scale),
          width: radius * 2.4 * scale,
          height: radius * 1.55 * scale,
        ),
        shadow,
      );
      for (var i = 0; i < 9; i++) {
        final angle = (i * 2.399 + seed * .41);
        final distance = (i.isEven ? .48 : .72) * radius * scale;
        final treeCenter = center + Offset(
          math.cos(angle) * distance,
          math.sin(angle) * distance * .62,
        );
        final treeRadius = (i % 3 == 0 ? 6.5 : 5.2) * scale;
        canvas.drawCircle(treeCenter, treeRadius, canopy);
        canvas.drawCircle(
          treeCenter + Offset(-1.6 * scale, -1.8 * scale),
          treeRadius * .58,
          canopyLight,
        );
      }
    }

    void drawTown(double x, double y, {int buildings = 5}) {
      final center = p(x, y);
      final scale = size.width / 900;
      final base = Paint()..isAntiAlias = true..color = const Color(0xFFFAF0D0).withValues(alpha: .95);
      final wall = Paint()..isAntiAlias = true..color = const Color(0xFFF4D7A0);
      final roof = Paint()..isAntiAlias = true..color = const Color(0xFFB96555);
      final outline = Paint()..isAntiAlias = true
        ..color = const Color(0xFF7D7158).withValues(alpha: .78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * scale;
      for (var i = 0; i < buildings; i++) {
        final column = i % 3;
        final row = i ~/ 3;
        final w = (7 + (i % 2) * 2) * scale;
        final h = (7 + (i % 3)) * scale;
        final origin = center + Offset((column - 1) * 11 * scale - w / 2, (row - .5) * 11 * scale);
        final body = Rect.fromLTWH(origin.dx, origin.dy, w, h);
        final roofPath = Path()
          ..moveTo(body.left - 1 * scale, body.top)
          ..lineTo(body.center.dx, body.top - 5 * scale)
          ..lineTo(body.right + 1 * scale, body.top)
          ..close();
        canvas.drawRect(body, base);
        canvas.drawRect(body, wall);
        canvas.drawPath(roofPath, roof);
        canvas.drawRect(body, outline);
        canvas.drawPath(roofPath, outline);
        canvas.drawRect(
          Rect.fromLTWH(body.center.dx - scale, body.bottom - 3 * scale, 2 * scale, 3 * scale),
          Paint()..isAntiAlias = true..color = const Color(0xFF6E8B9B),
        );
      }
    }

    void drawCave(double x, double y) {
      final center = p(x, y);
      final scale = size.width / 900;
      final rock = Paint()..isAntiAlias = true..color = const Color(0xFF8B8A78);
      final opening = Paint()..isAntiAlias = true
        ..color = const Color(0xFF353F3D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * scale;
      final edge = Paint()..isAntiAlias = true
        ..color = const Color(0xFFF2E7C6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * scale;
      final mound = Path()
        ..moveTo(center.dx - 13 * scale, center.dy + 5 * scale)
        ..quadraticBezierTo(center.dx - 10 * scale, center.dy - 13 * scale, center.dx, center.dy - 10 * scale)
        ..quadraticBezierTo(center.dx + 11 * scale, center.dy - 12 * scale, center.dx + 13 * scale, center.dy + 5 * scale)
        ..close();
      canvas.drawPath(mound, rock);
      canvas.drawArc(
        Rect.fromCenter(center: center + Offset(0, 2 * scale), width: 11 * scale, height: 13 * scale),
        math.pi,
        math.pi,
        false,
        opening,
      );
      canvas.drawPath(mound, edge);
    }

    // Broad forest clusters sit behind routes and selectable location markers.
    drawForest(.22, .35, 18, 2); // Viridian Forest area
    drawForest(.64, .79, 15, 5); // Safari Zone / Fuchsia area
    drawForest(.42, .31, 11, 3); // Celadon outskirts
    drawForest(.36, .55, 12, 7); // southern central woodland
    drawForest(.15, .30, 12, 1); // western uplands
    // Forest patches are decorative landscape, while town/cave symbols are
    // drawn at each actual selectable node below so they stay aligned.
    
    final occupiedLabelRects = <Rect>[];
    for (final place in places) {
      final point = p(place.x, place.y);
      final name = place.name;
      final isTown = (name.contains('City') ||
          name.contains('Town') ||
          name.contains('Island') ||
          name == 'Indigo Plateau') &&
          name != 'Seafoam Islands';
      final isCave = name.contains('Cave') ||
          name.contains('Tunnel') ||
          name == 'Mt. Moon' ||
          name == 'Victory Road' ||
          name == 'Seafoam Islands' ||
          name == 'Pokémon Tower' ||
          name == 'Pokémon Mansion' ||
          name == 'Team Rocket Hideout';
      final isBuilding = name.endsWith('Gym') ||
          name.contains('Laboratory') ||
          name.contains('Lab') ||
          name.contains('Department Store') ||
          name.contains('Game Corner') ||
          name.contains('Condominiums') ||
          name.contains('Dojo') ||
          name.contains('Silph Co.') ||
          name.contains('S.S. Anne') ||
          name.contains('GO Park') ||
          name.contains('Museum') ||
          name.contains('Fan Club') ||
          name.contains('Day Care') ||
          name.contains('Reception Gate') ||
          name.contains('House') ||
          name.contains('Cottage');
      if (isTown) {
        drawTown(
          place.x,
          place.y,
          buildings: name == 'Celadon City' || name == 'Saffron City' ? 7 : 4,
        );
      } else if (isCave) {
        drawCave(place.x, place.y);
      } else if (isBuilding) {
        _drawHouse(canvas, point + const Offset(0, -13), route);
      }
      if (name.startsWith('Route ')) {
        final routeNumber = name.substring('Route '.length);
        final isWaterRouteNode = {'19', '20', '21'}.contains(routeNumber);
        final badgeCenter = point + const Offset(0, 13);
        final badgeRect = Rect.fromCenter(
          center: badgeCenter,
          width: routeNumber.length == 1 ? 21 : 25,
          height: 17,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(badgeRect, const Radius.circular(5)),
          Paint()..isAntiAlias = true..color = const Color(0xFFFFF8E2).withValues(alpha: .96),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(badgeRect, const Radius.circular(5)),
          Paint()..isAntiAlias = true
            ..color = (isWaterRouteNode
                    ? const Color(0xFF4F9DA8)
                    : const Color(0xFF9A8159))
                .withValues(alpha: .88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        final badgeText = TextPainter(
          text: TextSpan(
            text: routeNumber,
            style: TextStyle(
              color: isWaterRouteNode
                  ? const Color(0xFF347D8B)
                  : const Color(0xFF6D614A),
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        badgeText.paint(
          canvas,
          Offset(
            badgeCenter.dx - badgeText.width / 2,
            badgeCenter.dy - badgeText.height / 2,
          ),
        );
        occupiedLabelRects.add(badgeRect.inflate(1));
      }
      final isSelected = place.name.toLowerCase() == selectedLocation.toLowerCase();
      if (isSelected) {
        canvas.drawCircle(point, 13, Paint()..isAntiAlias = true..color = route.withValues(alpha: .24));
      }
      if (place.name == 'Pallet Town') {
        _drawHouse(canvas, point + const Offset(0, -16), route);
      } else if (place.name == 'Route 1') {
        // A berry and Poké Ball indicate guide information for this route.
        // They are area markers only; they do not claim exact item coordinates.
        _drawBerry(canvas, point + const Offset(13, -15));
        _drawPokeball(canvas, point + const Offset(-12, -15));
      }
      canvas.drawCircle(point, isSelected ? 8 : 7, Paint()..isAntiAlias = true..color = route);
      canvas.drawCircle(point, 3, Paint()..isAntiAlias = true..color = Colors.white);
      final name = place.name;
      final isMajorPlace = name.contains('City') ||
          name.contains('Town') ||
          name.contains('Island') ||
          name.contains('Forest') ||
          (name.contains('Cave') && !name.contains('entrance')) ||
          name.contains('Moon') ||
          name.contains('Victory Road') ||
          name.contains('Indigo Plateau') ||
          name.contains('Safari Zone') ||
          name.contains('Pokémon Tower') ||
          name.contains('Pokémon Mansion') ||
          name.contains('Power Plant') ||
          name.contains('S.S. Anne') ||
          name.contains('GO Park') ||
          name.contains('Silph Co.') ||
          name.contains('Team Rocket Hideout') ||
          name.contains('Seafoam') ||
          name.contains('Bill\'s House') ||
          name.contains('Sea Cottage');
      // Keep the overview legible: every point remains tappable, while small
      // buildings/gyms and route labels appear when selected instead of colliding.
      if (isMajorPlace || isSelected) {
        final text = TextPainter(
          text: TextSpan(
            text: place.name,
            style: TextStyle(
              color: label,
              fontSize: size.width < 360 ? 8 : 9.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              shadows: [
                Shadow(
                  color: const Color(0xFFF5F0D8).withValues(alpha: .92),
                  blurRadius: 3,
                  offset: const Offset(1, 1),
                ),
                Shadow(
                  color: const Color(0xFFF5F0D8).withValues(alpha: .92),
                  blurRadius: 3,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: size.width * .42);
        final candidates = <Offset>[
          Offset(point.dx + 10, point.dy - text.height / 2),
          Offset(point.dx - text.width - 10, point.dy - text.height / 2),
          Offset(point.dx - text.width / 2, point.dy - text.height - 10),
          Offset(point.dx - text.width / 2, point.dy + 10),
        ];
        Offset? bestOffset;
        Rect? bestRect;
        var bestOverlap = double.infinity;
        for (final candidate in candidates) {
          final dx = candidate.dx.clamp(4.0, size.width - text.width - 4).toDouble();
          final dy = candidate.dy.clamp(4.0, size.height - text.height - 4).toDouble();
          final rect = Rect.fromLTWH(dx - 2, dy - 2, text.width + 4, text.height + 4);
          var overlap = 0.0;
          for (final occupied in occupiedLabelRects) {
            final intersection = rect.intersect(occupied);
            if (!intersection.isEmpty) {
              overlap += intersection.width * intersection.height;
            }
          }
          if (overlap < bestOverlap) {
            bestOverlap = overlap;
            bestOffset = Offset(dx, dy);
            bestRect = rect;
          }
          if (overlap == 0) break;
        }
        final labelOffset = bestOffset ?? candidates.first;
        final labelRect = bestRect ??
            Rect.fromLTWH(labelOffset.dx, labelOffset.dy, text.width, text.height);
        occupiedLabelRects.add(labelRect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
          Paint()..isAntiAlias = true..color = const Color(0xFFF8F1D9).withValues(alpha: .88),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(3)),
          Paint()..isAntiAlias = true
            ..color = const Color(0xFF78906F).withValues(alpha: .36)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7,
        );
        text.paint(canvas, labelOffset);
      }
    }

    // A small atlas cartouche anchors the composition without covering the
    // compass or the selectable northern locations.
    final title = TextPainter(
      text: const TextSpan(
        text: 'KANTO',
        style: TextStyle(
          color: Color(0xFF496E5A),
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final subtitle = TextPainter(
      text: const TextSpan(
        text: 'REGIONAL ATLAS  •  SCHEMATIC',
        style: TextStyle(
          color: Color(0xFF6F8068),
          fontSize: 6.5,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final cartouche = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 9, math.max(title.width, subtitle.width) + 18, 39),
      const Radius.circular(7),
    );
    canvas.drawRRect(
      cartouche.shift(const Offset(0, 2)),
      Paint()..isAntiAlias = true..color = const Color(0xFF6E8C73).withValues(alpha: .16),
    );
    canvas.drawRRect(
      cartouche,
      Paint()..isAntiAlias = true..color = const Color(0xFFFFF8E5).withValues(alpha: .94),
    );
    canvas.drawRRect(
      cartouche,
      Paint()..isAntiAlias = true
        ..color = const Color(0xFF78906F).withValues(alpha: .58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    title.paint(canvas, const Offset(19, 10));
    subtitle.paint(canvas, const Offset(20, 32));
  }

  void _drawPokeball(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 7, Paint()..isAntiAlias = true..color = Colors.white);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 7),
      3.14159,
      3.14159,
      true,
      Paint()..isAntiAlias = true..color = Colors.red.shade600,
    );
    canvas.drawCircle(
      center,
      7,
      Paint()..isAntiAlias = true
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      center + const Offset(-6.5, 0),
      center + const Offset(6.5, 0),
      Paint()..isAntiAlias = true..color = Colors.black87..strokeWidth = 1.5,
    );
    canvas.drawCircle(center, 2.2, Paint()..isAntiAlias = true..color = Colors.white);
    canvas.drawCircle(
      center,
      2.2,
      Paint()..isAntiAlias = true
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawBerry(Canvas canvas, Offset center) {
    final berryPaint = Paint()..isAntiAlias = true..color = Colors.pink.shade400;
    canvas.drawCircle(center + const Offset(-3, 1), 4, berryPaint);
    canvas.drawCircle(center + const Offset(3, 1), 4, berryPaint);
    canvas.drawCircle(center + const Offset(0, 4), 4, berryPaint);
    canvas.drawLine(
      center + const Offset(0, -1),
      center + const Offset(1, -7),
      Paint()..isAntiAlias = true
        ..color = Colors.green.shade700
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 8, Paint()..isAntiAlias = true..color = Colors.white.withValues(alpha: .75)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawHouse(Canvas canvas, Offset center, Color color) {
    final roof = Path()
      ..moveTo(center.dx - 9, center.dy)
      ..lineTo(center.dx, center.dy - 8)
      ..lineTo(center.dx + 9, center.dy)
      ..close();
    canvas.drawPath(roof, Paint()..isAntiAlias = true..color = Colors.brown.shade500);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 7, center.dy, 14, 10),
      Paint()..isAntiAlias = true..color = Colors.orange.shade100,
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 2, center.dy + 3, 4, 7),
      Paint()..isAntiAlias = true..color = color,
    );
    canvas.drawPath(
      roof,
      Paint()..isAntiAlias = true..color = Colors.black45..style = PaintingStyle.stroke..strokeWidth = 1,
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
