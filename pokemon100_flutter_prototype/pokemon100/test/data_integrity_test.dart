import 'package:flutter_test/flutter_test.dart';
import '../lib/data/move_data.dart';
import '../lib/data/pokemon_learnset_data.dart';
import '../lib/data/pokemon_data.dart';

void main() {
  group('Offline Pokédex data', () {
    test('contains 1025 unique National Pokédex entries', () {
      expect(pokemonList.length, 1025);
      final ids = pokemonList.map((pokemon) => pokemon.id).toSet();
      expect(ids.length, pokemonList.length);
      expect(ids, containsAll(<int>[1, 25, 150, 151]));
    });

    test('move catalogue has unique IDs and valid core fields', () {
      expect(moveCatalogue, isNotEmpty);
      expect(moveCatalogue.map((move) => move.id).toSet().length,
          moveCatalogue.length);
      for (final move in moveCatalogue) {
        expect(move.id, greaterThan(0));
        expect(move.name, isNotEmpty);
        expect(move.type, isNotEmpty);
        expect(<String>['physical', 'special', 'status'],
            contains(move.category));
        if (move.power != null) expect(move.power, greaterThanOrEqualTo(0));
        if (move.pp != null) expect(move.pp, greaterThan(0));
        if (move.accuracy != null) {
          expect(move.accuracy, inInclusiveRange(0, 100));
        }
      }
    });

    test('learnset entries parse and label known learning methods', () {
      final entry = PokemonLearnsetEntry.fromJson(<String, dynamic>{
        'pokemonId': 94,
        'moveId': 247,
        'versionGroupId': 8,
        'versionGroup': 'heartgold-soulsilver',
        'methodId': 1,
        'level': 25,
        'order': 3,
      });
      expect(entry.pokemonId, 94);
      expect(entry.moveId, 247);
      expect(entry.versionGroup, 'heartgold-soulsilver');
      expect(entry.level, 25);
      expect(entry.methodLabel, 'Poziom');
      final methodLabels = <int, String>{
        5: 'Specjalny ruch Pikachu',
        6: 'Jajko z Light Ball',
        7: 'Oczyszczenie (Colosseum)',
        8: 'Oczyszczenie (XD)',
        9: 'Zmiana formy',
        10: 'Przypomnienie ruchu',
        11: 'Ponowne nauczenie ruchu',
      };
      for (final method in methodLabels.entries) {
        expect(
          PokemonLearnsetEntry.fromJson(<String, dynamic>{
            'pokemonId': 25,
            'moveId': 1,
            'versionGroupId': 1,
            'methodId': method.key,
          }).methodLabel,
          method.value,
        );
      }
      expect(PokemonLearnsetEntry.fromJson(<String, dynamic>{
        'pokemonId': 1,
        'moveId': 1,
        'versionGroupId': 1,
        'methodId': 99,
      }).methodLabel, 'Metoda #99');
    });

    test('selected games map to their PokéAPI version groups', () {
      expect(
        PokemonLearnsetData.preferredVersionGroupForGame('lets_go_pikachu'),
        'lets-go-pikachu-lets-go-eevee',
      );
      expect(
        PokemonLearnsetData.preferredVersionGroupForGame('lets_go_eevee'),
        'lets-go-pikachu-lets-go-eevee',
      );
      expect(
        PokemonLearnsetData.preferredVersionGroupForGame('sword'),
        'sword-shield',
      );
      expect(
        PokemonLearnsetData.preferredVersionGroupForGame('legends_arceus'),
        'legends-arceus',
      );
      expect(
        PokemonLearnsetData.preferredVersionGroupForGame('emerald'),
        'emerald',
      );
      expect(
        PokemonLearnsetData.preferredVersionGroupForGame('not_a_game'),
        isNull,
      );
      expect(PokemonLearnsetData.preferredVersionGroupForGame(null), isNull);
    });

    test('learnset parser keeps valid rows around malformed data', () {
      final rows = PokemonLearnsetData.parseRows(<dynamic>[
        <String, dynamic>{
          'pokemonId': 25,
          'moveId': 84,
          'versionGroupId': 1,
          'versionGroup': 'red-blue',
          'methodId': 1,
          'level': 9,
        },
        <String, dynamic>{
          'pokemonId': 'invalid',
          'moveId': 85,
          'versionGroupId': 1,
          'methodId': 1,
        },
        'not a learnset row',
        <String, dynamic>{
          'pokemonId': 1,
          'moveId': 33,
          'versionGroupId': 1,
          'methodId': 1,
          'level': 1,
        },
        <String, dynamic>{
          'pokemonId': -2,
          'moveId': 33,
          'versionGroupId': 1,
          'methodId': 1,
        },
      ]);

      expect(rows.map((entry) => entry.pokemonId), <int>[25, 1]);
      expect(() => rows.add(rows.first), throwsUnsupportedError);
      expect(PokemonLearnsetData.parseRows(<dynamic>{}), isEmpty);
    });

    test('learnset index groups entries by Pokémon without mixing species', () {
      const entries = <PokemonLearnsetEntry>[
        PokemonLearnsetEntry(
          pokemonId: 25,
          moveId: 84,
          versionGroupId: 1,
          versionGroup: 'red-blue',
          methodId: 1,
          level: 9,
          order: 1,
        ),
        PokemonLearnsetEntry(
          pokemonId: 25,
          moveId: 85,
          versionGroupId: 2,
          versionGroup: 'gold-silver',
          methodId: 1,
          level: 15,
          order: 2,
        ),
        PokemonLearnsetEntry(
          pokemonId: 1,
          moveId: 33,
          versionGroupId: 1,
          versionGroup: 'red-blue',
          methodId: 1,
          level: 1,
        ),
      ];

      final index = PokemonLearnsetData.indexEntries(entries);
      expect(index.keys, containsAll(<int>[1, 25]));
      expect(index[25]!.map((entry) => entry.moveId), <int>[84, 85]);
      expect(index[1]!.map((entry) => entry.moveId), <int>[33]);
      expect(index[999], isNull);
      expect(() => index[25]!.add(entries.first), throwsUnsupportedError);
    });

    test('move lookup and search filters work offline', () {
      expect(moveById(1)?.name, 'Pound');
      expect(moveById(-1), isNull);

      // Every catalogue row must be reachable by its own ID, including
      // special Shadow moves whose IDs are outside the regular move range.
      for (final move in moveCatalogue) {
        expect(moveById(move.id), same(move));
      }
      expect(moveById(10001)?.name, 'Shadow Rush');

      expect(searchMoves(query: 'thunder').any(
          (move) => move.name.toLowerCase().contains('thunder')), isTrue);
      expect(searchMoves(type: 'fire').every((move) => move.type == 'fire'),
          isTrue);
      expect(searchMoves(category: 'status')
          .every((move) => move.category == 'status'), isTrue);
      expect(() => searchMoves(query: 'thunder').clear(),
          throwsUnsupportedError);
    });
  });
}

