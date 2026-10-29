### Mapy — kolejny audyt spójności mapy Kanto (2026-10-29)

- Po dodaniu 9 lokacji i danych spotkań jaskiń ponownie sprawdzono JSON oraz powiązania mapy.
- Wynik statyczny: 74 lokacje w indeksie i 74 węzły rysunku; 83/83 połączenia zgodne; brak nieistniejących celów połączeń, brak brakujących nazw lokacji i brak źródeł użytych przez lokacje bez wpisu w katalogu.
- Sprawdzono 1050 wystąpień nazw Pokémonów w danych spotkań; wszystkie dopasowują się do nazw w danych Pokédexu.
- Panel lokacji pokazuje teraz tekstowe listy przedmiotów i liczniki trenerów/ukrytych przedmiotów tam, gdzie są zapisane. Dodano opis zakresu mapy i legendę lokacji/jaskiń.
- Commity panelu/mapy: `051a86f3`, `b363a05c`; dziennik nie zastępuje testu uruchomionej aplikacji.
- Nadal nie jest to pełna mapa pikselowa z gry. Węzły są poglądowe, wnętrza nie mają jeszcze szczegółowych planów, a przedmioty/trenerzy nie mają zweryfikowanych pinezek. Nie uruchomiono `flutter analyze`, testów ani APK.

### Mapy — uzupełnienie danych spotkań w pozostałych głównych jaskiniach (2026-10-29)

- Dodano / zweryfikowano spotkania dla obu wersji Let’s Go w Diglett's Cave, Mt. Moon i Rock Tunnel.
- Dane obejmują poziomy, procenty ze źródła oraz opisy odcinków/pieter, a rzadkie spotkania bez opublikowanej szansy pozostają bez wymyślonego procentu.
- Dodano źródła RotomLabs dla tych trzech lokacji. Łącznie dane spotkań obejmują teraz trasy oraz sześć głównych jaskiń/obszarów specjalnych, w tym Cerulean Cave, Seafoam Islands i Victory Road.
- Commit: `1a17464c`. Nie uruchomiono `flutter analyze`, testów ani APK. Plany pięter i pinezki nadal nie są dokładnym odwzorowaniem gry.

### Mapy — rozszerzenie Kanto o wnętrza i punkty specjalne (2026-10-29)

- Rozszerzono indeks oraz rysowaną mapę z 65 do 74 lokacji. Dodano Player's House, Professor Oak's Laboratory, Celadon Department Store, Celadon Game Corner, Celadon Condominiums, Cinnabar Lab, Fighting Dojo, GO Park i Sea Cottage.
- Dodano ich połączenia do właściwych lokacji nadrzędnych; Sea Cottage jest powiązany z Route 25, a nie bezpośrednio z Cerulean City.
- Weryfikacja statyczna: 74/74 lokacje mają węzeł mapy; 83/83 połączenia zgadzają się między indeksem a rysunkiem; brak nieistniejących celów połączeń i brakujące identyfikatory źródeł zostały wyczyszczone.
- Pliki: `lets_go_kanto_audit.json`, `maps_screen.dart`. Commity: `340e75c4`, `4a69fe86`, `ad747e84`.
- To nadal mapa schematyczna. Dodane budynki są osobnymi wybieralnymi punktami, ale ich wnętrza, piętra, trenerzy i przedmioty nie zostały jeszcze odtworzone na dokładnych planach. Nie uruchomiono kompilacji APK, testów ani `flutter analyze`.

### Mapy — spotkania w jaskiniach i ważnych lokacjach Kanto (2026-10-29)

- Rozszerzono dane offline Let’s Go Pikachu/Eevee dla Cerulean Cave, Power Plant, Pokémon Tower, Pokémon Mansion, Seafoam Islands i Victory Road.
- Dodano poziomy, procenty tam, gdzie źródło je podaje, rozróżnienie spotkań lądowych/wodnych i wersji gry oraz statyczne spotkania Mewtwo Lv. 70, Zapdos Lv. 50, Articuno Lv. 50 i Moltres Lv. 50.
- Panel szczegółów lokacji pokazuje teraz również opis lokacji, tekstową listę przedmiotów, liczbę trenerów i liczbę ukrytych przedmiotów, jeśli te informacje są obecne w indeksie. Nie rysuje pinezek dla pozycji, których współrzędne nie zostały potwierdzone.
- Źródło danych o spotkaniach: RotomLabs — strony Cerulean Cave, Power Plant, Pokémon Tower, Pokémon Mansion, Seafoam Islands i Victory Road. Źródła zapisano w indeksie JSON.
- Statyczna kontrola po dodaniu danych: JSON poprawny; 65 lokacji; 980 wystąpień wpisów spotkań; wszystkie nazwy spotkań dopasowane do Pokédexu. Wykryte stare, błędne identyfikatory źródeł Route 7/8 usunięto.
- Commit danych spotkań: `0ab1ed16`; poprawka źródeł: `6a907d7c`; commit panelu lokacji: `7aa46dc6`.
- Nie uruchomiono `flutter analyze`, testów ani kompilacji APK. Nie jest to jeszcze dokładna mapa graficzna wnętrz i nie zawiera zweryfikowanych współrzędnych pinezek.

### Mapy — kontrola spójności kompletnej mapy Kanto (2026-10-29)

- Dodatkowy audyt porównał graf rysowany przez `_KantoMapPainter` z połączeniami `connectsTo` w JSON: 65/65 lokacji ma węzeł na mapie, 74/74 połączenia zgadzają się, brak dodatkowych lub pominiętych krawędzi.
- Sprawdzono 78 unikalnych nazw Pokémonów występujących w obecnych danych spotkań, prezentach i rzadkich spotkaniach; wszystkie dopasowują się do danych Pokédexu.
- Jest to kontrola statyczna kodu i danych, a nie test uruchomionej aplikacji. Nadal trzeba zbudować APK i sprawdzić dotyk, przewijanie, czytelność po przybliżeniu oraz otwieranie szczegółów Pokédexu na urządzeniu.

### Mapy — pełna interaktywność 65 lokacji Kanto i panel spotkań (2026-10-29)

- Umożliwiono wybieranie wszystkich 65 węzłów widocznych na schematycznej mapie Kanto; wcześniej panel szczegółów był powiązany tylko z pierwszymi lokacjami tutorialowymi.
- Panel Pokémonów obsługuje dane tras obu wersji Let’s Go, spotkania pogrupowane według pięter jaskiń, prezenty/specjalne spotkania oraz zweryfikowane ważne Pokémony. Nazwy rozpoznane w Pokédexie są klikalne i prowadzą do szczegółów Pokémona.
- Dane wariantów nie są zastępowane listą z drugiej gry, gdy brakuje wpisów dla wybranej wersji. Notatki opisowe nie są błędnie prezentowane jako Pokémony do kliknięcia.
- Statyczny audyt: 65 lokacji w indeksie i 65 węzłów mapy; brak brakujących/dodatkowych nazw; wszystkie trasy 1–25 (w tym wodne 20–21) mają wpisy spotkań dla Let’s Go Pikachu i Let’s Go Eevee; połączenia w indeksie nie odwołują się do brakujących lokacji.
- Zmiany kodu zapisane w commitach: `29de3f8c`, `895f9701`, `03fe3949`, `9251263d`.
- Ograniczenia: układ graficzny pozostaje mapą poglądową, a nie odwzorowaniem piksel po pikselu map z gry. Nie dodano niezweryfikowanych współrzędnych przedmiotów, trenerów ani dzikich Pokémonów. Nie uruchomiono `flutter analyze`, testów ani kompilacji APK — potrzebny jest test po stronie użytkownika.

### Mapy — rozszerzenie schematu Kanto do pełnego indeksu lokacji (2026-10-29)

- Rozszerzono rysowaną offline mapę regionu Kanto z 15 punktów do wszystkich 65 lokacji znajdujących się w istniejącym indeksie `kanto_audit.json`, w tym tras, miast, jaskiń, Gymów, budynków i obiektów pobocznych.
- Dodano 74 połączenia oparte na polach `connectsTo` w indeksie audytowym. Klikalne punkty korzystają z istniejącego mechanizmu wyboru lokacji; mapa nadal obsługuje przesuwanie i przybliżanie.
- Współrzędne w schemacie są układem poglądowym do rozmieszczenia węzłów, a nie zweryfikowanymi współrzędnymi z gry. To znaczące rozszerzenie mapy regionu, ale nie oznacza jeszcze ukończonej mapy HD ani dokładnych pinezek Pokémonów, przedmiotów i trenerów.
- Commit: `08030de0ba73e0a8d280ca5e59f515f54b387ed1`.
- Weryfikacja: nie uruchomiono `flutter analyze`, testów ani kompilacji APK. Po zmianie należy sprawdzić kompilację i czytelność etykiet po przybliżeniu.

### Mapy — powiększanie schematu lokacji (2026-10-29)

- Dodano możliwość dotknięcia lokalnego schematu, aby otworzyć jego większy widok w oknie dialogowym.
- Powiększenie zachowuje nazwę lokacji i etykiety schematu; użytkownik może wrócić do szczegółów mapy przyciskiem „Zamknij”.
- To powiększenie własnego schematu offline, nie wierna grafika terenu z gry. Dokładne podkłady nadal wymagają weryfikacji i osobnych zasobów.
- Commit kodu: `cb2574d`. Kompilacja i test ręczny nie zostały wykonane.

### Mapy — usunięcie niepotwierdzonego skrótu na mapie Kanto (2026-10-29)

- Usunięto bezpośrednią linię Pewter City–Indigo Plateau, która mogła sugerować trasę bez pokazania lokacji pośrednich.
- Nie dodano zastępczej trasy, ponieważ brakowało w tym module zweryfikowanych danych o jej przebiegu.
- Commit kodu: `00a0c3b`. Kompilacja i test ręczny nadal nie zostały wykonane.

### Mapy — nowe punkty z poradnika na mapie Kanto (2026-10-29)

- Dodano do przeglądu regionu klikalne punkty Route 2, Viridian Forest i Pewter Gym, których wcześniej brakowało na mapie mimo obecności tych lokacji w poradniku.
- Uzupełniono schematyczne połączenia podróży: Viridian City → Route 2 → Viridian Forest → Pewter City → Pewter Gym. Usunięto bezpośredni skrót Viridian City–Pewter City, aby nie pomijać lokacji z poradnika.
- Punkty są orientacyjne, nie stanowią dokładnych współrzędnych gry. Kliknięcie punktu wybiera lokację i pozwala przejść do powiązanych danych poradnika.
- Commit kodu: `c598fe6`.
- Weryfikacja kompilacji i działania dotyku nadal nie została wykonana.

### Audyt zakresu aplikacji i dalszy rozwój map (2026-10-29)

- Przejrzano bieżące pliki repozytorium, w tym ekran główny, poradniki, Pokédex, szczegóły Pokémonów, profil, osiągnięcia, Team, ustawienia, usługi zapisu i ekran map. To audyt kodu w repozytorium, a nie potwierdzenie poprawnego działania na urządzeniu.
- Potwierdzone w kodzie: katalog Pokédexu zawiera dane National Dex #001–#1025; adresy sprite'ów korzystają z numeru Pokédexu; karty Pokémonów w poradniku otwierają szczegóły Pokémonów; postęp poradników i złapane Pokémony są zapisywane w SharedPreferences; osiągnięcia Pokédexu 1/25/50/100 liczą globalnie unikalne gatunki.
- Potwierdzone ograniczenia: w `guides_data.dart` znajduje się obecnie jeden poradnik — Let’s Go, Pikachu! (początek przygody do pierwszego Gymu). Sam katalog 28 gier nie oznacza, że istnieją poradniki dla pozostałych gier.
- Osiągnięcia: aktualny plik zawiera 28 wpisów, z czego 5 jest ukrytych. Działają progi związane z liczbą złapanych Pokémonów i ukończeniem dostępnego Pokédexu; osiągnięcia zależne od odznak, walk, ewolucji, drużyny i ukończenia gier nie są jeszcze odblokowywane na podstawie śledzonych zdarzeń.
- Team: istnieje zapis drużyny i rekomendacje, ale dane dostępności oraz rekomendacje są obsługiwane tylko dla części gier. Preferencja pozostawienia Hauntera zamiast proponowania Gengara ma testy. Nie znaleziono dedykowanej reguły ograniczającej skład do maksymalnie trzech starterów.
- Ustawienia: są opcje ciemnego tła, koloru tekstu i znaczków, spoilerów oraz animacji. Nie znaleziono osobnego trybu dla daltonistów.
- AYN Thor: w bieżącym kodzie nie znaleziono implementacji Game Assist, wyboru ekranu startowego ani zapamiętywania preferencji dwóch ekranów per gra.
- Aktualizacje i powiadomienia: są szkielety integracji Google Play In-App Updates i Firebase Messaging, ale ich działanie zależy od konfiguracji dystrybucji/ Firebase; nie należy traktować ich jako zweryfikowanych.
- Mapy: ekran i schemat regionu Kanto istnieją i działają koncepcyjnie offline. Pozostałe regiony nie mają jeszcze przygotowanych map. Dokładne współrzędne przedmiotów i spotkań nie są potwierdzone.
- Zmiana map z tego audytu: dodano lokalne schematy poglądowe dla wszystkich siedmiu lokacji zapisanych w poradniku Let’s Go, Pikachu!: Pallet Town, Route 1, Viridian City, Route 2, Viridian Forest, Pewter City i Pewter Gym. Każdy schemat ma osobne etykiety i opisy; dane Pokémonów/przedmiotów pochodzą z kroków poradnika, a nie z domyślonych współrzędnych. Zmiany zapisane w commitach `7e36319` i `5d66b1a`.
- Weryfikacja: nie uruchomiono w tym audycie `flutter analyze`, testów ani budowy APK. Nowe schematy są zapisane w GitHubie, ale nadal wymagają sprawdzenia kompilacji i działania na urządzeniu.

