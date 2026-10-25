import 'package:flutter/material.dart';

/// Przegląd map regionów. Jeśli grafika regionu nie została jeszcze dodana
/// do assets/maps, ekran pokazuje czytelną informację zamiast błędu.
class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  int _generation = 1;

  static const Map<int, Map<String, String>> _regions = {
    1: {'name': 'Kanto', 'game': 'Red, Blue, Yellow, Let’s Go, Pikachu! / Eevee!', 'file': 'kanto.png'},
    2: {'name': 'Johto', 'game': 'Gold, Silver, Crystal, HeartGold, SoulSilver', 'file': 'johto.png'},
    3: {'name': 'Hoenn', 'game': 'Ruby, Sapphire, Emerald, Omega Ruby, Alpha Sapphire', 'file': 'hoenn.png'},
    4: {'name': 'Sinnoh', 'game': 'Diamond, Pearl, Platinum, Brilliant Diamond, Shining Pearl', 'file': 'sinnoh.png'},
    5: {'name': 'Unova', 'game': 'Black, White, Black 2, White 2', 'file': 'unova.png'},
    6: {'name': 'Kalos', 'game': 'X, Y', 'file': 'kalos.png'},
    7: {'name': 'Alola', 'game': 'Sun, Moon, Ultra Sun, Ultra Moon', 'file': 'alola.png'},
    8: {'name': 'Galar', 'game': 'Sword, Shield', 'file': 'galar.png'},
    9: {'name': 'Paldea', 'game': 'Scarlet, Violet', 'file': 'paldea.png'},
  };

  @override
  Widget build(BuildContext context) {
    final region = _regions[_generation]!;
    final asset = 'assets/maps/gen$_generation/${region['file']}';

    return Scaffold(
      appBar: AppBar(title: const Text('Mapy regionów')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Wybierz region Pokémon',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _generation,
            decoration: const InputDecoration(
              labelText: 'Generacja',
              border: OutlineInputBorder(),
            ),
            items: _regions.entries.map((entry) => DropdownMenuItem<int>(
              value: entry.key,
              child: Text('Generacja ${entry.key} — ${entry.value['name']}'),
            )).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _generation = value);
            },
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  constraints: const BoxConstraints(minHeight: 230),
                  alignment: Alignment.center,
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 12),
                          Text('Mapa regionu ${region['name']} nie została jeszcze dodana.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                            'Ekran map jest gotowy. Po dodaniu legalnej grafiki do folderu assets mapa wyświetli się tutaj.',
                            textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(region['name']!,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Gry: ${region['game']}'),
                      const SizedBox(height: 12),
                      const Text('Planowane rozszerzenia: trasy i miasta, ważne lokacje, przedmioty oraz Pokémony powiązane z krokami poradnika.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Uwaga: obecność pliku graficznego zależy od zawartości assets. Nie pokazujemy fikcyjnych lokalizacji ani nie oznaczamy map jako kompletnych, dopóki dane nie zostaną dodane.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
