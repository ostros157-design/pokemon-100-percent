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
  static const _defaultIds = <int>[25, 93, 3, 6, 131, 68];

  late List<Pokemon> _team;
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
    final savedIds = (prefs.getStringList(_storageKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final restored = <Pokemon>[];
    for (final id in savedIds) {
      final matches = pokemonList.where((pokemon) => pokemon.id == id);
      if (matches.isNotEmpty && !restored.any((p) => p.id == id) && restored.length < 6) {
        restored.add(matches.first);
      }
    }
    if (!mounted) return;
    setState(() {
      if (prefs.containsKey(_storageKey)) _team = restored;
      _nameController.text = prefs.getString(_teamNameKey) ?? 'Moja drużyna';
      _loading = false;
    });
  }

  Future<void> _saveTeam() async {
    if (_team.length > 6) return;
    setState(() {
      _saving = true;
      _status = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _storageKey,
        _team.map((pokemon) => pokemon.id.toString()).toList(),
      );
      await prefs.setString(_teamNameKey, _nameController.text.trim().isEmpty
          ? 'Moja drużyna'
          : _nameController.text.trim());
      if (!mounted) return;
      setState(() => _status = 'Drużyna została zapisana na tym urządzeniu.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'Nie udało się zapisać drużyny.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _choosePokemon() async {
    if (_team.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drużyna może mieć maksymalnie 6 Pokémonów.')),
      );
      return;
    }
    final chosen = await showModalBottomSheet<Pokemon>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PokemonPicker(excludedIds: _team.map((p) => p.id).toSet()),
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
    final recommendations = TeamRecommendationService.recommend(_team);
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
              const Text('Propozycje bazują na typach obecnej drużyny. Dostępność w konkretnej grze nie jest weryfikowana, ponieważ lokalny model nie zawiera list gatunków dla poszczególnych gier.'),
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
      appBar: AppBar(title: const Text('Kreator drużyny')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  "Pokémon: Let's Go, Pikachu!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Wybierz do 6 Pokémonów. Lista kandydatów pochodzi z ogólnego Pokédexu; '
                  'ten ekran nie potwierdza, czy każdy gatunek można zdobyć w tej grze.',
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

  const _PokemonPicker({required this.excludedIds});

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


/// Szybka analiza słabości oparta na podstawowych relacjach typów.
class _TeamAnalysis extends StatelessWidget {
  final List<Pokemon> team;

  const _TeamAnalysis({required this.team});

  static const Map<String, Set<String>> _superEffectiveAgainst = {
    'Normal': {},
    'Fire': {'Grass', 'Ice', 'Bug', 'Steel'},
    'Water': {'Fire', 'Ground', 'Rock'},
    'Electric': {'Water', 'Flying'},
    'Grass': {'Water', 'Ground', 'Rock'},
    'Ice': {'Grass', 'Ground', 'Flying', 'Dragon'},
    'Fighting': {'Normal', 'Ice', 'Rock', 'Dark', 'Steel'},
    'Poison': {'Grass', 'Fairy'},
    'Ground': {'Fire', 'Electric', 'Poison', 'Rock', 'Steel'},
    'Flying': {'Grass', 'Fighting', 'Bug'},
    'Psychic': {'Fighting', 'Poison'},
    'Bug': {'Grass', 'Psychic', 'Dark'},
    'Rock': {'Fire', 'Ice', 'Flying', 'Bug'},
    'Ghost': {'Psychic', 'Ghost'},
    'Dragon': {'Dragon'},
    'Dark': {'Psychic', 'Ghost'},
    'Steel': {'Ice', 'Rock', 'Fairy'},
    'Fairy': {'Fighting', 'Dragon', 'Dark'},
  };

  @override
  Widget build(BuildContext context) {
    final weaknesses = <String, int>{};
    for (final attackType in _superEffectiveAgainst.keys) {
      final count = team.where((pokemon) =>
          pokemon.types.any((defendingType) =>
              _superEffectiveAgainst[attackType]!.contains(defendingType))).length;
      if (count > 0) weaknesses[attackType] = count;
    }
    final sorted = weaknesses.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analiza słabości drużyny',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Liczba Pokémonów w drużynie podatnych na dany typ. '
                'To podstawowa analiza typów — nie uwzględnia zdolności, ruchów ani mnożników 4×.'),
            const SizedBox(height: 10),
            if (sorted.isEmpty)
              const Text('Brak słabości do pokazania.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sorted.map((entry) => Chip(
                  avatar: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: Text('${entry.key}: ${entry.value}/${team.length}'),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
