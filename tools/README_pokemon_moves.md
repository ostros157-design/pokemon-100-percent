# Import danych ruchów Pokémonów

Skrypt pobiera i przypisuje ruchy automatycznie na podstawie oficjalnych danych PokéAPI. Nie trzeba otwierać ani kopiować zawartości CSV ręcznie.

## Zalecany sposób: GitHub Actions (bez pobierania CSV na komputerze)

Workflow `.github/workflows/generate-pokemon-learnsets.yml` uruchamia generator na serwerach GitHuba i zapisuje wynik w repozytorium.

1. Otwórz repozytorium i przejdź do zakładki **Actions**.
2. Wybierz **Generate Pokémon learnsets**.
3. Kliknij **Run workflow**, pozostaw `max_dex` ustawione na `1025` i potwierdź.
4. Poczekaj na zakończenie pobierania, walidacji i zapisu.
5. Po sukcesie sprawdź commit `Generate Pokémon learnset data` oraz plik `pokemon100_flutter_prototype/pokemon100/assets/data/pokemon_learnsets.json`.

Workflow wymaga uprawnienia `contents: write`. Jeśli nie może wypchnąć commita, otwórz **Settings → Actions → General → Workflow permissions** i zezwól GitHub Actions na zapisywanie zawartości repozytorium. W razie błędu sprawdź logi uruchomienia; nie zakładaj, że dane zostały wygenerowane.

## Alternatywa: lokalnie w Windows / PowerShell

Zainstaluj Python 3, otwórz PowerShell w katalogu głównym repozytorium i uruchom:

```powershell
python tools/import_pokemon_moves.py --download --output pokemon100_flutter_prototype/pokemon100/assets/data/pokemon_learnsets.json
```

Skrypt sam pobierze brakujące pliki źródłowe do folderu `data` i wygeneruje JSON z relacjami Pokémon–ruch–gra–metoda nauki.

## Testy importera

Testy regresyjne korzystają wyłącznie z małych, syntetycznych plików CSV — nie pobierają danych z internetu ani nie zmieniają assetu aplikacji. Uruchom je z katalogu głównego repozytorium:

```powershell
python -m unittest tools.test_import_pokemon_moves -v
```

Workflow GitHub Actions uruchamia te testy automatycznie przed pobraniem pełnych danych.

## Źródła CSV

- [pokemon_moves.csv](https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon_moves.csv)
- [pokemon.csv](https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/pokemon.csv)
- [version_groups.csv](https://raw.githubusercontent.com/PokeAPI/pokeapi/master/data/v2/csv/version_groups.csv)

## Co zawiera wynik?

Każdy wiersz zawiera National Dex ID Pokémona, ID ruchu, grupę wersji gry, metodę nauki, poziom i kolejność (jeśli źródło ją podaje). Uwzględniane są domyślne formy gatunków do National Dex #1025. Ruchy są łączone z istniejącym katalogiem po `moveId`; skrypt nie zgaduje nazw ani danych, których źródło nie podaje.

Wynik trafia do `pokemon100_flutter_prototype/pokemon100/assets/data/pokemon_learnsets.json`. Po wygenerowaniu trzeba dodać/utrzymać ten plik w repozytorium i podłączyć do aplikacji Flutter. Skrypt wymaga połączenia z internetem wyłącznie przy pobieraniu danych źródłowych; sama aplikacja będzie mogła korzystać z zaimportowanego JSON offline.

## Walidacja i bezpieczeństwo importu

Importer sprawdza wymagane kolumny CSV i przerywa pracę, jeśli źródłowe pliki są puste, niekompletne albo nie zawierają pasujących rekordów. Pobierane pliki są zapisywane najpierw tymczasowo, a dopiero potem podmieniane, żeby przerwane pobieranie nie pozostawiło niepełnego CSV pod docelową nazwą. Jeśli import zgłosi błąd pobierania, uruchom komendę ponownie po odzyskaniu połączenia.
