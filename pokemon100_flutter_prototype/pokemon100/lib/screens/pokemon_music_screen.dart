import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provides a safe entry point to the official Pokémon Game Sound Library.
/// Audio stays on the rights-holder's website; the app does not copy or host tracks.
class PokemonMusicScreen extends StatelessWidget {
  const PokemonMusicScreen({super.key});

  static final Uri _libraryUri =
      Uri.parse('https://soundlibrary.pokemon.co.jp/en');

  Future<void> _openLibrary(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(_libraryUri, mode: LaunchMode.externalApplication);
      if (!opened) {
        opened = await launchUrl(_libraryUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: const Text('Nie udało się otworzyć strony. Sprawdź internet i domyślną przeglądarkę; możesz skopiować adres widoczny niżej.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Muzyka Pokémon')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.library_music, size: 76),
          const SizedBox(height: 16),
          const Text(
            'Oficjalna biblioteka melodii Pokémon',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Słuchaj utworów bezpośrednio w oficjalnej bibliotece The Pokémon Company. '
            'Aplikacja nie kopiuje ani nie przechowuje ścieżek dźwiękowych.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openLibrary(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Otwórz bibliotekę muzyki'),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dlaczego otwieramy stronę zewnętrzną?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Odtwarzanie odbywa się na oficjalnej stronie, zgodnie z jej dostępnością '
                    'i zasadami. Nie osadzamy ani nie pobieramy utworów bez wyraźnej licencji '
                    'na takie wykorzystanie.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'Źródło: ${_libraryUri.toString()}',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
