import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_data_download_service.dart';
import '../services/pokemon_sprite_cache.dart';

class DataDownloadSettingsScreen extends StatefulWidget {
  const DataDownloadSettingsScreen({super.key});
  @override
  State<DataDownloadSettingsScreen> createState() => _DataDownloadSettingsScreenState();
}

class _DataDownloadSettingsScreenState extends State<DataDownloadSettingsScreen> {
  String _language = 'pl';
  String _gameId = 'lets_go_pikachu';
  bool _busy = false;
  bool _spriteBusy = false;
  int _spriteCompleted = 0;
  int _spriteFailed = 0;
  Set<String> _downloaded = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = await GameDataDownloadService.downloadedPackages();
    if (!mounted) return;
    setState(() {
      _language = prefs.getString('test_language') ?? 'pl';
      _downloaded = downloaded;
    });
  }

  Future<void> _download() async {
    final pack = GameDataDownloadService.packages.firstWhere((p) => p.id == _gameId);
    setState(() => _busy = true);
    try {
      await GameDataDownloadService.download(pack);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pobrano dane mapy: ${pack.title}')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pobieranie nie powiodło się: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  Future<void> _downloadAllSprites() async {
    setState(() {
      _spriteBusy = true;
      _spriteCompleted = 0;
      _spriteFailed = 0;
    });
    try {
      final result = await PokemonSpriteCache.downloadNationalDex(
        onProgress: (completed, total, failed) {
          if (!mounted) return;
          setState(() {
            _spriteCompleted = completed;
            _spriteFailed = failed;
          });
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Zakończono: ${result.completedPokemon} Pokémonów; '
              'brakujące pliki sprite’ów: ${result.failedSprites}.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pobieranie sprite’ów przerwane: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _spriteBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = <String, Map<String, String>>{
      'pl': {'settings':'Ustawienia','preview':'To jest przykładowy podgląd tłumaczenia.'},
      'en': {'settings':'Settings','preview':'This is a sample translation preview.'},
      'de': {'settings':'Einstellungen','preview':'Dies ist eine beispielhafte Übersetzung.'},
      'es': {'settings':'Configuración','preview':'Esta es una vista previa de traducción.'},
      'fr': {'settings':'Paramètres','preview':'Ceci est un aperçu de traduction.'},
      'ja': {'settings':'設定','preview':'これは翻訳のテストプレビューです。'},
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Języki i pobieranie danych')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Język — tryb testowy', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _language,
          decoration: const InputDecoration(labelText: 'Wybierz język do testów'),
          items: const [
            DropdownMenuItem(value:'pl',child:Text('Polski')),
            DropdownMenuItem(value:'en',child:Text('English')),
            DropdownMenuItem(value:'de',child:Text('Deutsch')),
            DropdownMenuItem(value:'es',child:Text('Español')),
            DropdownMenuItem(value:'fr',child:Text('Français')),
            DropdownMenuItem(value:'ja',child:Text('日本語')),
          ],
          onChanged: (value) async {
            if (value == null) return;
            setState(() => _language = value);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('test_language', value);
          },
        ),
        Card(child: ListTile(
          leading: const Icon(Icons.translate),
          title: Text(labels[_language]!['settings']!),
          subtitle: Text(labels[_language]!['preview']!),
        )),
        const SizedBox(height: 24),
        Text('Dane gier — pobieranie offline', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Wybierz grę, której regionalny indeks mapy chcesz zapisać na urządzeniu. Wspólne regiony używają jednego pliku.'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _gameId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Gra'),
          items: GameDataDownloadService.packages.map((p) => DropdownMenuItem(value:p.id,child:Text(p.title,overflow:TextOverflow.ellipsis))).toList(),
          onChanged: _busy ? null : (value) { if (value != null) setState(() => _gameId = value); },
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _download,
          icon: _busy ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.download),
          label: Text(_busy ? 'Pobieranie…' : 'Pobierz dane wybranej gry'),
        ),
        const SizedBox(height: 8),
        Text('Dane pobierane są z repozytorium projektu. Jeśli pakiet nie został pobrany, aplikacja nadal używa wersji wbudowanej w APK.', style: Theme.of(context).textTheme.bodySmall),
        const Divider(height: 28),
        Text('Zapisane pakiety', style: Theme.of(context).textTheme.titleMedium),
        if (_downloaded.isEmpty) const ListTile(leading: Icon(Icons.cloud_off),title: Text('Brak pobranych pakietów')),
        ...GameDataDownloadService.packages.where((p) => _downloaded.contains(p.id)).map((p) => ListTile(
          dense: true, leading: const Icon(Icons.check_circle,color:Colors.green),
          title: Text(p.title), subtitle: const Text('Dane mapy zapisane offline'),
        )),
        const Divider(height: 32),
        Text('Sprite’y Pokémonów — pobieranie offline',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Pobierze zwykły i Shiny sprite dla każdego z 1025 numerów National Pokédex '
          '(maksymalnie 2050 obrazów). Wymaga internetu i wolnego miejsca; '
          'brakujące pliki zostaną pominięte, a pobieranie nie zatrzyma się przez pojedynczy błąd.',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _spriteBusy ? null : _downloadAllSprites,
          icon: _spriteBusy
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.cloud_download_outlined),
          label: Text(_spriteBusy ? 'Pobieranie sprite’ów…' : 'Pobierz wszystkie zwykłe + Shiny'),
        ),
        if (_spriteBusy || _spriteCompleted > 0) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _spriteCompleted / PokemonSpriteCache.nationalDexCount,
          ),
          const SizedBox(height: 6),
          Text(
            'Pokémony: $_spriteCompleted/${PokemonSpriteCache.nationalDexCount} '
            '• błędy plików: $_spriteFailed',
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Pliki trafiają do osobnego cache sprite’ów (limit 2500 plików, długi okres ważności). '
          'System Android może jednak usunąć cache przy czyszczeniu pamięci.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ]),
    );
  }
}
