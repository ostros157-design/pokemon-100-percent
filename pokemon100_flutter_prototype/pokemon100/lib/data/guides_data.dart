
import '../models/guide.dart';

const List<Guide> guidesList = [
Guide(
id: 'lg_pikachu_start',
gameId: 'lets_go_pikachu',
title: 'Pokémon Let’s Go, Pikachu! — Początek przygody',
description:
'Pierwsza część kompletnego poradnika od Pallet Town do pierwszego Gymu.',
steps: [
GuideStep(
title: 'Rozpocznij przygodę',
description:
'Rozpocznij nową grę i wybierz wygląd swojej postaci. '
'Następnie nadaj jej imię.',
location: 'Pallet Town',
),
GuideStep(
title: 'Zdobądź Pikachu',
description:
'Wyjdź z domu i spróbuj opuścić Pallet Town. '
'Profesor Oak zabierze Cię do laboratorium. '
'Wybierz Poké Balla, aby rozpocząć przygodę ze swoim partnerem Pikachu.',
location: 'Pallet Town',
pokemon: ['Pikachu'],
),
GuideStep(
title: 'Idź Route 1',
description:
'Opuść Pallet Town i przejdź na północ przez Route 1. '
'Po drodze możesz złapać pierwsze dzikie Pokémony.',
location: 'Route 1',
pokemon: [
'Pidgey',
'Rattata',
],
encounterRatesPercent: {
'Pidgey': 40,
'Rattata': 30,
},
),
GuideStep(
title: 'Dotrzyj do Viridian City',
description:
'Przejdź przez Route 1 i wejdź do Viridian City. '
'Odwiedź Pokémon Center, aby przygotować drużynę.',
location: 'Viridian City',
),
GuideStep(
title: 'Odbierz przesyłkę dla Profesora Oaka',
description:
'Wejdź do Poké Martu i porozmawiaj z pracownikiem. '
'Otrzymasz przesyłkę przeznaczoną dla Profesora Oaka.',
location: 'Viridian City',
items: ['Oak’s Parcel'],
),
GuideStep(
title: 'Wróć do Pallet Town',
description:
'Wróć Route 1 do laboratorium Profesora Oaka i przekaż mu przesyłkę.',
location: 'Pallet Town',
),
GuideStep(
title: 'Otrzymaj Pokédex',
description:
'Po wydarzeniach w laboratorium otrzymasz Pokédex. '
'Od tej chwili możesz rozpocząć jego kompletowanie.',
location: 'Pallet Town',
items: ['Pokédex'],
),
GuideStep(
title: 'Przygotuj drużynę',
description:
'Przed dalszą podróżą złap kilka Pokémonów i zdobądź trochę doświadczenia. '
'Nie musisz jeszcze tworzyć ostatecznej drużyny.',
location: 'Route 1',
pokemon: [
'Pidgey',
'Rattata',
],
encounterRatesPercent: {
'Pidgey': 40,
'Rattata': 30,
},
),
GuideStep(
title: 'Przejdź przez Route 2',
description:
'Rusz na północ przez Route 2. Następnie przygotuj się do wejścia do Viridian Forest.',
location: 'Route 2',
),
GuideStep(
title: 'Eksploruj Viridian Forest',
description:
'Przejdź przez Viridian Forest. '
'Warto złapać Pokémony dostępne w lesie i zebrać znajdujące się tam przedmioty.',
location: 'Viridian Forest',
pokemon: [
'Caterpie',
'Metapod',
'Pikachu',
],
encounterRatesPercent: {
'Caterpie': 25,
'Metapod': 10,
'Pikachu': 5,
},
),
GuideStep(
title: 'Dotrzyj do Pewter City',
description:
'Po wyjściu z Viridian Forest kontynuuj podróż do Pewter City. '
'Wylecz drużynę przed pierwszym Gymem.',
location: 'Pewter City',
),
GuideStep(
title: 'Przygotuj się na Brocka',
description:
'Brock używa Pokémonów typu Rock. '
'Pokémony typu Grass, Water i Fighting mogą być bardzo skuteczne.',
location: 'Pewter Gym',
pokemon: [
'Geodude',
'Onix',
],
),
GuideStep(
title: 'Pokonaj Brocka',
description:
'Pokonaj Brocka i zdobądź swoją pierwszą odznakę Gym.',
location: 'Pewter Gym',
pokemon: [
'Geodude',
'Onix',
],
items: ['Boulder Badge'],

GuideStep(
title: 'Przejdź Route 3',
description:
'Po zdobyciu Boulder Badge wyjdź z Pewter City na wschód. Przejdź przez trawiastą Route 3 i walcz z trenerami po drodze. Pokémony na tej trasie występują na poziomach 3–8.',
location: 'Route 3',
pokemon: ['Spearow', 'Rattata', 'Mankey', 'Sandshrew'],
encounterRatesPercent: {
'Spearow': 30,
'Rattata': 30,
'Mankey': 20,
'Sandshrew': 20,
},
),
GuideStep(
title: 'Przejdź przez Mt. Moon',
description:
'Wejdź do jaskini i eksploruj piętra 1F, B1F oraz B2F. Zbieraj przedmioty, walcz z trenerami i znajdź wyjście po wschodniej stronie. Dzikie Pokémony mają zwykle poziomy 5–10.',
location: 'Mt. Moon',
pokemon: ['Zubat', 'Geodude', 'Paras', 'Clefairy', 'Onix'],
encounterRatesPercent: {
'Zubat': 40,
'Geodude': 40,
'Paras': 15,
'Clefairy': 4,
'Onix': 1,
},
items: ['Moon Stone', 'Dome Fossil lub Helix Fossil'],
),
GuideStep(
title: 'Opuść Mt. Moon przez Route 4',
description:
'Po wyjściu z jaskini zbadaj trawiasty fragment Route 4 i skorzystaj z Pokémon Center, jeśli potrzebujesz leczenia. W tej wersji gry dostępne są tu poniższe spotkania w trawie.',
location: 'Route 4',
pokemon: ['Spearow', 'Rattata', 'Sandshrew', 'Mankey', 'Psyduck'],
encounterRatesPercent: {
'Spearow': 30,
'Rattata': 25,
'Sandshrew': 20,
'Mankey': 20,
'Psyduck': 5,
},
),
GuideStep(
title: 'Przygotuj się w Cerulean City',
description:
'Wylecz drużynę w Pokémon Center i uzupełnij zapasy w Poké Marcie. Jeśli masz już zarejestrowanych co najmniej 30 gatunków Pokémonów, porozmawiaj z dziewczyną w domu obok Pokémon Center, aby otrzymać Bulbasaura.',
location: 'Cerulean City',
pokemon: ['Bulbasaur'],
),
GuideStep(
title: 'Pokonaj trenerów na Nugget Bridge',
description:
'Wyjdź z miasta na północ i pokonaj pięciu trenerów na moście. Po serii walk otrzymasz Nugget. Przygotuj drużynę przed kolejnymi pojedynkami na Route 24.',
location: 'Route 24 — Nugget Bridge',
items: ['Nugget'],
),
GuideStep(
title: 'Przejdź przez Route 24',
description:
'Po moście pokonaj kolejnych trenerów i sprawdź trawiasty teren. Spotkania w trawie w Let’s Go, Pikachu! mają następujące udokumentowane udziały.',
location: 'Route 24',
pokemon: ['Pidgey', 'Venonat', 'Oddish', 'Psyduck'],
encounterRatesPercent: {
'Pidgey': 30,
'Venonat': 30,
'Oddish': 20,
'Psyduck': 20,
},
),
GuideStep(
title: 'Dokończ Route 25 i znajdź Billa',
description:
'Idź dalej na wschód przez Route 25. Pokonaj trenerów, zbierz przedmioty i dotrzyj do domu Billa. Pomóż mu wrócić do ludzkiej postaci, a następnie odbierz S.S. Ticket.',
location: 'Route 25',
pokemon: ['Pidgey', 'Venonat', 'Oddish', 'Psyduck'],
encounterRatesPercent: {
'Pidgey': 30,
'Venonat': 30,
'Oddish': 20,
'Psyduck': 20,
},
items: ['S.S. Ticket'],
),
GuideStep(
title: 'Zdobądź Cascade Badge',
description:
'Wróć do Cerulean City i wejdź do Cerulean Gym. Misty używa Pokémonów typu Water, więc najlepiej przygotować skuteczne ataki typu Electric lub Grass. Po wygranej odbierz Cascade Badge i TM nagrodę liderki.',
location: 'Cerulean Gym',
pokemon: ['Staryu', 'Starmie'],
items: ['Cascade Badge'],
),
),
],
),
];

