# Import danych ruchów Pokémonów

Skrypt pobiera i przypisuje ruchy automatycznie na podstawie oficjalnych danych PokéAPI. Nie trzeba otwierać ani kopiować zawartości CSV ręcznie.

## Najprostszy sposób (Windows / PowerShell)

Zainstaluj Python 3, otwórz PowerShell w katalogu głównym repozytorium i uruchom:

```powershell
python tools/import_pokemon_moves.py --download --output pokemon100_flutter_prototype/pokemon100/assets/data/pokemon_learnsets.json
```

Skrypt sam pobierze brakujące pliki źródłowe do folderu `data` i wygeneruje JSON z relacjami Pokémon–ruch–gra–metoda nauki.

## Źródła CSV

- [pokemon_moves.csv](https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon_moves.csv)
- [pokemon.csv](https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon.csv)
- [version_groups.csv](https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/version_groups.csv)

## Co zawiera wynik?

Każdy wiersz zawiera National Dex ID Pokémona, ID ruchu, grupę wersji gry, metodę nauki, poziom i kolejność (jeśli źródło ją podaje). Uwzględniane są domyślne formy gatunków do National Dex #1025. Ruchy są łączone z istniejącym katalogiem po `moveId`; skrypt nie zgaduje nazw ani danych, których źródło nie podaje.

Wynik trafia do `pokemon100_flutter_prototype/pokemon100/assets/data/pokemon_learnsets.json`. Po wygenerowaniu trzeba dodać/utrzymać ten plik w repozytorium i podłączyć do aplikacji Flutter. Skrypt wymaga połączenia z internetem wyłącznie przy pobieraniu danych źródłowych; sama aplikacja będzie mogła korzystać z zaimportowanego JSON offline.
