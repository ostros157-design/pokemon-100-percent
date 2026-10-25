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
    final availableGuides = guidesList.where((guide) => guide.gameId == selectedGame.id).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Wybór gry')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Główne gry Pokémon',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Wybierz konkretną wersję. Wybór jest zapisywany. Poradniki i dane gry będą dostępne, gdy zostaną dodane do aplikacji.',
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_esports, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Aktualnie wybrana gra',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(selectedGame.title),
                              Text('Region: ${selectedGame.region} · Generacja ${selectedGame.generation}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._games.map((game) {
                  final isSelected = game.id == _selectedGameId;
                  final gameGuides = guidesList.where((guide) => guide.gameId == game.id).toList();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(isSelected ? Icons.check : Icons.videogame_asset),
                      ),
                      title: Text(game.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Gen. ${game.generation} · ${game.region} · ${game.platform}'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.chevron_right),
                      onTap: () async {
                        await _selectGame(game);
                        if (!context.mounted) return;
                        if (gameGuides.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuideScreen(guide: gameGuides.first),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(
                              'Zapisano wybór: ${game.title}. Poradnik dla tej gry nie został jeszcze dodany.',
                            )),
                          );
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
