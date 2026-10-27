### Mapy — pierwsza poglądowa mapa regionu Kanto (2026-10-27)
- Dodano do istniejącego ekranu map schematyczną, działającą offline mapę Kanto rysowaną przez Flutter `CustomPainter`; nie wymaga osobnego pliku graficznego ani połączenia z internetem.
- Mapa pokazuje główne miasta i wybrane punkty (m.in. Pallet Town, Viridian City, Pewter City, Cerulean City, Vermilion City, Lavender Town, Celadon City, Saffron City, Fuchsia City, Cinnabar Island i Indigo Plateau) oraz schematyczne połączenia.
- Pozostałe regiony nadal pokazują uczciwy komunikat, że ich mapy graficzne nie są przygotowane. Opis na ekranie zaznacza, że Kanto jest schematyczne, a nie w skali; nie należy traktować linii jako dokładnego odwzorowania tras z gry.
- Commit kodu mapy: `b2f47d94ebdf339c6f410fc63e4e925b40aed5a9`.
- Status: zapisano w GitHubie. Nie uruchomiono jeszcze `flutter analyze`, testów ani kompilacji; wygląd i dopasowanie etykiet trzeba sprawdzić w aplikacji.

### Mapy — schemat kolejności podróży (2026-10-27)
- Dodano numerowane oznaczenia lokacji zgodne z kolejnością ich pierwszego wystąpienia w poradniku oraz krótki opis wyjaśniający, że numeracja nie przedstawia położenia geograficznego.
- Zmiana kodu: `255587758f511875521c67b85230d8c9fe97959c`.
- Weryfikacja repozytorium: jedynym plikiem graficznym w `assets/maps` jest obecnie `gen1/charmander.png`; nie ma tam rzeczywistych map regionów. Nie wygenerowano fikcyjnych map ani lokalizacji. Testy i kompilacja nie zostały uruchomione.

### Mapy — wyszukiwanie lokacji i kolejność poradnika (2026-10-27)
- Ekran map zachowuje teraz kolejność pierwszego wystąpienia lokacji w poradniku, zamiast sortować je alfabetycznie — lista lepiej odzwierciedla kolejność podróży.
- Dodano pole wyszukiwania lokacji oraz licznik wyników w formacie „wyniki/wszystkie”.
- Zmiana kodu: `d37446301547367eeb98419a54ddb604fb1df943`.
- Status: zmiana zapisana w GitHubie; nie uruchomiono `flutter analyze`, testów ani kompilacji. W repozytorium w `assets/maps/gen1` jest tylko plik `charmander.png`, który nie jest mapą regionu; nie potwierdzono jeszcze prawidłowych grafik map dla regionów. Nie oznaczamy więc listy lokacji jako pełnej mapy graficznej.

### Generowanie learnsetów przez GitHub Actions (2026-10-26)
- Zaktualizowano ręcznie uruchamiany workflow `.github/workflows/generate-pokemon-learnsets.yml`: parametr limitu National Dex, Python 3.12, limit czasu, kontrola minimalnej liczby rekordów i pól JSON oraz podsumowanie liczby Pokémonów i grup wersji.
- Workflow ma po walidacji commitować wygenerowany plik `pokemon100_flutter_prototype/pokemon100/assets/data/pokemon_learnsets.json` do repozytorium.
- Zaktualizowano `tools/README_pokemon_moves.md` o instrukcję uruchomienia w zakładce Actions i wymagane uprawnienia zapisu.
- Commity tej aktualizacji: workflow `da509d84b8e1b4fc2fa4404fba0dcd8c37aead1f`, instrukcja `01c7b86be365b3f4bf74527f1aa6c9a5e23c084e`.
- Status: workflow nie został uruchomiony z tej sesji. Plik learnsetów nadal wymaga wygenerowania i weryfikacji przez GitHub Actions.

### Automatyzacja generowania learnsetów (2026-10-26)
- Dodano workflow GitHub Actions `.github/workflows/generate-pokemon-learnsets.yml`, uruchamiany ręcznie przez `workflow_dispatch`.
- Workflow pobiera źródłowe CSV PokéAPI, uruchamia istniejący importer, sprawdza, czy JSON jest niepusty i ma wymagane pola, a następnie commituję wygenerowany asset do repozytorium, jeśli zawartość się zmieniła.
- Commit workflow: `ceecfda349c4bc6ae31b3998db5bc3c365a78047`.
- Status: workflow dodany, ale nieuruchomiony w tej sesji; `pokemon_learnsets.json` nie został jeszcze wygenerowany. Po uruchomieniu sprawdzić logi Actions oraz wynikowy plik i dopiero potem podłączenie danych w aplikacji.

### Pokédex — pełniejsze testy etykiet metod nauki (2026-10-26)
- Rozszerzono test modelu learnsetu, aby sprawdzał wszystkie znane metody 5–11, a nie tylko metodę 5 i nieznany identyfikator.
- Commit testu: `ff3f75b67cb6391e8fdbe4fe0a1de1afb7401a94`.
- Potwierdzono odczytem repozytorium, że model zawiera etykiety metod 5–11; plik `assets/data/pokemon_learnsets.json` nadal zawiera pustą tablicę `[]`, więc rzeczywiste dane ruchów nie są jeszcze dostępne w aplikacji.
- Status: testy nieuruchomione; import danych i kompilacja pozostają do wykonania.

### Pokédex — synchronizacja etykiet metod nauki (2026-10-26)
- Ponownie zapisano korektę etykiet metod nauki ruchów w modelu; wcześniejsza próba nie utrwaliła zmian w pobranej wersji pliku.
- Commit modelu: `b2fa96981ba0e00155ef5a4408b3103904a59b39`.
- Test etykiety metody 5 znajduje się w `test/data_integrity_test.dart`; testów nie uruchomiono.
- Status: zapis wykonany, wymagana późniejsza kontrola pobrania pliku oraz uruchomienie testów.

