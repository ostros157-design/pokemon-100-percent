import '../models/guide.dart';

const List<GuideStep> _emeraldContinuationSteps = [
  GuideStep(section: 'Dewford Town i druga odznaka', title: 'Odzyskaj Devon Goods i uratuj Peeko', description: 'Na Route 116 wejdź do Rusturf Tunnel. Pokonaj członka Team Aqua, odzyskaj Devon Goods i uratuj Wingulla Peeko należącego do Mr. Brineya.', location: 'Route 116 / Rusturf Tunnel', pokemon: ['Poochyena', 'Whismur'], encounterRatesPercent: {'Poochyena': 28, 'Nincada': 20, 'Taillow': 20, 'Whismur': 20, 'Abra': 10, 'Skitty': 2}, items: ['Devon Goods', 'Peeko']),
  GuideStep(section: 'Dewford Town i druga odznaka', title: 'Odbierz PokéNav i list do Stevena', description: 'Oddaj Devon Goods w Devon Corporation. Mr. Stone przekaże ci PokéNav oraz list dla Stevena, który przebywa w Granite Cave.', location: 'Rustboro City', items: ['PokéNav', 'Letter']),
  GuideStep(section: 'Dewford Town i druga odznaka', title: 'Przepłyń do Dewford Town', description: 'Wróć do domku Mr. Brineya na Route 104. Po uratowaniu Peeko przewiezie cię łodzią do Dewford Town.', location: 'Route 104 / Dewford Town'),
  GuideStep(section: 'Dewford Town i druga odznaka', title: 'Pokonaj Brawly’ego', description: 'Brawly specjalizuje się w typie Fighting. Wykorzystaj ataki Flying lub Psychic. Po zwycięstwie otrzymasz Knuckle Badge i TM08 Bulk Up.', location: 'Dewford Gym', pokemon: ['Machop', 'Meditite', 'Makuhita'], items: ['Knuckle Badge', 'TM08 Bulk Up']),
  GuideStep(section: 'Dewford Town i druga odznaka', title: 'Dostarcz list Stevenowi', description: 'Wejdź do Granite Cave. W ciemniejszych częściach jaskini przyda się Flash. Znajdź Stevena i przekaż mu Letter; w nagrodę otrzymasz TM47 Steel Wing.', location: 'Granite Cave', items: ['HM05 Flash', 'TM47 Steel Wing']),
  GuideStep(section: 'Slateport i trzecia odznaka', title: 'Dotrzyj do Slateport City', description: 'Mr. Briney może przewieźć cię na Route 109. Przejdź przez plażę do Slateport City, zbierając przedmioty i walcząc z trenerami.', location: 'Route 109 / Slateport City'),
  GuideStep(section: 'Slateport i trzecia odznaka', title: 'Oczyść Oceanic Museum z Team Aqua', description: 'Odwiedź Oceanic Museum i pokonaj członków Team Aqua, którzy próbują przejąć urządzenia badawcze. Po wydarzeniu rusz na północ Route 110.', location: 'Oceanic Museum'),
  GuideStep(section: 'Slateport i trzecia odznaka', title: 'Pokonaj rywala na Route 110', description: 'Na Route 110 spotkasz rywala. Jego drużyna zależy od wybranego startera; przygotuj się na Slugmę, Wingulla lub Lombre oraz rozwiniętego startera na poziomie 20.', location: 'Route 110', pokemon: ['Slugma', 'Wingull', 'Lombre', 'Grovyle', 'Combusken', 'Marshtomp']),
  GuideStep(section: 'Slateport i trzecia odznaka', title: 'Odbierz Rock Smash i rower', description: 'W Mauville City odwiedź Rydel’s Cycles i wybierz Mach Bike lub Acro Bike. Odbierz HM06 Rock Smash w jednym z domów.', location: 'Mauville City', items: ['HM06 Rock Smash', 'Mach Bike lub Acro Bike']),
  GuideStep(section: 'Slateport i trzecia odznaka', title: 'Pokonaj Wattsona', description: 'Wattson używa Pokémonów typu Electric. Najlepiej sprawdzają się ruchy Ground. Po zwycięstwie otrzymasz Dynamo Badge i TM34 Shock Wave.', location: 'Mauville Gym', pokemon: ['Voltorb', 'Electrike', 'Magneton', 'Manectric'], items: ['Dynamo Badge', 'TM34 Shock Wave']),
  GuideStep(section: 'Slateport i trzecia odznaka', title: 'Połącz Rusturf Tunnel', description: 'Przejdź przez Route 117 do Verdanturf Town. Użyj Rock Smash, aby usunąć skały w Rusturf Tunnel i połączyć obie strony tunelu.', location: 'Verdanturf Town / Rusturf Tunnel'),
  GuideStep(section: 'Fallarbor i czwarta odznaka', title: 'Przejdź przez Fiery Path i Route 113', description: 'Z Mauville skieruj się na północ przez Route 111 i Route 112. Przejdź przez Fiery Path, a następnie Route 113, gdzie możesz zbierać popiół wulkaniczny.', location: 'Route 111 / Fiery Path / Route 113'),
  GuideStep(section: 'Fallarbor i czwarta odznaka', title: 'Odwiedź Fallarbor i Meteor Falls', description: 'W Fallarbor przygotuj drużynę, a następnie przejdź Route 114 do Meteor Falls. Poznaj plany Team Aqua i Team Magma.', location: 'Fallarbor Town / Meteor Falls'),
  GuideStep(section: 'Fallarbor i czwarta odznaka', title: 'Zatrzymaj Team Magma na Mt. Chimney', description: 'Wjedź kolejką linową na Mt. Chimney. Pokonaj członków Team Magma, Tabithę i Maxiego. Następnie zejdź przez Jagged Pass do Lavaridge Town.', location: 'Mt. Chimney / Jagged Pass', pokemon: ['Mightyena', 'Zubat', 'Camerupt', 'Numel']),
  GuideStep(section: 'Fallarbor i czwarta odznaka', title: 'Pokonaj Flannery', description: 'Flannery specjalizuje się w typie Fire. Wykorzystaj ruchy Water, Ground lub Rock. Po zwycięstwie otrzymasz Heat Badge i TM50 Overheat; rywal przekaże ci Go-Goggles.', location: 'Lavaridge Gym', pokemon: ['Numel', 'Slugma', 'Camerupt', 'Torkoal'], items: ['Heat Badge', 'TM50 Overheat', 'Go-Goggles']),
  GuideStep(section: 'Piąta odznaka i Norman', title: 'Zbadaj pustynię Route 111', description: 'Dzięki Go-Goggles możesz wejść na pustynię. Zbadaj Mirage Tower i wybierz jedną z dwóch skamielin: Root Fossil albo Claw Fossil. Drugą będzie można zdobyć później w Desert Underpass.', location: 'Route 111 / Mirage Tower', items: ['Root Fossil lub Claw Fossil']),
  GuideStep(section: 'Piąta odznaka i Norman', title: 'Wróć do Petalburg City', description: 'Po zdobyciu czterech odznak wróć do Petalburg City i przygotuj się do walki z Normanem.', location: 'Petalburg City'),
  GuideStep(section: 'Piąta odznaka i Norman', title: 'Pokonaj Normana', description: 'Norman używa Pokémonów typu Normal. Fighting jest skuteczny. Uważaj na Truant Slakinga — wykorzystuj turę, w której nie atakuje. Po zwycięstwie otrzymasz Balance Badge i TM42 Facade. Rodzina Wally’ego przekaże HM03 Surf.', location: 'Petalburg Gym', pokemon: ['Spinda', 'Vigoroth', 'Linoone', 'Slaking'], items: ['Balance Badge', 'TM42 Facade', 'HM03 Surf']),
  GuideStep(section: 'Fortree i szósta odznaka', title: 'Przepraw się przez Route 118 i Route 119', description: 'Użyj Surf na wschód od Mauville. Przejdź Route 118 i długą Route 119, walcząc z trenerami i zbierając przedmioty.', location: 'Route 118 / Route 119'),
  GuideStep(section: 'Fortree i szósta odznaka', title: 'Uwolnij Weather Institute', description: 'Team Aqua zajmuje Weather Institute. Pokonaj członków organizacji i Shelly, aby uwolnić naukowców. Po wydarzeniu otrzymasz Castforma.', location: 'Weather Institute', pokemon: ['Castform']),
  GuideStep(section: 'Fortree i szósta odznaka', title: 'Zdobądź Devon Scope', description: 'W Fortree City niewidzialny Kecleon blokuje drogę do Gymu. Spotkaj Stevena na Route 120 i odbierz Devon Scope, a następnie użyj go, by ujawnić przeszkodę.', location: 'Fortree City / Route 120', pokemon: ['Kecleon'], items: ['Devon Scope']),
  GuideStep(section: 'Fortree i szósta odznaka', title: 'Pokonaj Winonę', description: 'Winona specjalizuje się w typie Flying. Wykorzystaj ruchy Electric, Ice lub Rock. Po zwycięstwie otrzymasz Feather Badge i TM40 Aerial Ace.', location: 'Fortree Gym', pokemon: ['Swablu', 'Tropius', 'Pelipper', 'Skarmory', 'Altaria'], items: ['Feather Badge', 'TM40 Aerial Ace']),
  GuideStep(section: 'Lilycove i Team Magma', title: 'Zbadaj Safari Zone i Mt. Pyre', description: 'Przejdź Route 121 i odwiedź Safari Zone. Następnie udaj się na Route 122 do Mt. Pyre. Na szczycie poznasz historię Red Orb i Blue Orb; Team Magma kradnie jeden z nich.', location: 'Safari Zone / Mt. Pyre', items: ['Red Orb', 'Blue Orb']),
  GuideStep(section: 'Lilycove i Team Magma', title: 'Pokonaj Maxiego w Magma Hideout', description: 'Wejdź do Team Magma Hideout w okolicy Jagged Pass. Przejdź przez bazę i pokonaj Tabithę oraz Maxiego.', location: 'Magma Hideout', pokemon: ['Mightyena', 'Crobat', 'Camerupt']),
  GuideStep(section: 'Aqua Hideout i siódma odznaka', title: 'Pokonaj rywala w Lilycove', description: 'W Lilycove City czeka kolejna walka z rywalem. Skład jego drużyny zależy od startera; przygotuj się na Tropiusa, Pokémony wspierające oraz rozwiniętego startera.', location: 'Lilycove City', pokemon: ['Tropius', 'Slugma', 'Pelipper', 'Ludicolo', 'Grovyle', 'Combusken', 'Marshtomp']),
  GuideStep(section: 'Aqua Hideout i siódma odznaka', title: 'Przejdź przez Aqua Hideout', description: 'W bazie Team Aqua korzystaj z teleportów, aby dotrzeć do właściwych pomieszczeń. Pokonaj Aqua Admin Matta i kontynuuj do Mossdeep City.', location: 'Aqua Hideout', pokemon: ['Mightyena', 'Golbat']),
  GuideStep(section: 'Aqua Hideout i siódma odznaka', title: 'Pokonaj Tate i Lizę', description: 'Walka w Mossdeep Gym jest podwójna. Tate i Liza używają Pokémonów typu Psychic; przydadzą się ruchy Dark, Ghost lub Bug. Po zwycięstwie otrzymasz Mind Badge i TM04 Calm Mind.', location: 'Mossdeep Gym', pokemon: ['Claydol', 'Xatu', 'Lunatone', 'Solrock'], items: ['Mind Badge', 'TM04 Calm Mind']),
  GuideStep(section: 'Seafloor Cavern i ósma odznaka', title: 'Zdobądź Dive i zbadaj trasy podwodne', description: 'Po wydarzeniach w Space Center porozmawiaj ze Stevenem, aby otrzymać HM08 Dive. Eksploruj Route 124, 125, 127 i 128, korzystając z Surf i Dive.', location: 'Mossdeep City / Route 124–128', items: ['HM08 Dive']),
  GuideStep(section: 'Seafloor Cavern i ósma odznaka', title: 'Zatrzymaj Archiego w Seafloor Cavern', description: 'Przejdź zagadki z głazami i wodą w Seafloor Cavern. Pokonaj Shelly oraz Archiego. Archie użyje Blue Orb, co doprowadzi do przebudzenia Kyogre.', location: 'Seafloor Cavern', pokemon: ['Sharpedo', 'Mightyena', 'Crobat']),
  GuideStep(section: 'Seafloor Cavern i ósma odznaka', title: 'Obudź Rayquazę i zakończ konflikt', description: 'Udaj się do Sootopolis City, a następnie na Route 131 do Sky Pillar. Na wyższych piętrach potrzebny jest Mach Bike. Obudź Rayquazę, aby zakończył konflikt Groudon–Kyogre, po czym wróć do Sootopolis.', location: 'Sootopolis City / Sky Pillar', pokemon: ['Rayquaza', 'Groudon', 'Kyogre']),
  GuideStep(section: 'Seafloor Cavern i ósma odznaka', title: 'Pokonaj Juana i zdobądź ósmy znaczek', description: 'Juan specjalizuje się w typie Water. Najlepsze będą ruchy Electric i Grass. Uważaj na Kingdrę. Po zwycięstwie otrzymasz Rain Badge i TM03 Water Pulse.', location: 'Sootopolis Gym', pokemon: ['Luvdisc', 'Whiscash', 'Sealeo', 'Crawdaunt', 'Kingdra'], items: ['Rain Badge', 'TM03 Water Pulse']),
  GuideStep(section: 'Victory Road i Pokémon League', title: 'Przygotuj się i przejdź Victory Road', description: 'Uzupełnij zapasy leczenia i przygotuj drużynę mniej więcej na poziomach 45–55. Użyj Waterfall, aby dotrzeć do Ever Grande City. W Victory Road pokonaj trenerów i Wally’ego.', location: 'Ever Grande City / Victory Road', pokemon: ['Magneton', 'Delcatty', 'Roselia', 'Altaria', 'Gardevoir']),
  GuideStep(section: 'Victory Road i Pokémon League', title: 'Pokonaj Elite Four — Sidney', description: 'Sidney specjalizuje się w typie Dark. Skuteczne będą ruchy Fighting i Bug.', location: 'Pokémon League', pokemon: ['Mightyena', 'Shiftry', 'Cacturne', 'Crawdaunt', 'Absol']),
  GuideStep(section: 'Victory Road i Pokémon League', title: 'Pokonaj Elite Four — Phoebe', description: 'Phoebe używa Pokémonów typu Ghost. Uważaj na statusy, Curse i Confuse Ray.', location: 'Pokémon League', pokemon: ['Dusclops', 'Banette', 'Sableye']),
  GuideStep(section: 'Victory Road i Pokémon League', title: 'Pokonaj Elite Four — Glacia', description: 'Glacia używa Pokémonów typu Ice. Przydadzą się ruchy Fighting, Rock, Electric i Steel.', location: 'Pokémon League', pokemon: ['Sealeo', 'Glalie', 'Walrein']),
  GuideStep(section: 'Victory Road i Pokémon League', title: 'Pokonaj Elite Four — Drake', description: 'Drake specjalizuje się w typie Dragon. Przygotuj silne ruchy Ice lub Dragon.', location: 'Pokémon League', pokemon: ['Shelgon', 'Altaria', 'Kingdra', 'Flygon', 'Salamence']),
  GuideStep(section: 'Victory Road i Pokémon League', title: 'Pokonaj Championa Wallace’a', description: 'Drużyna Wallace’a opiera się głównie na typie Water. Przygotuj ataki Electric i Grass. Uważaj na Recover Milotica, Toxic i Water Spout Wailorda. Po zwycięstwie trafisz do Hall of Fame.', location: 'Pokémon League', pokemon: ['Wailord', 'Tentacruel', 'Ludicolo', 'Whiscash', 'Gyarados', 'Milotic']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Odblokuj post-game i wybierz wędrującego Pokémona', description: 'Po Hall of Fame wrócisz do Littleroot Town. W rozmowie o tajemniczym Pokémonie wybierz kolor, aby określić, czy po Hoenn będzie wędrować Latias, czy Latios.', location: 'Littleroot Town', pokemon: ['Latias', 'Latios']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Odblokuj podróż S.S. Tidal', description: 'Po wejściu do Hall of Fame skorzystaj z S.S. Ticket. Leć do Slateport City albo Lilycove City, wejdź do portu i wybierz rejs. Po dotarciu do pierwszego portu ponownie wejdź na statek i wybierz Battle Frontier.', location: 'Slateport City / Lilycove City / S.S. Tidal', items: ['S.S. Ticket']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Odbierz Frontier Pass i sprawdź dom Scotta', description: 'Po pierwszym wejściu do Battle Frontier odbierz Frontier Pass przy bramie. Zapisuje on Battle Points, symbole i rekordy. Odwiedź Scotta w domu między Battle Dome i Battle Tower — może przyznać początkowe BP zależnie od wcześniejszych rozmów.', location: 'Battle Frontier — wejście / Scott’s House', items: ['Frontier Pass', 'Battle Points']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Battle Factory — zdobądź Knowledge Symbol', description: 'W Factory korzystasz z wypożyczonych Pokémonów i możesz wymieniać jednego z nich po walce. Noland pojawia się po 21. wygranej walce w serii (srebrny symbol) i po 42. (złoty symbol). Pokonaj go w obu próbach, aby zdobyć Knowledge Symbol.', location: 'Battle Factory', pokemon: ['Noland'], items: ['Silver Knowledge Symbol', 'Gold Knowledge Symbol']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Battle Dome — zdobądź Tactics Symbol', description: 'W turnieju bierze udział 16 trenerów. Przed walką poznajesz informacje o rywalu i wybierasz 2 Pokémony z drużyny 3. Tucker wyzywa cię po zdobyciu 5 tytułów mistrzowskich (srebrny symbol) i ponownie po 10 (złoty symbol).', location: 'Battle Dome', pokemon: ['Tucker'], items: ['Silver Tactics Symbol', 'Gold Tactics Symbol']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Battle Pike — zdobądź Luck Symbol', description: 'Przechodź przez zestawy po 3 pokoje, wybierając jedną z trzech dróg. W pokojach mogą czekać walki, dzikie Pokémony, leczenie lub statusy. Lucy pojawia się po 2 przejściach budynku (srebrny symbol) i po 10 przejściach (złoty symbol).', location: 'Battle Pike', pokemon: ['Lucy'], items: ['Silver Luck Symbol', 'Gold Luck Symbol']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Battle Tower — zdobądź Ability Symbol', description: 'Wybierz format Single 3 na 3 albo Double 4 na 4. Każda runda obejmuje 7 trenerów. Anabel pojawia się po 5 ukończonych rundach (srebrny symbol) i po 10 rundach (złoty symbol).', location: 'Battle Tower', pokemon: ['Anabel'], items: ['Silver Ability Symbol', 'Gold Ability Symbol']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Battle Arena — zdobądź Guts Symbol', description: 'Pojedynki trwają maksymalnie 3 tury. Jeśli nikt nie zostanie pokonany, sędziowie oceniają Mind, Skill i Body. Greta pojawia się po 28 zwycięstwach (srebrny symbol) i po 56 (złoty symbol).', location: 'Battle Arena', pokemon: ['Greta'], items: ['Silver Guts Symbol', 'Gold Guts Symbol']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Battle Palace — zdobądź Spirits Symbol', description: 'Nie wybierasz ruchów Pokémonów — zachowują się samodzielnie zależnie od natury i aktualnego HP. Spenser pojawia się po serii 21 zwycięstw (srebrny symbol) i 42 zwycięstw (złoty symbol).', location: 'Battle Palace', pokemon: ['Spenser'], items: ['Silver Spirits Symbol', 'Gold Spirits Symbol']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Battle Pyramid — zdobądź Brave Symbol', description: 'Przemierzaj siedem pięter w ciemności, pokonując trenerów i zbierając przedmioty do specjalnej Battle Bag. Zwykłych przedmiotów z torby nie zabierasz do środka. Brandon pojawia się po 21 piętrach (srebrny symbol) i po 70 piętrach (złoty symbol).', location: 'Battle Pyramid', pokemon: ['Brandon'], items: ['Silver Brave Symbol', 'Gold Brave Symbol']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Zdobądź wszystkie srebrne symbole', description: 'Pokonaj każdego z siedmiu Frontier Brains po raz pierwszy. Każde pierwsze zwycięstwo daje srebrny symbol odpowiedniego obiektu oraz 10 BP. Scott nagradza komplet siedmiu srebrnych symboli Lansat Berry.', location: 'Battle Frontier', items: ['7 Silver Frontier Symbols', 'Lansat Berry']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Zdobądź wszystkie złote symbole', description: 'Pokonaj ponownie wszystkich siedmiu Frontier Brains. Drugie zwycięstwo nad każdym z nich daje złoty symbol i 10 BP. Za komplet siedmiu złotych symboli Scott wręcza Starf Berry.', location: 'Battle Frontier', items: ['7 Gold Frontier Symbols', 'Starf Berry']),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Ukończ dodatkowe wyzwanie Battle Tower', description: 'Niezależnie od symboli Frontier Brain wygraj 50 kolejnych walk w Battle Tower, aby otrzymać Silver Shield od Scotta. Za 100 kolejnych zwycięstw otrzymasz Gold Shield.', location: 'Battle Tower / Scott’s House', items: ['Silver Shield', 'Gold Shield'], optional: true),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Zbadaj pozostałe atrakcje Battle Frontier', description: 'Po pokonaniu Sudowoodo użyj Wailmer Pail, aby je obudzić. Następnie zbadaj Artisan Cave, gdzie można spotkać Smeargle, Ranking Hall, wymianę Skitty na Meowth, Trainer Hill, Move Tutors i Exchange Service Corner. Wydawaj BP rozważnie — część tutorów i przedmiotów kosztuje ich sporo.', location: 'Battle Frontier', pokemon: ['Sudowoodo', 'Smeargle', 'Meowth'], items: ['Wailmer Pail', 'Battle Points'], optional: true),
  GuideStep(section: 'Post-game i Battle Frontier', title: 'Pokonaj Stevena w Meteor Falls', description: 'Po ukończeniu głównej historii możesz wrócić do Meteor Falls i zmierzyć się ze Stevenem.', location: 'Meteor Falls', optional: true),
  GuideStep(section: 'Legendarne Pokémony', title: 'Złap Rayquazę', description: 'Wróć do Sky Pillar po zakończeniu konfliktu fabularnego i przygotuj się do spotkania z Rayquazą.', location: 'Sky Pillar', pokemon: ['Rayquaza'], optional: true),
  GuideStep(section: 'Legendarne Pokémony', title: 'Znajdź Groudon i Kyogre', description: 'Po ukończeniu głównej historii sprawdzaj komunikaty Weather Institute, które wskazują pojawienie się Terra Cave lub Marine Cave. Lokacje zmieniają się.', location: 'Terra Cave / Marine Cave', pokemon: ['Groudon', 'Kyogre'], optional: true),
  GuideStep(section: 'Legendarne Pokémony', title: 'Otwórz ruiny Regi', description: 'Zdobądź Relicantha i Wailorda, a następnie rozwiąż zagadkę w Sealed Chamber. Wymagany jest także Dig.', location: 'Route 134 / Sealed Chamber', pokemon: ['Relicanth', 'Wailord'], items: ['Dig'], optional: true),
  GuideStep(section: 'Legendarne Pokémony', title: 'Złap Regirocka, Regice i Registeela', description: 'Po otwarciu ruin odwiedź Desert Ruins, Island Cave i Ancient Tomb. Każda ruina ma osobną zagadkę środowiskową.', location: 'Desert Ruins / Island Cave / Ancient Tomb', pokemon: ['Regirock', 'Regice', 'Registeel'], optional: true),
  GuideStep(section: 'Legendarne Pokémony', title: 'Sprawdź dostępność Latiasa i Latiosa', description: 'Jeden z Eon Pokémonów wędruje po Hoenn po ukończeniu ligi. Drugi wymaga Southern Island i Eon Ticket. Wydarzenia Faraway Island, Birth Island i Navel Rock są oddzielnymi wydarzeniami specjalnymi.', location: 'Hoenn / Southern Island', pokemon: ['Latias', 'Latios', 'Mew', 'Deoxys', 'Lugia', 'Ho-Oh'], optional: true),
  GuideStep(section: 'Zadania poboczne i Pokédex', title: 'Zdobądź drugą skamielinę', description: 'Po odpowiednim postępie odwiedź Desert Underpass i znajdź skamielinę, której nie wybrano w Mirage Tower. Ożyw ją w Rustboro City.', location: 'Desert Underpass / Rustboro City', optional: true),
  GuideStep(section: 'Zadania poboczne i Pokédex', title: 'Ukończ Abandoned Ship i New Mauville', description: 'W Abandoned Ship rozwiązuj zagadki z kluczami i znajdź Scanner, który można wymienić u Captain Stern. W New Mauville wyłącz generator.', location: 'Abandoned Ship / New Mauville', items: ['Scanner'], optional: true),
  GuideStep(section: 'Zadania poboczne i Pokédex', title: 'Ukończ pozostałe aktywności Hoenn', description: 'Wróć do Trick House, odwiedź Trainer Hill i Artisan Cave, weź udział w Pokémon Contests oraz zbierz wstążki. Sprawdź również Shoal Cave i pozostałe lokacje poboczne.', location: 'Hoenn', pokemon: ['Smeargle'], optional: true),
  GuideStep(section: 'Zadania poboczne i Pokédex', title: 'Uzupełnij Pokédex i ewolucje', description: 'Uzupełniaj Hoenn Pokédex i dostępny National Pokédex. Część gatunków wymaga ewolucji, hodowli, wymiany lub dostępu do późniejszych HM-ów. Wymiany i specjalne wydarzenia oznaczaj oddzielnie.', location: 'Hoenn', optional: true),
];


const List<Guide> guidesList = [
  Guide(
    id: 'emerald_start',
    gameId: 'emerald',
    title: 'Pokémon Emerald — Kompletny poradnik 100%',
    description:
        'Przewodnik od Littleroot Town przez wszystkie osiem odznak i Pokémon League, aż po post-game, legendarne Pokémony, zadania poboczne i Battle Frontier. Dane spotkań są podawane tylko tam, gdzie zostały wprowadzone.',
    sections: [
      'Początek przygody i pierwsza odznaka',
      'Dewford Town i druga odznaka',
      'Slateport i trzecia odznaka',
      'Fallarbor i czwarta odznaka',
      'Piąta odznaka i Norman',
      'Fortree i szósta odznaka',
      'Lilycove i Team Magma',
      'Aqua Hideout i siódma odznaka',
      'Seafloor Cavern i ósma odznaka',
      'Victory Road i Pokémon League',
      'Post-game i Battle Frontier',
      'Legendarne Pokémony',
      'Zadania poboczne i Pokédex',
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
      ..._emeraldContinuationSteps,
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