### Mapy — informacje lokacji oparte na poradniku (2026-10-28)
- Rozszerzono panel lokalnej mapy o sekcję „Dane z poradnika”: Pokémony i przedmioty są zbierane z rzeczywistych pól kroków poradnika dla wybranej lokacji, a kroki opcjonalne są liczone na podstawie oznaczeń w danych.
- Dodano informację wyjaśniającą, że lista jest oparta na poradniku i nie gwarantuje występowania każdego wpisu w każdym miejscu lokacji.
- Usunięto z Route 1 niepotwierdzone etykiety „Youngster Ronny” i „Razz Berry”, a ikony na mapie opisują teraz ogólne informacje/obszar poglądowy zamiast sugerować zweryfikowane położenie nagrody lub przedmiotu.
- Commit mapy: `081ac671417ce35a62454dd763df9c003b83c035`. Dodatkowa poprawka ikony: ef89df27d54d8545def709616792175037a3ccce.
- Nie uruchomiono `flutter analyze`, testów ani kompilacji. Zmiana wymaga weryfikacji lokalnej. Schematyczne rozmieszczenie elementów nadal nie jest dokładną mapą gry.

### Mapy — postęp ukończenia kroków przy lokacjach (2026-10-28)
- Ekran map odczytuje teraz zapisane kroki poradnika z `SharedPreferences` i pokazuje dla każdej lokacji licznik ukończenia (np. `2/4 kroki ukończone`).
- Lokacja, której wszystkie powiązane kroki są ukończone, otrzymuje znacznik ukończenia. Dane są odczytywane osobno dla wybranej gry, zgodnie z istniejącym kluczem `guide_progress_<gameId>_<guideId>`; nie dodano nowego, konkurencyjnego zapisu postępu.
- Po powrocie z poradnika ekran map ponownie odczytuje zapis, więc licznik powinien odświeżyć się po zaznaczeniu kroków.
- Commit kodu: `2650f33eb73e7ef0327327a043e32e939d85ee76`.
- Status: zmiana zapisana w GitHubie. Nie uruchomiono `flutter analyze`, testów ani kompilacji APK; trzeba potwierdzić zachowanie po kompilacji. Dokładność mapy i współrzędne nadal pozostają osobnym zadaniem — ta zmiana dotyczy wyłącznie postępu poradnika przypisanego do lokacji.

### Aktualizacje Google Play i przygotowanie powiadomień push (2026-10-28)
- Dodano zależności in_app_update oraz firebase_messaging, a także usługę sprawdzania aktualizacji Google Play.
- Aplikacja wykonuje kontrolę po uruchomieniu i ponawia ją co 24 godziny, gdy proces pozostaje aktywny. Jeśli Google Play zgłasza nową wersję, pokazuje okno „Dostępna aktualizacja” z przyciskiem uruchomienia oficjalnego przepływu aktualizacji.
- Ustawienia zawierają ręczne sprawdzanie aktualizacji oraz informację, czy FCM jest skonfigurowane. Dodano obsługę wiadomości FCM na pierwszym planie i uprawnienie Android 13+ do powiadomień.
- Push jest przygotowany w kodzie, ale NIE jest jeszcze aktywny: brakuje konfiguracji Firebase/Google Services w Androidzie. Nie dodano pliku google-services.json ani sekretów. Instrukcja: docs/PRIVATE_UPDATES_SETUP.md.
- Zapisano też ograniczenia: in-app update wymaga instalacji z Google Play, a sprawdzanie co 24 godziny działa tylko, gdy proces aplikacji pozostaje uruchomiony; następne sprawdzenie następuje przy kolejnym starcie.
- W tej sesji nie uruchomiono flutter pub get, flutter analyze, testów ani buildu. Należy skonfigurować identyfikator pakietu, podpisywanie i kanał testowy Google Play oraz Firebase przed testem end-to-end.

### Mapy — połączenie schematów lokacji z poradnikiem (2026-10-28)
- Po wybraniu elementu na schemacie Pallet Town lub Route 1 panel pokazuje teraz kroki poradnika przypisane do tej lokacji.
- Kliknięcie kroku otwiera właściwy poradnik; dane pochodzą z istniejących `GuideStep.location` i nie dodają fikcyjnych kroków ani współrzędnych.
- Gdy dla lokacji nie ma przypisanych kroków, aplikacja wyświetla jasny komunikat zamiast udawać, że powiązanie istnieje.
- Commit kodu: `8d353f44fd4885f090e58639cbe1174c4ded5098`.
- Status: zapisano w GitHubie. Nie uruchomiono `flutter analyze`, testów ani kompilacji APK, więc poprawność kompilacji i zachowanie w aplikacji nie są jeszcze potwierdzone.

### Naprawa błędu kompilacji APK — FlutterError (2026-10-28)
- Z logu użytkownika potwierdzono błąd kompilacji w `lib/data/pokemon_learnset_data.dart:104`: typ `FlutterError` nie był widoczny w pliku.
- Dodano jawny import `package:flutter/foundation.dart` z symbolem `FlutterError`. Obsługa brakującego assetu pozostaje bez zmian.
- Commit poprawki: `a19359ad35a607768b623f4d999f0463072fa2cb`.
- Status: poprawka zapisana w repozytorium. Nie można jeszcze oznaczyć buildu jako naprawionego, dopóki użytkownik nie powtórzy `flutter build apk --release`; wynik kompilacji po zmianie nie jest dostępny.
 
### Mapy — manifest audytu Kanto bez zgadywanych współrzędnych (2026-10-28)
- Dodano plik `pokemon100_flutter_prototype/pokemon100/assets/data/maps/lets_go_kanto_audit.json` i zarejestrowano go w `pubspec.yaml`.
- Manifest porządkuje źródła i pierwsze fakty dla Pallet Town oraz Route 1: budynki, połączenia lokacji, wydarzenia fabularne, partnera startowego, przeciwnika oraz różnice spotkań między Pikachu i Eevee.
- Każda lokacja ma jawny stan `coordinateStatus: unverified`, a podkład mapy pozostaje `null`. Manifest nie może być używany do rysowania pinów, dopóki nie zostaną sprawdzone współrzędne i zgodność z konkretnym podkładem.
- Dane spotkań Route 1 są rozdzielone na wersje: Pikachu — Pidgey, Rattata, Oddish; Eevee — Pidgey, Rattata, Bellsprout. Ukryte przedmioty pozostają do sprawdzenia dla każdej lokacji, zamiast zakładać, że ich nie ma.
- Status: manifest zapisany i zarejestrowany jako asset. Nie uruchomiono Flutter analyze/test/build; nie potwierdzono jeszcze odczytu JSON przez aplikację. To przygotowanie danych, a nie ukończona mapa offline.
- Źródła: https://theroutepedia.com/pokemon-lets-go-pikachu/map/kanto ; https://theroutepedia.com/pokemon-lets-go-pikachu/pallet-town ; https://theroutepedia.com/pokemon-lets-go-pikachu/route-1 ; https://theroutepedia.com/pokemon-lets-go-eevee/map/kanto ; https://theroutepedia.com/pokemon-lets-go-eevee/pallet-town ; https://theroutepedia.com/pokemon-lets-go-eevee/route-1 ; https://altissimo1.github.io/Main-Series/LGPE/berries.html ; https://bulbapedia.bulbagarden.net/wiki/Walkthrough:Pok%C3%A9mon:Let%27s_Go,_Pikachu!_and_Let%27s_Go,_Eevee!/Part_1

### Mapy — źródła dopasowane do wersji Let’s Go (2026-10-28)
- Ulepszono kartę w ekranie Mapy bez dodawania nowej pozycji do menu: źródła Routepedia są teraz osobnymi linkami do mapy całego Kanto, Pallet Town i Route 1.
- Linki automatycznie wybierają właściwą wersję Routepedia dla Pokémon Let’s Go, Pikachu! albo Let’s Go, Eevee!, zależnie od wybranej gry w aplikacji. Dodano też ikonki ułatwiające wybór lokacji.
- To skraca ręczną weryfikację pierwszego zakresu mapy. Nie oznacza jeszcze, że podkład ani współrzędne punktów są zapisane offline w aplikacji.
- Status: zapisano w GitHubie; Flutter analyze/test/build nadal nie zostały uruchomione.
- Źródła: https://theroutepedia.com/pokemon-lets-go-pikachu/map/kanto ; https://theroutepedia.com/pokemon-lets-go-pikachu/pallet-town ; https://theroutepedia.com/pokemon-lets-go-pikachu/route-1 ; https://theroutepedia.com/pokemon-lets-go-eevee/map/kanto ; https://theroutepedia.com/pokemon-lets-go-eevee/pallet-town ; https://theroutepedia.com/pokemon-lets-go-eevee/route-1

### Mapy — źródła weryfikacji Let’s Go Kanto (2026-10-28)
- Ekran Let’s Go pokazuje teraz pierwszy zakres audytu (Pallet Town i Route 1) oraz przyciski do zewnętrznych źródeł: interaktywnej mapy Routepedia, wykazu ukrytych jagód Altissimo i poradnika startowego Bulbapedia.
- Linki są oznaczone jako źródła online do ręcznej weryfikacji, a nie jako gotowa mapa offline. Nie dodano współrzędnych przybliżonych ani niezweryfikowanych.
- Potwierdzone dane tekstowe dla zakresu startowego: Pallet Town zawiera laboratorium Oaka, dom gracza i dom rywala; po otrzymaniu partnera gracz uzyskuje Pokédex i Town Map, a po dostarczeniu paczki — Razz Berries i Sportswear. Route 1 łączy Pallet Town z Viridian City i ma trenera Youngster Ronny; lista dzikich Pokémonów różni się między Let’s Go Pikachu i Eevee.
- Źródła: https://theroutepedia.com/pokemon-lets-go-pikachu/map/kanto ; https://theroutepedia.com/pokemon-lets-go-pikachu/pallet-town ; https://theroutepedia.com/pokemon-lets-go-pikachu/route-1 ; https://altissimo1.github.io/Main-Series/LGPE/berries.html ; https://bulbapedia.bulbagarden.net/wiki/Walkthrough:Pok%C3%A9mon:_Let%27s_Go,_Pikachu!_and_Let%27s_Go,_Eevee!/Part_1
- Status: etap źródeł i zakresu startowego zapisany. Brak lokalnego podkładu mapy z zatwierdzonymi punktami; pełna mapa nie jest ukończona. Nie uruchomiono Flutter analyze/test/build.
 
### Mapy — dokładność Kanto dla Let’s Go (2026-10-28)
- Wstrzymano wyświetlanie schematycznej mapy z przybliżonymi punktami dla Pokémon Let’s Go, Pikachu! / Let’s Go, Eevee!. Użytkownik wymaga dokładnych położeń, więc przybliżone współrzędne nie mogą być przedstawiane jako właściwe.
- Ekran map informuje teraz, że punkty pojawią się dopiero po przypisaniu zweryfikowanych współrzędnych do konkretnych map lokacji i rozdzieleniu kategorii: przedmioty, ukryte przedmioty, trenerzy, Pokémony i wejścia.
- Źródła weryfikacyjne znalezione w researchu: Routepedia udostępnia interaktywne mapy Let’s Go oraz pozycje punktów na mapach poszczególnych lokacji; Altissimo publikuje wykaz ukrytych przedmiotów i ich opisane miejsca. Źródła te są punktem odniesienia do dalszego opracowania, a nie dowodem, że kompletne dane współrzędnych zostały już zaimportowane.
- Status: to zabezpieczenie przed fałszywą precyzją, nie ukończona mapa. Współrzędne dla wszystkich lokacji nie zostały jeszcze zebrane i zweryfikowane. Flutter analyze/test/build nie zostały uruchomione.
- Źródła: https://theroutepedia.com/pokemon-lets-go-pikachu/map/kanto ; https://altissimo1.github.io/Main-Series/LGPE/hidden-items.html

### Mapy — poprawka referencji punktów Kanto (2026-10-27)
- Przy kontroli kodu po dodaniu interakcji znaleziono dwie pozostałe referencje do dawnej nazwy listy punktów; poprawiono je, aby rysowanie połączeń korzystało z aktualnej listy `places`.
- Commit poprawki: `ee7be8a42cdc8119f532673ddcc418e88e7e107c`.
- Status: poprawka zapisana. Nadal nie uruchomiono Flutter analyze/test/build, więc nie traktujemy kompilacji jako potwierdzonej.

### Mapy — interaktywne punkty Kanto (2026-10-27)
- Punkty miast na schematycznej mapie Kanto można teraz naciskać; wybrany punkt zostaje podświetlony, a pole wyszukiwania i indeks lokacji filtrują się do tej lokacji.
- Jeśli wybrana lokacja nie ma jeszcze wpisu w poradniku aktualnie wybranej gry, aplikacja pokazuje komunikat zamiast sugerować, że ma dane poradnika.
- Pole wyszukiwania ma kontroler, więc kliknięcie punktu aktualizuje również widoczny tekst pola.
- Commit: `acabfb01d9bda71331b5618eac58881dbcfa5f75`.
- Status: zapisane w GitHubie. Nie uruchomiono `flutter analyze`, testów ani builda; trzeba zweryfikować działanie dotyku i układ na urządzeniu.

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



### Mapy — weryfikacja tekstowych danych Route 1 Let’s Go (2026-10-28)
- Rozszerzono manifest audytu `assets/data/maps/lets_go_kanto_audit.json` o osobne listy spotkań dla Let’s Go, Pikachu! i Let’s Go, Eevee!: Pidgey 40%, Rattata 30% oraz odpowiednio Oddish/Bellsprout 30%, wszystkie na poziomach 3–4.
- Doprecyzowano Youngstera Ronny’ego: Rattata poziom 3, ruchy Tackle/Tail Whip, nagroda 60 i 3 Poké Balle.
- Dodano opisane tekstowo przedmioty Route 1: Razz Berry z krzaka w północno-wschodniej części trasy (partner musi wskazać krzak), Potion od pracownika Poké Martu po dostarczeniu paczki oraz 3 Poké Balle za pokonanie trenera.
- Weryfikacja tekstowa opiera się na Serebii Pokéarth, Neoseeker i Routepedii. Źródła: https://www.serebii.net/pokearth/kanto/route1.shtml ; https://www.neoseeker.com/pokemon-lets-go-pikachu/Beginning_to_First_Gym/Route_1 ; https://theroutepedia.com/pokemon-lets-go-pikachu/route-1 ; https://theroutepedia.com/pokemon-lets-go-eevee/route-1
- **Ograniczenie zachowane:** nie zatwierdzono współrzędnych ani lokalnego podkładu. Manifest nadal ma status badawczy i nie wolno rysować z niego dokładnych pinów. Pozycja Razz Berry jest opisana słownie, ale nie została dopasowana do pikseli/siatki mapy.
- Status: dane zapisane w GitHubie; nie uruchomiono Flutter analyze, testów ani builda APK. Następny krok mapowy: zweryfikować podkład i układ Pallet Town oraz Route 1, zanim powstaną współrzędne.


