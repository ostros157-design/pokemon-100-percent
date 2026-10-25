# Pokémon 100% — postęp projektu

Ostatnia aktualizacja: 2026-10-25

Ten plik jest dziennikiem postępu projektu. Po kolejnych zmianach należy dopisywać datę, zakres prac, pliki/obszary oraz status testów.

## Ostatnie prace

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
