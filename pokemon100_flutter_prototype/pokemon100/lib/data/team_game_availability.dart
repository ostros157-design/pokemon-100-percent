/// Conservative game-availability data for Team Making.
///
/// The regional-dex lists below identify Pokémon listed in each regional dex;
/// they do not prove that every species outside the list is unobtainable.
/// Let's Go version exclusives and special access methods are handled explicitly.
enum TeamAvailabilityKind {
  inGame,
  regionalDex,
  tradeRequired,
  specialAccess,
  postGame,
  breedingRequired,
  outsideRegionalDex,
  notInGame,
  unknown,
}

class TeamPokemonAvailability {
  final TeamAvailabilityKind kind;
  final String label;
  final String detail;

  const TeamPokemonAvailability(this.kind, this.label, this.detail);

  bool get canBeAdded => kind == TeamAvailabilityKind.inGame || kind == TeamAvailabilityKind.regionalDex;
  bool get canBeRecommended => canBeAdded ||
      kind == TeamAvailabilityKind.tradeRequired ||
      kind == TeamAvailabilityKind.postGame ||
      kind == TeamAvailabilityKind.breedingRequired;
  bool get canBeShownAsExtra =>
      kind == TeamAvailabilityKind.tradeRequired ||
      kind == TeamAvailabilityKind.specialAccess ||
      kind == TeamAvailabilityKind.postGame ||
      kind == TeamAvailabilityKind.breedingRequired ||
      kind == TeamAvailabilityKind.outsideRegionalDex ||
      kind == TeamAvailabilityKind.unknown;
}

class TeamGameAvailability {
  static const Map<String, String> _ranges = {
    'emerald': '25-28,37-45,54-55,59,63-68,72-76,81-82,84-85,88-89,100-101,109-112,116-121,127,129-130,141,169-172,174,177-178,182-184,186,202-203,214,218-219,222,227,230-232,252-282,285-306,309-314,316-334,336,338-386',
    'firered': '1-150',
    'soulsilver': '1-55,60-150,152-166,169-206,208-225,227-230,233-250,424,463,465,469,473',
    'x': '1-18,21-34,36,39-45,50-52,54-55,59-76,79-85,91-95,100-105,108,111-112,115-124,127-137,142-150,161-172,174,179-189,193-199,202,206-230,235,238,241,247-248,261-264,270-272,276-284,290-308,310-321,324-330,333-342,352-354,358-360,366-373,396-400,406-407,412-419,425-426,430,433-435,438-439,441,443-455,458-464,469-473,475-476,479,504-505,509-516,524-528,531-534,538-539,543-545,550-553,557-561,568-571,574-584,587-591,594,597-598,607-625,631-635,650-689,692-716,718',
    'y': '1-18,21-36,39-45,50-52,54-55,59-76,79-85,90-95,98-105,108,111-112,115-119,122-124,128-137,142-150,161-172,174,179-189,193-199,202,206-227,230,235,238,241,246-248,263-264,270-272,276-284,290-303,307-321,324-330,333-342,352-354,358-360,366-373,396-400,406-407,412-419,425-426,430,433-435,438-439,441,443-455,458-464,469-473,475-476,479,504-505,509-516,524-528,531-534,538,543-545,550-553,557-561,568-571,574-584,587-591,594,597-598,607-625,631-635,650-683,686-691,694-715,717-718',
    'legends_arceus': '25,35-38,41-42,46-48,54-55,60,63-68,72-74,81-82,92-95,108,111-114,119,122-123,125-126,129-130,133-138,143,155-156,160,169,172-173,175-176,184-185,190,193,196-198,200-201,207-208,212,214-217,220-221,223-224,226,233-234,239-240,242,265-269,280-282,299,315,339-340,355-356,358,361-365,387-493,501-502,548,627,641-642,645,700,704,712,722-723,899-905',
  };

