import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pokemon_guide/services/pokemon_music_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('autostart defaults to enabled and the setting persists', () async {
    final music = PokemonMusicService.instance;

    expect(await music.getAutoStartEnabled(), isTrue);

    await music.setAutoStartEnabled(false);
    expect(await music.getAutoStartEnabled(), isFalse);

    await music.setAutoStartEnabled(true);
    expect(await music.getAutoStartEnabled(), isTrue);
  });

  test('disabled autostart does not start or configure the audio player',
      () async {
    final music = PokemonMusicService.instance;
    await music.setAutoStartEnabled(false);

    await expectLater(music.startIfEnabled(), completes);
    expect(await music.getAutoStartEnabled(), isFalse);
  });
}
