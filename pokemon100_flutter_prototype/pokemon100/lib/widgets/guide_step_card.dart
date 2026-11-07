import 'package:flutter/material.dart';

import '../data/pokemon_data.dart';
import '../models/guide.dart';
import '../screens/pokemon_details_screen.dart';

class GuideStepCard extends StatelessWidget {
  final GuideStep step;
  final bool completed;
  final VoidCallback onChanged;

  const GuideStepCard({
    super.key,
    required this.step,
    required this.completed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: completed,
                  onChanged: (_) => onChanged(),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration:
                          completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              step.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                decoration:
                    completed ? TextDecoration.lineThrough : null,
              ),
            ),
            if (step.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      step.location!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (step.wildPokemon.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Pokémon (dzikie spotkania):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _buildPokemonGroup(context, step.wildPokemon),
            ],
            if (_trainerNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Trenerzy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 5,
                runSpacing: 3,
                children: _trainerNames
                    .map((name) => Chip(
                          avatar: const Icon(Icons.person, size: 14),
                          label: Text(name),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 3),
                        ))
                    .toList(),
              ),
            ],
            if (step.trainerPokemon.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Pokémony trenerów:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _buildPokemonGroup(context, step.trainerPokemon),
            ],
            if (step.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Przedmioty:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _buildItemList(),
            ],
            if (step.optional) ...[
              const SizedBox(height: 8),
              const Text(
                'Opcjonalne',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> get _trainerNames {
    if (step.trainers.isNotEmpty) return step.trainers;

    final names = <String>{};
    const classes = [
      'Camper', 'Picnicker', 'Hiker', 'Fisherman', 'Swimmer',
      'Bird Keeper', 'Bug Catcher', 'Bug Maniac', 'Aroma Lady',
      'Psychic', 'Cooltrainer', 'Black Belt', 'Battle Girl',
      'Kindler', 'Ninja Boy', 'Hex Maniac', 'PokéManiac',
      'Pokémon Breeder', 'Collector', 'Guitarist', 'Triathlete',
      'Parasol Lady', 'Gentleman', 'Pokéfan', 'Sailor', 'Expert',
      'Ruin Maniac', 'Youngster', 'Tuber',
    ];
    for (final trainerClass in classes) {
      final pattern = RegExp(
        '\${RegExp.escape(trainerClass)}\\s+([A-ZÀ-Ż][a-zà-ż’\\-]+)',
      );
      for (final match in pattern.allMatches(step.description)) {
        final name = match.group(1);
        if (name != null) names.add('$trainerClass $name');
      }
    }

    final namedBattles = RegExp(
      r'(?:Pokonaj|zmierz się z|walcz z)\s+([A-ZÀ-Ż][a-zà-ż’\-]+)',
      caseSensitive: false,
    );
    for (final match in namedBattles.allMatches(step.title)) {
      final name = match.group(1);
      if (name != null) names.add(name);
    }
    return names.toList(growable: false);
  }

  Widget _buildPokemonGroup(BuildContext context, List<String> names) {
    final chips = names
        .map((name) => _buildPokemonChip(context, name))
        .toList();
    if (chips.length <= 5) {
      return Wrap(spacing: 4, runSpacing: 2, children: chips);
    }
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
      childrenPadding: const EdgeInsets.only(bottom: 4),
      title: Text('Pokaż (\${chips.length})'),
      children: [Wrap(spacing: 6, runSpacing: 6, children: chips)],
    );
  }

  Widget _buildItemList() {
    final chips = step.items
        .map((item) => Chip(
              avatar: const Icon(Icons.backpack, size: 15),
              label: Text(item),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 3),
            ))
        .toList();
    if (chips.length <= 4) {
      return Wrap(spacing: 6, runSpacing: 6, children: chips);
    }
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text('Pokaż przedmioty (${chips.length})'),
      children: [Wrap(spacing: 6, runSpacing: 6, children: chips)],
    );
  }

  Color _typeColor(String type) {
    const colors = <String, Color>{
      'normal': Color(0xFFA8A77A), 'fire': Color(0xFFEE8130),
      'water': Color(0xFF6390F0), 'electric': Color(0xFFF7D02C),
      'grass': Color(0xFF7AC74C), 'ice': Color(0xFF96D9D6),
      'fighting': Color(0xFFC22E28), 'poison': Color(0xFFA33EA1),
      'ground': Color(0xFFE2BF65), 'flying': Color(0xFFA98FF3),
      'psychic': Color(0xFFF95587), 'bug': Color(0xFFA6B91A),
      'rock': Color(0xFFB6A136), 'ghost': Color(0xFF735797),
      'dragon': Color(0xFF6F35FC), 'dark': Color(0xFF705746),
      'steel': Color(0xFFB7B7CE), 'fairy': Color(0xFFD685AD),
    };
    return colors[type.toLowerCase()] ?? Colors.blueGrey;
  }

  String _typeEmoji(String type) {
    const emojis = <String, String>{
      'normal': '⚪', 'fire': '🔥', 'water': '💧', 'electric': '⚡',
      'grass': '🍃', 'ice': '❄️', 'fighting': '🥊', 'poison': '☠️',
      'ground': '🌍', 'flying': '🪽', 'psychic': '🔮', 'bug': '🐛',
      'rock': '🪨', 'ghost': '👻', 'dragon': '🐉', 'dark': '🌑',
      'steel': '⚙️', 'fairy': '✨',
    };
    return emojis[type.toLowerCase()] ?? '🔹';
  }

  String _pokemonLabel(String name, double? encounterRate) {
    if (encounterRate == null) return name;
    final percent = encounterRate == encounterRate.roundToDouble()
        ? encounterRate.toStringAsFixed(0)
        : encounterRate.toStringAsFixed(1);
    return '$name · $percent%';
  }

  Widget _buildPokemonChip(BuildContext context, String name) {
    double? encounterRate;
    for (final entry in step.encounterRatesPercent.entries) {
      if (entry.key.toLowerCase() == name.toLowerCase()) {
        encounterRate = entry.value;
        break;
      }
    }
    final matches = pokemonList.where(
      (pokemon) => pokemon.name.toLowerCase() == name.toLowerCase(),
    );
    final pokemon = matches.isEmpty ? null : matches.first;

    if (pokemon == null) {
      return Chip(
        avatar: const Icon(Icons.catching_pokemon, size: 15),
        label: Text(_pokemonLabel(name, encounterRate)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsets.symmetric(horizontal: 3),
      );
    }

    final primaryType = pokemon.types.isNotEmpty ? pokemon.types.first : 'normal';
    final typeNames = pokemon.types.join(' / ');
    return ActionChip(
      avatar: const Icon(Icons.catching_pokemon, size: 15),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_typeEmoji(primaryType)} '),
          Text(
            _pokemonLabel(name, encounterRate),
            style: TextStyle(
              color: _typeColor(primaryType),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (pokemon.types.length > 1) ...[
            const SizedBox(width: 4),
            Text(
              '($typeNames)',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 3),
      tooltip: 'Otwórz Pokédex: $name — $typeNames',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PokemonDetailsScreen(pokemon: pokemon),
          ),
        );
      },
    );
  }
}
