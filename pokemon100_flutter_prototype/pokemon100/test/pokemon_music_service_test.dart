import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pokemon_guide/services/pokemon_music_service.dart';

class _FakeAudioPlayer extends AudioPlayer {
  PlayerState _state = PlayerState.stopped;
  ReleaseMode? configuredReleaseMode;
  double? configuredVolume;
  int playCount = 0;
  int resumeCount = 0;
  int pauseCount = 0;

  void simulateInterruption() {
    _state = PlayerState.paused;
  }

  @override
  PlayerState get state => _state;

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {
    configuredReleaseMode = releaseMode;
  }

  @override
  Future<void> setVolume(double volume) async {
    configuredVolume = volume;
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    playCount++;
    _state = PlayerState.playing;
  }

  @override
  Future<void> resume() async {
    resumeCount++;
    _state = PlayerState.playing;
  }

  @override
  Future<void> pause() async {
    pauseCount++;
    _state = PlayerState.paused;
  }
}

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
    final music = PokemonMusicService.forTesting(_FakeAudioPlayer());

    await music.setAutoStartEnabled(false);
    expect(await music.getAutoStartEnabled(), isFalse);

    await music.setAutoStartEnabled(true);
    expect(await music.getAutoStartEnabled(), isTrue);
  });

  test('configures looping and reuses one player instead of restarting on navigation', () async {
    final player = _FakeAudioPlayer();
    final music = PokemonMusicService.forTesting(player);

    await music.configure();
    expect(player.configuredReleaseMode, ReleaseMode.loop);
    expect(player.configuredVolume, 0.65);

    await music.playOrResume();
    await music.playOrResume();

    expect(player.playCount, 1);
    expect(music.isPlaying, isTrue);
  });

  test('resumes an interrupted track but respects an explicit in-app pause', () async {
    final player = _FakeAudioPlayer();
    final music = PokemonMusicService.forTesting(player);

    await music.playOrResume();
    player.simulateInterruption();
    await music.resumeIfInterrupted();
    expect(player.resumeCount, 1);

    await music.pause();
    expect(player.pauseCount, 1);
    await music.resumeIfInterrupted();
    expect(player.resumeCount, 1);

    await music.playOrResume();
    expect(player.resumeCount, 2);
  });

  test('autostart disabled prevents playback until the user enables it', () async {
    final player = _FakeAudioPlayer();
    final music = PokemonMusicService.forTesting(player);

    await music.setAutoStartEnabled(false);
    await music.startIfEnabled();
    expect(player.playCount, 0);

    await music.setAutoStartEnabled(true);
    await music.startIfEnabled();
    expect(player.playCount, 1);
  });
}
