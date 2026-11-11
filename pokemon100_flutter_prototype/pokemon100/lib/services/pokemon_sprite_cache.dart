import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PokemonSpriteCache {
  static final Set<int> _requested = <int>{};
  static const _base = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/';

  static Future<void> prefetchPair(int pokemonId) async {
    if (pokemonId < 1 || !_requested.add(pokemonId)) return;
    try {
      await Future.wait([
        DefaultCacheManager().downloadFile('$_base$pokemonId.png'),
        DefaultCacheManager().downloadFile('$_base' 'shiny/$pokemonId.png'),
      ]);
    } catch (_) {
      // The visible normal sprite still renders through CachedNetworkImage;
      // a failed background Shiny prefetch can be retried after app restart.
      _requested.remove(pokemonId);
    }
  }
}