### Pokédex — poprawne etykiety metod nauki ruchów (2026-10-26)
- Skorygowano opisy metod 5–11 zgodnie z identyfikatorami metod PokéAPI; metoda 5 nie jest ewolucją, jak sugerowała wcześniejsza etykieta.
- Rozszerzono test parsowania o sprawdzenie etykiety specjalnego ruchu Pikachu.
- Commity: `9a180732596188a9136e3f943c4675a4202af611` (model), `d101f611fca67e4ecc2ba3fe3f4c5b54b12fa7e4` (test).
- Status: zapisane w repozytorium; testy nieuruchomione. Rzeczywiste learnsety nadal wymagają wygenerowania i dodania do assetów.

### Importer learnsetów — walidacja źródeł (2026-10-26)
- Importer sprawdza wymagane kolumny CSV, odrzuca puste źródła i przerywa pracę, gdy nie znaleziono pasujących Pokémonów lub rekordów learnsetów.
- Pobieranie zapisuje plik tymczasowy i podmienia plik docelowy dopiero po zakończeniu odczytu, ograniczając ryzyko pozostawienia częściowego CSV po przerwaniu pobierania.
- Instrukcja `tools/README_pokemon_moves.md` opisuje nowe kontrole.
- Commity: `994d66ba88150408f4f5eeed9c9ee8680fa21100` (importer), `9ac72c0e8dace3f75ae885348f8920756f2837ee` (instrukcja).
- Status: zmiany zapisane; nie uruchomiono skryptu ani testów Flutter w tej sesji. Nadal potrzebne jest wygenerowanie rzeczywistego pliku learnsetów.

### Pokédex — testy parsowania learnsetów (2026-10-26)
- Uzupełniono `test/data_integrity_test.dart` o test modelu `PokemonLearnsetEntry`: parsowanie identyfikatorów, grupy wersji, poziomu oraz etykiet metod nauki, w tym nieznanej metody.
- Commit testu: `c976e5fd5b8d4f709574bd7d601836c6fcb726c0`.
- Status: test dodany w GitHubie, ale nieuruchomiony; dane learnsetów nadal wymagają importu.

### Pokédex — osobna kolekcja dla wybranej gry (2026-10-26)
- Ekran Pokédexa odczytuje teraz `selected_pokemon_game_id` i zapisuje złapane Pokémony oraz oznaczenia Shiny pod kluczami zależnymi od gry.
- Karta szczegółów korzysta z tego samego klucza dla statusu złapania; przechodzenie między Pokémonami w drzewku ewolucji zachowuje kontekst gry.
- Istniejące globalne listy nie są kasowane. Przy pierwszym użyciu kolekcji danej gry stary zapis jest kopiowany, jeśli nie ma jeszcze zapisu dla tej gry.
- Commity: `f57b97d197b4b6958a001462402c187d20666ec0` (Pokédex), `fca382ddc5d66690b280ed4cd00fd3e9e7a4e03b` (karta szczegółów).
- Status: zapisane w GitHubie; nie uruchomiono `flutter analyze`, testów ani kompilacji. Wymagana weryfikacja na urządzeniu, szczególnie migracji starego zapisu i przełączania gry.

### Pokédex — sortowanie i ładowanie obrazów (2026-10-25)
- Dodano widoczny wybór sortowania listy: numer National Pokédex rosnąco, numer malejąco oraz nazwa A–Z.
- Usunięto automatyczne pobieranie wszystkich 1025 obrazów przy otwarciu ekranu. Obrazki są teraz pobierane przez widoczne karty, co ogranicza niepotrzebny transfer i opóźnienie startu.
- Commit kodu: `7f5df3ef77156bb8a16625d4718982d776854c80`.
- Status: zapisane w GitHubie; testy Flutter i kompilacja nie zostały uruchomione w tej sesji.

# Pokémon 100% — postęp projektu

Ostatnia aktualizacja: 2026-10-25

Ten plik jest dziennikiem postępu projektu. Po kolejnych zmianach należy dopisywać datę, zakres prac, pliki/obszary oraz status testów.

## Ostatnie prace

### Katalog ruchów — poprawka filtrów (2026-10-25)
- Usunięto pozycje `DropdownMenuItem(value: null)` z list rozwijanych o typie `String`; puste pole oznacza teraz brak filtra, a więc wszystkie typy/kategorie. To eliminuje ryzyko asercji i niejednoznaczności wartości null w dropdownie.
- Commit: `93d6be46ff7474a37fb9f02fb62c9011a17d5f10`.
- Testy Flutter nie zostały uruchomione w tej sesji.


### Pokédex — API zapytań learnsetów (2026-10-25)
- Rozszerzono lokalne repozytorium learnsetów o metody zwracające dostępne grupy wersji gry dla Pokémona oraz wpisy dla konkretnej grupy.
- Metody korzystają z tego samego cache danych offline i nie wymagają połączenia sieciowego w aplikacji.
- Commit: `700ebd48344061d7d3e000f35a7cfe49f7789de0`.
- Status testów bez zmian: Flutter SDK nie został uruchomiony w tej sesji; rzeczywisty JSON learnsetów pozostaje pustym placeholderem do czasu importu.


### Pokédex — integracja sekcji ruchów z kartą Pokémona (2026-10-25)
- Dodano `lib/data/pokemon_learnset_data.dart`: model wpisu learnsetu, parser JSON i lokalny odczyt danych z bezpiecznym zachowaniem, gdy dane nie są jeszcze dostępne.
- Dodano asset `assets/data/pokemon_learnsets.json` z pustym placeholderem oraz wpis do `pubspec.yaml`, aby projekt nie odwoływał się do nieistniejącego zasobu.
- Karta szczegółowa ma sekcję „Ruchy i ataki” z filtrem grupy wersji, nazwami ruchów z lokalnego katalogu, metodą nauki i poziomem. Usunięto dawny tekst zastępczy o przyszłej liście ataków.
- Dodano test parsera learnsetu w `test/data_integrity_test.dart`.
- Commity: `dcf9bd98615b99a3490bd682a74d19f172d65872` (model), `4ea98c875b612b791acfa27d47a3ae66b582eeb6` (karta), `c8f3a24f16f83a3257ab086d1f9c9e71eef4d41e` (asset), `cafab842332a7164a7cac6afdc9465c7587aaa4c` (pubspec), `73985700a3fbca5cfe74e2b76e40d607eb7e30a1` (test).
- Status: kod zapisany; rzeczywisty zbiór learnsetów nadal nie został wygenerowany, więc sekcja pokaże informację o braku importu do czasu uruchomienia importera. `flutter test`, `flutter analyze` i build nie zostały uruchomione w tej sesji.


