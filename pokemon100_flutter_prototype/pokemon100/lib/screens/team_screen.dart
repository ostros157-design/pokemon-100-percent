import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pokemon_data.dart';
import '../models/pokemon.dart';
import '../services/team_recommendation_service.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  static const _storageKey = 'team_making_saved_team_v1';
  static const _teamNameKey = 'team_making_saved_name_v1';
  static const _gameKey = 'team_making_selected_game_v1';
  static const _teamsStorageKey = 'team_making_saved_teams_v2';
  static const _activeTeamStorageKey = 'team_making_active_team_v2';
  static const _defaultIds = <int>[25, 93, 3, 6, 131, 68];

  static const Map<String, String> _games = {
    'lets_go_pikachu': "Pokémon: Let's Go, Pikachu!",
    'emerald': 'Pokémon Emerald',
    'firered': 'Pokémon FireRed',
    'soulsilver': 'Pokémon SoulSilver',
    'xy': 'Pokémon X/Y',
    'sword': 'Pokémon Sword (dane do sprawdzenia)',
    'legends_arceus': 'Pokémon Legends: Arceus',
  };

  String _selectedGame = TeamRecommendationService.supportedGameId;
  late List<Pokemon> _team;
  final List<_SavedTeam> _savedTeams = [];
  String? _activeTeamId;
  final TextEditingController _nameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _team = _defaultIds
        .map((id) => pokemonList.firstWhere((pokemon) => pokemon.id == id))
        .toList();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedTeams = prefs.getString(_teamsStorageKey);
    final restoredTeams = <_SavedTeam>[];

    if (encodedTeams != null) {
      try {
        final decoded = jsonDecode(encodedTeams);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final team = _SavedTeam.fromJson(Map<String, dynamic>.from(item));
              if (team != null) restoredTeams.add(team);
            }
          }
        }
      } catch (_) {
        // A damaged new-format save should not prevent loading the legacy team.
      }
    }

    // One-time migration: preserve the team saved by older app versions.
    if (restoredTeams.isEmpty && prefs.containsKey(_storageKey)) {
      final ids = (prefs.getStringList(_storageKey) ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .toList();
      final legacyTeam = _SavedTeam(
        id: 'legacy-team',
        name: prefs.getString(_teamNameKey) ?? 'Moja drużyna',
        gameId: prefs.getString(_gameKey) ?? TeamRecommendationService.supportedGameId,
        pokemonIds: ids,
      );
      restoredTeams.add(legacyTeam);
    }

    final activeId = prefs.getString(_activeTeamStorageKey);
    _SavedTeam? active;
    for (final team in restoredTeams) {
      if (team.id == activeId) {
        active = team;
        break;
      }
    }
    active ??= restoredTeams.isNotEmpty ? restoredTeams.first : null;
    if (!mounted) return;
    setState(() {
      _savedTeams
        ..clear()
        ..addAll(restoredTeams);
      _activeTeamId = active?.id;
      if (active != null) {
        _team = _pokemonFromIds(active.pokemonIds);
        _nameController.text = active.name;
        _selectedGame = _games.containsKey(active.gameId)
            ? active.gameId
            : TeamRecommendationService.supportedGameId;
      } else {
        _team = _defaultIds
            .map((id) => pokemonList.firstWhere((pokemon) => pokemon.id == id))
            .toList();
        _nameController.text = 'Moja drużyna';
        _selectedGame = TeamRecommendationService.supportedGameId;
      }
      _loading = false;
    });
    if (encodedTeams == null && restoredTeams.isNotEmpty) {
      await _persistSavedTeams();
    }
  }

  List<Pokemon> _pokemonFromIds(List<int> ids) {
    final restored = <Pokemon>[];
    for (final id in ids) {
      final matches = pokemonList.where((pokemon) => pokemon.id == id);
      if (matches.isNotEmpty && !restored.any((p) => p.id == id) && restored.length < 6) {
        restored.add(matches.first);
      }
    }
    return restored;
  }

  Future<void> _persistSavedTeams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _teamsStorageKey,
      jsonEncode(_savedTeams.map((team) => team.toJson()).toList()),
    );
    if (_activeTeamId != null) {
      await prefs.setString(_activeTeamStorageKey, _activeTeamId!);
    }
  }

  Future<void> _saveTeam() async {
    if (_team.length > 6) return;
    setState(() {
      _saving = true;
      _status = null;
    });
    try {
      final name = _nameController.text.trim().isEmpty
          ? 'Moja drużyna'
          : _nameController.text.trim();
      final saved = _SavedTeam(
        id: _activeTeamId ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        gameId: _selectedGame,
        pokemonIds: _team.map((pokemon) => pokemon.id).toList(),
      );
      final existingIndex = _savedTeams.indexWhere((team) => team.id == saved.id);
      setState(() {
        if (existingIndex >= 0) {
          _savedTeams[existingIndex] = saved;
        } else {
          _savedTeams.add(saved);
        }
        _activeTeamId = saved.id;
      });
      await _persistSavedTeams();
      if (!mounted) return;
      setState(() => _status = 'Zapisano drużynę „$name”.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'Nie udało się zapisać drużyny.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _createNewTeam() {
    setState(() {
      _activeTeamId = null;
      _team = [];
      _nameController.text = 'Nowa drużyna';
      _selectedGame = TeamRecommendationService.supportedGameId;
      _status = 'Utworzono nowy skład. Poprzednie zapisane drużyny pozostają bez zmian.';
    });
  }

  Future<void> _showSavedTeams() async {
    if (_savedTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie masz jeszcze zapisanych drużyn. Zapisz obecny skład, aby pojawił się na liście.')),
      );
      return;
    }
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.65,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Zapisane drużyny', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._savedTeams.map((saved) => Card(
                child: ListTile(
                  leading: const Icon(Icons.groups),
                  title: Text(saved.name),
                  subtitle: Text('${saved.pokemonIds.length}/6 Pokémonów · ${_games[saved.gameId] ?? saved.gameId}'),
                  trailing: _activeTeamId == saved.id
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(sheetContext, saved.id),
                ),
              )),
            ],
          ),
        ),
      ),
    );
    if (selectedId == null || !mounted) return;
    final selected = _savedTeams.where((team) => team.id == selectedId).firstOrNull;
    if (selected == null) return;
    setState(() {
      _activeTeamId = selected.id;
      _team = _pokemonFromIds(selected.pokemonIds);
      _nameController.text = selected.name;
      _selectedGame = _games.containsKey(selected.gameId)
          ? selected.gameId
          : TeamRecommendationService.supportedGameId;
      _status = 'Wczytano drużynę „${selected.name}”.';
    });
    await _persistSavedTeams();
  }

  Future<void> _choosePokemon() async {
    if (_team.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drużyna może mieć maksymalnie 6 Pokémonów.')),
      );
      return;
    }
    if (!TeamRecommendationService.isSupportedGame(_selectedGame)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dostępność Pokémonów nie została jeszcze zweryfikowana dla tej gry. Wybierz Let\'s Go, Pikachu!, aby uniknąć nieprawidłowych propozycji.')));
      return;
    }
    final chosen = await showModalBottomSheet<Pokemon>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PokemonPicker(excludedIds: _team.map((p) => p.id).toSet(), gameId: _selectedGame),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      if (_team.length < 6 && !_team.any((p) => p.id == chosen.id)) {
        _team.add(chosen);
        _status = null;
      }
    });
  }

  Future<void> _showRecommendations() async {
    if (!TeamRecommendationService.isSupportedGame(_selectedGame)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nie ma jeszcze danych dostępności dla tej gry.')));
      return;
    }
    final recommendations = TeamRecommendationService.recommend(_team, gameId: _selectedGame);
    if (!mounted) return;
    if (recommendations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie znaleziono kandydatów poprawiających pokrycie słabości na podstawie danych typów.')),
      );
      return;
    }
    final chosen = await showModalBottomSheet<Pokemon>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.72,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Dopasuj Pokémona', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Propozycje bazują na typach obecnej drużyny i filtrze dostępności dla wybranej gry. Filtr korzysta z regionalnego Pokédexu, więc nie uwzględnia jeszcze etapu fabuły, poziomu, pełnych warunków wymian ani wszystkich wydarzeń specjalnych.'),
              const SizedBox(height: 12),
              ...recommendations.map((recommendation) => Card(
                child: ListTile(
                  leading: SizedBox(width: 48, height: 48, child: CachedNetworkImage(
                    imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${recommendation.pokemon.id}.png',
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => CircleAvatar(child: Text('${recommendation.pokemon.id}')),
                  )),
                  title: Text(recommendation.pokemon.name),
                  subtitle: Text('${recommendation.pokemon.types.join(' / ')}\n${recommendation.reasons.take(2).join('; ')}'),
                  isThreeLine: true, trailing: Text('+ ${recommendation.score}'),
                  onTap: () => Navigator.pop(sheetContext, recommendation.pokemon),
                ),
              )),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    if (_team.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drużyna ma już 6 Pokémonów. Usuń jednego przed dodaniem rekomendacji.')),
      );
      return;
    }
    setState(() {
      if (!_team.any((pokemon) => pokemon.id == chosen.id)) {
        _team.add(chosen);
        _status = '${chosen.name} dodany do drużyny. Zapisz drużynę, aby zachować zmianę.';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kreator drużyny'),
        actions: [
          IconButton(
            tooltip: 'Zapisane drużyny',
            onPressed: _showSavedTeams,
            icon: const Icon(Icons.folder_open),
          ),
          IconButton(
            tooltip: 'Nowa drużyna',
            onPressed: _createNewTeam,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Dopasuj drużynę do gry',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _activeTeamId == null ? 'Niezapisany skład' : 'Edytujesz zapisany skład',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showSavedTeams,
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: Text('Moje drużyny (${_savedTeams.length})'),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: _selectedGame,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Wybierz grę',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.videogame_asset),
                  ),
                  items: _games.entries.map((entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    enabled: TeamRecommendationService.isSupportedGame(entry.key),
                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedGame = value;
                      _status = TeamRecommendationService.isSupportedGame(value)
                          ? 'Filtr dostępności oparty na danych regionalnego Pokédexu.'
                          : 'Brak danych dostępności dla tej gry — wybór i rekomendacje są zablokowane.';
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedGame == TeamRecommendationService.supportedGameId
                      ? "Filtr dostępności: Let's Go, Pikachu! Pokémony dostępne wyłącznie w wersji Eevee i Mew są wykluczone. Ewolucje przez wymianę mogą wymagać wymiany."
                      : TeamRecommendationService.isSupportedGame(_selectedGame)
                          ? 'Filtr oparty na regionalnym Pokédexie; może nie obejmować wszystkich spotkań po zakończeniu gry.'
                          : 'Dla tej gry nie ma jeszcze danych dostępności.' ,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa drużyny',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Skład drużyny: ${_team.length}/6',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _team.length >= 6 ? null : _choosePokemon,
                      icon: const Icon(Icons.add),
                      label: const Text('Dodaj'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _team.isEmpty ? null : _showRecommendations,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Dopasuj Pokémona'),
                  ),
                ),
                const SizedBox(height: 8),
                if (_team.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Drużyna jest pusta. Wybierz „Dodaj”, aby zacząć.'),
                    ),
                  ),
                ...List.generate(_team.length, (index) {
                  final pokemon = _team[index];
                  return Card(
                    child: ListTile(
                      leading: SizedBox(
                        width: 52,
                        height: 52,
                        child: CachedNetworkImage(
                          imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png',
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => CircleAvatar(child: Text('${pokemon.id}')),
                        ),
                      ),
                      title: Text(pokemon.name),
                      subtitle: Text('#${pokemon.id.toString().padLeft(3, '0')} · ${pokemon.types.join(' / ')}'),
                      trailing: IconButton(
                        tooltip: 'Usuń z drużyny',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() {
                          _team.removeAt(index);
                          _status = null;
                        }),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                if (_team.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _TeamAnalysis(team: _team),
                ],
                FilledButton.icon(
                  onPressed: _saving ? null : _saveTeam,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Zapisywanie...' : 'Zapisz drużynę'),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 8),
                  Text(_status!, style: TextStyle(color: _status!.startsWith('Nie udało') ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary)),
                ],
              ],
            ),
    );
  }
}

class _PokemonPicker extends StatefulWidget {
  final Set<int> excludedIds;
  final String gameId;

  const _PokemonPicker({required this.excludedIds, required this.gameId});

  @override
  State<_PokemonPicker> createState() => _PokemonPickerState();
}

class _PokemonPickerState extends State<_PokemonPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final results = pokemonList.where((pokemon) {
      if (widget.excludedIds.contains(pokemon.id)) return false;
      if (!TeamRecommendationService.isAvailableInGame(pokemon, widget.gameId)) return false;
      return query.isEmpty ||
          pokemon.name.toLowerCase().contains(query) ||
          pokemon.id.toString().contains(query) ||
          pokemon.types.any((type) => type.toLowerCase().contains(query));
    }).take(100).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Wybierz Pokémona', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Szukaj po nazwie, numerze lub typie',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('Brak wyników.'))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final pokemon = results[index];
                        return ListTile(
                          leading: SizedBox(
                            width: 44,
                            height: 44,
                            child: CachedNetworkImage(
                              imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png',
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => CircleAvatar(child: Text('${pokemon.id}')),
                            ),
                          ),
                          title: Text(pokemon.name),
                          subtitle: Text('#${pokemon.id.toString().padLeft(3, '0')} · ${pokemon.types.join(' / ')}'),
                          onTap: () => Navigator.pop(context, pokemon),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Analiza rozdziela problemy defensywne (tarcza) i ofensywne (miecz).
class _TeamAnalysis extends StatelessWidget {
  final List<Pokemon> team;
  const _TeamAnalysis({required this.team});

  static const Map<String, Set<String>> _strongAgainst = {
    'Normal': {}, 'Fire': {'Grass', 'Ice', 'Bug', 'Steel'},
    'Water': {'Fire', 'Ground', 'Rock'}, 'Electric': {'Water', 'Flying'},
    'Grass': {'Water', 'Ground', 'Rock'}, 'Ice': {'Grass', 'Ground', 'Flying', 'Dragon'},
    'Fighting': {'Normal', 'Ice', 'Rock', 'Dark', 'Steel'}, 'Poison': {'Grass', 'Fairy'},
    'Ground': {'Fire', 'Electric', 'Poison', 'Rock', 'Steel'}, 'Flying': {'Grass', 'Fighting', 'Bug'},
    'Psychic': {'Fighting', 'Poison'}, 'Bug': {'Grass', 'Psychic', 'Dark'},
    'Rock': {'Fire', 'Ice', 'Flying', 'Bug'}, 'Ghost': {'Psychic', 'Ghost'},
    'Dragon': {'Dragon'}, 'Dark': {'Psychic', 'Ghost'}, 'Steel': {'Ice', 'Rock', 'Fairy'},
    'Fairy': {'Fighting', 'Dragon', 'Dark'},
  };
  static const Map<String, Set<String>> _resists = {
    'Normal': {}, 'Fire': {'Fire', 'Grass', 'Ice', 'Bug', 'Steel', 'Fairy'},
    'Water': {'Fire', 'Water', 'Ice', 'Steel'}, 'Electric': {'Electric', 'Flying', 'Steel'},
    'Grass': {'Water', 'Electric', 'Grass', 'Ground'}, 'Ice': {'Ice'},
    'Fighting': {'Bug', 'Rock', 'Dark'}, 'Poison': {'Grass', 'Fighting', 'Poison', 'Bug', 'Fairy'},
    'Ground': {'Poison', 'Rock'}, 'Flying': {'Fighting', 'Bug', 'Grass'},
    'Psychic': {'Fighting', 'Psychic'}, 'Bug': {'Fighting', 'Ground', 'Grass'},
    'Rock': {'Normal', 'Fire', 'Poison', 'Flying'}, 'Ghost': {'Poison', 'Bug'},
    'Dragon': {'Fire', 'Water', 'Electric', 'Grass'}, 'Dark': {'Ghost', 'Dark'},
    'Steel': {'Normal', 'Grass', 'Ice', 'Flying', 'Psychic', 'Bug', 'Rock', 'Dragon', 'Steel', 'Fairy'},
    'Fairy': {'Fighting', 'Bug', 'Dark'},
  };
  static const Map<String, Set<String>> _immune = {
    'Normal': {'Ghost'}, 'Electric': {}, 'Ground': {'Electric'},
    'Flying': {'Ground'}, 'Ghost': {'Normal', 'Fighting'},
    'Dark': {'Psychic'}, 'Steel': {'Poison'}, 'Fairy': {'Dragon'},
  };

  double _multiplier(String attackType, List<String> defendingTypes) {
    var multiplier = 1.0;
    for (final defendingType in defendingTypes) {
      if (_immune[defendingType]?.contains(attackType) ?? false) return 0;
      if (_strongAgainst[attackType]?.contains(defendingType) ?? false) {
        multiplier *= 2;
      } else if (_resists[defendingType]?.contains(attackType) ?? false) {
        multiplier *= 0.5;
      }
    }
    return multiplier;
  }

  @override
  Widget build(BuildContext context) {
    final defensive = <String, int>{};
    for (final attackType in _strongAgainst.keys) {
      final count = team.where((pokemon) => _multiplier(attackType, pokemon.types) > 1).length;
      if (count > 0) defensive[attackType] = count;
    }
    final defensiveSorted = defensive.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));

    final offensiveGaps = _strongAgainst.keys.where((defendingType) =>
      !team.any((pokemon) => pokemon.types.any((attackType) =>
        _strongAgainst[attackType]?.contains(defendingType) ?? false))).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Analiza drużyny', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Jak czytać wynik: 2/6 oznacza, że 2 z 6 Pokémonów są słabe na ten typ ataku. Im mniejsza liczba, tym lepiej. To nie jest ocena całej drużyny — sprawdź też, czy te same Pokémony mają kilka wspólnych słabości.'),
          const SizedBox(height: 14),
          Row(children: [
            Icon(Icons.shield, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Tarcza — słabości w obronie', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          if (defensiveSorted.isEmpty)
            const Text('Brak wykrytych słabości defensywnych.')
          else
            Wrap(spacing: 8, runSpacing: 4, children: defensiveSorted.map((entry) => Chip(
              avatar: Icon(Icons.shield, size: 18, color: Theme.of(context).colorScheme.error),
              label: Text('${entry.key} · ${entry.value}/${team.length} podatne'),
            )).toList()),
          const SizedBox(height: 14),
          Row(children: [
            Icon(Icons.sports_martial_arts, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Miecz — braki w ataku', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          const Text('Pokazuje typy przeciwników, na które żaden typ Twojego Pokémona nie zadaje super skutecznych obrażeń. Nie sprawdza jeszcze konkretnych ruchów.'),
          const SizedBox(height: 6),
          if (offensiveGaps.isEmpty)
            const Text('Drużyna ma super skuteczne pokrycie przeciwko wszystkim typom.')
          else
            Wrap(spacing: 8, runSpacing: 4, children: offensiveGaps.map((type) => Chip(
              avatar: Icon(Icons.sports_martial_arts, size: 18, color: Theme.of(context).colorScheme.primary),
              label: Text(type),
            )).toList()),
          const SizedBox(height: 8),
          Text(
            'Analiza uwzględnia podstawowe relacje typów i podwójne typy w obronie. Nie uwzględnia rzeczywistych ruchów, zdolności ani statystyk Pokémonów.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ]),
      ),
    );
  }
}


class _SavedTeam {
  final String id;
  final String name;
  final String gameId;
  final List<int> pokemonIds;

  const _SavedTeam({
    required this.id,
    required this.name,
    required this.gameId,
    required this.pokemonIds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gameId': gameId,
    'pokemonIds': pokemonIds,
  };

  static _SavedTeam? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final gameId = json['gameId'];
    final rawIds = json['pokemonIds'];
    if (id is! String || name is! String || gameId is! String || rawIds is! List) {
      return null;
    }
    final ids = rawIds.whereType<num>().map((value) => value.toInt()).take(6).toList();
    return _SavedTeam(id: id, name: name, gameId: gameId, pokemonIds: ids);
  }
}
