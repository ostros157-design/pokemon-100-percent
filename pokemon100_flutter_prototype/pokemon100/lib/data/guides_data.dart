import '../models/guide.dart';

const List<Guide> guidesList = [
  Guide(
    id: 'emerald_start',
    gameId: 'emerald',
    title: 'Pokémon Emerald — Początek przygody i pierwsza odznaka',
    description:
        'Poradnik prowadzi od Littleroot Town do zdobycia Stone Badge w Rustboro City. '
        'Zawiera spotkania dzikich Pokémonów z procentowymi szansami dla trawiastych obszarów.',
    sections: [
      'Littleroot Town i wybór startera',
      'Route 101, Oldale Town i pierwsza walka rywala',
      'Route 102 i Petalburg City',
      'Route 104, Petalburg Woods i Rustboro City',
      'Pierwsza sala — Roxanne',
    ],
    steps: [
      GuideStep(
        title: 'Ustaw zegar i odbierz Potion',
        description:
            'Po wyjściu z ciężarówki wejdź do nowego domu. Na piętrze ustaw zegar, a następnie sprawdź komputer w swoim pokoju — znajdziesz w nim Potion.',
        location: 'Littleroot Town',
        items: ['Potion'],
      ),
      GuideStep(
        title: 'Odwiedź dom sąsiadów',
        description:
            'Wejdź do domu Profesora Bircha i porozmawiaj z jego rodziną. Następnie idź na Route 101, gdzie profesor będzie potrzebował pomocy.',
        location: 'Littleroot Town',
      ),
      GuideStep(
        title: 'Wybierz starter i uratuj Profesora Bircha',
        description:
            'Birch jest ścigany przez dzikiego Zigzagoona. Wybierz jednego z trzech Pokémonów z torby profesora: Treecko, Torchic albo Mudkip. Po walce wybrany starter zostanie z tobą.',
        location: 'Route 101',
        pokemon: ['Treecko', 'Torchic', 'Mudkip', 'Zigzagoon'],
      ),
      GuideStep(
        title: 'Wróć do laboratorium i poznaj następny cel',
        description:
            'Wróć z profesorem do jego laboratorium. Otrzymasz wybranego startera na stałe. Birch poprosi cię o spotkanie z May lub Brendanem na Route 103. Jeśli Pokémon jest osłabiony, możesz go uleczyć u mamy.',
        location: 'Littleroot Town',
        pokemon: ['Treecko', 'Torchic', 'Mudkip'],
      ),
      GuideStep(
        title: 'Przejdź przez Route 101 do Oldale Town',
        description:
            'Idź na północ przez wysoką trawę. Na tym etapie nie masz jeszcze Poké Balli, więc dzikie Pokémony możesz tylko spotykać i pokonywać — nie da się ich złapać.',
        location: 'Route 101',
        pokemon: ['Poochyena', 'Wurmple', 'Zigzagoon'],
        encounterRatesPercent: {
          'Poochyena': 45,
          'Wurmple': 45,
          'Zigzagoon': 10,
        },
      ),
      GuideStep(
        title: 'Odbierz darmowy Potion w Oldale Town',
        description:
            'Odwiedź Pokémon Center i Poké Mart. Porozmawiaj z pracownicą sklepu stojącą przy wyjściu na Route 101 — wskaże ci drogę do sklepu i podaruje Potion.',
        location: 'Oldale Town',
        items: ['Potion'],
      ),
      GuideStep(
        title: 'Przygotuj się do spotkania na Route 103',
        description:
            'Z Oldale idź na północ przez Route 103. Po drugiej stronie trasy spotkasz May lub Brendana. Pamiętaj, że przed zdobyciem Poké Balli nie możesz jeszcze łapać dzikich Pokémonów.',
        location: 'Route 103',
        pokemon: ['Poochyena', 'Zigzagoon', 'Wingull'],
        encounterRatesPercent: {
          'Poochyena': 60,
          'Zigzagoon': 20,
          'Wingull': 20,
        },
      ),
      GuideStep(
        title: 'Pokonaj rywala na Route 103',
        description:
            'May lub Brendan wyzwie cię na pierwszą walkę. Rywal używa startera mającego przewagę typu nad twoim wyborem. Korzystaj z ataków, pilnuj HP i w razie potrzeby użyj Potion. Nagroda za zwycięstwo wynosi 300₽.',
        location: 'Route 103',
        pokemon: ['Treecko', 'Torchic', 'Mudkip'],
      ),
      GuideStep(
        title: 'Odbierz Pokédex, Poké Balle i Running Shoes',
        description:
            'Po walce wróć za rywalem do laboratorium Bircha. Profesor da ci Pokédex, a May/Brendan przekaże 5 Poké Balli. Przy wyjściu z Littleroot porozmawiaj z mamą, aby otrzymać Running Shoes — przytrzymaj B, by biegać.',
        location: 'Littleroot Town',
        items: ['Pokédex', 'Poké Ball ×5', 'Running Shoes'],
      ),
      GuideStep(
        title: 'Zbadaj Route 102 i złap przydatne Pokémony',
        description:
            'Wróć do Oldale, a następnie skieruj się na zachód do Petalburg City. To dobre miejsce na rozbudowanie drużyny. Ralts jest rzadki, ale może być bardzo wartościowym członkiem zespołu. Na północy trasy znajdziesz też miękką ziemię z jagodami, a na południowym zachodzie ukryty Potion.',
        location: 'Route 102',
        pokemon: [
          'Poochyena',
          'Wurmple',
          'Lotad',
          'Zigzagoon',
          'Ralts',
          'Seedot',
        ],
        encounterRatesPercent: {
          'Poochyena': 30,
          'Wurmple': 30,
          'Lotad': 20,
          'Zigzagoon': 15,
          'Ralts': 4,
          'Seedot': 1,
        },
        items: ['Oran Berry ×2', 'Pecha Berry ×2', 'Potion (ukryty)'],
      ),
      GuideStep(
        title: 'Pomóż Wally’emu złapać Raltsa',
        description:
            'W Petalburg City odwiedź Gym i porozmawiaj z Normanem. Wally poprosi o pomoc w złapaniu Pokémona. Norman pożyczy mu Zigzagoona i Poké Balla; przejdź z nim na Route 102 i obejrzyj samouczek łapania Raltsa. Norman wyjaśni, że możesz rzucić wyzwanie Roxanne w Rustboro, a jego własny Gym będzie dostępny dopiero po zdobyciu czterech odznak.',
        location: 'Petalburg City',
        pokemon: ['Ralts', 'Zigzagoon'],
      ),
      GuideStep(
        title: 'Przejdź na zachód przez Route 104',
        description:
            'Opuść Petalburg City na zachód. Na południowej części Route 104 możesz złapać Marilla, a także zebrać jagody i kilka ukrytych przedmiotów przy brzegu. Przy domku Mr. Brineya znajduje się droga do Petalburg Woods.',
        location: 'Route 104',
        pokemon: ['Poochyena', 'Marill', 'Wurmple', 'Taillow', 'Wingull'],
        encounterRatesPercent: {
          'Poochyena': 40,
          'Marill': 20,
          'Wurmple': 20,
          'Taillow': 10,
          'Wingull': 10,
        },
        items: [
          'Antidote (ukryty)',
          'Heart Scale (ukryty)',
          'Potion (ukryty)',
          'Pecha Berry ×2',
          'Oran Berry ×2',
        ],
      ),
      GuideStep(
        title: 'Eksploruj Petalburg Woods',
        description:
            'Wejdź do lasu i przejdź na północ. Spotkasz trenerów oraz członka Team Aqua, który zaczepia pracownika Devon Corporation. Pokonaj Grunta, aby odzyskać spokój w lesie — wdzięczny pracownik podaruje ci Great Ball. W lesie można też znaleźć Parlyz Heal, Ether oraz ukryte przedmioty.',
        location: 'Petalburg Woods',
        pokemon: [
          'Poochyena',
          'Wurmple',
          'Shroomish',
          'Silcoon',
          'Cascoon',
          'Taillow',
          'Slakoth',
        ],
        encounterRatesPercent: {
          'Poochyena': 30,
          'Wurmple': 25,
          'Shroomish': 15,
          'Silcoon': 10,
          'Cascoon': 10,
          'Taillow': 5,
          'Slakoth': 5,
        },
        items: [
          'Parlyz Heal',
          'Great Ball (od pracownika Devon)',
          'Ether',
          'Potion (ukryty)',
          'Poké Ball (ukryty)',
        ],
      ),
      GuideStep(
        title: 'Przejdź północną część Route 104',
        description:
            'Po wyjściu z lasu idź na północ do Rustboro City. Pokémony w trawie są takie same jak na południowej części Route 104. Zajrzyj do Pretty Petal Flower Shop — otrzymasz Wailmer Pail, a przy sklepie znajdziesz kolejne jagody i przedmioty.',
        location: 'Route 104',
        pokemon: ['Poochyena', 'Marill', 'Wurmple', 'Taillow', 'Wingull'],
        encounterRatesPercent: {
          'Poochyena': 40,
          'Marill': 20,
          'Wurmple': 20,
          'Taillow': 10,
          'Wingull': 10,
        },
        items: [
          'Wailmer Pail',
          'TM09 Bullet Seed',
          'Oran Berry ×2',
          'Cheri Berry ×4',
          'Chesto Berry',
          'Leppa Berry ×2',
          'Poké Ball (ukryty)',
          'Potion',
          'Super Potion (ukryty)',
        ],
      ),
      GuideStep(
        title: 'Przygotuj się w Rustboro City',
        description:
            'Wylecz drużynę w Pokémon Center. Odwiedź szkołę trenerów i porozmawiaj z nauczycielem, aby dostać Quick Claw. W domu obok Pokémon Center możesz wymienić Raltsa na Seedota (otrzymany Seedot trzyma Chesto Berry). W domu Cuttera odbierzesz HM01 Cut, a chłopiec w jednym z budynków podaruje Premier Ball.',
        location: 'Rustboro City',
        pokemon: ['Seedot', 'Ralts'],
        items: ['Quick Claw', 'HM01 Cut', 'Premier Ball'],
      ),
      GuideStep(
        title: 'Pokonaj Roxanne i zdobądź Stone Badge',
        description:
            'Pierwszy Gym specjalizuje się w Pokémonach typu Rock. Roxanne używa dwóch Geodude i Nosepass. Najłatwiej wykorzystać ruchy typu Water lub Grass; Fighting również jest skuteczny. Geodude są jednocześnie typu Ground, więc ataki Water i Grass zadają im poczwórne obrażenia. Po zwycięstwie otrzymasz Stone Badge oraz TM39 Rock Tomb.',
        location: 'Rustboro Gym',
        pokemon: ['Geodude', 'Nosepass'],
        items: ['Stone Badge', 'TM39 Rock Tomb'],
      ),
    ],
  ),
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
            'Rozpocznij nową grę i wybierz wygląd swojej postaci. Następnie nadaj jej imię.',
        location: 'Pallet Town',
      ),
      GuideStep(
        title: 'Zdobądź Pikachu',
        description:
            'Wyjdź z domu i spróbuj opuścić Pallet Town. Profesor Oak zabierze Cię do laboratorium. Wybierz Poké Balla, aby rozpocząć przygodę ze swoim partnerem Pikachu.',
        location: 'Pallet Town',
        pokemon: ['Pikachu'],
      ),
      GuideStep(
        title: 'Idź Route 1',
        description:
            'Opuść Pallet Town i przejdź na północ przez Route 1. Po drodze możesz złapać pierwsze dzikie Pokémony.',
        location: 'Route 1',
        pokemon: ['Pidgey', 'Rattata'],
      ),
      GuideStep(
        title: 'Dotrzyj do Viridian City',
        description:
            'Przejdź przez Route 1 i wejdź do Viridian City. Odwiedź Pokémon Center, aby przygotować drużynę.',
        location: 'Viridian City',
      ),
      GuideStep(
        title: 'Odbierz przesyłkę dla Profesora Oaka',
        description:
            'Wejdź do Poké Martu i porozmawiaj z pracownikiem. Otrzymasz przesyłkę przeznaczoną dla Profesora Oaka.',
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
            'Po wydarzeniach w laboratorium otrzymasz Pokédex. Od tej chwili możesz rozpocząć jego kompletowanie.',
        location: 'Pallet Town',
        items: ['Pokédex'],
      ),
      GuideStep(
        title: 'Przygotuj drużynę',
        description:
            'Przed dalszą podróżą złap kilka Pokémonów i zdobądź trochę doświadczenia. Nie musisz jeszcze tworzyć ostatecznej drużyny.',
        location: 'Route 1',
        pokemon: ['Pidgey', 'Rattata'],
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
            'Przejdź przez Viridian Forest. Warto złapać Pokémony dostępne w lesie i zebrać znajdujące się tam przedmioty.',
        location: 'Viridian Forest',
        pokemon: ['Caterpie', 'Metapod', 'Pikachu'],
      ),
      GuideStep(
        title: 'Dotrzyj do Pewter City',
        description:
            'Po wyjściu z Viridian Forest kontynuuj podróż do Pewter City. Wylecz drużynę przed pierwszym Gymem.',
        location: 'Pewter City',
      ),
      GuideStep(
        title: 'Przygotuj się na Brocka',
        description:
            'Brock używa Pokémonów typu Rock. Pokémony typu Grass, Water i Fighting mogą być bardzo skuteczne.',
        location: 'Pewter Gym',
        pokemon: ['Geodude', 'Onix'],
      ),
      GuideStep(
        title: 'Pokonaj Brocka',
        description:
            'Pokonaj Brocka i zdobądź swoją pierwszą odznakę Gym.',
        location: 'Pewter Gym',
        pokemon: ['Geodude', 'Onix'],
        items: ['Boulder Badge'],
      ),
    ],
  ),
];