### Pokédex — automatyczne przygotowanie learnsetów (2026-10-25)
- Ulepszono `tools/import_pokemon_moves.py`: opcja `--download` automatycznie pobiera brakujące CSV z oficjalnego repozytorium PokéAPI, więc nie trzeba ręcznie kopiować ani zapisywać wielkiego pliku.
- Zaktualizowano `tools/README_pokemon_moves.md` o pojedynczą komendę PowerShell dla Windows.
- Commity: `155a6928cdbde751278671b5c4c0ca9c6cd43600` (importer), `b5e9fa46ca33a1a6e7fcfe94070b9853edfb9e1a` (instrukcja).
- Status: zmiany zapisane w repozytorium. Importu danych jeszcze nie uruchomiono, więc plik JSON z przypisaniami nie został jeszcze wygenerowany; aplikacja nie ma jeszcze gotowych learnsetów. Kolejny krok: podłączyć import do modelu i ekranu szczegółów oraz wygenerować dane źródłowe.
- Testy/Flutter analyze/build nieuruchomione w tej sesji.


### Pokédex — ekran katalogu ruchów (2026-10-25)
- Dodano `lib/screens/move_catalog_screen.dart`: ekran offline z wyszukiwaniem po nazwie/ID, filtrem typu i kategorii oraz rozwijanymi szczegółami mocy, celności, PP, priorytetu i generacji.
- Dodano na ekranie głównym przycisk `Katalog ruchów`, który otwiera nowy ekran.
- Commity: `f2b2e86db6b17e8596a550d96c3d5794548ba126` (ekran), `d00c075c76cb3a96b651ccda2909197e145dd4a5` (nawigacja).
- Status: kod zapisany w repozytorium; kompilacja i testy nie zostały uruchomione. Należy sprawdzić zachowanie filtrów DropdownButtonFormField na docelowej wersji Flutter.
- Learnsety przypisane do gatunków i wersji gier nadal nie są zintegrowane. PokéAPI publikuje plik `pokemon_moves.csv` o rozmiarze ok. 10,2 MB, którego nie udało się pobrać przez connector; źródło potwierdzone, dane niezaimportowane.


### Pokédex — wyszukiwanie ruchów i testy integralności (2026-10-25)
- Rozszerzono `lib/data/move_data.dart` o `moveById` oraz `searchMoves`, obsługujące wyszukiwanie po nazwie/typie/kategorii/ID i filtrowanie po typie oraz kategorii. Funkcje działają na danych lokalnych.
- Dodano `test/data_integrity_test.dart`: kontrola liczby 1025 wpisów Pokédexa, unikalności ID, podstawowych pól i parametrów katalogu ruchów oraz testy wyszukiwania.
- Commity: `a50dac9dff8e9b5c5e5ba3480b8c75fc9718d125` (API katalogu ruchów), `c8cdc17402dc1e84f614a835c4de05ca912faeda` (testy).
- Status: testy zapisane, ale nieuruchomione — środowisko tej sesji nie uruchamia Flutter SDK. Nie oznaczać danych jako zweryfikowanych testami, dopóki nie zostanie wykonane `flutter test`.
- Nadal otwarte: import relacji Pokémon–ruch–wersja gry–metoda nauki. Próba pobrania `pokemon_moves.csv` przez GitHub connector zwróciła pustą zawartość; nie przypisujemy ruchów do Pokémonów bez źródła.
 

### Pokédex — lokalny katalog ruchów (2026-10-25)
- Dodano `lib/data/move_data.dart` z katalogiem 937 ruchów z pliku `moves.csv` PokéAPI oraz nazwami angielskimi z `move_names.csv`.
- Każdy ruch ma ID, nazwę, typ, kategorię (physical/special/status), moc, PP, celność, priorytet i generację. Wartości nieznane w źródle pozostają `null`.
- Katalog jest zapisany lokalnie i może działać offline.
- Źródło: `PokeAPI/pokeapi/data/v2/csv/moves.csv`, `move_names.csv`, `types.csv`, `move_damage_classes.csv`.
- Commit: `d8baa158f398eff1e71568bf9917ed0db6b6c445`.
- Ograniczenie: źródłowy plik `pokemon_moves.csv` nie został zwrócony przez GitHub connector (pusty content), więc nie wolno jeszcze przypisywać tych ruchów do konkretnych Pokémonów ani udawać, że metody nauki są gotowe. Następny krok to pozyskać i zaimportować relacje Pokémon–ruch–gra–metoda nauki, potem zbudować interfejs ruchów na karcie.
- Status: katalog wygenerowany i zapisany; Flutter analyze/test/build nieuruchomione.


### Pokédex — dodatkowe metadane gatunków (2026-10-25)
- Rozszerzono model `Pokemon` o współczynnik łapania, bazową przyjaźń, cykl wykluwania, współczynnik płci, generację oraz flagi legendary/mythical/baby.
- Uzupełniono wszystkie 1025 wpisów na podstawie `pokemon_species.csv` z repozytorium PokéAPI.
- Karta szczegółowa wyświetla teraz te wartości oraz etykiety „Legendarny”, „Mityczny” i „Baby Pokémon”. Współczynnik płci pokazuje procentowy podział, a gatunki bez płci są oznaczane osobno.
- Commity: `16e5a8b7aba004a534db9b53f9189642e878d46c` (model), `593aae3b5ebd42241f693bb3edce39146ee75a55` (1025 wpisów), `2b0a53768c7aec6e5d888d5f9b65cf639512232b` (UI).
- Status: zapisane w GitHubie. Kompilacja i testy nie zostały uruchomione.
- Pozostaje: pełne ruchy z parametrami/metodami nauki oraz automatyczne testy i walidacja danych.


