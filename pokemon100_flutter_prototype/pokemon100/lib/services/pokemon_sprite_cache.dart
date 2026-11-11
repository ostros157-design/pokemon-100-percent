import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SpriteDownloadResult {
  final int completedPokemon;
  final int failedSprites;

  const SpriteDownloadResult({
    required this.completedPokemon,
    required this.failedSprites,
  });
}

class PokemonSpriteCache {
  // Keep the complete National Pokédex cache instead of the default 200-file limit.
  static final CacheManager manager = CacheManager(
    Config(
      'pokemon100SpriteCache',
      stalePeriod: const Duration(days: 3650),
      maxNrOfCacheObjects: 2500,
    ),
  );

  static final Set<int> _requested = <int>{};
  static const int nationalDexCount = 1025;
  static const int _parallelPokemon = 6;
  static const _base =
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/';

  static String normalUrl(int pokemonId) => '$_base$pokemonId.png';
  static String shinyUrl(int pokemonId) => '${_base}shiny/$pokemonId.png';

  static Future<bool> _ensureCached(String url) async {
    try {
      final cached = await manager.getFileFromCache(url);
      if (cached != null) return true;
      await manager.downloadFile(url);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> prefetchPair(int pokemonId) async {
    if (pokemonId < 1 || pokemonId > nationalDexCount ||
        !_requested.add(pokemonId)) return;
    final results = await Future.wait([
      _ensureCached(normalUrl(pokemonId)),
      _ensureCached(shinyUrl(pokemonId)),
    ]);
    if (!results.every((ok) => ok)) {
      // Retry failed downloads on a later visit.
      _requested.remove(pokemonId);
    }
  }

  /// Downloads normal and Shiny sprites for National Pokédex IDs 1–1025.
  /// Missing or unavailable images are counted and do not stop the batch.
  static Future<SpriteDownloadResult> downloadNationalDex({
    required void Function(int completedPokemon, int totalPokemon, int failedSprites)
        onProgress,
  }) async {
    var completed = 0;
    var failed = 0;
    for (var start = 1; start <= nationalDexCount; start += _parallelPokemon) {
      final end = (start + _parallelPokemon - 1)
          .clamp(1, nationalDexCount);
      await Future.wait([
        for (var id = start; id <= end; id++)
          () async {
            final results = await Future.wait([
              _ensureCached(normalUrl(id)),
              _ensureCached(shinyUrl(id)),
            ]);
            failed += results.where((ok) => !ok).length;
            completed++;
            _requested.add(id);
            onProgress(completed, nationalDexCount, failed);
          }(),
      ]);
    }
    return SpriteDownloadResult(
      completedPokemon: completed,
      failedSprites: failed,
    );
  }
}