### Dystrybucja — automatyczny instalator APK w GitHub Releases (2026-10-28)
- Dodano workflow `.github/workflows/build-android-release.yml`.
- Workflow uruchamia się po zmianach w aplikacji na gałęzi `main` (oraz po ręcznym uruchomieniu z zakładki Actions), instaluje zależności Flutter i wykonuje `flutter build apk --release` na Ubuntu z Java 17.
- Po udanej kompilacji workflow publikuje plik APK jako `pokemon-100-percent.apk` w nowym GitHub Release oznaczonym `android-build-N`; wydanie zawiera SHA commita źródłowego.
- Plik workflow zapisany w commicie `140df77f3b358531dfc3905642ba24a621a67bc8`.
- **Status:** konfiguracja zapisana, ale wynik pierwszego przebiegu GitHub Actions nie został jeszcze sprawdzony. Instalator nie jest potwierdzony jako dostępny do pobrania, dopóki workflow nie zakończy się sukcesem i nie pojawi się Release.
- Repozytorium jest prywatne, więc dostęp do wydania i pobrania APK wymaga uprawnień do tego repozytorium. APK jest instalatorem Androida, nie programem Windows.


### Poprawki po teście instalatora na urządzeniu (2026-10-28)
- Osiągnięcia: odblokowane nazwy i ikony używają teraz jawnie koloru głównego motywu; zablokowane pozostają szare. Commit: `2e017795257fd5524faad265431187d37672c497`.
- Mapy offline: ekran Let’s Go pokazuje schematyczną mapę Kanto rysowaną lokalnie w aplikacji. Jest dostępna bez internetu, ale nie przedstawia dokładnej mapy gry ani dokładnych punktów przedmiotów/trenerów/Pokémonów. Pozostałe regiony nadal wymagają przygotowania zweryfikowanych map. Commit: `c4704815813541174212108b7e295b6f4ee68995`.
- Ataki: wykryto, że `assets/data/pokemon_learnsets.json` zawierało `[]`, dlatego sekcja ruchów była pusta. Zmieniono workflow generowania learnsetów, aby uruchamiał się również po zmianach importera/workflow i domyślnie pobierał dane dla National Dex do #1025. Commity workflow: `1110b477d0fa369a9c42b12c522815e8c9400e35`, `42bad4aac7b7db27c2a1177adc76c7ad32a6b6e3`.
- Status: generowanie danych i nowe kompilacje APK są w GitHub Actions. Nie oznaczać jeszcze learnsetów ani nowego APK jako przetestowanych, dopóki oba workflow nie zakończą się sukcesem i nie zostanie pobrane wydanie.

### Automatyzacja — commit wygenerowanych learnsetów wykryty (2026-10-28)
- W historii GitHuba pojawił się commit autorstwa `github-actions[bot]` **`c66dcd5a252b49733ad9ba9d34b801ad03a39ff1`** z komunikatem `Generate Pokémon learnset data`. To potwierdza, że automatyzacja wykonała etap zapisu pliku danych.
- Connector plików nie zwraca obecnie zawartości dużego pliku `pokemon_learnsets.json` (zwraca pustą treść i dawny SHA), dlatego nie potwierdzono przez ten odczyt liczby rekordów ani ich zawartości. Nie należy na tej podstawie twierdzić, że dane są puste lub kompletne.
- W commicie `5cd1b932c9a8a40e6a446aa8643f602613cf4629` workflow generowania rozszerzono o kroki instalacji Java 17 i Flutter, kompilację APK oraz publikację wydania `android-learnsets-N`.
- **Status:** commit generujący dane istnieje; wynik kompilacji i istnienie opublikowanego Release wymagają osobnego potwierdzenia. Nie uruchomiono lokalnie Flutter analyze/test/build.



### Instalator Android — niezawodniejsze publikowanie APK (2026-10-28)
- Sprawdzono historię GitHub Actions: kompilacja APK w przebiegu `40643466684` zakończyła się sukcesem i utworzyła plik ok. 55 MB, ale publikacja GitHub Release nie powiodła się błędem HTTP 403 `Resource not accessible by integration`.
- Zaktualizowano `.github/workflows/build-android-release.yml`: jawne uprawnienie `contents: write` na poziomie zadania, jawne przekazanie `secrets.GITHUB_TOKEN` do akcji publikującej, stała nazwa pliku `pokemon-100-percent.apk` oraz dodatkowy artefakt Actions do pobrania przez 30 dni jako zabezpieczenie, gdy publikacja Release zawiedzie.
- Istniejące wydanie z APK pozostaje dostępne: https://github.com/ostros157-design/pokemon-100-percent/releases/tag/android-build-2 . Istnieje też wydanie z danymi learnsetów: https://github.com/ostros157-design/pokemon-100-percent/releases/tag/android-learnsets-4 .
- Commit zmiany workflow: `8a5076c546a43405cfbe8430b95877fa18477698`.
- Status: poprawkę zapisano w GitHubie. Nowy przebieg Actions musi jeszcze potwierdzić, że publikacja Release przechodzi bez 403; sama kompilacja APK była potwierdzona w poprzednim przebiegu, ale jego publikacja nie.


### Instalator Android — korekta składni workflow (2026-10-28)
- Po zmianie publikowania wykryto, że workflow nie uruchomił zadania: blok akcji publikującej zawierał podwójne `with:`. Usunięto duplikat i pozostawiono `token` oraz wszystkie parametry publikacji w jednym bloku.
- Commit korekty: `e0d54a228c51df3727e93cf9939b8f05ff1602f5`.
- Status: poprawka zapisana. Trzeba sprawdzić kolejny przebieg GitHub Actions; dopiero jego wynik potwierdzi poprawność składni i publikacji APK.


### Instalator Android — priorytet najnowszej kompilacji (2026-10-28)
- Zaktualizowano `.github/workflows/build-android-release.yml`: ustawiono `cancel-in-progress: true`, aby nowszy commit nie czekał za przestarzałymi buildami w tej samej grupie, oraz limit czasu zadania 45 minut.
- Zachowano automatyczne uruchamianie po pushu do `main` dla zmian aplikacji, workflow i dziennika postępu, a także ręczne `workflow_dispatch`.
- Zachowano publikację APK w GitHub Releases i artefakt Actions jako zapasową drogę pobrania.
- Commit workflow: `a432b4a5844c28a6bd564a9340fcb7d89aba713d`.
- Status: zmiana zapisana na GitHubie. Trwa sprawdzenie nowego przebiegu; automatyzację uznamy za działającą dopiero po potwierdzeniu udanego builda oraz publikacji APK.


### Instalator Android — build działa, publikacja Release ma ograniczenie uprawnień (2026-10-28)
- Odczyt logów GitHub Actions potwierdził, że `flutter build apk --release` zakończył się sukcesem i wygenerował APK o rozmiarze 57,7 MB. Artefakt `pokemon-100-percent-apk` również został poprawnie przesłany i jest dostępny przez 30 dni.
- Dokładny błąd występuje dopiero przy tworzeniu GitHub Release: HTTP 403 `Resource not accessible by integration`, mimo deklaracji `contents: write`. To ograniczenie uprawnień tokena/integracji, a nie błąd kompilacji Flutter.
- Zmieniono krok publikacji Release na opcjonalny (`continue-on-error: true`), aby problem uprawnień nie oznaczał nieudanego całego workflow i aby gotowy APK nadal był dostępny jako artefakt Actions.
- Zachowano automatyczne uruchamianie po pushu do `main`, ręczne `workflow_dispatch`, anulowanie przestarzałych buildów oraz limit 45 minut.
- Commity workflow: `a432b4a5844c28a6bd564a9340fcb7d89aba713d` (najnowsza kompilacja ma pierwszeństwo), `1238cffcdab23263dbdb7b1ab2fa2191ab5ee9b0` (nieblokowanie buildu przez błąd publikacji Release).
- Status: build i upload artefaktu potwierdzone w logach uruchomienia 9; poprawka awaryjnego sukcesu oczekuje na wynik nowego uruchomienia. Bez zmiany uprawnień GitHuba nie można obiecać, że GitHub Release zostanie utworzony; artefakt Actions pozostaje działającą drogą pobrania APK.

### Mapy — pierwsze szczegóły lokacji Let’s Go Kanto (2026-10-28)
- Rozbudowano `lib/screens/maps_screen.dart` o offline’owy panel szczegółów dla Pallet Town i Route 1, z szybkimi przyciskami wyboru lokacji.
- Pallet Town pokazuje ważne budynki, wydarzenia/podarki początku gry oraz partnera i Pokémon rywala zależnie od wersji Let’s Go Pikachu / Let’s Go Eevee.
- Route 1 pokazuje potwierdzone spotkania w trawie z poziomami i procentami, trenera Youngster Ronny’ego z drużyną i nagrodą oraz opis ukrytej Razz Berry.
- Nie dodano niezweryfikowanych pinezek ani współrzędnych. Panel jasno zaznacza, że pozycja pikselowa ukrytego przedmiotu nie została potwierdzona.
- Commit kodu: `39112efe514d8df2585c3d8191511b0b8fb41f9c`.
- Status: zmiany zapisane bezpośrednio w GitHubie; `flutter analyze`, testy i build nie zostały uruchomione w tej sesji. Wymagany test na urządzeniu oraz sprawdzenie automatycznej kompilacji APK.

## Mapy — przesuwanie, przybliżanie i chwilowa etykieta lokacji (2026-10-28)

- Mapa Kanto w `lib/screens/maps_screen.dart` ma teraz interakcje przesuwania i zoomu przez gesty, zamiast reagować wyłącznie na pojedyncze kliknięcia.
- Podczas przesuwania/zoomowania aplikacja sprawdza, czy środek widocznego obszaru znajduje się blisko oznaczonej lokacji. Jeśli tak, pokazuje u góry nazwę miejsca; etykieta znika po około 2 sekundach bez zmiany lokacji.
- Dodano Route 1 jako osobny punkt na schemacie między Pallet Town a Viridian City. Kliknięcie oznaczonego punktu nadal wybiera lokację i aktualizuje wyszukiwanie.
- Ważne ograniczenie: podkład pozostaje schematycznym rysunkiem Kanto, a nie wierną mapą z gry. Punkty mają charakter poglądowy; dokładna, duża mapa regionu i dokładne granice lokacji wymagają osobnego, zweryfikowanego podkładu/danych.
- Testy Flutter, analiza statyczna i budowa APK nie zostały uruchomione w tej zmianie. Należy sprawdzić kompilację oraz zachowanie gestów na urządzeniu.

## Mapy — czytelne ikony lokacji i przedmiotów (2026-10-28)

- Ulepszono schemat Kanto w `lib/screens/maps_screen.dart`: połączenia między głównymi punktami prowadzą teraz przez Route 1 i Viridian City zamiast części wcześniejszych, nielogicznych skrótów.
- Dodano proste graficzne znaczniki: budynek w Pallet Town oraz ikony Poké Balla i jagody przy Route 1, aby użytkownik szybciej rozpoznawał typ informacji.
- Dodano legendę opisującą znaczenie ikon. Tekst jasno zaznacza, że znaczniki Route 1 przypisują informacje do obszaru, a nie wskazują dokładnych współrzędnych przedmiotów.
- To nadal mapa poglądowa z własnoręcznie rysowanym podkładem; jej układ nie jest jeszcze wierną rekonstrukcją mapy gry.
- Nie uruchomiono `flutter analyze`, testów ani budowy APK. Ostatnie uruchomienia GitHub Actions kończą się błędem; przed uznaniem funkcji za gotową trzeba ustalić przyczynę i sprawdzić kompilację.

### Mapy — osobne kliknięcia ikon przy Route 1 (2026-10-28)
- Ikona Poké Balla na schemacie Kanto ma teraz osobny obszar kliknięcia: pokazuje etykietę „Route 1 • nagroda trenera” i wybiera Route 1 w indeksie lokacji.
- Ikona jagody ma osobny obszar kliknięcia: pokazuje „Route 1 • Razz Berry (obszar przybliżony)” i wybiera szczegóły Route 1. Etykieta nie sugeruje dokładnych współrzędnych ukrytego przedmiotu.
- Zmiana kodu: `de40ee6964300e10360a796220e36c3c1cd93433`.
- Status: zapisano w GitHubie. Nie uruchomiono `flutter analyze`, testów ani kompilacji APK; działanie gestów i trafiania w ikony wymaga sprawdzenia w aplikacji.

### Mapy — lokalne schematy Pallet Town i Route 1 (2026-10-28)
- Po wpisaniu lub wybraniu dokładnie „Pallet Town” albo „Route 1” pod panelem danych pojawia się osobny, większy schemat lokalny działający offline.
- Pallet Town pokazuje symbole domu gracza, domu rywala i laboratorium Oaka; Route 1 pokazuje wejście od strony Pallet Town, obszar trawy, punkt informacyjny trenera Youngster Ronny’ego oraz obszar informacji o Razz Berry.
- Pod schematem są wybieralne etykiety. Po wybraniu etykiety pojawia się krótki opis danego punktu; przełączenie lokacji czyści poprzedni wybór.
- Schematy są wyraźnie oznaczone jako poglądowe. Nie są deklarowane jako dokładne współrzędne ani rekonstrukcja pikselowa map z gry.
- Commity kodu: `4cd99d0e67782ea1e72aaeeb22f26a9c65f1bf85` (lokalne schematy) oraz `f16a8c2233a9b3cc1d05d0cb1a86f4e13c174cc1` (jawna konwersja pozycji etykiety na `double`).
- Status: zapisano w GitHubie. Nie uruchomiono `flutter analyze`, testów ani builda APK; wygląd i kompilacja wymagają weryfikacji w CI lub na urządzeniu.



### Mapy i poradniki — otwieranie wybranego kroku (2026-10-28)
- Rozszerzono `GuideScreen` o opcjonalny parametr `initialStepNumber`. Gdy poradnik jest otwierany z mapy, po odtworzeniu zapisanego postępu ekran przewija się do wskazanego kroku; zwykłe otwieranie poradnika nadal zaczyna się od początku.
- Oba miejsca na ekranie map, które otwierają krok poradnika, przekazują teraz numer kroku. Dzięki temu kliknięcie lokacji/kroku nie tylko otwiera poradnik, ale od razu pokazuje właściwy fragment.
- Zachowano dotychczasowy zapis postępu kroków w SharedPreferences. Widok listy kroków jest budowany z kluczami, aby przewinięcie mogło znaleźć konkretną kartę.
- Commity kodu: `05acb2625730c3ae8609792ff9d0154cf78fdcc5` (GuideScreen), `bebdfd199d2e746427ec91e841c251e4e11afa7a` (mapy).
- Status: zapisano bezpośrednio w GitHubie. Nie uruchomiono `flutter analyze`, testów ani builda APK w tej sesji; przewijanie należy potwierdzić po kompilacji i na urządzeniu.