### Pokédex — lokalne statystyki i dane gatunków #001–#1025 (2026-10-25)
- Zaimportowano dane domyślnych form dla wszystkich 1025 numerów National Pokédex z publicznych CSV PokéAPI: sześć statystyk bazowych, wzrost, masę, bazowe doświadczenie, umiejętności i umiejętności ukryte.
- Wpisy `pokemon_data.dart` zawierają teraz konkretne wartości zamiast pustych pól. Karta szczegółowa może wyświetlać statystyki, BST, wzrost, masę i umiejętności offline, bez pobierania ich w czasie działania.
- Jednostki źródłowe PokéAPI są przeliczane w UI: wzrost z decymetrów na metry, masa z hektogramów na kilogramy.
- Źródła CSV: `PokeAPI/pokeapi/data/v2/csv/pokemon_stats.csv`, `pokemon.csv`, `pokemon_abilities.csv`, `abilities.csv`. Dane dotyczą domyślnych form; nie opisują wszystkich wariantów regionalnych/specjalnych.
- Commity: `23e394d7e1ff431b8e5e21b021ea92947accae15` (wygenerowany zestaw danych pomocniczych), `ec2c6b142660572dbf205c0f23eff3a3e2088a83` (wpisy Pokédexa z wartościami).
- Status: sprawdzono liczbę wygenerowanych rekordów na etapie importu (1025); kompilacja Flutter i testy automatyczne nie zostały uruchomione.
- Nadal do zrobienia w ramach punktu 1: lokalne dane ruchów z parametrami i metodami nauki, pełniejsze informacje o gatunkach oraz automatyczna walidacja spójności danych i testy.


### Pokédex — rozszerzenie modelu danych gatunku (2026-10-25)
- Rozszerzono model `Pokemon` o pola na sześć statystyk bazowych, sumę statystyk, wzrost, masę, bazowe doświadczenie, umiejętności i umiejętności ukryte.
- Karta szczegółowa ma teraz sekcje „Statystyki bazowe” i „Dane gatunku”, w tym wizualne paski statystyk, sumę BST oraz jednostki wzrostu i masy.
- Brakujące wartości są jawnie pokazywane jako „Brak danych”; kod nie podstawia fikcyjnych statystyk.
- Ważne ograniczenie: istniejący `pokemon_data.dart` nadal nie wypełnia nowych pól dla wszystkich 1025 gatunków. To przygotowuje model i UI, ale nie oznacza, że statystyki/umiejętności są już kompletne. Następnym etapem jest zaimportowanie zweryfikowanego zestawu danych i walidacja identyfikatorów.
- Commity: `df0bc2a8ea59163a571d4b591ba6c0b90fb6a7b2` (model), `cb5be2b0331864ffa6004d79e3bc36f1da92c433` (karta szczegółowa).
- Status: zapisane w GitHubie; kompilacja, formatowanie i testy Flutter nie zostały uruchomione.


### Pokédex — analiza słabości i odporności typów (2026-10-25)
- Dodano `lib/data/type_effectiveness.dart` z tabelą skuteczności 18 typów i mnożnikami dla pojedynczych oraz podwójnych typów.
- Karta szczegółowa pokazuje typy ataków zadające zwiększone lub zmniejszone obrażenia oraz immunitety 0×.
- Opis interfejsu zaznacza ograniczenie: nie uwzględnia zdolności, przedmiotów ani różnic zasad konkretnej gry.
- Commity: `6377d35f8828c3913e668afae402fd2c97b9d465` (tabela typów), `73edbced794cfb31f750072e7268e7f13fb2295b` (karta szczegółowa).
- Status: zapisane w GitHubie; kompilacja i testy nie zostały uruchomione.

### Pokédex — widoczny filtr gry (2026-10-25)
- Dodano rozwijane pole „Gra” obok filtra typów.
- Dostępne wybory: „Wszystkie” oraz „Let's Go, Pikachu!”. Wybór Let's Go ogranicza listę do Pokémonów #1–#151 z uwzględnieniem listy wykluczeń zapisanej w kodzie.
- To na razie jedyna gra z osobną logiką dostępności w Pokédexie; nie dodano pozornych filtrów dla gier bez przygotowanych danych.
- Zmiana kodu: commit `4996b5fa3b1e64a2decb237a1e688cfe24da24dc`. Kompilacja i testy nadal nie zostały uruchomione.

### Pokédex — kolekcja i sortowanie (2026-10-25)
- Dodano oznaczanie złapanych Pokémonów bezpośrednio na kartach Pokédexa oraz filtr „Tylko złapane”.
- Dodano licznik złapanych Pokémonów oraz sortowanie po numerze rosnąco/malejąco i alfabetycznie.
- Stan złapania i wybór Shiny są zapisywane w SharedPreferences i odczytywane po ponownym uruchomieniu.
- Zmiana zapisana w GitHubie w commicie `41d4d43c8d0667cf75df53c1d408224f7f2d2684`; kompilacja i testy nadal niepotwierdzone.


### Pokédex — drzewko ewolucji (2026-10-25)
- Dodano sekcję „Drzewko ewolucji” na ekranie szczegółów Pokémona.
- Formy z dostępnych rodzin są klikalne i prowadzą do karty wybranego Pokémona.
- Wykorzystywana jest istniejąca, częściowa mapa rodzin z `lib/data/evolution_data.dart`; nie obejmuje ona jeszcze wszystkich Pokémonów ani warunków ewolucji.
- Status: zapisane w GitHubie (commit `98ff6563c10c90ea67e7078e9a048ad1e80c4171`); kompilacja i testy na urządzeniu niepotwierdzone.


### Muzyka Pokémon — 2026-10-25
- Dodano ekran „Muzyka Pokémon” oraz pozycję na ekranie głównym.
- Ekran otwiera oficjalną Pokémon Game Sound Library w zewnętrznej przeglądarce; aplikacja nie hostuje, nie pobiera ani nie osadza chronionych nagrań.
- Dodano zależność `url_launcher`.
- Źródło: https://soundlibrary.pokemon.co.jp/en . Dostępność utworów i warunki użycia zależą od oficjalnej witryny.
- Status: zmiany zapisane w GitHubie; kompilacja i działanie na urządzeniu niepotwierdzone.


