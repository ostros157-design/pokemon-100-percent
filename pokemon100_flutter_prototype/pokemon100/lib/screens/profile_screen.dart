import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/guides_data.dart';
import '../data/pokemon_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _caughtPokemonKey = 'caught_pokemon_ids';
  bool _loading = true;
  int _completedGuideSteps = 0;
  int _totalGuideSteps = 0;
  int _caughtPokemon = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final preferences = await SharedPreferences.getInstance();
    var completedSteps = 0;
    var totalSteps = 0;

    for (final guide in guidesList) {
      totalSteps += guide.steps.length;
      final saved = preferences.getStringList(
            'guide_progress_${guide.gameId}_${guide.id}',
          ) ??
          const <String>[];
      completedSteps += saved
          .map(int.tryParse)
          .whereType<int>()
          .where((index) => index >= 0 && index < guide.steps.length)
          .toSet()
          .length;
    }

    final caughtIds = (preferences.getStringList(_caughtPokemonKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    final validCaughtCount =
        pokemonList.where((pokemon) => caughtIds.contains(pokemon.id)).length;

    if (!mounted) return;
    setState(() {
      _completedGuideSteps = completedSteps;
      _totalGuideSteps = totalSteps;
      _caughtPokemon = validCaughtCount;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalObjectives = _totalGuideSteps + pokemonList.length;
    final completedObjectives = _completedGuideSteps + _caughtPokemon;
    final percent = totalObjectives == 0
        ? 0
        : (completedObjectives * 100 / totalObjectives).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 55),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.track_changes),
                    title: const Text('Globalny postęp Pokémon 100%'),
                    subtitle: Text('$percent% — poradniki i Pokédex łącznie'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text('Kroki poradników ukończone'),
                    subtitle: Text('$_completedGuideSteps / $_totalGuideSteps'),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.catching_pokemon),
                    title: const Text('Pokémony oznaczone jako złapane'),
                    subtitle: Text('$_caughtPokemon / ${pokemonList.length}'),
                  ),
                ),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Jak liczymy 100%?'),
                    subtitle: Text(
                      'Każdy ukończony krok poradnika oraz każdy Pokémon '
                      'oznaczony jako złapany liczy się do globalnego postępu. '
                      'Wynik obejmuje obecnie tylko dane dostępne w aplikacji.',
                    ),
                  ),
                ),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.emoji_events),
                    title: Text('Osiągnięcia'),
                    subtitle: Text('Statystyki osiągnięć nie są jeszcze połączone.'),
                  ),
                ),
              ],
            ),
    );
  }
}
