import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pokemon_guide/services/pokemon_music_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('background music autostart defaults to enabled', () async {
    expect(
      await PokemonMusicService.instance.getAutoStartEnabled(),
      isTrue,
    );
  });

  test('autostart preference can be disabled and restored persistently', () async {
    final music = PokemonMusicService.instance;

    await music.setAutoStartEnabled(false);
    expect(await music.getAutoStartEnabled(), isFalse);

    await music.setAutoStartEnabled(true);
    expect(await music.getAutoStartEnabled(), isTrue);
  });
}