### Pokédex — filtry typów
- Dodano panel „Filtry” z wyborem typów Pokémonów.
- Można wybrać kilka typów; wynik pasuje, jeśli Pokémon ma co najmniej jeden zaznaczony typ.
- Filtry współpracują z wyszukiwaniem po nazwie i numerze.
- Status: zapisane w GitHubie; kompilacja i testy urządzeniowe niepotwierdzone.

### Pokédex — wybór gry i Shiny
- Rozpoczęto dodawanie filtra gry: „Wszystkie Pokémony” oraz „Pokémon: Let’s Go, Pikachu!”.
- Dodano logikę przełączania sprite'a na Shiny po kliknięciu lub przesunięciu po obrazku karty.
- Shiny ma być wyłącznie opcjonalną zmianą wizualną i nie może być wymagane do ukończenia Pokédexa w 100%.
- Status: kod zapisany w GitHubie, ale wymaga przeglądu i kompilacji. Nie uznawać za przetestowane.

### Team Making
- Dodano usługę rekomendowania Pokémonów, które mogą uzupełnić słabości drużyny.
- Dodano wybór gry; aktualnie zweryfikowana ścieżka dostępności dotyczy Let’s Go, Pikachu!, pozostałe gry wymagają uzupełnienia danych.
- Zachowujemy preferencję użytkownika: Haunter ma pozostać Haunterem; nie proponować wymiany na Gengara.
- Status: zapisane w GitHubie; kompilacja i testy wymagają potwierdzenia.

### Poprawki kompilacji zgłoszone wcześniej
- W `lib/main.dart` zmieniono `CardTheme` na `CardThemeData`.
- W `lib/screens/pokedex_screen.dart` poprawiono odwołanie do URL obrazka.
- Status: poprawki zapisane, ale wynik kolejnej kompilacji nie został potwierdzony.

## Zasady raportowania postępu
- Po każdej zmianie kodu dopisać krótki wpis w tym pliku.
- Oddzielać status „zapisane w GitHubie” od „skompilowane” i „przetestowane”.
- Nie deklarować, że funkcja działa poprawnie, dopóki nie ma wyniku kompilacji/testu.
- Zapisywać istotne problemy, brakujące dane i następny krok.

## Następne kroki
1. Pobrać zmiany i uruchomić `flutter build apk --release`.
2. Naprawić wszystkie zgłoszone błędy kompilacji.
3. Sprawdzić działanie filtrów typów, filtra gry i przełączania Shiny.
4. Po weryfikacji dopisać wyniki testów do tego pliku.
5. Kontynuować aktualizowanie dziennika przy każdej kolejnej zmianie.


### Mapy regionów — 2026-10-25
- Dodano ekran `MapsScreen` z wyborem regionu dla generacji 1–9 (Kanto, Johto, Hoenn, Sinnoh, Unova, Kalos, Alola, Galar, Paldea).
- Dodano wejście „Mapy regionów” na ekranie głównym.
- Ekran próbuje wczytać grafikę z `assets/maps/genN/nazwa_regionu.png`; jeśli jej brakuje, pokazuje informację zamiast awarii.
- Ważne: nie potwierdzono, że odpowiednie pliki graficzne są już w repozytorium. Trasy, miasta, oznaczenia Pokémonów/przedmiotów i połączenie z poradnikiem pozostają kolejnym etapem.
- Status: zapisane w GitHubie; kompilacja i test na urządzeniu nie zostały uruchomione.


### Katalog głównych gier Pokémon — 2026-10-25
- Zaktualizowano ekran wyboru gry: dodano katalog głównych gier z generacji I–IX, w tym wersje i remaki.
- Priorytetem pozostaje Pokémon: Let’s Go, Pikachu!; jest domyślnie wybraną grą.
- Wybrana gra jest zapisywana w SharedPreferences pod kluczem `selected_pokemon_game_id` i przy ponownym otwarciu ekranu jest odczytywana.
- Jeśli dla wybranej gry istnieje poradnik w `guides_data.dart`, można go otworzyć. Dla pozostałych gier ekran informuje, że poradnik nie został jeszcze dodany — sam wpis w katalogu nie oznacza kompletności danych.
- Ważna luka: zapis postępu poradnika jest już rozdzielany przez `gameId`, ale lista złapanych Pokémonów nadal używa globalnego klucza `caught_pokemon_ids`. Wymaganie osobnego postępu dla każdej wersji nie jest jeszcze w pełni wdrożone; trzeba przenieść zapis złapanych Pokémonów na klucze zależne od wybranej gry i połączyć wybór gry z Pokédexem, mapami oraz Team Making.
- Status: kod zapisany w GitHubie; nie uruchomiono kompilacji ani testów. Nie deklarować jeszcze pełnej obsługi wszystkich gier.


### Team Making — tarcza i miecz w analizie — 2026-10-25
- Zastąpiono ostrzegawcze trójkąty dwoma sekcjami: tarcza oznacza typy ataków, na które podatni są członkowie drużyny; miecz oznacza typy przeciwników, przeciw którym drużyna nie ma super skutecznego pokrycia na podstawie typów Pokémonów.
- Analiza defensywna uwzględnia podwójne typy, podstawowe odporności i immunitety. Przy tarczy pokazuje liczbę podatnych Pokémonów z całej drużyny.
- Analiza ofensywna opiera się na typach Pokémonów, nie na faktycznie poznanych ruchach; ten limit jest opisany w interfejsie.
- Status: zmiana zapisana w GitHubie; kompilacja i testy nie zostały uruchomione.


### Poprawki UX zgłoszone przez użytkownika — 2026-10-25
- Kreator drużyny: doprecyzowano etykietę tarczy — np. „2/6 podatne” oznacza 2 Pokémony z 6 podatne na dany typ; dodano krótkie wyjaśnienie i opis ograniczeń miecza.
- Pokédex: przesunięcie poziome ma przełączać Shiny na całej karcie, nie tylko po trafieniu dokładnie w obrazek; stuknięcie w obrazek nadal przełącza Shiny.
- Muzyka: dodano próbę otwarcia linku w trybie domyślnym, jeśli otwarcie zewnętrzne się nie powiedzie, oraz czytelniejszy komunikat błędu.
- Szczegóły Pokémona: zastąpiono część placeholderów sekcją „Spotkanie i łapanie”; UI wyjaśnia, że procent spotkania i szansa złapania wymagają danych zależnych od gry i warunków. Nie wstawiono zmyślonych procentów.
- Status: zapisano poprawki kodu; kompilacja i test na Androidzie nie zostały uruchomione. Wymagane dalsze prace: zweryfikowane dane spotkań dla konkretnej gry/lokacji oraz kalkulator szansy złapania.


