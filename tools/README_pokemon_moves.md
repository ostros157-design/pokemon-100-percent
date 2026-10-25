# Import danych ruchów Pokémonów

Źródła: oficjalne CSV PokéAPI: https://github.com/PokeAPI/pokeapi/tree/master/data/v2/csv

Pobierz pliki:
- [pokemon_moves.csv](https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon_moves.csv)
- [pokemon.csv](https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon.csv)
- [version_groups.csv](https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/version_groups.csv)

Uruchom z katalogu głównego repozytorium (Python 3.10+):

```powershell
python tools/import_pokemon_moves.py --pokemon-moves data/pokemon_moves.csv --pokemon data/pokemon.csv --version-groups data/version_groups.csv --output pokemon100_flutter_prototype/pokemon100/assets/data/pokemon_learnsets.json
```

Najpierw utwórz folder `data` i umieść w nim trzy pobrane pliki. Plik wynikowy zawiera relacje dla domyślnych form Pokémonów do National Dex #1025, wraz z ID ruchu, grupą wersji gry, metodą nauki, poziomem i kolejnością, jeśli jest dostępna.

Po wygenerowaniu pliku dodaj w `pubspec.yaml` wpis assetu `assets/data/pokemon_learnsets.json` (lub katalog `assets/data/`) i użyj `rootBundle.loadString` w aplikacji. Skrypt nie pobiera niczego z internetu i nie nadpisuje danych źródłowych.
