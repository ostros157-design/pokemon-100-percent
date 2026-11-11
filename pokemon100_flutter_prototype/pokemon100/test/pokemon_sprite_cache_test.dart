import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_guide/services/pokemon_sprite_cache.dart';

void main() {
  group('PokemonSpriteCache', () {
    test('covers the 1025 National Pokédex species IDs', () {
      expect(PokemonSpriteCache.nationalDexCount, 1025);
    });

    test('builds matching normal and Shiny PokeAPI sprite URLs', () {
      expect(
        PokemonSpriteCache.normalUrl(25),
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
      );
      expect(
        PokemonSpriteCache.shinyUrl(25),
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/25.png',
      );
    });
  });
}