### Poradnik — procent pojawienia się obok nazwy Pokémona — 2026-10-25
- Rozszerzono model `GuideStep` o opcjonalną mapę `encounterRatesPercent`, która pozwala przypisać zweryfikowany procent spotkania do konkretnego Pokémona w danym kroku/lokacji.
- Chip Pokémona w poradniku wyświetla procent obok nazwy, gdy taka wartość jest podana; nazwa nadal otwiera szczegóły w Pokédexie.
- Nie wpisano przykładowych ani zmyślonych wartości. Obecne kroki poradników nie otrzymają procentów, dopóki nie uzupełnimy zweryfikowanych danych dla konkretnej gry i lokacji.
- Status: zmiany zapisane w GitHubie; kompilacja/testy nie zostały uruchomione.

### Pokédex — przywrócenie statystyk bazowych (2026-10-27)
- Przywrócono w `pokemon_data.dart` sześć statystyk bazowych, wzrost, masę, bazowe doświadczenie, umiejętności i umiejętności ukryte dla wszystkich 1025 wpisów National Dex.
- Zachowano aktualne metadane gatunków z bieżącego pliku, w tym współczynnik łapania, szczęście bazowe, licznik jaj, płeć, generację oraz flagi Legendary/Mythical/Baby.
- Walidacja przed zapisem: 1025 wpisów, 1025 pól HP, 1025 wzrostów, 1025 zestawów umiejętności i 1025 współczynników łapania.
- Commit danych: `68b77b65b7b8bdf6306aa67074de5450cdb1a8fd`.
- Status: sprawdzono strukturę wygenerowanego tekstu; `flutter analyze`, testy i kompilacja APK nie zostały jeszcze uruchomione.


### Profil — postęp oddzielnie dla wybranej gry (2026-10-27)
- Zmieniono `lib/screens/profile_screen.dart`, aby profil odczytywał wyłącznie kroki poradników przypisane do gry zapisanej pod `selected_pokemon_game_id`.
- Liczba złapanych Pokémonów korzysta teraz z klucza `caught_pokemon_ids_<gameId>`, zgodnego z zapisem Pokédexa. Dodano zgodny wstecz fallback do starego klucza globalnego, aby nie ukrywać dotychczasowego postępu przed migracją.
- Profil pokazuje nazwę wybranej gry i opisuje procent jako postęp dla tej gry zamiast błędnie sumować poradniki z wielu wersji.
- Commit kodu: `7170eb118f6307d18e119d395aa78cd7761671ac`.
- Status: zapisano w GitHubie; `flutter analyze`, testy i kompilacja APK nie zostały uruchomione w tej sesji. Po stronie lokalnej należy pobrać zmiany i zweryfikować przełączanie gry oraz zachowanie starszych zapisów.


### Osiągnięcia — odblokowywanie kamieni milowych Pokédexu (2026-10-27)
- Zmieniono `lib/screens/achievements_screen.dart` z widoku statycznego na ekran odczytujący zapisane postępy dla aktualnie wybranej gry.
- Osiągnięcia „Pierwszy Pokémon”, „Początek Pokédexu”, 25, 50, 100 Pokémonów oraz pełny Pokédex są teraz odblokowywane na podstawie liczby unikalnych Pokémonów oznaczonych jako złapane w tej grze.
- Pozostałe osiągnięcia pozostają zablokowane, dopóki aplikacja nie będzie zapisywać rzeczywistych sygnałów ich ukończenia (np. odznak lub zwycięstw). Nie udajemy, że są już śledzone.
- Commit kodu: `76a0710bed4b00d26b846f9e255dba92c955433b`.
- Status: zapisano w GitHubie; testy, `flutter analyze` i build APK nie zostały uruchomione w tej sesji. Wymagane testy lokalne: progi 1/25/50/100, przełączanie wybranej gry oraz zgodność z istniejącymi zapisami.


### Postęp gry — izolacja starszych zapisów (2026-10-27)
- Dodatkowo zabezpieczono profil i osiągnięcia przed pokazywaniem starej globalnej kolekcji jako postępu w każdej nowej grze.
- Stary klucz `caught_pokemon_ids` jest używany jako fallback tylko wtedy, gdy nie istnieje jeszcze żadna kolekcja per gra. Gdy kolekcje per gra już istnieją, brak wpisu dla danej wersji oznacza 0 zapisanych Pokémonów w tej wersji.
- Commity poprawek: `10830d15221cb8242beb00fa8e118e1285039a97` (profil), `8e03b5318710e9c37c75ae0fa928bdd4f58f9a62` (osiągnięcia).
- Status: zapisano w GitHubie; wymagane lokalne `flutter analyze`, testy i build APK.


### Osiągnięcia — wspólna kolekcja między grami (2026-10-27)
- Zmieniono `lib/screens/achievements_screen.dart`, aby kamienie milowe Pokédexu 1/25/50/100 liczyły różne gatunki zebrane we wszystkich zapisach gier, a nie tylko w aktualnie wybranej grze.
- Liczenie używa sumy unikalnych National Dex ID z kluczy `caught_pokemon_ids_<gameId>`, więc ten sam Pokémon złapany w kilku grach liczy się do globalnego osiągnięcia tylko raz.
- Starszy globalny zapis `caught_pokemon_ids` pozostaje obsługiwany, gdy użytkownik nie ma jeszcze żadnych zapisów per gra.
- Ekran pokazuje teraz osobno globalną liczbę różnych Pokémonów i liczbę złapanych w wybranej grze. Osiągnięcia zależne od odznak, walk, ewolucji i drużyn nadal pozostają zablokowane, ponieważ te zdarzenia nie są jeszcze śledzone.
- Commit: `4a3f242021bc9adb760de32fd82b347a05dd385c`.
- Status: zapisano w GitHubie; nie uruchomiono jeszcze `flutter analyze`, testów ani kompilacji APK. Należy sprawdzić składnię i progi 1/25/50/100 po pobraniu zmian.