  static const Set<int> _letsGoEeveeExclusives = {
    23, 24, 37, 38, 52, 53, 69, 70, 71, 109, 110, 127,
  };
  static const Set<int> _letsGoPikachuExclusives = {
    27, 28, 43, 44, 45, 56, 57, 58, 59, 88, 89, 123,
  };
  static const Set<int> _tradeEvolutionsInLetsGo = {65, 68, 76, 94};
  static const Set<int> _leafGreenExclusivesInFireRed = {
    27, 28, 37, 38, 69, 70, 71, 79, 80, 120, 121, 126, 127,
    183, 184, 199, 200, 215, 223, 224, 226, 240, 298,
  };
  static const Set<int> _fireRedExclusivesInLeafGreen = {
    23, 24, 43, 44, 45, 54, 55, 58, 59, 90, 91, 123, 125,
    182, 194, 195, 198, 211, 212, 225, 227, 239,
  };
  static const Set<int> _fireRedPostGameSpecies = {
    182, 194, 195, 198, 211, 212, 225, 227, 239,
  };
  static const Set<int> _leafGreenPostGameSpecies = {
    183, 184, 199, 200, 215, 223, 224, 226, 240, 298,
  };
  static const Set<int> _tradeEvolutionsInFireredLeafgreen = {65, 68, 76, 94};

  static bool supports(String gameId) =>
      gameId == 'lets_go_pikachu' ||
      gameId == 'lets_go_eevee' ||
      gameId == 'firered' ||
      gameId == 'leafgreen' ||
      gameId == 'sword' ||
      _ranges.containsKey(gameId) ||
      gameId == 'xy';

  static bool hasVerifiedData(String gameId) =>
      gameId != 'sword' && supports(gameId);

  static bool _regionalContains(String gameId, int nationalDex) {
    final encoded = gameId == 'xy'
        ? '${_ranges['x']},${_ranges['y']}'
        : _ranges[gameId];
    if (encoded == null) return false;
    for (final part in encoded.split(',')) {
      final bounds = part.split('-');
      final start = int.parse(bounds.first);
      final end = bounds.length == 2 ? int.parse(bounds.last) : start;
      if (nationalDex >= start && nationalDex <= end) return true;
    }
    return false;
  }