- Drobna korekta typowania po przeglądzie kodu: indeks kroku po ograniczeniu do zakresu jest jawnie konwertowany na `int`. Commit: `284314e0a893628a554f8dfc96b50106615d6da6`. Nadal nie uruchomiono analizy ani kompilacji.


### Mapy — nowy kierunek graficzny: miękka ilustracja HD (2026-10-29)
- Ustalono docelowy styl map: nowoczesna, ręcznie malowana ilustracja z płynnymi krawędziami, miękkim cieniowaniem i detalami o wysokiej czytelności; inspiracją są gładkie tekstury HD, a nie widoczne piksele.
- Styl ma zachowywać tożsamość konkretnej gry i regionu (np. Hoenn z Emerald), zamiast nakładać jeden identyczny wygląd na wszystkie regiony.
- Wymagane warstwy informacyjne: Pokémony, przedmioty, miasta, trasy, trenerzy i znajdźki 100%; mapa ma być dostępna offline.
- Zasada danych: nie dodawać fikcyjnych współrzędnych ani niezweryfikowanych pinów. Dekoracyjne tekstury terenu muszą być odróżnialne od potwierdzonych danych geograficznych.
- Status: zapis kierunku wizualnego; implementacja graficzna wymaga osobnego commita. Nie uruchomiono Flutter analyze, testów ani builda APK.


### Mapy — pierwsze wygładzenie ilustracji Kanto (2026-10-29)
- W `lib/screens/maps_screen.dart` zmieniono paletę tła mapy Kanto: woda i ląd używają teraz łagodnych gradientów, brzeg ma subtelny cień i jasny kontur, a na lądzie dodano miękkie plamy kolorystyczne.
- To pierwsza warstwa nowego stylu „miękka ilustracja HD”; nie dodano nowych miast, dróg ani pinezek. Dekoracyjne plamy nie są oznaczeniami biomów ani potwierdzonymi danymi geograficznymi.
- Commit kodu: `ffda5919b5761146ed9a9379177aaf87fb383941`.
- Status: zapisano w GitHubie. Nie uruchomiono Flutter analyze, testów ani builda APK; wygląd na urządzeniu i kompilacja pozostają niezweryfikowane.


### Mapy — płynniejsze drogi na ilustracji Kanto (2026-10-29)
- Połączono punkty istniejącej mapy miękkimi, zakrzywionymi ścieżkami z cieniem, jasnym obrzeżem i ciepłym środkiem zamiast pojedynczych prostych kresek.
- Zmieniono wyłącznie sposób rysowania istniejących połączeń; nie dodano nowych relacji między lokacjami ani nowych współrzędnych. Przebieg nadal jest schematyczny, nie w skali.
- Commit kodu: `1b462a301f717e1777f31304e68559ffb5ccb0e5`.
- Status: zapisano w GitHubie. Nie uruchomiono Flutter analyze, testów ani builda APK.


### Mapy — dekoracyjne drzewa i wzgórza na ilustracji Kanto (2026-10-29)
- Dodano miękkie, półprzezroczyste grupy drzew oraz delikatne linie wzgórz, aby mapa wyglądała bardziej jak ilustracja malowana, a mniej jak płaski diagram.
- Elementy te są wyłącznie teksturą dekoracyjną: nie oznaczają zweryfikowanego lasu, gór ani konkretnej lokacji w grze. Nie dodano nowych pinezek, przedmiotów ani współrzędnych.
- Commit kodu: `388877c7d670048f4f36fedb2edc03bd3f0dd553`.
- Status: zapisano w GitHubie. Flutter analyze, testy i build APK nie zostały uruchomione; kompilacja i wygląd na urządzeniu nie są jeszcze zweryfikowane.


### Mapy — pełna legenda wymaganych warstw Kanto (2026-10-29)
- Rozszerzono legendę mapy o wszystkie wymagane kategorie: miasta, trasy, Pokémony, przedmioty, trenerzy/walki i znajdźki do 100%.
- Dodano jawne wyjaśnienie, że obecne miasta/trasy są schematyczne, a kategorie Pokémonów, przedmiotów, trenerów i znajdziek nie mają jeszcze zweryfikowanych pinezek. To legenda planowanych warstw danych, nie deklaracja, że wszystkie znaczniki już działają.
- Commit kodu: `e83ca503b649ec2eda793cab421ed47fba608154`.
- Status: zapisano w GitHubie. Nie uruchomiono Flutter analyze, testów ani builda APK; poprawność kompilacji i wygląd na urządzeniu pozostają niezweryfikowane.


### Mapy — zweryfikowane dane Viridian City (2026-10-29)
- Dodano do manifestu badawczego `assets/data/maps/lets_go_kanto_audit.json` wpis Viridian City: Pokémon Center, Poké Mart, przekazanie Oak’s Parcel, zablokowane północne wyjście podczas pierwszej wizyty oraz tekstowy opis ukrytej Potion.
- Połączenia Route 1 (południe), Route 2 (północ) i Route 22 (zachód) opisano na podstawie źródła poradnikowego. Wszystkie współrzędne pozostają niezweryfikowane; ukryta Potion nie jest rysowana jako pinezka.
- Ekran map otrzymał przycisk szybkiego wyboru Viridian City i offlineowy panel tych informacji. Panel wyraźnie odróżnia opis tekstowy od dokładnej pozycji na mapie.
- Źródło: https://bulbapedia.bulbagarden.net/wiki/Walkthrough:Pok%C3%A9mon:Let%27s_Go,_Pikachu!_and_Let%27s_Go,_Eevee!/Part_2
- Commity: dane `5c735e4204f631b25ed8ccfd160ac459f6eea0e4`; ekran `e204da2c24009463b0aa2b7bdae5665fb273d4f1`.
- Status: zapisano w GitHubie. Nie uruchomiono `flutter analyze`, testów ani builda APK; kompilacja i zachowanie interfejsu nie są jeszcze zweryfikowane.


### Mapy — spotkania i układ Route 2 (2026-10-29)
- Rozszerzono manifest `lets_go_kanto_audit.json` o Route 2: połączenia z Viridian City, Viridian Forest i Pewter City, rozdzielenie trasy przez las oraz opis wschodniej ścieżki w stronę Diglett’s Cave.
- Dodano tekstowe spotkania w trawie dla obu wersji Let’s Go. Pikachu: Pidgey 30%, Rattata 20%, Oddish 20%, Caterpie 15%, Weedle 15%; Eevee zamiast Oddish ma Bellsprout 20%. Wszystkie wymienione spotkania mają poziomy 3–4 według Pokéarth/Serebii.
- Ekran map pokazuje te spotkania offline po wybraniu Route 2. Nie dodano współrzędnych ani pinezek dla trawy, trenerów czy przedmiotów; szczegóły mapy pozostają tekstowe.
- Źródła: https://www.serebii.net/pokearth/kanto/route2.shtml ; https://theroutepedia.com/pokemon-lets-go-pikachu/route-2 ; https://theroutepedia.com/pokemon-lets-go-eevee/route-2
- Commity: manifest `e8f908bcb107ecfae4406baaecda4fc4021b4e23`; ekran `7c35bfafa3aae8e2466906653e3f82333c035ee0`.
- Status: zapisano w GitHubie. `flutter analyze`, testy i build APK nie zostały uruchomione; kompilacja i zachowanie UI pozostają niezweryfikowane.


### Mapy — Viridian Forest i Pewter City (2026-10-29)
- Dodano do ekranu map szybkie wybieranie Viridian Forest i Pewter City oraz offlineowe panele informacyjne.
- Viridian Forest pokazuje spotkania w trawie zależne od wersji Let’s Go Pikachu/Eevee, poziomy 3–6, rzadkie spotkanie Bulbasaur przy użyciu Lure, podstawowych trenerów i listę przedmiotów. Informacje o trainerach i itemach są tekstowe; nie umieszczono ich na mapie jako dokładnych pinezek.
- Pewter City pokazuje Pokémon Center, Poké Mart, Pewter Museum of Science, Gym Brocka, 5 Potion od Trace przy pierwszym wejściu, nagrody po walce z Brockiem oraz jego drużynę: Geodude Lv. 11 i Onix Lv. 12.
- Manifest `assets/data/maps/lets_go_kanto_audit.json` zawiera teraz rekordy Viridian Forest i Pewter City z połączeniami, danymi spotkań/wydarzeń i odnośnikami do źródeł. Współrzędne pozostają niezweryfikowane.
- Źródła: https://bulbapedia.bulbagarden.net/wiki/Walkthrough:Pok%C3%A9mon:_Let%27s_Go,_Pikachu!_and_Let%27s_Go,_Eevee!/Part_3 ; https://theroutepedia.com/pokemon-lets-go-pikachu/viridian-forest ; https://theroutepedia.com/pokemon-lets-go-eevee/viridian-forest ; https://theroutepedia.com/pokemon-lets-go-pikachu/pewter-city
- Commity: ekran `a4e778168b77cd16db1dd1607455603957f7351f`; manifest `e497f65d35c59e0a5dd7120713f3afad19bf3b13`.
- Status: zapisano w GitHubie. Nie uruchomiono `flutter analyze`, testów ani builda APK; kompilacja i zachowanie interfejsu nadal wymagają weryfikacji.


### Mapy — kontynuacja Kanto (2026-10-29)

- Rozszerzono dane offline do Route 25. Dokładne pinezki nadal nie są zweryfikowane; testów i kompilacji nie uruchamiano.


### Mapy — dalsze dane Kanto i panele offline (2026-10-29)

- Rozszerzono indeks danych mapy Let’s Go o Route 4, Cerulean City, Route 24, Route 25, Route 5, Underground Path (Routes 5–6), Route 6 i Vermilion City.
- Dodano tekstowe panele offline dla Route 4, Cerulean City, Routes 24–25, Routes 5–6, Underground Path oraz Vermilion City. Panele pokazują wersjozależne spotkania, część trenerów, przedmioty i kluczowe miejsca.
- Poprawiono spotkania Route 3 w Let's Go Eevee: Spearow 40%, Rattata 40%, Ekans 20% (różni się od Pikachu).
- Dane i źródła: `354c6f2`, `3e05e53`; panele UI: `9a18bb7`, `ae8ee57`, `1cbf6b7`, poprawka Route 3 `c3f4fcb`.
- Weryfikacja przez odczyt GitHub potwierdziła poprawny JSON, 16 rekordów lokacji i obecność paneli Route 3/Mt. Moon. Nie uruchamiano Flutter analyze, testów ani kompilacji APK.
- Mapa nie jest kompletna: brakuje wielu lokacji Kanto, dokładnego podkładu z gry i zweryfikowanych pozycji pinezek. Nie należy przedstawiać jej jako gotowej mapy całego regionu.


### Mapy — dalsze Kanto (2026-10-29)

Dodano dane lokacji Route 7–14, Rock Tunnel, Lavender Town, Underground Path 7–8 i Diglett's Cave. Pozycje pinezek nie są zweryfikowane; mapa nie jest kompletna. Testów i kompilacji nie uruchamiano.


### Mapy — rozszerzenie UI do Fuchsia City (2026-10-29)

- Dodano Route 15 i Fuchsia City do indeksu offline Kanto; liczba rekordów lokacji wzrosła do 30.
- Dodano szybkie przyciski wyboru lokacji do Route 12 i Fuchsia City oraz panele informacyjne dla Route 11, Diglett’s Cave, Route 12, Routes 13–15 i Fuchsia City.
- Commity: `8e4edc5`, `4bd5b7c`, `6fff8ab`, `b985af1`.
- To nadal mapa części Kanto, a nie ukończona mapa całego regionu. Współrzędne i pinezki szczegółowe pozostają niezweryfikowane; nie uruchamiano Flutter analyzer, testów ani APK.


### Mapy — rozszerzenie indeksu Kanto do lokacji pobocznych (2026-10-29)

- Rozszerzono `lets_go_kanto_audit.json` z 45 do 53 lokacji: dodano S.S. Anne, Power Plant, Pokémon Tower, Team Rocket Hideout, Silph Co., Pokémon Mansion, Safari Zone i Viridian Gym. Rekordy oznaczają brak zweryfikowanych pinezek i dokładnych planów wnętrz.
- Dodano dane dla Celadon City, Saffron City, Routes 16–23, Seafoam Islands, Cinnabar Island, Victory Road, Indigo Plateau i Cerulean Cave; UI ma panele informacyjne dla tych obszarów oraz lokacji pobocznych.
- Dodano szybkie selektory do dalszych lokacji Kanto. Użytkownik może nadal wpisać nazwę w wyszukiwarkę lokacji.
- Źródła bazowe: Routepedia dla Let’s Go Pikachu (mapa regionu i lokacje) oraz rozdziały walkthrough Bulbapedia dla lokacji fabularnych.
- Commity: `0ebfc74`, `55cc864`, `97e65c6`, `fbdce6a`, `5539052`, `764881b`.
- Nadal nie jest to gotowa, dokładna graficzna mapa całego Kanto: brak zweryfikowanego podkładu w skali gry i pinezek dla większości trenerów/przedmiotów; niektóre rekordy to indeksy połączeń. Flutter analyzer, testy i APK nie zostały uruchomione.


### Mapy — sale i źródła lokacji startowych (2026-10-29)

- Uzupełniono źródła dla Pallet Town, Route 1 i Viridian City.
- Dodano rekordy siedmiu sal Kanto: Pewter, Cerulean, Vermilion, Celadon, Saffron, Fuchsia i Cinnabar Gym; w `maps_screen.dart` dodano panele informacyjne z wyraźnym oznaczeniem danych, które wymagają dalszej weryfikacji.
- Commity: `35b4fee`, `24945d2`, `cab524c`.
- Mapa Kanto nadal jest indeksem i schematem, nie gotową precyzyjną mapą z pinezkami. Trzeba jeszcze uzupełnić szczegóły spotkań, przedmiotów, wnętrz i pozostałych regionów Pokémon.


### Mapy — ważne budynki i 100% lokacji Kanto (2026-10-29)

