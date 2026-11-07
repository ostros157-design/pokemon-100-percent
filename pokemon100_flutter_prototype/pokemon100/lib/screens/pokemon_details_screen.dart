import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pokemon.dart';
import '../data/pokemon_data.dart';
import '../data/evolution_data.dart';
import '../data/type_effectiveness.dart';
import '../data/move_data.dart';
import '../data/pokemon_learnset_data.dart';

class PokemonDetailsScreen extends StatefulWidget {
  final Pokemon pokemon;
  final String? gameId;

  const PokemonDetailsScreen({super.key, required this.pokemon, this.gameId});

  @override
  State<PokemonDetailsScreen> createState() => _PokemonDetailsScreenState();
}

class _PokemonDetailsScreenState extends State<PokemonDetailsScreen> {
  bool _caught = false;
  bool _shiny = false;
  String _activeGameId = 'lets_go_pikachu';
  Color _cardTextColor = Colors.white;
  String _pokemonEmoji = '';

  static const List<Color> _cardTextColors = [
    Colors.white, Colors.black, Color(0xFFFFD54F), Color(0xFF80DEEA),
    Color(0xFFFF8A80), Color(0xFFB9F6CA), Color(0xFFD1C4E9),
    Color(0xFFFFCCBC), Color(0xFF90CAF9), Color(0xFFF5F5F5),
  ];
  static const List<String> _pokemonEmojis = [
    '', '🔥', '🌱', '💧', '⚡', '❄️', '👻', '🐉', '⭐', '❤️',
    '🌸', '🌙', '☀️', '🍀', '💎', '🪽', '🦴', '🎀', '👑', '💥',
  ];

  String get _caughtPokemonKey => 'caught_pokemon_ids_${_activeGameId}';
  bool _loadingCaught = true;
  String? _selectedLearnsetVersion;

  @override
  void initState() {
    super.initState();
    _loadCaughtStatus();
  }

