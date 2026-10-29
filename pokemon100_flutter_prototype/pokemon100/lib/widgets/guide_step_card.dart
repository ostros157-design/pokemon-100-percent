import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: completed,
                  onChanged: (_) => onChanged(),
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
            const SizedBox(height: 8),
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
              const SizedBox(height: 12),
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
            if (step.pokemon.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Pokémon:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: step.pokemon
                    .map((name) => _buildPokemonChip(context, name))
                    .toList(),
              ),
            ],
            if (step.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Przedmioty:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: step.items
                    .map(
                      (item) => Chip(
                        avatar: const Icon(
                          Icons.backpack,
                          size: 18,
                        ),
                        label: Text(item),
                      ),
                    )
                    .toList(),
              ),
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
    final label = _pokemonLabel(name, encounterRate);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: pokemon == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PokemonDetailsScreen(pokemon: pokemon),
                ),
              );
            },
      child: Container(
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.catching_pokemon, size: 19),
            const SizedBox(width: 4),
            if (pokemon != null)
              CachedNetworkImage(
                imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${pokemon.id}.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(Icons.catching_pokemon, size: 18),
                ),
                errorWidget: (_, __, ___) => const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(Icons.image_not_supported_outlined, size: 16),
                ),
              )
            else
              const SizedBox(
                width: 28,
                height: 28,
                child: Icon(Icons.catching_pokemon, size: 18),
              ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