  static TeamPokemonAvailability forPokemon(String gameId, int nationalDex) {
    if (nationalDex <= 0) {
      return const TeamPokemonAvailability(
        TeamAvailabilityKind.notInGame, 'Nieprawidłowy numer', 'Numer Pokédexu musi być dodatni.',
      );
    }

    if (gameId == 'firered' || gameId == 'leafgreen') {
      if (nationalDex == 151 || nationalDex == 386) {
        return const TeamPokemonAvailability(
          TeamAvailabilityKind.specialAccess, 'Wydarzenie specjalne',
          'Mew i Deoxys wymagają historycznego przedmiotu/eventu; nie są zwykłymi spotkaniami.',
        );
      }
      final oppositeVersionExclusives = gameId == 'firered'
          ? _leafGreenExclusivesInFireRed
          : _fireRedExclusivesInLeafGreen;
      if (oppositeVersionExclusives.contains(nationalDex)) {
        return TeamPokemonAvailability(
          TeamAvailabilityKind.tradeRequired,
          gameId == 'firered' ? 'Wymaga wymiany z LeafGreen' : 'Wymaga wymiany z FireRed',
          'Gatunek jest ekskluzywny dla drugiej wersji FireRed/LeafGreen.',
        );
      }
      final postGameSpecies = gameId == 'firered'
          ? _fireRedPostGameSpecies
          : _leafGreenPostGameSpecies;
      if (postGameSpecies.contains(nationalDex)) {
        if (_tradeEvolutionsInFireredLeafgreen.contains(nationalDex) ||
            nationalDex == 212 || nationalDex == 199) {
          return const TeamPokemonAvailability(
            TeamAvailabilityKind.tradeRequired, 'Ewolucja przez wymianę',
            'Ten gatunek wymaga wymiany w FireRed/LeafGreen.',
          );
        }
        if (nationalDex == 239 || nationalDex == 240 || nationalDex == 298) {
          return const TeamPokemonAvailability(
            TeamAvailabilityKind.breedingRequired, 'Wymaga hodowli',
            'Ten gatunek uzyskuje się przez hodowlę po odblokowaniu odpowiednich obszarów.',
          );
        }
        return const TeamPokemonAvailability(
          TeamAvailabilityKind.postGame, 'Dostępny po fabule',
          'Ten gatunek jest dostępny po odblokowaniu obszarów Sevii Islands.',
        );
      }
      if (_tradeEvolutionsInFireredLeafgreen.contains(nationalDex)) {
        return const TeamPokemonAvailability(
          TeamAvailabilityKind.tradeRequired, 'Ewolucja przez wymianę',
          'Ten etap ewolucji wymaga wymiany w FireRed/LeafGreen.',
        );
      }
      if (nationalDex >= 1 && nationalDex <= 150) {
        return TeamPokemonAvailability(
          TeamAvailabilityKind.inGame,
          gameId == 'firered' ? 'Dostępny w FireRed' : 'Dostępny w LeafGreen',
          'Gatunek występuje w tej wersji; miejsce i metoda zależą od gatunku.',
        );
      }
      return const TeamPokemonAvailability(
        TeamAvailabilityKind.outsideRegionalDex, 'Poza regionalnym Pokédexem',
        'Brak potwierdzenia dla zwykłej rozgrywki. Może wymagać innej gry, wymiany lub eventu.',
      );
    }

    if (gameId == 'sword') {
      return const TeamPokemonAvailability(
        TeamAvailabilityKind.unknown, 'Brak zweryfikowanej listy',
        'Dla Sword nie mamy jeszcze kompletnej listy Galar, Isle of Armor i Crown Tundra. Wybór ręczny nie potwierdza dostępności.',
      );
    }

    if (gameId == 'lets_go_pikachu' || gameId == 'lets_go_eevee') {
      if (nationalDex == 151) {
        return const TeamPokemonAvailability(
          TeamAvailabilityKind.specialAccess, 'Specjalny dostęp',
          'Mew wymaga Poké Ball Plus; nie jest zwykłym spotkaniem w grze.',
        );
      }
      if (nationalDex == 808 || nationalDex == 809) {
        return const TeamPokemonAvailability(
          TeamAvailabilityKind.specialAccess, 'Transfer z Pokémon GO',
          'Meltan i Melmetal trafiają do Let’s Go przez połączenie z Pokémon GO.',
        );
      }
      if (nationalDex < 1 || nationalDex > 150) {
        return const TeamPokemonAvailability(
          TeamAvailabilityKind.notInGame, 'Poza grą',
          'Let’s Go obsługuje gatunki Kanto oraz Meltan i Melmetal.',
        );
      }
      final oppositeExclusive = gameId == 'lets_go_pikachu'
          ? _letsGoEeveeExclusives
          : _letsGoPikachuExclusives;
      if (oppositeExclusive.contains(nationalDex)) {
        return const TeamPokemonAvailability(
          TeamAvailabilityKind.tradeRequired, 'Wymaga wymiany',
          'Gatunek jest wersjo-ekskluzywny w drugiej wersji Let’s Go.',
        );
      }
      if (_tradeEvolutionsInLetsGo.contains(nationalDex)) {
        return const TeamPokemonAvailability(
          TeamAvailabilityKind.tradeRequired, 'Ewolucja przez wymianę',
          'Ten etap ewolucji wymaga wymiany w Let’s Go.',
        );
      }
      return const TeamPokemonAvailability(
        TeamAvailabilityKind.inGame, 'Dostępny w grze',
        'Gatunek występuje w tej wersji; szczegóły miejsca i etapu gry nie są tu rozpisane.',
      );
    }

    if (!supports(gameId)) {
      return const TeamPokemonAvailability(
        TeamAvailabilityKind.unknown, 'Brak danych',
        'Nie mamy jeszcze wiarygodnego zestawienia dla tej gry.',
      );
    }
    if (_regionalContains(gameId, nationalDex)) {
      return const TeamPokemonAvailability(
        TeamAvailabilityKind.regionalDex, 'W regionalnym Pokédexie',
        'Gatunek znajduje się na liście regionalnej. Dane nie rozróżniają, czy zdobycie wymaga wymiany, post-game, eventu lub konkretnej metody.',
      );
    }
    return const TeamPokemonAvailability(
      TeamAvailabilityKind.outsideRegionalDex, 'Poza regionalnym Pokédexem',
      'Brak wpisu na używanej liście regionalnej nie dowodzi, że gatunek jest niemożliwy do zdobycia. Sprawdź wymiany, post-game i wydarzenia.',
    );
  }

  static bool contains(String gameId, int nationalDex) =>
      forPokemon(gameId, nationalDex).canBeAdded;
}