  Future<void> _loadCaughtStatus() async {
    final preferences = await SharedPreferences.getInstance();
    _activeGameId = widget.gameId ??
        preferences.getString('selected_pokemon_game_id') ??
        'lets_go_pikachu';
    // Preserve the legacy global collection and copy it only when this game's
    // collection has not been initialized yet.
    if (!preferences.containsKey(_caughtPokemonKey)) {
      final legacyIds = preferences.getStringList('caught_pokemon_ids');
      if (legacyIds != null) {
        await preferences.setStringList(_caughtPokemonKey, legacyIds);
      }
    }
    final ids = (preferences.getStringList(_caughtPokemonKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    final shinyKey = 'shiny_pokemon_ids_' + _activeGameId;
    if (!preferences.containsKey(shinyKey)) {
      final legacyShiny = preferences.getStringList('shiny_pokemon_ids');
      if (legacyShiny != null) await preferences.setStringList(shinyKey, legacyShiny);
    }
    final shinyIds = (preferences.getStringList(shinyKey) ?? const <String>[])
        .map(int.tryParse).whereType<int>().toSet();
    final textColorValue = preferences.getInt('pokemon_card_text_color_${widget.pokemon.id}');
    final emoji = preferences.getString('pokemon_card_emoji_${widget.pokemon.id}') ?? '';
    if (!mounted) return;
    setState(() {
      _caught = ids.contains(widget.pokemon.id);
      _shiny = shinyIds.contains(widget.pokemon.id);
      _cardTextColor = textColorValue == null ? Colors.white : Color(textColorValue);
      _pokemonEmoji = emoji;
      _loadingCaught = false;
    });
  }

  Future<void> _toggleShiny() async {
    final preferences = await SharedPreferences.getInstance();
    final key = 'shiny_pokemon_ids_' + _activeGameId;
    final ids = (preferences.getStringList(key) ?? const <String>[])
        .map(int.tryParse).whereType<int>().toSet();
    if (_shiny) { ids.remove(widget.pokemon.id); } else { ids.add(widget.pokemon.id); }
    await preferences.setStringList(key, ids.map((id) => id.toString()).toList());
    if (mounted) setState(() => _shiny = !_shiny);
  }

  Future<void> _toggleCaught() async {
    final preferences = await SharedPreferences.getInstance();
    final ids = (preferences.getStringList(_caughtPokemonKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();

    setState(() {
      if (_caught) {
        ids.remove(widget.pokemon.id);
        _caught = false;
      } else {
        ids.add(widget.pokemon.id);
        _caught = true;
      }
    });
    await preferences.setStringList(
      _caughtPokemonKey,
      ids.map((id) => id.toString()).toList(),
    );
  }

  Future<void> _showAppearanceEditor() async {
    var selectedColor = _cardTextColor;
    var selectedEmoji = _pokemonEmoji;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refreshSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wygląd karty: ${widget.pokemon.name}',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 18),
                const Text('Kolor tekstu', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _cardTextColors.map((color) => InkWell(
                    onTap: () => refreshSheet(() => selectedColor = color),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: selectedColor == color ? 3 : 1,
                        ),
                      ),
                      child: selectedColor == color
                          ? Icon(Icons.check,
                              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                          : null,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Emoji Pokémona', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _pokemonEmojis.map((emoji) => ChoiceChip(
                    label: Text(emoji.isEmpty ? 'Brak' : emoji,
                        style: const TextStyle(fontSize: 20)),
                    selected: selectedEmoji == emoji,
                    onSelected: (_) => refreshSheet(() => selectedEmoji = emoji),
                  )).toList(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final preferences = await SharedPreferences.getInstance();
                      await preferences.setInt(
                        'pokemon_card_text_color_${widget.pokemon.id}',
                        selectedColor.value,
                      );
                      await preferences.setString(
                        'pokemon_card_emoji_${widget.pokemon.id}',
                        selectedEmoji,
                      );
                      if (!mounted) return;
                      setState(() {
                        _cardTextColor = selectedColor;
                        _pokemonEmoji = selectedEmoji;
                      });
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Zapisz wygląd'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvolutionTree(BuildContext context, Pokemon pokemon) {
    final familyIds = evolutionFamilies[pokemon.id];
    if (familyIds == null || familyIds.length < 2) {
      return const SizedBox.shrink();
    }
    final family = familyIds
        .map((id) => pokemonList.where((item) => item.id == id))
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toList();
    if (family.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Drzewko ewolucji',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < family.length; i++) ...[
                  if (i > 0)
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                  ActionChip(
                    avatar: CachedNetworkImage(
                      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${family[i].id}.png',
                      width: 38,
                      height: 38,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.catching_pokemon),
                    ),
                    label: Text(family[i].name),
                    tooltip: family[i].id == pokemon.id
                        ? 'Aktualny Pokémon'
                        : 'Otwórz ${family[i].name}',
                    onPressed: family[i].id == pokemon.id
                        ? null
                        : () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => PokemonDetailsScreen(
                                  pokemon: family[i],
                                  gameId: widget.gameId ?? _activeGameId,
                                ),
                              ),
                            ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeMatchups(Pokemon pokemon) {
    const attackTypes = <String>[
      'Normal', 'Fire', 'Water', 'Electric', 'Grass', 'Ice', 'Fighting',
      'Poison', 'Ground', 'Flying', 'Psychic', 'Bug', 'Rock', 'Ghost',
      'Dragon', 'Dark', 'Steel', 'Fairy',
    ];
    final weaknesses = <String>[];
    final resistances = <String>[];
    final immunities = <String>[];
    for (final attackType in attackTypes) {
      final multiplier = effectivenessAgainst(attackType, pokemon.types);
      if (multiplier == 0) {
        immunities.add(attackType);
      } else if (multiplier > 1) {
        weaknesses.add('$attackType ×${multiplier.toStringAsFixed(multiplier == multiplier.roundToDouble() ? 0 : 2)}');
      } else if (multiplier < 1) {
        resistances.add('$attackType ×${multiplier.toStringAsFixed(multiplier == multiplier.roundToDouble() ? 0 : 2)}');
      }
    }

    Widget group(String title, IconData icon, List<String> values) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (values.isEmpty)
            const Text('Brak', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: values.map((value) => Chip(
                avatar: Icon(icon, size: 16),
                label: Text(value),
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Słabości i odporności',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                group('Słabości (obrażenia zwiększone)', Icons.warning_amber, weaknesses),
                group('Odporności (obrażenia zmniejszone)', Icons.shield, resistances),
                group('Immunitety (0× obrażeń)', Icons.block, immunities),
                const Text(
                  'Obliczenia uwzględniają oba typy Pokémona i standardową tabelę typów generacji VI+. Nie uwzględniają zdolności, przedmiotów ani zmian zasad konkretnej gry.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBaseStats(Pokemon pokemon) {
    final stats = <(String, int?)>[
      ('HP', pokemon.hp),
      ('Atak', pokemon.attack),
      ('Obrona', pokemon.defense),
      ('Atak specjalny', pokemon.specialAttack),
      ('Obrona specjalna', pokemon.specialDefense),
      ('Szybkość', pokemon.speed),
    ];
    final complete = pokemon.hasCompleteBaseStats;
    final maxStat = stats.map((entry) => entry.$2 ?? 0).fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Statystyki bazowe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final stat in stats)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(width: 132, child: Text(stat.$1)),
                        Expanded(
                          child: stat.$2 == null
                              ? const Text('Brak danych')
                              : LinearProgressIndicator(
                                  value: (stat.$2! / maxStat).clamp(0.0, 1.0),
                                  minHeight: 8,
                                ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 34,
                          child: Text(
                            stat.$2?.toString() ?? '—',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Suma statystyk bazowych',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(pokemon.baseStatTotal?.toString() ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (!complete)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Brak zweryfikowanych statystyk w lokalnym zbiorze danych. Wartości nie są zgadywane.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSpeciesData(Pokemon pokemon) {
    String heightText(int? value) =>
        value == null ? 'Brak danych' : '${(value / 10).toStringAsFixed(1)} m';
    String weightText(int? value) =>
        value == null ? 'Brak danych' : '${(value / 10).toStringAsFixed(1)} kg';

    Widget valueRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dane gatunku',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                valueRow('Wzrost', heightText(pokemon.height)),
                valueRow('Masa', weightText(pokemon.weight)),
                valueRow('Bazowe doświadczenie', pokemon.baseExperience?.toString() ?? 'Brak danych'),
                valueRow('Współczynnik łapania', pokemon.captureRate?.toString() ?? 'Brak danych'),
                valueRow('Bazowa przyjaźń', pokemon.baseHappiness?.toString() ?? 'Brak danych'),
                valueRow('Cykl wykluwania', pokemon.hatchCounter?.toString() ?? 'Brak danych'),
                valueRow('Generacja', pokemon.generation?.toString() ?? 'Brak danych'),
                valueRow('Płeć', pokemon.genderRate == null
                    ? 'Brak danych'
                    : pokemon.genderRate == -1
                        ? 'Brak płci'
                        : 'Samce: ${((8 - pokemon.genderRate!) / 8 * 100).round()}%, samice: ${(pokemon.genderRate! / 8 * 100).round()}%'),
                if (pokemon.isLegendary || pokemon.isMythical || pokemon.isBaby)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (pokemon.isLegendary) const Chip(label: Text('Legendarny')),
                        if (pokemon.isMythical) const Chip(label: Text('Mityczny')),
                        if (pokemon.isBaby) const Chip(label: Text('Baby Pokémon')),
                      ],
                    ),
                  ),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    pokemon.abilities.isEmpty
                        ? 'Umiejętności: brak danych w lokalnym zbiorze'
                        : 'Umiejętności: ${pokemon.abilities.join(', ')}',
                  ),
                ),
                if (pokemon.hiddenAbilities.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Umiejętności ukryte: ${pokemon.hiddenAbilities.join(', ')}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }


  Widget _buildLearnset(Pokemon pokemon) {
    return FutureBuilder<List<PokemonLearnsetEntry>>(
      future: PokemonLearnsetData.forPokemon(pokemon.id),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <PokemonLearnsetEntry>[];
        final versionGroups = entries.map((e) => e.versionGroup).toSet().toList()..sort();
        final preferred = PokemonLearnsetData.preferredVersionGroupForGame(
          widget.gameId ?? _activeGameId,
        );
        final selected = versionGroups.contains(_selectedLearnsetVersion)
            ? _selectedLearnsetVersion
            : versionGroups.contains(preferred)
                ? preferred
                : (versionGroups.isNotEmpty ? versionGroups.first : null);
        final visible = entries.where((e) => e.versionGroup == selected).toList()
          ..sort((a, b) {
            final method = a.methodId.compareTo(b.methodId);
            if (method != 0) return method;
            final level = a.level.compareTo(b.level);
            if (level != 0) return level;
            return (a.order ?? 999).compareTo(b.order ?? 999);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ruchy i ataki', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: snapshot.connectionState != ConnectionState.done
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ))
                    : entries.isEmpty
                        ? const Text(
                            'Dane nauki ruchów nie zostały jeszcze zaimportowane. Po wygenerowaniu pliku pokemon_learnsets.json ta sekcja pokaże ruchy tego Pokémona z podziałem na gry, poziomy i metody nauki.',
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: selected,
                                decoration: const InputDecoration(labelText: 'Grupa wersji gry'),
                                items: versionGroups.map((group) => DropdownMenuItem(
                                  value: group,
                                  child: Text(group.replaceAll('-', ' ')),
                                )).toList(),
                                onChanged: (value) => setState(() => _selectedLearnsetVersion = value),
                              ),
                              const SizedBox(height: 8),
                              ...visible.map((entry) {
                                final move = moveById(entry.moveId);
                                final detail = move == null
                                    ? 'Ruch #${entry.moveId} • brak w katalogu offline'
                                    : '${move.name} • ${move.type} • ${move.category}';
                                final moveStats = move == null
                                    ? null
                                    : <String>[
                                        if (move.power != null) 'Moc ${move.power}',
                                        if (move.accuracy != null) 'Celność ${move.accuracy}%',
                                        if (move.pp != null) 'PP ${move.pp}',
                                        if (move.priority != 0) 'Priorytet ${move.priority > 0 ? '+' : ''}${move.priority}',
                                      ].join(' • ');
                                final method = entry.methodId == 1 && entry.level > 0
                                    ? 'Poziom ${entry.level}'
                                    : entry.methodLabel;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(detail),
                                  subtitle: Text([
                                    method,
                                    if (moveStats != null && moveStats.isNotEmpty) moveStats,
                                  ].join(' • ')),
                                );
                              }),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }


  Color _primaryTypeColor(Pokemon pokemon) {
    const colors = <String, Color>{
      'Normal': Color(0xFFA8A77A), 'Fire': Color(0xFFEE8130),
      'Water': Color(0xFF6390F0), 'Electric': Color(0xFFF7D02C),
      'Grass': Color(0xFF7AC74C), 'Ice': Color(0xFF96D9D6),
      'Fighting': Color(0xFFC22E28), 'Poison': Color(0xFFA33EA1),
      'Ground': Color(0xFFE2BF65), 'Flying': Color(0xFFA98FF3),
      'Psychic': Color(0xFFF95587), 'Bug': Color(0xFFA6B91A),
      'Rock': Color(0xFFB6A136), 'Ghost': Color(0xFF735797),
      'Dragon': Color(0xFF6F35FC), 'Dark': Color(0xFF705746),
      'Steel': Color(0xFFB7B7CE), 'Fairy': Color(0xFFD685AD),
    };
    return colors[pokemon.types.isEmpty ? 'Normal' : pokemon.types.first] ??
        const Color(0xFF6688CC);
  }

  void _openAdjacentPokemon(int offset) {
    final index = pokemonList.indexWhere((item) => item.id == widget.pokemon.id);
    final nextIndex = index + offset;
    if (nextIndex < 0 || nextIndex >= pokemonList.length) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PokemonDetailsScreen(
          pokemon: pokemonList[nextIndex],
          gameId: widget.gameId ?? _activeGameId,
        ),
      ),
    );
  }

  Widget _buildHero(Pokemon pokemon, Color color, {required bool compact}) {
    return Container(
      height: compact ? 148 : 286,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: 18,
            child: Icon(Icons.catching_pokemon,
                size: compact ? 100 : 170, color: Colors.white.withValues(alpha: 0.10)),
          ),
          Column(
            children: [
              SizedBox(height: compact ? 4 : 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_pokemonEmoji.isNotEmpty) ...[
                    Text(_pokemonEmoji, style: TextStyle(fontSize: compact ? 20 : 26)),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    pokemon.name,
                    style: TextStyle(
                      color: _cardTextColor,
                      fontSize: compact ? 19 : 27,
                      fontWeight: FontWeight.w800,
                      shadows: const [Shadow(color: Colors.black26, blurRadius: 8)],
                    ),
                  ),
                ],
              ),
              Text(
                '#${pokemon.id.toString().padLeft(3, '0')}',
                style: TextStyle(
                  color: _cardTextColor.withValues(alpha: 0.88),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CachedNetworkImage(
                      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${_shiny ? 'shiny/' : ''}${pokemon.id}.png',
                      fit: BoxFit.contain,
                      width: compact ? 112 : 230,
                      height: compact ? 78 : 210,
                      placeholder: (context, url) => const SizedBox(
                        width: 36, height: 36,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.catching_pokemon, size: 120, color: Colors.white,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Poprzedni Pokémon',
                        onPressed: pokemon.id > pokemonList.first.id
                            ? () => _openAdjacentPokemon(-1) : null,
                        color: Colors.white,
                        icon: const Icon(Icons.chevron_left, size: 34),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Następny Pokémon',
                        onPressed: pokemon.id < pokemonList.last.id
                            ? () => _openAdjacentPokemon(1) : null,
                        color: Colors.white,
                        icon: const Icon(Icons.chevron_right, size: 34),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: compact ? 6 : 18),
                child: Wrap(
                  spacing: 8,
                  children: pokemon.types.map((type) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(type,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pokemon = widget.pokemon;
    final primaryColor = _primaryTypeColor(pokemon);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Pokédex'),
          actions: [
            IconButton(
              tooltip: 'Dostosuj wygląd karty',
              onPressed: _showAppearanceEditor,
              icon: const Icon(Icons.palette_outlined),
            ),
            IconButton(
              tooltip: _shiny ? 'Pokaż zwykłą formę' : 'Pokaż Shiny',
              onPressed: _toggleShiny,
              icon: Icon(_shiny ? Icons.auto_awesome : Icons.auto_awesome_outlined),
            ),
          ],
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            final compact = orientation == Orientation.landscape;
            return Column(
              children: [
                _buildHero(pokemon, primaryColor, compact: compact),
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    isScrollable: compact,
                    labelColor: primaryColor,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    indicatorColor: primaryColor,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    tabs: const [
                      Tab(text: 'Informacje'),
                      Tab(text: 'Statystyki'),
                      Tab(text: 'Ewolucja'),
                      Tab(text: 'Ruchy'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildInfoTab(pokemon),
                      _buildStatsTab(pokemon),
                      _buildEvolutionTab(pokemon),
                      _buildMovesTab(pokemon),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tabContent(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildInfoTab(Pokemon pokemon) {
    final classifications = <String>[
      if (pokemon.isLegendary) 'Legendarny',
      if (pokemon.isMythical) 'Mityczny',
      if (pokemon.isBaby) 'Baby Pokémon',
    ];

    return _tabContent([
      const Text('Opis Pokémona',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            pokemon.description.trim().isEmpty
                ? 'Brak opisu tego Pokémona w lokalnej bazie danych.'
                : pokemon.description,
            style: const TextStyle(fontSize: 15, height: 1.55),
          ),
        ),
      ),
      if (classifications.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: classifications.map((label) => Chip(
            avatar: const Icon(Icons.star, size: 16),
            label: Text(label),
            visualDensity: VisualDensity.compact,
          )).toList(),
        ),
      ],
      const SizedBox(height: 12),
      _buildSpeciesData(pokemon),
      const Text('Moja kolekcja',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                _caught ? Icons.check_circle : Icons.catching_pokemon_outlined,
                color: _caught ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _loadingCaught
                      ? 'Sprawdzanie statusu...'
                      : _caught
                          ? 'Ten Pokémon jest oznaczony jako złapany.'
                          : 'Ten Pokémon nie jest jeszcze oznaczony jako złapany.',
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _loadingCaught ? null : _toggleCaught,
                child: Text(_caught ? 'Cofnij' : 'Złapany'),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildStatsTab(Pokemon pokemon) {
    return _tabContent([
      _buildBaseStats(pokemon),
      _buildTypeMatchups(pokemon),
    ]);
  }

  Widget _buildEvolutionTab(Pokemon pokemon) {
    final familyIds = evolutionFamilies[pokemon.id];
    if (familyIds == null || familyIds.length < 2) {
      return _tabContent([
        const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text('Ten Pokémon nie ma zapisanej rodziny ewolucyjnej.'),
          ),
        ),
      ]);
    }
    return _tabContent([
      _buildEvolutionTree(context, pokemon),
    ]);
  }

  Widget _buildMovesTab(Pokemon pokemon) {
    return _tabContent([
      Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: const Icon(Icons.bolt),
          title: const Text('Lista ruchów',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Rozwiń, aby zobaczyć ruchy i metody nauki'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _buildLearnset(pokemon),
            ),
          ],
        ),
      ),
    ]);
  }
}
