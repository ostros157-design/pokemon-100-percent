
import 'package:flutter/material.dart';

import '../models/guide.dart';

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
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Wrap(
spacing: 6,
runSpacing: 6,
children: step.pokemon
    .map(
(pokemon) => Chip(
avatar: const Icon(
Icons.catching_pokemon,
size: 18,
),
label: Text(pokemon),
),
)
    .toList(),
),
],

if (step.items.isNotEmpty) ...[
const SizedBox(height: 12),
const Text(
'Przedmioty:',
style: TextStyle(
fontWeight: FontWeight.bold,
),
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
}

