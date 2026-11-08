import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pokemon_data.dart';
import '../data/move_data.dart';
import '../data/pokemon_learnset_data.dart';
import '../models/pokemon.dart';
import '../services/team_recommendation_service.dart';
import '../services/team_battle_analysis.dart';
import '../data/team_game_availability.dart';

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
    'lets_go_eevee': "Pokémon: Let's Go, Eevee!",
    'emerald': 'Pokémon Emerald',
    'firered': 'Pokémon FireRed',
    'leafgreen': 'Pokémon LeafGreen',
    'soulsilver': 'Pokémon SoulSilver',
    'xy': 'Pokémon X/Y',
    'sword': 'Pokémon Sword (dostępność niezweryfikowana)',
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
    final availableMoveDetails = learnset.map((entry) {
      final name = moveById[entry.moveId]?.name;
      if (name == null) return null;
      final method = entry.methodId == 1
          ? 'poziom ' + entry.level.toString()
          : entry.methodLabel;
      return name + ' — ' + method;
    }).whereType<String>().toSet();
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
              if (canVerify) ...[
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Pokaż dostępne ruchy (${availableMoveNames.length})'),
                  children: [
                    ...((availableMoveDetails.toList()..sort()).map((detail) => Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(detail, style: Theme.of(dialogContext).textTheme.bodySmall),
                      ),
                    ))),
                  ],
                ),
              ],
              const SizedBox(height: 8),
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
    if (!TeamRecommendationService.hasVerifiedAvailabilityData(_selectedGame)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nie ma zweryfikowanej listy dostępności dla tej gry. Możesz budować skład ręcznie, ale rekomendacje są wyłączone.')));
      return;
    }
    final recommendations = TeamRecommendationService.recommend(_team, gameId: _selectedGame, movesByPokemon: _movesByPokemon);
    if (!mounted) return;
    if (recommendations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie znaleziono kandydatów poprawiających równowagę drużyny na podstawie dostępnych danych.')),
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
              const Text('Propozycje uwzględniają odporności typów, statystyki bazowe, wybrane umiejętności oraz przypisane ruchy. Kandydat uzupełniający lukę typem nie ma automatycznie potwierdzonego odpowiedniego ruchu. Ranking bierze tylko gatunki potwierdzone w danych regionalnych lub podstawowej wersji Let’s Go; wymiany, eventy i niepełne dane nie są zgadywane.'),
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

  Future<void> _showTeamComparison() async {
    if (_savedTeams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zapisz co najmniej dwie drużyny, aby móc je porównać.')),
      );
      return;
    }

    var firstId = _savedTeams.first.id;
    var secondId = _savedTeams[1].id;

    List<Pokemon> membersOf(_SavedTeam saved) => _pokemonFromIds(saved.pokemonIds);
    String summary(_SavedTeam saved) {
      final members = membersOf(saved);
      final types = members.expand((pokemon) => pokemon.types).toSet().toList()..sort();
      final knownTotals = members.map((pokemon) => pokemon.baseStatTotal).whereType<int>().toList();
      final average = knownTotals.isEmpty
          ? 'brak danych'
          : (knownTotals.reduce((a, b) => a + b) / knownTotals.length).round().toString();
      final movesSet = saved.movesByPokemon.values.where((moves) => moves.isNotEmpty).length;
      return '${members.length}/6 Pokémonów · ${types.length} typów · średnia suma statystyk: $average · zestawy ruchów: $movesSet/${members.length}';
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final first = _savedTeams.firstWhere((team) => team.id == firstId);
          final second = _savedTeams.firstWhere((team) => team.id == secondId);
          final firstMembers = membersOf(first);
          final secondMembers = membersOf(second);
          final firstIds = firstMembers.map((pokemon) => pokemon.id).toSet();
          final secondIds = secondMembers.map((pokemon) => pokemon.id).toSet();
          final commonIds = firstIds.intersection(secondIds);
          final onlyFirst = firstMembers.where((pokemon) => !secondIds.contains(pokemon.id)).toList();
          final onlySecond = secondMembers.where((pokemon) => !firstIds.contains(pokemon.id)).toList();
          final sameGame = first.gameId == second.gameId;
          final profileA = TeamBattleAnalysis.analyze(firstMembers, first.movesByPokemon, gameId: first.gameId);
          final profileB = TeamBattleAnalysis.analyze(secondMembers, second.movesByPokemon, gameId: second.gameId);
          final sharedCoverage = profileA.coveredTypes.intersection(profileB.coveredTypes).toList()..sort();
          final onlyCoverageA = profileA.coveredTypes.difference(profileB.coveredTypes).toList()..sort();
          final onlyCoverageB = profileB.coveredTypes.difference(profileA.coveredTypes).toList()..sort();

          String counts(Map<String, int> values) {
            final entries = values.entries.toList()
              ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
            return entries.isEmpty ? 'brak' : entries.map((e) => e.key + ' (' + e.value.toString() + ')').join(', ');
          }

          Widget profileColumn(String heading, TeamBattleProfile profile) {
            return Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('Słabości: ' + counts(profile.weaknesses), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 5),
                Text('Odporności: ' + counts(profile.resistances), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 5),
                Text('Immunitety: ' + counts(profile.immunities), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 5),
                Text('Pokryte typy ruchami: ' + (profile.coveredTypes.isEmpty ? 'brak' : (profile.coveredTypes.toList()..sort()).join(', ')), style: Theme.of(context).textTheme.bodySmall),
                Text('Braki: ' + (profile.uncoveredTypes.isEmpty ? 'brak' : profile.uncoveredTypes.join(', ')), style: Theme.of(context).textTheme.bodySmall),
                Text('Ruchy STAB: ' + profile.stabMoveCount.toString() + ' · ataki: ' + profile.damagingMoveCount.toString(), style: Theme.of(context).textTheme.bodySmall),
              ],
            ));
          }

          Widget teamPicker(String label, String selectedId, ValueChanged<String?> onChanged) {
            return DropdownButtonFormField<String>(
              value: selectedId,
              isExpanded: true,
              decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
              items: _savedTeams.map((team) => DropdownMenuItem<String>(
                value: team.id,
                child: Text(team.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: onChanged,
            );
          }

          Widget comparisonColumn(String title, _SavedTeam saved) {
            final members = membersOf(saved);
            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(saved.name, style: Theme.of(context).textTheme.titleMedium),
                  Text(summary(saved), style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  ...members.map((pokemon) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${pokemon.name}'),
                  )),
                ],
              ),
            );
          }

          return AlertDialog(
            title: const Text('Porównanie drużyn'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    teamPicker('Pierwsza drużyna', firstId, (value) {
                      if (value != null) setDialogState(() => firstId = value);
                    }),
                    const SizedBox(height: 10),
                    teamPicker('Druga drużyna', secondId, (value) {
                      if (value != null) setDialogState(() => secondId = value);
                    }),
                    const SizedBox(height: 16),
                    if (firstId == secondId)
                      const Text('Wybierz dwie różne drużyny.')
                    else ...[
                      if (!sameGame)
                        const Text('Uwaga: drużyny są przygotowane do różnych gier, więc porównanie dostępności nie jest bezpośrednie.',
                          style: TextStyle(color: Colors.orange)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          comparisonColumn('Drużyna A', first),
                          const SizedBox(width: 12),
                          comparisonColumn('Drużyna B', second),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('Wspólne Pokémony: ${commonIds.isEmpty ? 'brak' : firstMembers.where((p) => commonIds.contains(p.id)).map((p) => p.name).join(', ')}'),
                      const SizedBox(height: 8),
                      Text('Tylko w A: ${onlyFirst.isEmpty ? 'brak' : onlyFirst.map((p) => p.name).join(', ')}'),
                      const SizedBox(height: 8),
                      Text('Tylko w B: ${onlySecond.isEmpty ? 'brak' : onlySecond.map((p) => p.name).join(', ')}'),
                      const Divider(height: 24),
                      const Align(alignment: Alignment.centerLeft, child: Text('Porównanie walki', style: TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          profileColumn('Drużyna A', profileA),
                          const SizedBox(width: 12),
                          profileColumn('Drużyna B', profileB),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Wspólne pokrycie ruchami: ' + (sharedCoverage.isEmpty ? 'brak' : sharedCoverage.join(', '))),
                      const SizedBox(height: 4),
                      Text('Pokrycie tylko A: ' + (onlyCoverageA.isEmpty ? 'brak' : onlyCoverageA.join(', '))),
                      const SizedBox(height: 4),
                      Text('Pokrycie tylko B: ' + (onlyCoverageB.isEmpty ? 'brak' : onlyCoverageB.join(', '))),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Zamknij')),
            ],
          );
        },
      ),
    );
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
            tooltip: 'Porównaj drużyny',
            onPressed: _showTeamComparison,
            icon: const Icon(Icons.compare_arrows),
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
                      _status = !TeamRecommendationService.isSupportedGame(value)
                          ? 'Brak danych dostępności dla tej gry — wybór jest zablokowany.'
                          : value == 'sword'
                              ? 'Dane Sword są niezweryfikowane: możesz ręcznie dodać Pokémony, ale nie otrzymasz automatycznych rekomendacji.'
                              : (value == 'lets_go_pikachu' || value == 'lets_go_eevee')
                                  ? 'Dostępność rozróżnia wersjo-ekskluzywne Pokémony, wymiany i specjalne metody.'
                                  : (value == 'firered' || value == 'leafgreen')
                                      ? 'Filtr FireRed/LeafGreen uwzględnia wersjo-ekskluzywne Pokémony, wymiany i część metod post-game.'
                                      : 'Filtr oparty na regionalnym Pokédexie; pozycje spoza listy pozostają niepotwierdzone.';
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedGame == 'lets_go_pikachu' || _selectedGame == 'lets_go_eevee'
                      ? 'Filtr rozróżnia Pokémony dostępne w tej wersji, ekskluzywne dla drugiej wersji, ewolucje przez wymianę i specjalny transfer. W selektorze możesz włączyć także pozycje wymagające wymiany lub dodatkowej metody.'
                      : _selectedGame == 'firered' || _selectedGame == 'leafgreen'
                          ? 'Filtr uwzględnia ekskluzywne Pokémony FireRed/LeafGreen, wymiany, część post-game i hodowlę. Pozostałe gatunki spoza listy wymagają dodatkowego sprawdzenia.'
                          : _selectedGame == 'sword'
                              ? 'Dostępność Sword nie ma jeszcze kompletnej, zweryfikowanej listy. Możesz ręcznie dodawać gatunki z oznaczeniem „Brak zweryfikowanej listy”, ale automatyczne rekomendacje są wyłączone.'
                              : TeamRecommendationService.hasVerifiedAvailabilityData(_selectedGame)
                                  ? 'Dane potwierdzają przynależność do regionalnego Pokédexu. Gatunki spoza listy można pokazać osobno, ale ich dostępność wymaga sprawdzenia (np. post-game, wymiana lub event).'
                                  : 'Dla tej gry nie ma jeszcze wiarygodnych danych dostępności.' ,
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
                            subtitle: Text('#${pokemon.id.toString().padLeft(3, '0')} · ${pokemon.types.join(' / ')}\\n${TeamGameAvailability.forPokemon(widget.gameId, pokemon.id).label}'),
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
                  _TeamAnalysis(team: _team, movesByPokemon: _movesByPokemon, gameId: _selectedGame),
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
  bool _showOutsideRegionalDex = false;

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final results = pokemonList.where((pokemon) {
      if (widget.excludedIds.contains(pokemon.id)) return false;
      final availability = TeamGameAvailability.forPokemon(widget.gameId, pokemon.id);
      if (availability.kind != TeamAvailabilityKind.inGame &&
          !(_showOutsideRegionalDex && availability.canBeShownAsExtra)) return false;
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
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('Pokaż też wymiany, eventy i gatunki spoza regionalnego Pokédexu'),
              subtitle: const Text('Takie pozycje są oznaczone jako wymagające dodatkowej weryfikacji.'),
              value: _showOutsideRegionalDex,
              onChanged: (value) => setState(() => _showOutsideRegionalDex = value),
            ),
            const SizedBox(height: 4),
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
                          subtitle: Text('#${pokemon.id.toString().padLeft(3, '0')} · ${pokemon.types.join(' / ')}\\n${TeamGameAvailability.forPokemon(widget.gameId, pokemon.id).label}'),
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


/// Ekranowa prezentacja wspólnego profilu walki.
class _TeamAnalysis extends StatelessWidget {
  final List<Pokemon> team;
  final Map<int, List<String>> movesByPokemon;
  final String gameId;

  const _TeamAnalysis({required this.team, required this.movesByPokemon, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final profile = TeamBattleAnalysis.analyze(team, movesByPokemon, gameId: gameId);
    final weaknessEntries = profile.weaknesses.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    final resistanceEntries = profile.resistances.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));
    final immunityEntries = profile.immunities.entries.toList()
      ..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Analiza drużyny', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Zestawy ruchów ustawiono u ' + profile.configuredMoveSets.toString() +
              '/' + team.length.toString() + ' Pokémonów. Rozpoznano ' +
              profile.damagingMoveCount.toString() + ' ataków, w tym ' +
              profile.stabMoveCount.toString() + ' ruchów STAB.'),
          const SizedBox(height: 14),
          const Row(children: [
            Icon(Icons.shield_outlined),
            SizedBox(width: 8),
            Text('Tarcza — obrona', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          const Text('Liczba Pokémonów podatnych, odpornych lub odpornych całkowicie na dany typ ataku.'),
          const SizedBox(height: 6),
          if (weaknessEntries.isEmpty)
            const Text('Brak wykrytych słabości.')
          else
            Wrap(spacing: 7, runSpacing: 4, children: weaknessEntries.map((entry) => Chip(
              avatar: const Icon(Icons.warning_amber, size: 17),
              label: Text(entry.key + ' · ' + entry.value.toString() + '/' + team.length.toString() + ' słabych'),
            )).toList()),
          if (resistanceEntries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Odporności: ' + resistanceEntries.map((e) => e.key + ' (' + e.value.toString() + ')').join(', ')),
          ],
          if (immunityEntries.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Immunitety: ' + immunityEntries.map((e) => e.key + ' (' + e.value.toString() + ')').join(', ')),
          ],
          const Divider(height: 24),
          const Row(children: [
            Icon(Icons.sports_martial_arts),
            SizedBox(width: 8),
            Text('Miecz — pokrycie ruchami', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          if (profile.damagingMoveCount == 0)
            const Text('Dodaj rozpoznane ruchy zadające obrażenia, aby sprawdzić pokrycie typów.')
          else ...[
            Text('Brakujące typy, na które można trafić super skutecznie: ' +
                (profile.uncoveredTypes.isEmpty ? 'brak' : profile.uncoveredTypes.join(', '))),
            const SizedBox(height: 8),
            ...profile.moveCoverage.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(entry.key + ': ' + entry.value.join(', '), style: Theme.of(context).textTheme.bodySmall),
            )),
          ],
          if (profile.synergyHints.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Synergie ruchów i umiejętności', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...profile.synergyHints.map((hint) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('• ' + hint, style: Theme.of(context).textTheme.bodySmall),
            )),
          ],
          if (profile.unknownMoves.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Nierozpoznane nazwy pominięte w analizie: ' + profile.unknownMoves.join(', '),
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Text('Analiza obejmuje typy, STAB, dopasowanie kategorii ruchu do statystyk i wybrane synergie umiejętności. To podpowiedzi, nie symulacja obrażeń: nie uwzględnia m.in. natur, EV/IV, przedmiotów, pogody, efektów pobocznych ani wszystkich zdolności.',
            style: Theme.of(context).textTheme.bodySmall),
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