### Pokédex — indeksowanie danych learnsetów (2026-10-27)
- Zoptymalizowano `PokemonLearnsetData`: wpisy są indeksowane według National Dex ID, więc kolejne odczyty dla konkretnego Pokémona nie filtrują za każdym razem całego pliku.
- Indeks jest budowany leniwie i cache'owany; listy w indeksie są niemodyfikowalne. Obsługa brakującego lub niepoprawnego assetu nadal zwraca pustą listę zamiast powodować awarię aplikacji.
- Dodano test izolacji indeksu: wpisy różnych Pokémonów nie mieszają się, a brakujący ID zwraca brak wyniku.
- Commity: `9c7e0ceff8b108580de6554e77469a08e7096ff5` (indeks), `f2dc4165758ec91674973a9aae02e3905276e467` (test).
- Status: zmiany zapisane w GitHubie. Testy Flutter, analiza statyczna i kompilacja APK nie zostały uruchomione. Dane `pokemon_learnsets.json` nadal wymagają wygenerowania przez workflow GitHub Actions i sprawdzenia jego wyniku.

### Pokédex — indeks katalogu ruchów (2026-10-27)
- Zmieniono `lib/data/move_data.dart`: wyszukiwanie ruchu po PokéAPI ID korzysta teraz z niemodyfikowalnego indeksu budowanego raz, zamiast przeglądać cały katalog przy każdym wywołaniu.
- Dzięki temu odczyt ruchu podczas łączenia wpisów learnsetu z katalogiem ma średni koszt O(1). Nie zmieniono danych ruchów ani zasad ich interpretacji.
- Commit: `1d5b6244a1374f6a6f83989179d1624ca057f5ac`.
- Status: zapisane w GitHubie. Testy Flutter, `flutter analyze` i kompilacja APK nie zostały uruchomione. Rzeczywisty learnset nadal wymaga wygenerowania przez workflow GitHub Actions.

### Pokédex — szczegóły ruchów w learnsecie (2026-10-27)
- Rozszerzono listę ruchów na karcie szczegółowej Pokémona o dane dostępne w katalogu offline: moc, celność, PP i priorytet (pokazywane tylko wtedy, gdy źródło zawiera daną wartość).
- Jeśli ID ruchu z learnsetu nie występuje w katalogu, ekran jawnie pokazuje jego ID i informację o braku w katalogu zamiast przypisywać mu błędną nazwę.
- Commit: `a7922158be3cc1d919ce05f36d9a214d7e68818a`.
- Status: zapisane w GitHubie. Nie uruchomiono testów Flutter, analizy statycznej ani kompilacji APK. Dane learnsetu nadal wymagają wygenerowania i sprawdzenia workflow GitHub Actions.

### Pokédex — odporne wczytywanie learnsetów (2026-10-27)
- `lib/data/pokemon_learnset_data.dart`: dodano `parseRows`, które waliduje identyfikatory i pomija pojedyncze wadliwe rekordy zamiast odrzucać cały plik przez błąd jednego wiersza. Nieprawidłowy format głównego JSON-a nadal daje pustą listę.
- `test/data_integrity_test.dart`: dodano test mieszanki poprawnych rekordów, błędnego pola, elementu niebędącego mapą, niepoprawnego ID oraz niemodyfikowalnego wyniku.
- Commity: `28bdc8c47f3e5b8fdbd573ea1238cedd9bc28d62`, `dac9e8eddf87ae5546dc24249a0bc9ce8c49bfa9`.
- Status: kod i test zapisane na GitHubie. Testów nie uruchomiono lokalnie. Nadal wymagane jest uruchomienie workflow importującego rzeczywiste dane PokéAPI oraz sprawdzenie jego wyniku.

### Automatyzacja — dokładniejsza walidacja importu learnsetów (2026-10-27)
- Workflow `.github/workflows/generate-pokemon-learnsets.yml` przekazuje limit National Dex przez zmienną środowiskową zamiast wstawiać go bezpośrednio do polecenia powłoki.
- Walidacja sprawdza teraz każdy rekord JSON: wymagane pola, typy liczbowe, dodatnie identyfikatory, nieujemny poziom, typ nazwy grupy wersji oraz minimalne pokrycie gatunków. Wcześniej kontrolowane były głównie pola pierwszego rekordu i ogólna liczba wierszy.
- Commit: `600bce55e65db1461ff8bf20e5b40b5ad7d3a178`.
- Status: workflow zapisany na GitHubie, ale nie został uruchomiony z tej sesji; walidacja nie jest jeszcze potwierdzona wykonaniem. Testy Flutter i budowanie APK również nie zostały uruchomione.

### Testy danych — kompletność indeksu katalogu ruchów (2026-10-27)
- Rozszerzono `test/data_integrity_test.dart`: test sprawdza teraz, że każdy ruch z katalogu jest dostępny przez `moveById` i zwraca dokładnie ten sam obiekt, w tym specjalne ruchy Cienia o ID spoza zwykłego zakresu.
- Dodano sprawdzenie, że wyniki wyszukiwania są niemodyfikowalne, zgodnie z kontraktem usługi offline.
- Commit testu: `eebcd21fa0d646303c1cb839e57e888796c0c78a`.
- Status: test zapisany w GitHubie; nie został uruchomiony lokalnie, więc wynik pozostaje niepotwierdzony.

### Dane offline — poprawny placeholder dla learnsetu (2026-10-27)
- Pusty plik `assets/data/pokemon_learnsets.json` zastąpiono poprawnym JSON-em `[]`. Dzięki temu zasób jest składniowo poprawny i jasno oznacza brak zaimportowanych rekordów, zamiast zawierać pusty plik.
- To **nie** jest pełny zbiór ruchów: sekcja learnsetu nadal będzie informować, że dane nie zostały zaimportowane, dopóki workflow nie wygeneruje właściwej zawartości.
- Commit zasobu: `4cd8c5ba169cc790b8218c1d8591aede827a973a`.
- Testy i kompilacja Flutter nie zostały uruchomione.

