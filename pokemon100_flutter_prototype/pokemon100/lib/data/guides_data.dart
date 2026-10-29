
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
),
],
),
];

