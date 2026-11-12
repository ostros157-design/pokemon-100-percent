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

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final moves = searchMoves(
      query: _searchController.text,
      type: _selectedType,
      category: _selectedCategory,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog ruchów'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primaryContainer, colors.surfaceContainerHighest],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: colors.surface.withValues(alpha: 0.75),
                        child: Icon(Icons.bolt, color: colors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Baza ruchów Pokémonów',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Wyszukuj ataki i porównuj ich parametry offline',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _countBadge(context, moves.length),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Szukaj ruchu',
                    hintText: 'Wpisz nazwę lub numer ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Wyczyść wyszukiwanie',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                    filled: true,
                    fillColor: colors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 520;
                    final typeField = DropdownButtonFormField<String>(
                      value: _selectedType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Typ',
                        prefixIcon: const Icon(Icons.category_outlined),
                        filled: true,
                        fillColor: colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Wszystkie typy'),
                        ),
                        ..._types.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(_capitalize(type)),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedType = value),
                    );
                    final categoryField = DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Kategoria',
                        prefixIcon: const Icon(Icons.bolt_outlined),
                        filled: true,
                        fillColor: colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem<String>(value: null, child: Text('Wszystkie kategorie')),
                        DropdownMenuItem(value: 'physical', child: Text('Fizyczny')),
                        DropdownMenuItem(value: 'special', child: Text('Specjalny')),
                        DropdownMenuItem(value: 'status', child: Text('Statusowy')),
                      ],
                      onChanged: (value) => setState(() => _selectedCategory = value),
                    );

                    if (narrow) {
                      return Column(
                        children: [
                          typeField,
                          const SizedBox(height: 8),
                          categoryField,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: typeField),
                        const SizedBox(width: 10),
                        Expanded(child: categoryField),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Wyniki wyszukiwania',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${moves.length} / ${moveCatalogue.length}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty ||
                        _selectedType != null ||
                        _selectedCategory != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.filter_alt_off, size: 17),
                        label: const Text('Wyczyść'),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: moves.isEmpty
                    ? _emptyState(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        itemCount: moves.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final move = moves[index];
                          return _MoveCard(move: move);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countBadge(BuildContext context, int count) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: colors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text('ruchów', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 54, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Nie znaleziono ruchów',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Zmień wyszukiwaną nazwę lub wybrane filtry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Wyczyść filtry'),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

class _MoveCard extends StatelessWidget {
  final MoveData move;

  const _MoveCard({required this.move});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final category = switch (move.category) {
      'physical' => 'Fizyczny',
      'special' => 'Specjalny',
      _ => 'Statusowy',
    };
    final categoryIcon = switch (move.category) {
      'physical' => Icons.sports_martial_arts,
      'special' => Icons.auto_awesome,
      _ => Icons.tune,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey(move.id),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Text(
            move.id.toString(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          move.name,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            spacing: 6,
            runSpacing: 5,
            children: [
              _tag(context, _capitalize(move.type), colors.secondaryContainer),
              _tag(context, category, colors.surfaceContainerHighest, icon: categoryIcon),
            ],
          ),
        ),
        trailing: Icon(Icons.expand_more, color: colors.onSurfaceVariant),
        children: [
          const Divider(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric(context, 'Moc', move.power?.toString() ?? '—', Icons.flash_on),
              _metric(context, 'Celność', move.accuracy == null ? '—' : '${move.accuracy}%', Icons.gps_fixed),
              _metric(context, 'PP', move.pp?.toString() ?? '—', Icons.replay),
              _metric(context, 'Priorytet', move.priority > 0 ? '+${move.priority}' : move.priority.toString(), Icons.low_priority),
              _metric(context, 'Generacja', 'Gen. ${move.generation}', Icons.auto_awesome),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String label, Color background, {IconData? icon}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: colors.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: colors.onSurface, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colors.primary),
              const SizedBox(width: 5),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}