- Dodano rekordy Bill’s House, Pewter Museum of Science, Pokémon Fan Club i Pokémon Day Care oraz panele offline dla tych miejsc.
- Indeks Let’s Go Kanto ma teraz 64 rekordy lokacji, w tym wszystkie trasy Route 1–25, miasta, główne jaskinie, Ligę, sale i wybrane budynki poboczne.
- Commity: `bb55ebe`, `94ff883`.
- Liczba 64 oznacza rekordy indeksu, nie 64 ukończone dokładne mapy: większość wnętrz i pozycji pinezek nadal wymaga weryfikacji. Kolejny etap to audyt grafu połączeń, kompletność przedmiotów/trenerów oraz osobne regiony z pozostałych gier.


### Mapy — kontrola spójności indeksu Kanto (2026-10-29)

- Automatyczna kontrola JSON: poprawny format; wszystkie Route 1–25 mają rekordy; 64 lokacje, 76 źródeł; brak niedziałających odwołań `connectsTo`, brak lokacji bez drogi po grafie od Pallet Town i brak brakujących `sourceIds`.
- Naprawiono brakujące źródło dla Fuchsia Gym (`964114a`).
- To kontrola spójności indeksu, a nie walidacja w grze: dokładność każdego spotkania, przedmiotu i współrzędnej nadal wymaga weryfikacji źródłowej. Nie uruchamiano Flutter analyze, testów ani APK.


### Mapy — indeksy regionów i integracja offline (2026-10-29)

- Utworzono indeksy lokacji dla Johto (59), Hoenn (72), Sinnoh (71), Unovy (59), Kalos (55), Aloli (54), Galar (43), Hisui (25) i Paldei z DLC (49). Indeksy Kanto obejmują 64 lokacje.
- Zarejestrowano wszystkie pliki JSON w `pubspec.yaml` i dodano w `maps_screen.dart` ładowanie indeksów z assetów oraz wyszukiwalną listę lokacji dla wybranego regionu. Dla regionów bez zweryfikowanej grafiki UI wyraźnie pokazuje indeks, a nie udaje gotowej mapy.
- Poprawiono dwa problemy wykryte w audycie: połączenie S.S. Aqua do Vermilion City i duplikat Glaseado Mountain.
- Commity: `75b2545`, `6bcce3d`, `3fa56b8`, `d91fef2`, `faa9bdd`, `ac4a981`, `594388e`, `ea00e66`, `3a5dbdd`, `8c603e0`, `41b4536`, `455810b`, `e6cb928`, `ee4eb9b`, `7f59b10`, `5df190a`, `b872c57`.
- Weryfikacja JSON: wszystkie 10 indeksów parsują się; brak zduplikowanych ID, brak nieistniejących źródeł i brak błędnych połączeń `connectsTo` po poprawkach. Dla większości nowych regionów połączenia pozostają celowo nieuzupełnione do czasu sprawdzenia wariantu gry.
- Nie uruchamiano Flutter analyzer, testów ani APK. Cała mapa Pokémon nie jest jeszcze ukończona: brakuje zweryfikowanych grafów tras, dokładnych map graficznych, wnętrz, pinezek przedmiotów/trenerów/Pokémonów oraz audytu różnic między wersjami.


### Mapy — grafy tras i dobór regionu według gry (2026-10-29)

- Dodano ogólny indeks Kanto (71 lokacji) oddzielny od indeksu Let’s Go (65 lokacji). Dzięki temu Red/Blue/Yellow oraz FireRed/LeafGreen nie pokazują spotkań i przedmiotów specyficznych dla Let’s Go.
- Uzupełniono graf połączeń tras dla Kanto, Johto, Hoenn, Sinnoh, Unovy, Kalos, Aloli i Galar na podstawie tabeli końców tras Bulbapedia; dodano brakujące węzły pośrednie i znormalizowano połączenia dwukierunkowe.
- `maps_screen.dart` ładuje 11 indeksów z assetów offline, wybiera region według ID gry (ważne dla FireRed/LeafGreen, Omega Ruby/Alpha Sapphire, Sword/Shield i Legends: Arceus), umożliwia wyszukiwanie lokacji i pokazuje jej status, notatki oraz połączenia.
- Commity: `b4f7655`, `986e9c6`, `8e33827`, `60af84a`, `151f41f`, `82cb120`, `c10cb32`, `c63eb83`, `b22bf45`, `478b692`, `9532707`, `eca450a`, `bbc4d3e`, `bfe1e87`, `55f68e2`, `daa4bb1`, `4535255`, `4a367a3`, `1fb5c24`, `2d1ca15`, `93d9554`, `db3cb1a`, `f27d5c8`, `b172579`.
- Audyt danych: 11 plików JSON parsuje się; brak zduplikowanych ID, brak nieistniejących `sourceIds` i brak niedziałających `connectsTo` po poprawkach. To nie jest jeszcze walidacja kompilacji Flutter.
- Nadal nie ma dokładnych map graficznych w skali gry dla pozostałych regionów, pełnych map wnętrz ani zweryfikowanych pinezek dla wszystkich Pokémonów, trenerów i przedmiotów. Nie uruchamiano Flutter analyzer, testów ani APK.


### Mapy — Hisui i Paldea: rozwinięcie obszarów 100% (2026-10-29)

- Hisui rozszerzono do 109 rekordów: pięć głównych obszarów, obozy bazowe, osady oraz nazwane podobszary, areny, jaskinie i ruiny. Opis wyraźnie rozróżnia wybór obszaru/fast travel od fizycznych tras.
- Paldeę rozszerzono do 81 rekordów: Area Zero i obiekty wewnętrzne, cztery sanktuaria, punkty orientacyjne, bazy Team Star oraz biomy DLC; dodano metadane prowincji i źródła dla mapy otwartego świata.
- Commity: `a395662`, `9c17f9a`, `78c2dd4`, `d0db878`.
- Paldea nie ma ponumerowanych tras; nadal nie ma dokładnych pinezek Pokémonów, przedmiotów, stake’ów, Gimmighoul, raidów i trenerów. Hisui nadal wymaga dokładnych planów map obszarów i punktów znajdziek.


### Mapy — rozszerzenie DLC Paldea i grafu Hisui (2026-10-29)

- Paldea + DLC ma 100 rekordów lokacji: dodano kolejne obszary Kitakami, Timeless Woods, Infernal Pass, Crystal Pool oraz miejsca Blueberry Academy/Terarium.
- Dodano źródła PokeDB i Routepedia dla Paldei; metadane opisują prowincję i jasno zaznaczają, że Scarlet/Violet to otwarty świat bez ponumerowanych tras.
- Połączono podobszary Hisui z właściwymi regionami i obozami w indeksie; połączenia oznaczają obszarowe powiązania, nie dokładne współrzędne.
- Commity: `a31138a`, `cb4fc88`.


### Mapy — wybór Kanto/Johto w grach generacji II (2026-10-29)

- Dodano wybór regionu do wyświetlenia dla Pokémon Gold/Silver/Crystal: można przełączyć indeks Johto ↔ Kanto, co odzwierciedla możliwość odwiedzenia obu regionów po postgame.
- Wybór regionu resetuje wyszukiwanie lokacji, a zmiana gry resetuje ręczne nadpisanie regionu, aby nie pokazywać przypadkowo mapy z poprzedniej gry.
- Commit: `d2cd817`.


### Mapy — audyt indeksów i obsługa wyboru regionu (2026-10-29)

- Rozbudowano Hisui do 109 rekordów i Paldeę + DLC do 100 rekordów; dodano dostęp do obszarów Hisui przez Jubilife Village jako fast travel oraz metadane prowincji Paldei.
- Dodano przełącznik regionu Johto/Kanto dla Gold, Silver i Crystal. Wybór gry mapuje się na rzeczywisty region (np. FireRed → Kanto, Omega Ruby → Hoenn, Legends: Arceus → Hisui).
- Zaktualizowano opis map, aby nie sugerował, że wszystkie regiony mają już gotowe mapy graficzne.
- Commit UI: `1fcd9a3`; Hisui: `818c9bf`; Paldea: `a31138a`, `d0db878`.
- Ostatni audyt: wszystkie 11 indeksów parsuje się, wszystkie są w `pubspec.yaml` i są ładowane przez `MapsScreen`; brak duplikatów ID, brak niedziałających połączeń i brak odwołań do nieistniejących źródeł. Paldea jest otwartym światem, więc nie wymuszono fałszywej sieci tras.


### Mapy — połączenia pobocznych lokacji i DLC (2026-10-29)

- Rozbudowano połączenia pobocznych lokacji: Hoenn (ruiny, hideouty i Battle Frontier/Resort), Sinnoh (kopalnia, Stary Zamek, Great Marsh, Spear Pillar i Battle Zone), Unova (mosty, jaskinie, ruiny i lokacje B2W2), Kalos (Friend Safari, Battle Maison, Team Flare HQ i jaskinie), Alola (Poni, Ultra Space, Aether Paradise) oraz Galar (Wild Area, Galar Mine, Glimwood Tangle i DLC).
- Uzupełniono parent-region i powiązania dla pozostałych znanych lokacji Hisui.
- Commity: `a47b69c`, `482eae6`, `bccce66`, `66df0f2`, `57b2dfd`, `082ab96`, `5c28600`, `6386e02`.
- Część połączeń jest oznaczona jako wymagająca audytu wariantu gry/DLC. Nadal nie ma zweryfikowanych współrzędnych ani pełnych pinów dla każdego obszaru.


### Mapy — korekty po audycie grafów (2026-10-29)

- Usunięto duplikat Iki Town w indeksie Aloli i poprawiono połączenia Pokémon League w Galar; Galar nie jest sztucznie łączony z nieistniejącą w tej grze Victory Road.
- Commity: `fa624a3`, `30479f5`.


### Mapy — końcowy audyt spójności indeksów i naprawa odwołań (2026-10-29)

- Przeaudytowano wszystkie 11 indeksów offline: 816 rekordów lokacji łącznie. Każdy plik parsuje się jako JSON, jest zarejestrowany w `pubspec.yaml` i ładowany przez `MapsScreen`.
- Naprawiono duplikaty nazw `Giant's Bed` i `Arena's Approach`, zachowując powiązane dane; naprawiono też odwołania `connectsTo` do scalonych rekordów. Uzupełniono jawny status danych Route 2 w indeksie Let’s Go.
- Ponowny audyt: 0 zduplikowanych ID, 0 zduplikowanych nazw, 0 brakujących `sourceIds`, 0 niedziałających `connectsTo`, 0 lokacji bez `dataStatus`.
- Commity napraw: `9ee9216`, `2670d41`, `6c67404`, `afb57f5`, `70d4eaa`.
- To jest kontrola struktury i odwołań plików, nie test uruchomienia Flutter. Nie uruchamiano analyzer, testów ani APK. Mapa jako całość nie jest ukończona: nadal potrzebuje dokładnych ilustracji map, zweryfikowanych pinezek 100% i kontroli wariantów gry.


### Mapy — wygodniejsze przechodzenie między lokacjami (2026-10-29)

- Połączenia w szczegółach lokacji są teraz klikalnymi chipami: wybranie połączonego miejsca ustawia je w wyszukiwarce i pokazuje jego kartę.
- Wyszukiwanie indeksu offline obejmuje teraz nazwę, ID, typ, notatki, status, obszar nadrzędny, prowincję i identyfikatory połączeń, a nie tylko nazwę lokacji.
- Commity: `6a9c61e`, `5862715`, `f91bbab`.
- Po audycie danych i naprawach: 11 indeksów, 816 rekordów; brak duplikatów ID/nazw, brak brakujących źródeł, brak niedziałających połączeń i brak brakujących statusów. Nie uruchamiano Flutter analyzer/testów/APK.


### Mapy — źródła otwierane z karty lokacji (2026-10-29)

- Karty lokacji pokazują teraz powiązane źródła danych jako klikalne chipy; otwierają adres HTTP/HTTPS w zewnętrznej przeglądarce. Dzięki temu łatwiej sprawdzić, skąd pochodzi wpis i czy trzeba doprecyzować wariant gry.
- Commit: `9f2560c`.
- Nadal brak testu uruchomieniowego po zmianach UI; nie uruchamiano analyzer, testów ani APK.


### Mapy — Galar: Wild Area z 18 podobszarami (2026-10-29)

- Dodano 18 osobnych rekordów podobszarów Wild Area: Meetup Spot, Rolling Fields, jeziora Axewell/Miloch, Bridge Field, Dusty Bowl, Lake of Outrage i pozostałe nazwane strefy.
- Połączono je z rekordem Wild Area oraz dodano potwierdzone punkty dostępu od Motostoke i Hammerlocke. Źródło: Bulbapedia — Wild Area (`https://bulbapedia.bulbagarden.net/wiki/Wild_Area`).
- Indeks Galar wzrósł z 48 do 66 lokacji. Nazwy podobszarów są indeksowane, ale dokładne pinezki, granice podobszarów i warunki pogodowe nadal wymagają osobnej weryfikacji.
- Commit: `05f2299`.


### Mapy — Paldea: zweryfikowane połączenia w części południowej (2026-10-29)

- Dodano połączenia między Cabo Poco, South Province (Area One), Los Platos i Mesagoza oraz sąsiednimi obszarami południowej prowincji i wejściem do Pokémon League.
- Połączenia oparto na opisach lokacji Bulbapedia: `South Province (Area One)` i `Mesagoza`; rekordy mają jawny status, że zweryfikowano dostęp, ale nie pinezki na mapie.
- Commit: `c11c806`.
- Paldea pozostaje otwartym światem: pozostałe obszary trzeba łączyć na podstawie stron poszczególnych lokacji, bez udawania ponumerowanych tras.


### Mapy — Alola: połączenia promowe między wyspami (2026-10-29)

- Dodano zweryfikowane połączenia dostępu promem między Hau’oli City, Heahea City, Malie City, Seafolk Village i Aether Paradise. Notatki zaznaczają, że są to połączenia transportowe, a nie fizyczne sąsiedztwo; część kursów zależy od postępu fabuły.
- Dodano osobne źródła dla terminali promowych w Hau’oli, Heahea i Malie City.
- Commit: `8c1b96f`.


### Mapy — Galar: dostęp kolejowy i stacje DLC (2026-10-29)

