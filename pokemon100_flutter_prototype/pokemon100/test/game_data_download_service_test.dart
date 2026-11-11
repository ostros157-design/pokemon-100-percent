import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_guide/services/game_data_download_service.dart';

void main() {
  group('GameDataDownloadService package catalog', () {
    test('contains all 22 selectable main-series game entries', () {
      expect(GameDataDownloadService.packages, hasLength(22));
    });

    test('game identifiers are unique', () {
      final ids = GameDataDownloadService.packages.map((item) => item.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('each package points to a regional map JSON asset', () {
      for (final item in GameDataDownloadService.packages) {
        expect(item.assetPath, startsWith('assets/data/maps/'));
        expect(item.assetPath, endsWith('_audit.json'));
        expect(item.fileName, item.assetPath.split('/').last);
      }
    });
  });
}
