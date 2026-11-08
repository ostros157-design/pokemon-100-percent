import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pokemon_data.dart';
import '../data/move_data.dart';
import '../data/pokemon_learnset_data.dart';
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
  final Map<int, List<String>> _movesByPokemon = {};
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
        _movesByPokemon
          ..clear()
          ..addAll(active.movesByPokemon.map((key, value) => MapEntry(key, List<String>.from(value))));
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
    } else {
      await prefs.remove(_activeTeamStorageKey);
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
        movesByPokemon: Map<int, List<String>>.fromEntries(
          _movesByPokemon.entries.where((entry) => _team.any((pokemon) => pokemon.id == entry.key)).map(
            (entry) => MapEntry(entry.key, List<String>.from(entry.value)),
          ),
        ),
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
      _movesByPokemon.clear();
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
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.7,
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
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Opcje drużyny',
                    onSelected: (choice) => Navigator.pop(sheetContext, '$choice:${saved.id}'),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'load', child: ListTile(
                        dense: true, leading: Icon(Icons.folder_open), title: Text('Wczytaj'),
                      )),
                      PopupMenuItem(value: 'copy', child: ListTile(
                        dense: true, leading: Icon(Icons.copy), title: Text('Utwórz kopię'),
                      )),
                      PopupMenuItem(value: 'delete', child: ListTile(
                        dense: true, leading: Icon(Icons.delete_outline), title: Text('Usuń'),
                      )),
                    ],
                  ),
                  onTap: () => Navigator.pop(sheetContext, 'load:${saved.id}'),
                ),
              )),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;
    final separator = action.indexOf(':');
    if (separator < 0) return;
    final command = action.substring(0, separator);
    final teamId = action.substring(separator + 1);
    _SavedTeam? selected;
    for (final team in _savedTeams) {
      if (team.id == teamId) {
        selected = team;
        break;
      }
    }
    if (selected == null) return;

    if (command == 'load') {
      setState(() {
        _activeTeamId = selected!.id;
        _team = _pokemonFromIds(selected.pokemonIds);
        _movesByPokemon
          ..clear()
          ..addAll(selected!.movesByPokemon.map((key, value) => MapEntry(key, List<String>.from(value))));
        _nameController.text = selected.name;
        _selectedGame = _games.containsKey(selected.gameId)
            ? selected.gameId
            : TeamRecommendationService.supportedGameId;
        _status = 'Wczytano drużynę „${selected.name}”.';
      });
      await _persistSavedTeams();
      return;
    }

    if (command == 'copy') {
      final copy = _SavedTeam(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: '${selected.name} — kopia',
        gameId: selected.gameId,
        pokemonIds: List<int>.from(selected.pokemonIds),
        movesByPokemon: selected.movesByPokemon.map((key, value) => MapEntry(key, List<String>.from(value))),
      );
      setState(() {
        _savedTeams.add(copy);
        _activeTeamId = copy.id;
        _team = _pokemonFromIds(copy.pokemonIds);
        _movesByPokemon
          ..clear()
          ..addAll(copy.movesByPokemon.map((key, value) => MapEntry(key, List<String>.from(value))));
        _nameController.text = copy.name;
        _selectedGame = _games.containsKey(copy.gameId)
            ? copy.gameId
            : TeamRecommendationService.supportedGameId;
        _status = 'Utworzono kopię drużyny „${selected.name}”.';
      });
      await _persistSavedTeams();
      return;
    }

    if (command == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Usunąć drużynę?'),
          content: Text('Czy na pewno chcesz usunąć „${selected!.name}”? Tej operacji nie można cofnąć.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Anuluj'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Usuń'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() {
        _savedTeams.removeWhere((team) => team.id == selected!.id);
        if (_activeTeamId == selected.id) {
          _activeTeamId = null;
          _team = [];
          _movesByPokemon.clear();
          _nameController.text = 'Nowa drużyna';
          _selectedGame = TeamRecommendationService.supportedGameId;
        }
        _status = 'Usunięto drużynę „${selected.name}”.';
      });
      await _persistSavedTeams();
    }
  }

  Future<void> _editMoves(Pokemon pokemon) async {
    final versionGroup = PokemonLearnsetData.preferredVersionGroupForGame(_selectedGame);
    List<PokemonLearnsetEntry> learnset = const <PokemonLearnsetEntry>[];
    if (versionGroup != null) {
      learnset = await PokemonLearnsetData.forPokemonAndVersion(
        pokemon.id,
        versionGroup,
      );
    }
    if (!mounted) return;

    final moveById = <int, MoveData>{
      for (final move in moveCatalogue) move.id: move,
    };
    final availableMoveNames = learnset
        .map((entry) => moveById[entry.moveId]?.name)
        .whereType<String>()
        .toSet();
    final canVerify = learnset.isNotEmpty && availableMoveNames.isNotEmpty;
    final existing = _movesByPokemon[pokemon.id] ?? const <String>[];
    final controllers = List.generate(
      4,
      (index) => TextEditingController(
        text: index < existing.length ? existing[index] : '',
      ),
    );
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Ruchy — ${pokemon.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                canVerify
                    ? 'Sprawdzanie według danych nauki ruchów dla wybranej gry: ${_games[_selectedGame] ?? _selectedGame}.'
                    : 'Brak pełnych danych nauki ruchów dla tego Pokémona i gry. Nazwy zostaną zapisane bez weryfikacji dostępności.',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ...List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: controllers[index],
                  maxLength: 30,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Ruch ${index + 1}',
                    hintText: 'Wpisz nazwę ruchu',
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controllers.map((controller) => controller.text.trim()).toList(),
            ),
            child: const Text('Zapisz ruchy'),
          ),
        ],
      ),
    );
    for (final controller in controllers) {
      controller.dispose();
    }
    if (result == null || !mounted) return;

    final moves = result.where((move) => move.isNotEmpty).take(4).toList();
    if (canVerify) {
      final allowedByLowercase = {
        for (final name in availableMoveNames) name.toLowerCase(): name,
      };
      final invalid = moves.where(
        (name) => !allowedByLowercase.containsKey(name.toLowerCase()),
      ).toList();
      if (invalid.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Ruch niedostępny w tej grze'),
            content: Text(
              'Ten Pokémon nie ma tych ruchów w danych dla wybranej gry: ${invalid.join(', ')}.\n\nUsuń je lub zastąp ruchem z dostępnej listy. Zestaw nie został zapisany.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Wróć'),
              ),
            ],
          ),
        );
        return;
      }
    }

    setState(() {
      if (moves.isEmpty) {
        _movesByPokemon.remove(pokemon.id);
      } else {
        _movesByPokemon[pokemon.id] = moves;
      }
      _status = canVerify
          ? 'Zapisano ruchy ${pokemon.name}; sprawdzono dostępność w wybranej grze. Zapisz drużynę, aby zachować zmianę.'
          : 'Zmieniono ruchy ${pokemon.name}, ale dostępność nie została zweryfikowana z powodu braku danych dla tej gry. Zapisz drużynę, aby zachować zmianę.';
    });
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
                  final moves = _movesByPokemon[pokemon.id] ?? const <String>[];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          ListTile(
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
                                _movesByPokemon.remove(pokemon.id);
                                _status = null;
                              }),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    moves.isEmpty ? 'Ruchy: nie ustawiono' : 'Ruchy: ${moves.join(' · ')}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _editMoves(pokemon),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: Text(moves.isEmpty ? 'Dodaj ruchy' : 'Edytuj ruchy'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                if (_team.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _TeamAnalysis(team: _team, movesByPokemon: _movesByPokemon),
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
  final Map<int, List<String>> movesByPokemon;

  const _TeamAnalysis({required this.team, required this.movesByPokemon});

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
  static const Map<String, String> _displayTypes = {
    'normal': 'Normal', 'fire': 'Fire', 'water': 'Water', 'electric': 'Electric',
    'grass': 'Grass', 'ice': 'Ice', 'fighting': 'Fighting', 'poison': 'Poison',
    'ground': 'Ground', 'flying': 'Flying', 'psychic': 'Psychic', 'bug': 'Bug',
    'rock': 'Rock', 'ghost': 'Ghost', 'dragon': 'Dragon', 'dark': 'Dark',
    'steel': 'Steel', 'fairy': 'Fairy',
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

    final catalogue = <String, MoveData>{
      for (final move in moveCatalogue) move.name.trim().toLowerCase(): move,
    };
    final coverage = <String, List<String>>{};
    final unknown = <String>[];
    var damagingMoveCount = 0;
    for (final pokemon in team) {
      for (final name in movesByPokemon[pokemon.id] ?? const <String>[]) {
        final move = catalogue[name.trim().toLowerCase()];
        if (move == null) {
          unknown.add('${pokemon.name}: $name');
          continue;
        }
        if (move.category == 'status' || (move.power ?? 0) <= 0) continue;
        damagingMoveCount++;
        final moveType = _displayTypes[move.type.toLowerCase()];
        if (moveType == null) continue;
        for (final target in _strongAgainst.keys) {
          if (_multiplier(moveType, [target]) > 1) {
            final label = '${pokemon.name} — ${move.name}';
            coverage.putIfAbsent(target, () => <String>[]);
            if (!coverage[target]!.contains(label)) coverage[target]!.add(label);
          }
        }
      }
    }
    final gaps = _strongAgainst.keys.where((type) => !coverage.containsKey(type)).toList();
    final configured = team.where((p) => (movesByPokemon[p.id] ?? const <String>[]).isNotEmpty).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Analiza drużyny', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Jak czytać wynik: 2/6 oznacza, że 2 z 6 Pokémonów są słabe na ten typ ataku. Im mniejsza liczba, tym lepiej.'),
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
            const Text('Miecz — pokrycie konkretnymi ruchami', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          Text('Zestawy ruchów ustawiono u $configured/${team.length} Pokémonów. Rozpoznano $damagingMoveCount ruchów zadających obrażenia.'),
          const SizedBox(height: 8),
          if (damagingMoveCount == 0)
            const Text('Dodaj nazwy ruchów z katalogu aplikacji, aby sprawdzić ich skuteczność przeciwko typom przeciwników.')
          else ...[
            if (gaps.isEmpty)
              const Text('Ruchy w drużynie mają super skuteczne pokrycie przeciwko wszystkim typom.')
            else
              Wrap(spacing: 8, runSpacing: 4, children: gaps.map((type) => Chip(
                avatar: Icon(Icons.warning_amber, size: 18, color: Theme.of(context).colorScheme.error),
                label: Text(type),
              )).toList()),
            const SizedBox(height: 8),
            ...coverage.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('${entry.key}: ${entry.value.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
            )),
          ],
          if (unknown.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Nierozpoznane nazwy pominięte w analizie: ${unknown.join(', ')}',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Text(
            'Analiza wykorzystuje typ i kategorię ruchu z lokalnego katalogu. Nie oblicza jeszcze obrażeń, STAB, statystyk, zdolności ani ograniczeń dostępności ruchu w wybranej grze. Ruchy statusowe są pomijane.',
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
  final Map<int, List<String>> movesByPokemon;

  const _SavedTeam({
    required this.id,
    required this.name,
    required this.gameId,
    required this.pokemonIds,
    this.movesByPokemon = const <int, List<String>>{},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gameId': gameId,
    'pokemonIds': pokemonIds,
    'movesByPokemon': movesByPokemon.map((key, value) => MapEntry(key.toString(), value)),
  };

  static _SavedTeam? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final gameId = json['gameId'];
    final rawIds = json['pokemonIds'];
    final rawMoves = json['movesByPokemon'];
    if (id is! String || name is! String || gameId is! String || rawIds is! List) {
      return null;
    }
    final ids = rawIds.whereType<num>().map((value) => value.toInt()).take(6).toList();
    final moves = <int, List<String>>{};
    if (rawMoves is Map) {
      for (final entry in rawMoves.entries) {
        final pokemonId = int.tryParse(entry.key.toString());
        final values = entry.value;
        if (pokemonId != null && values is List) {
          final cleaned = values.whereType<String>().map((move) => move.trim()).where((move) => move.isNotEmpty).take(4).toList();
          if (cleaned.isNotEmpty) moves[pokemonId] = cleaned;
        }
      }
    }
    return _SavedTeam(id: id, name: name, gameId: gameId, pokemonIds: ids, movesByPokemon: moves);
  }
}