- Dodano węzeł sieci kolejowej oraz 9 stacji: Wedgehurst, Wild Area, Motostoke, Hulbury, Hammerlocke, White Hill, Wyndon, Armor i Crown Tundra.
- Połączenia kolejowe są opisane jako transport, nie jako fizyczna bliskość. Węzły pomagają przechodzić między główną częścią Galar a Isle of Armor i Crown Tundra; dostęp zależy od fabuły i DLC.
- Źródła: `https://bulbapedia.bulbagarden.net/wiki/Wild_Area_Station` oraz `https://bulbapedia.bulbagarden.net/wiki/Transportation_in_the_Pok%C3%A9mon_world`.
- Commity: `e135641`, `87841f1`, `239173b`.


### Mapy — audyt grafów i połączenia Paldei / regionów (2026-10-29)

- Poprawiono spójność tras: Sinnoh Victory Road ma połączenie z Route 223, a Fight Area dostęp statkiem ze Snowpoint City; Unova dostała Skyarrow Bridge oraz połączenie transportowe Virbank–Castelia i brakujące przejście przy Twist Mountain; Alola dostała połączenia Diglett’s Tunnel oraz Akala Outskirts/Memorial Hill/Poni.
- Paldea: połączono główne osady z obszarami na podstawie listy połączeń lokacji Bulbapedia, dodano relacje Area Zero, Kitakami i Blueberry Academy/Terarium oraz sąsiednie obszary południowej, wschodniej i północnej prowincji.
- Commity: `15faa25`, `a83f43c`, `b398450`, `4085596`, `a044f05`, `3d42e3e`, `4fe2c71`, `1e9f391`.
- Grafy są traktowane jako dostęp/transport, jeśli nie chodzi o bezpośrednie sąsiedztwo; źródła i statusy zaznaczają niezweryfikowane dokładne pinezki. Paldea nadal wymaga dalszego łączenia i weryfikacji pozostałych obszarów.


### Mapy — kontrola połączeń między regionami i indeksów po rozbudowie (2026-10-29)

- Połączono wszystkie rekordy w grafie Sinnoh, Unovy, Aloli i Galar poprzez źródłowo opisane przejścia, promy lub kolej. Takie połączenia są opisane jako dostęp/transport, nie jako bezpośrednie sąsiedztwo.
- Paldea ma teraz źródłowo połączone główne osady, część prowincji, Area Zero, Kitakami i Blueberry Academy/Terarium. Pozostałe lokacje nadal mają nieuzupełnione połączenia, bo nie dodajemy ich na chybił trafił.
- Ostatni audyt wszystkich 11 indeksów: 844 rekordy; wszystkie pliki parsują się, są zarejestrowane i ładowane, brak duplikatów ID/nazw, brak brakujących źródeł/statusów i brak niedziałających `connectsTo`.
- Commity z tej partii: `15faa25`, `a83f43c`, `b398450`, `4085596`, `a044f05`, `3d42e3e`, `4fe2c71`, `1e9f391`, `8c1b96f`, `a6806ea`.
- Nie uruchamiano Flutter analyzer, testów ani APK. Audyt dotyczy struktury danych, nie testu działania aplikacji.


### Mapy — Paldea: komplet 10 Sights i punkty orientacyjne (2026-10-29)

- Uzupełniono brakujące rekordy Grand Olive Orchard, Secluded Beach i Glaseado’s Grasp; wszystkie 10 Ten Sights ma teraz reprezentację w indeksie.
- Połączono punkty orientacyjne ze zweryfikowanymi obszarami: Colonnade Hollow, Million Volt Skyline, Leaking Tower, Fury Falls, Gracia Stones, Casseroya Falls, Paldea’s Highest Peak, Groundblight/Icerend/Firescourge/Grasswither Shrine, Poco Path Lighthouse i akademie w Mesagoza.
- Źródło dla Ten Sights: `https://bulbapedia.bulbagarden.net/wiki/Casseroya_Falls`; pozycje pinezek pozostają niezweryfikowane.
- Commit: `db37cc5`; indeks Paldea ma teraz 103 lokacje.


### Mapy — korekta nazw i niezweryfikowanych placeholderów Paldei (2026-10-29)

- Usunięto trzy niepotwierdzone placeholdery `Distant Rock`, `Socarrat Trail Sight` i `Tropical Biome`; ostatni nie pasował do rzeczywistej czwórki biomów Terarium, gdzie używamy `Savanna Biome`.
- Po korekcie Paldea ma 100 rekordów, w tym wszystkie 10 nazwanych Ten Sights i cztery właściwe biomy Terarium. Nie dodajemy lokacji tylko po to, by sztucznie zwiększyć licznik.
- Commit: `7c41d93`.


### Mapy — rozdzielenie Kanto od tras Johto (2026-10-29)

- Usunięto z indeksu Kanto rekordy Route 26–28, Tohjo Falls, Mt. Silver i New Bark Town, które należą do postgame Johto, a nie do mapy Kanto w Red/Blue/Yellow/FireRed/LeafGreen.
- Usunięto również odwołania do tych rekordów z Pokémon League Reception Gate. Indeks Kanto ma teraz 65 lokacji i nie miesza dwóch regionów.
- Commit: `794c9eb`.


### Mapy — Paldea: dostęp do Area Zero i jaskini Oni Mountain (2026-10-29)

- Połączono Zero Gate z West Province (Area Three), gdzie znajduje się wejście do Great Crater of Paldea, oraz Oni Mountain Cave z Oni Mountain.
- Te krawędzie opisują dostęp do obiektu, nie współrzędne ani dokładną geometrię mapy.
- Commit: `daf3aa7`.


### Mapy — FireRed/LeafGreen: osobny indeks Sevii Islands (2026-10-29)

- Dodano osobny indeks offline Sevii Islands z 7 wyspami i 22 nazwanymi lokacjami/obszarami, w tym Mt. Ember, Icefall Cave, Lost Cave, Dotted Hole, Trainer Tower i Tanoby Ruins.
- Zarejestrowano asset w `pubspec.yaml`, dodano ładowanie do `MapsScreen` i wybór `Kanto` ↔ `Sevii Islands` dla FireRed/LeafGreen. Kanto pozostaje oddzielone od wysp i nie pokazuje ich w grach, które ich nie zawierają.
- Commity: `a97c548`, `6360a4b`, `1c95545`.
- Pozycje pinezek pozostają niezweryfikowane; indeks opisuje nazwy i dostęp, a nie dokładną mapę w skali.


### Mapy — pełny audyt po dodaniu Sevii Islands (2026-10-29)

- Sprawdzono 12 indeksów offline: 867 rekordów lokacji. Wszystkie JSON-y parsują się, każdy plik jest wpisany w `pubspec.yaml` i ładowany przez `MapsScreen`.
- Wynik strukturalny: 0 zduplikowanych ID, 0 zduplikowanych nazw, 0 brakujących `sourceIds`, 0 niedziałających `connectsTo`, 0 lokacji bez statusu danych.
- UI ma wyszukiwanie po nazwie/notatkach/typie/połączeniach, klikalne przejścia między lokacjami i klikalne źródła. FireRed/LeafGreen mają przełącznik Kanto ↔ Sevii Islands.
- To nie oznacza ukończenia całej mapy: poza schematem Kanto nie ma jeszcze dokładnych map graficznych w skali, a wiele regionów wymaga dokładnych pinezek przedmiotów, trenerów, Pokémonów, znajdziek i pełnego audytu wersji. Nie uruchamiano Flutter analyzer, testów ani APK.


### Mapy — schemat Kanto także dla klasycznych gier Kanto (2026-10-29)

- Dodano schematyczną mapę Kanto dla indeksu Kanto w Red/Blue/Yellow, FireRed/LeafGreen oraz po przełączeniu regionu Kanto w Gold/Silver/Crystal. Warianty nie pokazują paneli spotkań specyficznych dla Let’s Go.
- Ekran wyraźnie opisuje grafikę jako schemat orientacyjny, bez dokładnych pozycji przedmiotów, trenerów i Pokémonów.
- Commit: `b98808b`.


### Mapy — audyt kompletności numerowanych tras (2026-10-29)

- Zweryfikowano obecność wszystkich rekordów tras w indeksach: Kanto 1–25, Johto 26–48, Hoenn 101–134, Sinnoh 201–230, Unova 1–23, Kalos 1–22, Alola 1–17 i Galar 1–10. Brakujące rekordy tras: 0.
- Dla Paldei nie dodano numerowanych tras, bo Scarlet/Violet używają otwartego świata z prowincjami i obszarami.


### Mapy — szczegóły lokacji z indeksu w UI (2026-10-29)

- Karta wybranej lokacji wyświetla teraz dane zapisane w JSON: dzikie spotkania (z uwzględnieniem wariantu Let’s Go i pięter jaskiń), przedmioty, trenerów/drużyny oraz wydarzenia/nagrody.
- Wpisy z niezweryfikowanymi pozycjami nadal pokazują opis tekstowy; UI nie tworzy pinezek ani współrzędnych na podstawie samego opisu.
- Commit: `ddf6015`.
- Nie uruchamiano Flutter analyzer/testów/APK, więc zmiana wymaga późniejszego sprawdzenia w aplikacji.

### Mapy — Pokémony na trasach otwierają Pokédex (2026-10-29)

- W karcie lokacji sekcja spotkań została zmieniona na klikalne znaczniki Pokémonów z poziomami, metodą i procentową szansą, jeśli takie dane znajdują się w indeksie.
- Kliknięcie Pokémonа prowadzi do jego szczegółów w Pokédexie; obsługuje zarówno rekordy ze szczegółowymi obiektami (np. Route 1–2), jak i starszy format list (np. Route 3).
- Lista nadal zależy od wybranej wersji Let’s Go Pikachu / Let’s Go Eevee. Niezweryfikowane pozycje na mapie pozostają opisowe — nie dodano fałszywych pinezek.
- Commit UI: `7b52d8c`.
- Nie uruchamiano Flutter analyzer, testów ani APK. Zmiana wymaga późniejszego testu w aplikacji.

### Mapy — klikalne spotkania również w widoku Let’s Go (2026-10-29)

- Dodano panel spotkań dla wybranej lokacji w widoku Kanto dla Let’s Go, Pikachu! i Let’s Go, Eevee!, korzystający z danych indeksu `lets_go_kanto_audit.json`.
- Panel wyświetla Pokémony, poziomy, procenty i metodę spotkania, jeśli pola są dostępne. Nazwa prowadzi do szczegółów Pokédexu.
- Poprawiono wyszukiwanie gatunku tak, aby nie wymagało rozszerzenia `firstOrNull`.
- Commity: `70a9a31` (panel), `300df8d` (zgodność Dart).
- Nadal nie uruchamiano Flutter analyzer, testów ani budowy APK; proszę sprawdzić działanie po swojej stronie.

- Dodatkowo: lokacje bez kompletnej listy spotkań wyświetlają teraz jawny komunikat zamiast pustej sekcji; aplikacja nie zgaduje brakujących gatunków. Commit: `aa7c7d9`.

### Mapy — spotkania na Route 7 i Route 8 (2026-10-29)

- Uzupełniono dane Let’s Go Pikachu/Eevee o spotkania naziemne, Pokémony pojawiające się na niebie oraz spotkania specjalne dla Route 7 i Route 8.
- Poziomy i procenty zapisano tylko tam, gdzie źródło je podaje; dla spotkań specjalnych bez wiarygodnego procentu nie wymyślono szansy.
- Dodano i poprawiono identyfikatory źródeł Serebii oraz Routepedia. Dane nadal są tekstowe — nie są dokładnymi pinezkami na mapie.
- Commity danych: `d4d329e`, `a88a8bb`.
- Nie uruchamiano Flutter analyzer, testów ani APK.

### Mapy — spotkania na Route 9 i Route 10 (2026-10-29)

- Uzupełniono tabele spotkań dla obu wersji Let’s Go: trawa, niebo i specjalne spotkania, a dla Route 10 również Pokémony podczas surfowania.
- Poziomy i szanse są oparte na tabelach Serebii; specjalne spotkania bez podanej szansy nie otrzymały zmyślonego procentu.
- Dane pozostają tekstowe, bez fałszywych pinezek. Commit: `4b46751`.
- Nie uruchamiano Flutter analyzer, testów ani APK.

### Mapy — spotkania na Route 12 i Route 13 (2026-10-29)

- Dodano spotkania naziemne i wodne dla obu wersji Let’s Go, a dla Route 12 również standardowe spotkania na niebie oraz spotkanie fabularne ze Snorlaxem w wersji Pikachu.
- Dodano poziomy i procenty z tabel źródłowych; rzadkie spotkania specjalne bez podanej szansy pozostają bez procentu.
- Dane nadal nie określają dokładnych pikselowych lokalizacji. Commit: `ad686dd`.
- Nie uruchamiano Flutter analyzer, testów ani APK.

### Mapy — spotkania na Route 14 i Route 15 (2026-10-29)

- Dodano spotkania naziemne, standardowe spotkania na niebie i specjalne spawny dla obu wersji Let’s Go.
- Uwzględniono różnice wersji, m.in. Oddish/Gloom i Scyther w Pikachu oraz Bellsprout/Weepinbell i Pinsir w Eevee.
- Brakujące procenty dla rzadkich spotkań specjalnych nie zostały dopowiedziane. Commit: `53cd78e`.
- Nie uruchamiano Flutter analyzer, testów ani APK.

### Mapy — spotkania na Route 16–18 (2026-10-29)

- Uzupełniono tabele spotkań dla obu wersji Let’s Go: Pokémony na ziemi, standardowe spotkania na niebie i rzadkie spawny specjalne.
- Dodano także spotkanie fabularne ze Snorlaxem na Route 16.
- Dane nie zawierają zmyślonych szans dla specjalnych spawnow. Nie są to pinezki dokładnych pozycji. Commit: `5aa911f`.
- Nie uruchamiano Flutter analyzer, testów ani APK.

### Mapy — spotkania na Route 22 i Route 23 (2026-10-29)

- Dodano dane o spotkaniach naziemnych, wodnych i na niebie dla obu wersji Let’s Go; uwzględniono również rzadkie spawny specjalne, gdy źródła je wymieniają.
- W Route 22 poziomy odpowiadają wczesnej części gry, a Route 23 ma zakres poziomów 41–46. Specjalnym spawnow bez podanej szansy nie przypisano procentów.
- Commit: `d999c20`. Dane nadal nie określają dokładnych pinezek.
- Nie uruchamiano Flutter analyzer, testów ani APK.

### Mapy — ujednolicenie spotkań na Route 11 i Route 19–21 (2026-10-29)

