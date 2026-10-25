import 'package:flutter_test/flutter_test.dart';
import '../lib/data/move_data.dart';
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

    test('move lookup and search filters work offline', () {
      expect(moveById(1)?.name, 'Pound');
      expect(moveById(-1), isNull);
      expect(searchMoves(query: 'thunder').any(
          (move) => move.name.toLowerCase().contains('thunder')), isTrue);
      expect(searchMoves(type: 'fire').every((move) => move.type == 'fire'),
          isTrue);
      expect(searchMoves(category: 'status')
          .every((move) => move.category == 'status'), isTrue);
    });
  });
}