### Importer learnsetów — bezpieczniejszy zapis i testy regresyjne (2026-10-27)
- `tools/import_pokemon_moves.py`: dodano walidację `--max-dex` (wartość musi być co najmniej 1). Wynik JSON jest zapisywany do pliku tymczasowego i podmieniany dopiero po poprawnym zakończeniu serializacji, aby błąd zapisu nie pozostawił uciętego pliku docelowego.
- Dodano `tools/test_import_pokemon_moves.py` z testami na syntetycznych CSV: mapowanie domyślnych form na National Dex i sortowanie, odrzucenie nieprawidłowego limitu oraz zatrzymanie importu przy pustym źródle.
- Workflow `.github/workflows/generate-pokemon-learnsets.yml` uruchamia teraz testy importera przed pobieraniem danych i generowaniem assetu.
- Commity: importer `b2411c517701bb972de8d1c8bc94dce989691154`, testy `60d33a68c69460a8ce87e7bfc6dc954a55544259`, workflow `ad50c0cefbd7cfe1c7cc8354dc5b6a92b77ad97b`.
- Status: zmiany zapisane w GitHubie. Testy nie zostały uruchomione w tej sesji; nadal wymagane jest wykonanie workflow i sprawdzenie, czy wygenerowany learnset przechodzi walidację.

### Importer learnsetów — instrukcja uruchamiania testów (2026-10-27)
- Do `tools/README_pokemon_moves.md` dodano komendę uruchamiania testów regresyjnych w PowerShell oraz wyjaśnienie, że testy korzystają z syntetycznych CSV i nie wymagają internetu.
- Commit dokumentacji: `cc5207e605c9b473872a097a4dc933124c3d7948`.
- Status: dokumentacja zapisana; testów nadal nie uruchomiono w tej sesji.

### Karta Pokémona — dopasowanie learnsetu do wybranej gry (2026-10-27)
- Dodano mapowanie ID gier aplikacji na identyfikatory grup wersji PokéAPI w `PokemonLearnsetData.preferredVersionGroupForGame`.
- Sekcja „Ruchy i ataki” próbuje teraz domyślnie wybrać grupę odpowiadającą aktywnej grze (np. Emerald → `emerald`, Sword → `sword-shield`, X/Y → `x-y`). Jeśli w danych Pokémona nie ma tej grupy, zachowany jest bezpieczny fallback do pierwszej dostępnej grupy. Użytkownik nadal może ręcznie zmienić wybór.
- Dodano testy mapowania znanych gier oraz nieznanego/null ID.
- Commity: mapowanie `3fb21772110f870e48a8b23883ae49e05efac3ca`, UI `4b0ccc9c6044b8990af089ca75d6da8d926700d8`, test `f90ebfa678f17f274cb904b5cf14c1a5e6dc4e74`.
- Status: zapisane w GitHubie; testy i analiza Flutter nie zostały uruchomione. Rzeczywisty dobór grup wymaga potwierdzenia po wygenerowaniu pełnego pliku learnsetów.

### Korekta identyfikatora grupy Let's Go (2026-10-27)
- Podczas ponownego przeglądu mapowania wykryto niepoprawny identyfikator grupy PokéAPI dla Let's Go. Zmieniono go na `lets-go-pikachu-lets-go-eevee` dla obu wersji gry.
- Rozszerzono test, aby sprawdzał zarówno Let's Go, Pikachu!, jak i Let's Go, Eevee!.
- Commity: poprawka mapowania `a7540aeb5e8a27566bd6646751afb0c8b7610686`; test `b298987ccec5d83dd09263973b7b7c358121a34c`.
- Status: zapisane w GitHubie. Testy Flutter nadal nie zostały uruchomione; poprawność należy potwierdzić po uruchomieniu testów i workflow generowania danych.

### Test pokrycia mapowania wszystkich gier (2026-10-27)
- Dodano test integracyjny łączący `gamesList` z `PokemonLearnsetData.preferredVersionGroupForGame`: każda gra oferowana w selektorze musi mieć mapowanie grupy learnsetów.
- Dzięki temu dodanie kolejnej gry bez mapowania zostanie wykryte przez test zamiast cicho wybierać niepasującą grupę.
- Commit: `975633b07dc0bc62b51410e14de4a864003c9efb`.
- Status: zapisane w GitHubie; testów nie uruchomiono w tej sesji. Asset `pokemon_learnsets.json` nadal jest pustą listą i wymaga wygenerowania przez GitHub Actions.

### Mapy — indeks lokacji offline powiązany z poradnikami (2026-10-27)
- Przebudowano `lib/screens/maps_screen.dart`: ekran pozwala wybrać generację/region oraz konkretną grę z istniejącego katalogu.
- Ekran odczytuje zapisaną grę (`selected_pokemon_game_id`) i zapisuje wybór gry; lokacje są agregowane wyłącznie z rzeczywistych pól `location` kroków `guidesList`, bez wymyślania tras, przedmiotów ani spotkań.
- Rozwijane lokacje pokazują kroki poradnika oraz Pokémony i przedmioty wymienione w tych krokach; kliknięcie kroku otwiera odpowiedni poradnik.
- Poprawiono obsługę gry Legends: Arceus, aby region wyświetlał się jako Hisui, oraz parsowanie numeru generacji.
- Commity: `cca85265626b84fee2c903985b0cf08ad9f119e7` (ekran), `ccd73549c75bfeea880dfe8831a12c10507e0662` (poprawki wyboru gry i generacji).
- Ograniczenie: w repozytorium nie ma jeszcze rzeczywistych map regionów — obecne pliki w `assets/maps` to jedynie katalogi i plik `charmander.png`, a nie mapy. Ten etap dostarcza działający indeks lokacji z poradników, nie pełną mapę graficzną.
- Status: kod zapisany i ponownie odczytany z GitHuba; Flutter analyze/test/build nie zostały uruchomione w tej sesji.

- Dodatkowa poprawka: jeśli użytkownik nie ma jeszcze zapisanej gry, indeks map wybiera pierwszą grę z katalogu zamiast pokazywać pusty ekran (`e666101ff122842d3a0c0adbf2ecd30471cfff09`).