- Przeniesiono dane spotkań do wspólnego formatu dla Let’s Go Pikachu/Eevee, tak aby klikalna lista mogła pokazywać oba warianty.
- Uzupełniono spotkania naziemne, wodne, na niebie i specjalne, zgodnie z tabelami Serebii. Route 20 pokazuje zakres 37–44 i notatkę wyjaśniającą różnice między wschodnią a zachodnią częścią.
- Commity: `b1584f3`, `259cca1`.
- Nie uruchamiano Flutter analyzer, testów ani APK.

- Walidacja powiązań nazw z Pokédexem wykryła różnicę w apostrofie w nazwie Farfetch’d. Porównywanie nazw normalizuje teraz proste i typograficzne apostrofy, aby ten wpis również otwierał Pokédex. Commit: `e2276a4`.

### Audyt pokrycia spotkań na trasach Kanto (2026-10-29)

- Sprawdzono wszystkie 25 tras w indeksie Let’s Go: każda ma teraz listę dla Let’s Go Pikachu i Let’s Go Eevee.
- Sprawdzono też nazwy wszystkich wpisów względem katalogu Pokédexu oraz to, że identyfikatory źródeł istnieją w indeksie. Walidacja tekstowych danych nie zastępuje testu w aplikacji i nie potwierdza dokładnych współrzędnych na mapie.
- Naprawiono dopasowanie apostrofu w Farfetch’d. Commity: `e2276a4`, `78fac90`.

### Mapy — pełniejsze spotkania na Route 1, 4, 6, 24 i 25 (2026-10-29)

- Uzupełniono spotkania na niebie, specjalne spawny i wodne dla tras, gdzie źródła je podają.
- Poprawiono też błąd w tabeli Route 4: wersja Pikachu ma Sandshrew i Mankey, a wersja Eevee — Ekans; teraz listy wersji są rozdzielone.
- Route 24 i Route 25 uwzględniają Squirtle jako specjalne spotkanie, a dane wodne pozostają osobną metodą.
- Commit: `ad2ab21`. Nie uruchamiano Flutter analyzer, testów ani APK.

### Mapy — dodatkowe spotkania na Route 2, 3 i 5 (2026-10-29)

- Uzupełniono spotkania na niebie i spawny specjalne zgodnie z tabelami Serebii.
- Route 3 uwzględnia Charmandera jako specjalne spotkanie. Route 2 wyjaśnia różnicę poziomów między częścią południową (3–4) i północną (3–8).
- Commit: `cc77bd8`. Nie uruchamiano Flutter analyzer, testów ani APK.

### Końcowa walidacja danych tras przed testem użytkownika (2026-10-29)

- Po kolejnych uzupełnieniach ponownie sprawdzono JSON: 25/25 tras ma osobne tablice spotkań dla Let’s Go Pikachu i Let’s Go Eevee.
- Nazwy z tabel spotkań dopasowują się do wpisów Pokédexu po normalizacji apostrofów; wszystkie identyfikatory źródeł użyte przez tabele istnieją w katalogu źródeł.
- To kontrola struktury i spójności tekstowych danych, nie test uruchomieniowy. Nadal nie uruchamiano `flutter analyze`, testów ani `flutter build apk`.

### Mapy — Kanto: ilustracyjna warstwa wysokiej jakości (2026-10-29)

- Rozbudowano rysowanie mapy Kanto o wektorowe pasma górskie, delikatne linie poziomic, strumień, małe wysepki, miękkie cieniowanie terenu i ozdobną ramkę z kompasem.
- Elementy są rysowane ścieżkami i gradientami Flutter Canvas, więc pozostają gładkie przy powiększaniu zamiast wyglądać jak rozciągnięte piksele. To autorska, stylizowana warstwa ilustracyjna — nie kopia oficjalnej mapy ani potwierdzenie dokładnych kształtów terenu.
- Zachowano istniejące wybieranie lokacji, sieć 74 punktów i powiększanie/przesuwanie mapy. Poprawiono też komentarz liczby lokacji i składnię zamknięcia listy połączeń.
- Commit mapy: `488b736`.
- Nie uruchamiano Flutter analyzer, testów ani APK. Kolejny etap: lepsze, ręcznie stylizowane ikony miast/lasów/jaskiń oraz dopracowanie kształtu lądu i przebiegu dróg bez fałszywego sugerowania dokładnych współrzędnych.

### Mapy — Kanto: ręcznie stylizowana warstwa ilustracyjna (2026-10-29, kontynuacja)

- Dodano wektorowe ilustracje lasów, skupisk małych budynków w miastach oraz wejść do jaskiń; wykorzystują krzywe, okręgi, gradienty i przezroczystość zamiast bitmap/pikselowych tekstur.
- Ozdobna warstwa mapy obejmuje już góry, poziomice, strumień, wysepki, ramkę i kompas. Elementy mają charakter ilustracyjny i nie udają zweryfikowanych współrzędnych z gry.
- Ograniczono kolizje napisów na widoku ogólnym: nazwy głównych miejsc są widoczne stale, a nazwy mniejszych obiektów i tras pojawiają się po wybraniu punktu. Wszystkie 74 punkty pozostają wybieralne.
- Uaktualniono opis mapy i legendę, aby jasno rozróżniały dekoracyjną grafikę od danych lokalizacyjnych.
- Kontrola statyczna po zmianach: 74/74 nazwy lokacji zgodne z indeksem danych; 83/83 połączenia zgodne; brak nieprawidłowych indeksów połączeń.
- Nie uruchamiano `flutter analyze`, testów ani budowania APK. Wciąż do zrobienia przed uznaniem mapy za kompletną: szczegółowe plany wnętrz i jaskiń, weryfikacja przebiegu terenu względem wiarygodnych map źródłowych oraz dalsze sprawdzenie czytelności po uruchomieniu aplikacji.

### Mapy — Kanto: schematy lokalne dla całego indeksu 74 lokacji (2026-10-29, kontynuacja)

- Rozszerzono panel lokalnych schematów z początkowych 7 miejsc do wszystkich 74 lokacji w indeksie Kanto. Każda lokacja ma teraz własny zestaw nazwanych stref/elementów w panelu.
- Dodano poglądowe plany głównych jaskiń i obiektów: Mt. Moon, Rock Tunnel, Diglett's Cave, Seafoam Islands, Cerulean Cave, Victory Road, Pokémon Tower, Pokémon Mansion, Power Plant i S.S. Anne.
- Dodano schematyczne plany głównych miast: Cerulean, Vermilion, Celadon, Saffron, Lavender, Fuchsia, Cinnabar i Indigo Plateau; dodano też wnętrza ważnych budynków, Gymów, przejść podziemnych i wszystkich tras 1–25.
- Schematy wykorzystują wektorowe strefy, korytarze, ikony i etykiety. Nadal są ilustracją orientacyjną, nie wiernym odwzorowaniem kafelków, map pięter ani dokładnych współrzędnych z gry; pozycje trenerów, przedmiotów i spotkań nie są zmyślonymi pinezkami.
- Audyt statyczny: 74/74 lokacje mają węzeł mapy; 83 połączenia nie odwołują się do nieistniejących indeksów; wszystkie 74 nazwy lokacji mają odpowiadający schemat lokalny; brak dodatkowych nazw i duplikatów kluczy w mapie schematów.
- Commity tej serii obejmują m.in. `76f4461`, `911a263`, `f4bd042`, `f798ec7`, `b538ccd`, `e66d851`, `04be4d5`, `dd0fddc` i `1d6fc3f`.
- Nie uruchamiano `flutter analyze`, testów ani APK zgodnie z dotychczasowym sposobem pracy. Przed określeniem mapy jako gotowej nadal potrzebne są: przegląd wizualny po uruchomieniu aplikacji oraz weryfikacja geometrii i pięter z wiarygodnymi mapami źródłowymi.

### Mapy — Kanto: pokrycie wszystkich lokacji planem lokalnym (2026-10-29, audyt po rozszerzeniu)

- Uzupełniono brakujące plany lokalne dla Safari Zone i Pokémon League Reception Gate. Indeks 74 lokacji ma teraz 74 odpowiadające wpisy w `_featuresByLocation`; nie wykryto duplikatów ani dodatkowych nazw.
- Dodano własne schematy korytarzy dla tras 1–25 i obu Underground Path, plany stref dla głównych jaskiń, pięter budynków, Gymów, miast, Safari Zone i bramy Ligi.
- Uporządkowano rysowanie wejścia do jaskini: osobny pędzel obrysu nie modyfikuje już stylu w trakcie wywołania `drawArc`.
- Ponowny audyt statyczny: 74 lokacje w danych i rysunku, 83 połączenia, 74 zestawy elementów planu lokalnego, brak brakujących nazw i duplikatów w zestawie planów. To walidacja tekstowa/strukturalna, nie kompilacja.
- Nie uruchamiano `flutter analyze`, testów ani APK. Ostateczny wygląd, skalowanie i interakcje muszą być obejrzane po uruchomieniu aplikacji; plany są celowo oznaczone jako poglądowe, dopóki geometria pięter nie zostanie zweryfikowana z mapami źródłowymi.

### Mapy — Kanto: etykiety tras i kierunków (2026-10-29)

- Dla lokalnych schematów Route 3–25 oraz obu Underground Path dodano etykiety końców trasy oparte na połączeniach zapisanych w indeksie Kanto, zamiast ogólnych napisów „początek/koniec”.
- Zachowano ostrzeżenie, że ścieżki są schematyczne, a ich kształt nie stanowi dokładnej geometrii mapy z gry. Dla tras wodnych zastosowano odrębną paletę ilustracyjną.
- Commit: `82adfef`. Bez uruchamiania testów, Flutter analyzer i budowy APK.

### Mapy — Kanto: czytelność etykiet schematów lokalnych (2026-10-29)

- Dodano delikatne, zaokrąglone tła i obrys etykiet na lokalnych planach, żeby napisy pozostały czytelne na tle stref i korytarzy.
- Wektorowa grafika głównej mapy i planów lokalnych nadal skaluje się bez bitmapowego powiększania. Ostateczna czytelność na telefonie wymaga jeszcze obejrzenia w działającej aplikacji.
- Commit: `81e2255`. Nie uruchamiano testów, analyzer ani APK.

### Mapy — Kanto: ikony lokacji przypięte do węzłów (2026-10-29)

- Zmieniono rozmieszczenie ilustracji miast i jaskiń tak, aby były rysowane bezpośrednio przy właściwych wybieralnych węzłach mapy, a nie jako osobna, potencjalnie przesunięta dekoracja.
- Miasta mają miniaturowe skupiska budynków; jaskinie, tunele i główne obiekty podziemne mają wektorowe wejścia. Las pozostaje miękką dekoracyjną warstwą terenu.
- Commit: `9015515`. Nie uruchamiano kompilacji ani testów.

### Mapy — Kanto: ograniczenie nakładania etykiet na mapie głównej (2026-10-29)

- Etykiety głównych lokacji mają teraz kilka możliwych położeń względem punktu. Rysowanie wybiera miejsce z najmniejszą kolizją z wcześniej rozmieszczonymi etykietami.
- Dodano delikatne tła i obrysy etykiet w stylu atlasu, aby napisy były czytelne nad terenem i drogami.
- To heurystyka rysowania, nie gwarancja braku kolizji przy każdej wielkości ekranu; potrzebny jest ogląd mapy w działającej aplikacji.
- Commit: `18cbd00`. Bez uruchamiania analyzer, testów i APK.

### Mapy — Kanto: dokumentacja źródeł ilustracji (2026-10-29)

- Do indeksu Kanto dodano źródła pomocnicze: oficjalny opis regionu Let’s Go oraz indeks map MewMaps. Istniejące źródło Routepedia nadal służy do sprawdzania listy lokacji i połączeń.
- Dodano jawne `illustrationPolicy`: grafika mapy i plany pięter są autorskimi ilustracjami wektorowymi; nie wolno traktować ich kształtów ani pozycji węzłów jako dokładnych współrzędnych z gry. Nie kopiowano obrazów źródłowych do zasobów aplikacji.
- Commit danych: `f1d7e20`. JSON został zapisany w poprawnym formacie i wymaga jeszcze zwykłego testu ładowania w aplikacji, którego nie uruchamiano.

### Mapy — Kanto: lepszy układ regionu i trasy wodne (2026-10-29)

- Przestawiono 74 węzły w głównej ilustracji, aby lepiej wykorzystać przestrzeń mapy i czytelniej oddać ogólną relację północ–południe: Indigo Plateau/Pewter/Mt. Moon na północy, centralne miasta w środku, Fuchsia i wodne trasy na południu.
- Zmieniono obrys lądu i położenie dekoracyjnych gór/lasów tak, aby pasowały do nowego układu. Węzły pozostają schematyczne; nie są dokładnymi współrzędnymi z gry.
- Route 19, 20 i 21 oraz ich połączenia rysują się teraz jako niebieskie, przerywane trasy wodne; dodano odpowiednią pozycję w legendzie.
- Statycznie sprawdzono, że nazwy i połączenia nadal zachowują indeks: 74/74 węzły, 83 połączenia, brak nieistniejących indeksów. Nie uruchamiano analyzer, testów ani APK.
- Commity: `3d1ac9f`, `1d299db`, `4bf0423`, `e100b9a`.

### Mapy — Kanto: ikony typów lokacji na widoku regionu (2026-10-29)

- Rozróżniono na mapie głównej skupiska budynków/miast, osobne budynki i Gymy oraz wejścia do jaskiń/tuneli. Ikony są wektorowe i rysowane przy wybieralnych węzłach.
- Seafoam Islands otrzymały symbol jaskini/wysp zamiast ikony miasta; wyspy Cinnabar zachowują symbol zabudowy.
- Commity: `cbe4e6b`, `0f2e274`. To poprawka warstwy ilustracyjnej; nie wykonywano testów ani kompilacji.

### Mapy — Kanto: topologia i style dróg powierzchniowych/podziemnych (2026-10-29)

- Dodatkowo skorygowano połączenie Route 11–Route 12, które błędnie łączyło dwie odrębne trasy. Route 11 łączy teraz Vermilion City z Diglett's Cave; Route 12 pozostaje połączony z Lavender Town i Route 13. Indeks i rysunek są zgodne na poziomie 82 połączeń.
- Przesunięto Route 11 na wschód od Vermilion City i dopasowano Route 5/6/7/8 oraz Diglett's Cave do czytelniejszego układu regionu.
- Powierzchniowe drogi są kremowo-złote, trasy wodne niebieskie i przerywane, a połączenia podziemne mają osobny, stonowany przerywany styl. Link Route 2–Diglett's Cave pozostaje wejściem powierzchniowym; połączenie Diglett's Cave–Route 11 oznacza przejście podziemne.
- Commity: `77ec257`, `f0ff1c2`, `ee22d2c`, `7501fee`, `e3577e0`, `ae6d2b5`. Nie uruchamiano testów ani APK.

