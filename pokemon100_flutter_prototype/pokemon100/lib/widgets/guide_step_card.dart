import 'package:flutter/material.dart';

import '../data/pokemon_data.dart';
import '../models/guide.dart';
import '../screens/pokemon_details_screen.dart';

class GuideStepCard extends StatelessWidget {
  final GuideStep step;
  final int stepNumber;
  final bool completed;
  final VoidCallback onChanged;

  const GuideStepCard({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.completed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: completed ? 0 : 1,
      color: completed ? colors.surfaceContainerLow : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: completed ? colors.primary.withValues(alpha: 0.45) : colors.outlineVariant,
          width: completed ? 1.2 : 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'KROK ${stepNumber.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                if (step.optional)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DODATKOWE',
                      style: TextStyle(
                        color: colors.onTertiaryContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
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
                      color: completed ? colors.onSurfaceVariant : colors.onSurface,
                      decoration:
                          completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (completed) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: colors.primary, size: 22),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurfaceVariant,
                decoration:
                    completed ? TextDecoration.lineThrough : null,
              ),
            ),
            if (step.location != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 17, color: colors.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          step.location!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

    if (pokemon == null) {
      return Chip(
        avatar: const Icon(Icons.catching_pokemon, size: 18),
        label: Text(_pokemonLabel(name, encounterRate)),
      );
    }

    return ActionChip(
      avatar: const Icon(Icons.catching_pokemon, size: 18),
      label: Text(_pokemonLabel(name, encounterRate)),
      tooltip: 'Otwórz Pokédex: $name',
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
