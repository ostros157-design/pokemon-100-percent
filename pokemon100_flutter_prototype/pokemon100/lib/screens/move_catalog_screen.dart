import 'package:flutter/material.dart';

import '../data/move_data.dart';

/// Offline searchable catalogue of Pokémon moves.
class MoveCatalogScreen extends StatefulWidget {
  const MoveCatalogScreen({super.key});

  @override
  State<MoveCatalogScreen> createState() => _MoveCatalogScreenState();
}

class _MoveCatalogScreenState extends State<MoveCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;
  String? _selectedCategory;

  static const _types = <String>[
    'normal', 'fire', 'water', 'electric', 'grass', 'ice', 'fighting',
    'poison', 'ground', 'flying', 'psychic', 'bug', 'rock', 'ghost',
    'dragon', 'dark', 'steel', 'fairy', 'shadow',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moves = searchMoves(
      query: _searchController.text,
      type: _selectedType,
      category: _selectedCategory,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Katalog ruchów')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Szukaj ruchu',
                hintText: 'Nazwa lub numer ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Wyczyść wyszukiwanie',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Typ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Wszystkie')),
                      ..._types.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(_capitalize(type)),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kategoria',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Wszystkie')),
                      DropdownMenuItem(value: 'physical', child: Text('Fizyczny')),
                      DropdownMenuItem(value: 'special', child: Text('Specjalny')),
                      DropdownMenuItem(value: 'status', child: Text('Statusowy')),
                    ],
                    onChanged: (value) => setState(() => _selectedCategory = value),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Znaleziono: ${moves.length}'),
            ),
          ),
          Expanded(
            child: moves.isEmpty
                ? const Center(child: Text('Brak ruchów pasujących do filtrów.'))
                : ListView.builder(
                    itemCount: moves.length,
                    itemBuilder: (context, index) {
                      final move = moves[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ExpansionTile(
                          key: ValueKey(move.id),
                          leading: CircleAvatar(
                            child: Text(move.id.toString(), style: const TextStyle(fontSize: 11)),
                          ),
                          title: Text(move.name),
                          subtitle: Text(
                            '${_capitalize(move.type)} · ${_categoryName(move.category)}',
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _statChip('Moc', move.power?.toString() ?? '—'),
                                _statChip('Celność', move.accuracy == null ? '—' : '${move.accuracy}%'),
                                _statChip('PP', move.pp?.toString() ?? '—'),
                                _statChip('Priorytet', move.priority.toString()),
                                _statChip('Generacja', move.generation.toString()),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) => Chip(label: Text('$label: $value'));

  String _categoryName(String category) => switch (category) {
        'physical' => 'Fizyczny',
        'special' => 'Specjalny',
        _ => 'Statusowy',
      };

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}