### Mapy — Kanto: precyzyjniejsze wybieranie punktów przy powiększeniu (2026-10-29)

- Promień dotknięcia punktów mapy i symboli Route 1 jest teraz przeliczany względem aktualnej skali powiększenia. Po mocnym zoomie dotknięcie nie powinno wybierać odległego punktu tylko dlatego, że dawny promień był liczony w jednostkach mapy.
- Commit: `20e1c71`. Zmiana wymaga sprawdzenia dotykiem na urządzeniu; nie uruchamiano testów ani APK.

### Mapy — Kanto: dwa wejścia Diglett's Cave i pełny indeks 76 lokacji (2026-10-29)

- Rozdzielono wejście Diglett's Cave od Route 2 i wejście od Route 11 na osobne wybieralne punkty. Główna lokacja jaskini leży teraz między nimi, a połączenia do niej są rysowane jako podziemny przerywany korytarz; wejścia łączą się z trasami drogami powierzchniowymi.
- Indeks i rysunek mają teraz 76 lokacji oraz 84 połączenia. Każda lokacja ma lokalny schemat, a źródła nowych wejść korzystają z już istniejących referencji Routepedia/RotomLabs.
- Legenda rozróżnia drogi lądowe, wodne i przejścia podziemne.
- Statyczna walidacja: 76/76 nazw węzłów zgodnych, 84/84 połączenia zgodne z `connectsTo`, brak nieistniejących indeksów i brak brakujących identyfikatorów źródeł. Nie uruchamiano Flutter analyzer, testów ani APK.
- Commity: `27640d7`, `e990330`, `c853e1d`, `386a06f`, `e8f7ef2`, `fa317cc`, `fff4e55`.

### Mapy — Kanto: wybrzeże i ocean w stylu atlasu (2026-10-29)

- Dodano jasny pas piasku przy linii brzegowej oraz delikatne, wektorowe fale rysowane wyłącznie po stronie oceanu. Fale są odcinane maską kształtu lądu, więc nie powinny nachodzić na punkty lokacji.
- Commit: `7add644`. To dekoracyjna ilustracja, nie dokładny brzeg z gry; nie uruchamiano testów ani APK.

### Mapy — Kanto: osobne pinezki obu wejść Diglett's Cave (2026-10-29)

- Rozszerzono indeks z 74 do 76 lokacji przez dodanie dwóch wyraźnie opisanych podlokacji: wejścia od Route 2 i wejścia od Route 11. Główna lokacja jaskini łączy się z oboma wejściami, a każde wejście z właściwą trasą.
- Zamiast jednej długiej linii Route 11–Diglett's Cave rysunek pokazuje teraz dwa wejścia i osobne połączenia podziemne. Schemat lokalny każdego wejścia ma własne etykiety.
- Aktualny graf ma 84 połączenia; statyczna walidacja po zmianie potwierdziła 76/76 nazw i 84/84 połączeń. Nie uruchamiano testów ani APK.
- Commity: `27640d7`, `e990330`, `c853e1d`, `386a06f`, `e8f7ef2`, `fa317cc`, `fff4e55`.

### Mapy — Kanto: zatoka i strumień w warstwie ilustracyjnej (2026-10-29)

- Dodano niewielką, nieregularną zatokę z piaskowym brzegiem, gradientem wody i obrysem; strumień jest poprowadzony w jej kierunku. To element autorskiej stylizacji, nie dokładny kształt wody z gry.
- Commit: `2231359`. Nie uruchamiano testów, analyzer ani APK.

### Mapy — Kanto: numery tras na widoku ogólnym (2026-10-29)

- Dodano małe, czytelne plakietki z numerami Route 1–25 przy odpowiednich węzłach. Trasy wodne 19–21 mają osobny niebieski obrys, zgodny z ich przerywanymi liniami.
- Dzięki temu nazwy tras nie muszą być stale wyświetlane i nie zaśmiecają widoku głównego, a numer trasy nadal jest widoczny.
- Commit: `5dd7a40`. Nie uruchamiano testów, analyzer ani APK.

### Mapy — Kanto: kolizje etykiet z numerami tras (2026-10-29)

- Do algorytmu rozmieszczania etykiet dodano prostokąty plakietek tras jako zajęte obszary, aby nazwy lokacji nie były celowo układane na numerach Route.
- Commit: `ce47527`. To poprawka układu graficznego; bez testów i APK.

### Mapy — Kanto: kompas z oznaczeniem północy (2026-10-29)

- Dodano literę N nad kompasem, aby ozdobny element wskazywał również orientację mapy.
- Commit: `b13b24e`. Bez uruchamiania testów i APK.

### Mapy — Kanto: aktualizacja opisu po dodaniu wejść jaskini (2026-10-29)

- Ujednolicono opis mapy i planów lokalnych: liczba lokacji wynosi teraz 76 w obu miejscach UI.
- Commit: `6193e2b`. Bez testów i APK.

### Mapy — Kanto: odsunięcie kompasu od północno-wschodnich lokacji (2026-10-29)

- Przesunięto kompas do wolniejszego obszaru przy górnej krawędzi, aby nie nachodził na Route 25, Bill's House ani Sea Cottage.
- Commit: `c1308b2`. Nie uruchamiano testów ani APK.

### Mapy — Kanto: ręczne przyciski zoomu i centrowania (2026-10-29)

- Dodano przyciski „+”, „−” i „Wyśrodkuj mapę” na samym widoku mapy. Powiększanie odbywa się względem środka widoku i respektuje zakres skali 0,55–4×.
- Sterowanie przydaje się szczególnie na PC, gdzie gest szczypania nie zawsze jest dostępny; przesuwanie i gesty dotykowe pozostają bez zmian.
- Commit: `e295080`. Nie uruchamiano Flutter analyzer, testów ani APK; działanie przycisków wymaga późniejszego testu na urządzeniu/PC.

### Mapy — Kanto: poprawiony podpis Route 11 (2026-10-29)

- Lokalny schemat Route 11 wskazuje teraz jako wschodni koniec osobne wejście Diglett's Cave od Route 11, zamiast błędnie podpisywać Route 12.
- Commit: `e5f3ffb`. Bez testów i APK.

### Mapy — Kanto: ujednolicenie nazwy wejścia w Route 11 (2026-10-29)

- Ujednolicono podpis końca Route 11 i nazwę punktu w panelu lokalnym: oba wskazują teraz „Diglett's Cave (Route 11 entrance)”.
- Commit: `68879d0`. Bez testów i APK.

### Mapy — Kanto: uzupełniony schemat Route 2 (2026-10-29)

- Lokalny plan Route 2 pokazuje teraz kierunek do Viridian City, Viridian Forest i Pewter City oraz boczne wejście Diglett's Cave od Route 2.
- Commit: `02005cf`. Bez testów i APK.

### Mapy — Kanto: audyt nazw końców tras (2026-10-29)

- Sprawdzono 25 definicji końców dla Route 3–25 i obu Underground Path: każda nazwa końcowa wskazuje istniejący węzeł mapy, w tym nową lokację „Diglett's Cave (Route 11 entrance)”.
- Commity po tej korekcie: `e5f3ffb`, `68879d0`, `02005cf`. To audyt statyczny nazw, nie test aplikacji.

### Mapy — Kanto: wygładzenie grafiki i porządek w punktach lokacji (2026-10-29)

- Włączono antyaliasing dla wszystkich 82 pędzli używanych przez główny rysunek Kanto i lokalne schematy, aby krawędzie krzywych, ikon, tras i etykiet były gładsze przy skalowaniu.
- Rozsunięto 26 punktów budynków, Gymów i innych obiektów w zatłoczonych skupiskach. Statyczny pomiar układu wykazał spadek par węzłów oddalonych od siebie o mniej niż 3,5% rozmiaru mapy z 22 do 4; nie zmienia to topologii połączeń.
- Doprecyzowano tekst w UI: 76 lokacji ma schematy lokalne, 84 połączenia odpowiadają indeksowi, a dostępne listy spotkań/notatki nie oznaczają dokładnych pinezek.
- Wszystkim 76 lokacjom jawnie ustawiono `coordinateStatus: "unverified"`, ponieważ ich pozycje na ilustracji są poglądowe i nie wolno przedstawiać ich jako zweryfikowanych współrzędnych gry.
- Audyt statyczny: 76/76 nazw lokacji znajduje się na mapie; 84/84 połączenia są zgodne z indeksem; 76/76 lokacji ma własny zestaw schematu lokalnego; brak duplikatów nazw schematów i brak błędnych identyfikatorów źródeł. 121 rozpoznanych nazw spotkań Pokémonów pasuje do katalogu Pokédexu.
- Commity: `35e9e7a` (antyaliasing), `fff5166` (rozsunięcie punktów), `51b6ece` (status współrzędnych), `5966b82` (opisy UI).
- Nie uruchamiano `flutter analyze`, testów ani budowania APK. Grafika pozostaje autorską mapą poglądową; dokładna geometria terenu, pięter i pozycje pinezek wymagają osobnej weryfikacji ze źródłowymi mapami gry oraz oglądu w działającej aplikacji.

### Mapy — Kanto: końcowy audyt układu i referencji (2026-10-29)

- Po ostatnim rozstawieniu punktów mapa ma 76/76 lokacji, 84/84 połączenia zgodne z indeksem i 76/76 zestawów schematów lokalnych; nie wykryto brakujących ani dodatkowych nazw, duplikatów kluczy, połączeń do nieistniejących lokacji ani pozycji poza obszarem mapy.
- Węzły są lepiej rozdzielone w zatłoczonych miastach; pozostała tylko jedna para w odległości mniejszej niż 3,5% rozmiaru mapy (Saffron City–Silph Co.), czyli poniżej progu 4 par z poprzedniego audytu.
- Sprawdzono wszystkie 122 źródła i odwołania: brak identyfikatorów źródeł, których nie ma w indeksie. Wszystkie 76 lokacji mają jawny status współrzędnych `unverified`; to zabezpiecza przed pomyleniem układu ilustracji z dokładnymi współrzędnymi gry.
- Nazwy spotkań w danych (121 nazw Pokémonów oraz dodatkowy wpis lokalizacyjny) dopasowują się do katalogu Pokédexu. To kontrola tekstowa, nie dowód dokładnego położenia na planszy.
- Dodano referencje do mapy regionu Kanto i katalogu map lokacji w Bulbagarden Archives. Używane są jako źródła porównawcze; żadna grafika z gry nie została skopiowana do zasobów aplikacji.
- Commit układu: `6914569`; commit referencji danych: `e0b1f21`.
- Nie uruchamiano `flutter analyze`, testów ani budowania APK. Nadal nierozstrzygnięte bez oglądu aplikacji i ręcznego porównania ze źródłowymi mapami: dokładne współrzędne terenu, pięter oraz pinezek przedmiotów/trenerów/Pokémonów.

### Mapy — Kanto: pełny widok mapy na telefonie i PC (2026-10-29)

- Zmieniono obszar rysowania z kwadratu 900×900 na proporcje 900×660, bliższe szerokiemu układowi mapy regionu.
- Mapa automatycznie dopasowuje teraz skalę i pozycję do widocznego obszaru przy pierwszym otwarciu oraz po użyciu przycisku centrowania; zmniejszono minimalną skalę do 0,35×, aby zmieścić cały region także na wąskich ekranach.
- Poprawiono przeliczenia współrzędnych wybierania punktów dla nowego wymiaru mapy. Zoom dotykowy, przesuwanie i ręczne przyciski pozostają dostępne.
- Commit: `6cf9e32`. Weryfikacja tekstowa potwierdziła 76 węzłów, 84 połączenia, brak brakujących lokacji i brak pozycji poza obszarem mapy. Nie uruchamiano aplikacji, analyzer, testów ani APK; rzeczywiste zachowanie interakcji nadal wymaga sprawdzenia na telefonie/PC.

### Mapy — Kanto: dopasowanie widoku i status pinezek w szczegółach (2026-10-29)

- Główny widok Kanto ma teraz proporcje 900×660 i dopasowuje skalę do widocznego obszaru przy otwarciu oraz centrowaniu; dzięki temu pełna mapa mieści się od razu w widoku telefonu i komputera zamiast zaczynać od przyciętego kwadratu.
- Zmieniono przeliczenia współrzędnych dotyku dla nowego wymiaru mapy i obniżono minimalny zoom do 0,35×.
- Panel lokacji Let’s Go pokazuje jawny status pozycji pinezek. Przy `coordinateStatus: "unverified"` użytkownik widzi informację, że położenie jest poglądowe — również gdy dana lokacja nie ma jeszcze listy spotkań.
- Commity: `6cf9e32` (dopasowanie mapy), `af94e00` i `a63589a` (status pinezek w panelu).
- Nie uruchamiano testów, analyzer ani APK. Dopasowanie skali i interakcje wymagają późniejszego sprawdzenia na rzeczywistym ekranie; nie potwierdzono jeszcze dokładnych współrzędnych gry.

### Mapy — Kanto: status współrzędnych widoczny w panelu lokacji (2026-10-29)

- Panel danych Let’s Go pokazuje status weryfikacji pinezek także dla lokacji bez kompletnej listy spotkań; nie sugeruje, że brakujące pozycje są już znane.
- Wszystkie lokacje w indeksie mają teraz jawne `coordinateStatus: "unverified"`, a komunikat UI jest przygotowany na przyszłe lokacje z potwierdzonym statusem.
- Commity: `af94e00`, `a63589a`. Bez uruchamiania testów, analyzer ani APK.

### Mapy — Kanto: lepsze wykorzystanie dużych ekranów (2026-10-29)

- Dopasowanie początkowe i przycisk centrowania mogą powiększyć mapę do 1,25× na dużych ekranach, jeśli viewport na to pozwala; na telefonach nadal skala jest dobierana tak, aby zmieścić cały obszar.
- Commit: `ea01685`. Kontrola statyczna potwierdziła, że zasób JSON jest wpisany w `pubspec.yaml`, a 76 lokacji i 84 połączenia nadal pasują do indeksu. Bez uruchamiania aplikacji, testów ani APK.

