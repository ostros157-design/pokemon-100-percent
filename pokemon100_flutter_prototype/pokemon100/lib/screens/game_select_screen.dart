import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/guides_data.dart';
import 'guide_screen.dart';

class _PokemonGame {
  final String id;
  final String title;
  final String generation;
  final String region;
  final String platform;

  const _PokemonGame({
    required this.id,
    required this.title,
    required this.generation,
    required this.region,
    required this.platform,
  });
}

class GameSelectScreen extends StatefulWidget {
  const GameSelectScreen({super.key});

  @override
  State<GameSelectScreen> createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  static const _selectedGameKey = 'selected_pokemon_game_id';
  static const _games = <_PokemonGame>[
    _PokemonGame(id: 'red_blue', title: 'Pokémon Red / Blue', generation: 'I', region: 'Kanto', platform: 'Game Boy'),
    _PokemonGame(id: 'yellow', title: 'Pokémon Yellow', generation: 'I', region: 'Kanto', platform: 'Game Boy'),
    _PokemonGame(id: 'fire_red_leaf_green', title: 'Pokémon FireRed / LeafGreen', generation: 'III', region: 'Kanto', platform: 'Game Boy Advance'),
    _PokemonGame(id: 'gold_silver', title: 'Pokémon Gold / Silver', generation: 'II', region: 'Johto', platform: 'Game Boy Color'),
    _PokemonGame(id: 'crystal', title: 'Pokémon Crystal', generation: 'II', region: 'Johto', platform: 'Game Boy Color'),
    _PokemonGame(id: 'heart_gold_soul_silver', title: 'Pokémon HeartGold / SoulSilver', generation: 'IV', region: 'Johto', platform: 'Nintendo DS'),
    _PokemonGame(id: 'ruby_sapphire', title: 'Pokémon Ruby / Sapphire', generation: 'III', region: 'Hoenn', platform: 'Game Boy Advance'),
    _PokemonGame(id: 'emerald', title: 'Pokémon Emerald', generation: 'III', region: 'Hoenn', platform: 'Game Boy Advance'),
    _PokemonGame(id: 'diamond_pearl', title: 'Pokémon Diamond / Pearl', generation: 'IV', region: 'Sinnoh', platform: 'Nintendo DS'),
    _PokemonGame(id: 'platinum', title: 'Pokémon Platinum', generation: 'IV', region: 'Sinnoh', platform: 'Nintendo DS'),
    _PokemonGame(id: 'black_white', title: 'Pokémon Black / White', generation: 'V', region: 'Unova', platform: 'Nintendo DS'),
    _PokemonGame(id: 'black_2_white_2', title: 'Pokémon Black 2 / White 2', generation: 'V', region: 'Unova', platform: 'Nintendo DS'),
    _PokemonGame(id: 'x_y', title: 'Pokémon X / Y', generation: 'VI', region: 'Kalos', platform: 'Nintendo 3DS'),
    _PokemonGame(id: 'omega_ruby_alpha_sapphire', title: 'Pokémon Omega Ruby / Alpha Sapphire', generation: 'VI', region: 'Hoenn', platform: 'Nintendo 3DS'),
    _PokemonGame(id: 'sun_moon', title: 'Pokémon Sun / Moon', generation: 'VII', region: 'Alola', platform: 'Nintendo 3DS'),
    _PokemonGame(id: 'ultra_sun_ultra_moon', title: 'Pokémon Ultra Sun / Ultra Moon', generation: 'VII', region: 'Alola', platform: 'Nintendo 3DS'),
    _PokemonGame(id: 'lets_go_pikachu', title: 'Pokémon: Let’s Go, Pikachu!', generation: 'VII', region: 'Kanto', platform: 'Nintendo Switch'),
    _PokemonGame(id: 'lets_go_eevee', title: 'Pokémon: Let’s Go, Eevee!', generation: 'VII', region: 'Kanto', platform: 'Nintendo Switch'),
    _PokemonGame(id: 'sword_shield', title: 'Pokémon Sword / Shield', generation: 'VIII', region: 'Galar', platform: 'Nintendo Switch'),
    _PokemonGame(id: 'brilliant_diamond_shining_pearl', title: 'Pokémon Brilliant Diamond / Shining Pearl', generation: 'VIII', region: 'Sinnoh', platform: 'Nintendo Switch'),
    _PokemonGame(id: 'legends_arceus', title: 'Pokémon Legends: Arceus', generation: 'VIII', region: 'Hisui', platform: 'Nintendo Switch'),
    _PokemonGame(id: 'scarlet_violet', title: 'Pokémon Scarlet / Violet', generation: 'IX', region: 'Paldea', platform: 'Nintendo Switch'),
  ];

  String _selectedGameId = 'lets_go_pikachu';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedGame();
  }

  Future<void> _loadSelectedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_selectedGameKey);
    if (!mounted) return;
    setState(() {
      if (saved != null && _games.any((game) => game.id == saved)) {
        _selectedGameId = saved;
      }
      _loading = false;
    });
  }

  Future<void> _selectGame(_PokemonGame game) async {
    setState(() => _selectedGameId = game.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedGameKey, game.id);
  }

  @override
  Widget build(BuildContext context) {
    final selectedGame = _games.firstWhere((game) => game.id == _selectedGameId);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final generations = _games.map((game) => game.generation).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Wybór gry')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sports_esports_rounded,
                            color: colors.onPrimaryContainer,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Wybierz swoją przygodę',
                              style: textTheme.titleLarge?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Wybór gry jest zapisywany i wykorzystywany przez '
                        'pozostałe sekcje aplikacji.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: colors.primaryContainer,
                          child: Icon(
                            Icons.check_rounded,
                            color: colors.onPrimaryContainer,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aktualnie wybrana gra',
                                style: textTheme.labelLarge?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selectedGame.title,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Region ${selectedGame.region} · Generacja ${selectedGame.generation}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Dostępne gry',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wybierz grę z listy poniżej.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final generation in generations) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Generacja $generation',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final game in _games.where(
                    (game) => game.generation == generation,
                  ))
                    _GameTile(
                      game: game,
                      selected: game.id == _selectedGameId,
                      onTap: () async {
                        await _selectGame(game);
                        if (!context.mounted) return;
                        final gameGuides = guidesList
                            .where((guide) => guide.gameId == game.id)
                            .toList();
                        if (gameGuides.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuideScreen(
                                guide: gameGuides.first,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Zapisano wybór: ${game.title}. '
                                'Poradnik dla tej gry nie został jeszcze dodany.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ],
            ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final _PokemonGame game;
  final bool selected;
  final VoidCallback onTap;

  const _GameTile({
    required this.game,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      color: selected ? colors.primaryContainer.withValues(alpha: 0.58) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: selected
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                child: Icon(
                  selected
                      ? Icons.check_rounded
                      : Icons.videogame_asset_outlined,
                  color: selected
                      ? colors.onPrimary
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: selected ? colors.primary : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedGame.region} · ${game.platform}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Icon(Icons.check_circle, color: colors.primary)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
