import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pokemon_music_data.dart';

/// One app-wide player: playback survives navigation between screens.
class PokemonMusicService {
  PokemonMusicService._();

  static final PokemonMusicService instance = PokemonMusicService._();

  final AudioPlayer player = AudioPlayer();
  double volume = 0.65;
  bool _configured = false;
  bool _userPaused = false;
  static const _autoStartKey = 'pokemon_background_music_autostart';

  Future<void> configure() async {
    if (_configured) return;
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(volume);
    _configured = true;
  }

  Future<void> setVolume(double value) async {
    volume = value.clamp(0.0, 1.0).toDouble();
    await player.setVolume(volume);
  }

  Future<bool> getAutoStartEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_autoStartKey) ?? true;
  }

  Future<void> setAutoStartEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_autoStartKey, enabled);
  }

  Future<void> startIfEnabled() async {
    if (await getAutoStartEnabled()) await playOrResume();
  }

  bool get isPlaying => player.state == PlayerState.playing;

  Future<void> resumeIfInterrupted() async {
    if (_userPaused || isPlaying) return;
    await playOrResume();
  }

  Future<void> playOrResume() async {
    _userPaused = false;
    await configure();
    if (player.state == PlayerState.paused) {
      await player.resume();
    } else if (player.state != PlayerState.playing) {
      await player.play(BytesSource(pokemonOfflineMusicBytes));
    }
  }

  Future<void> pause() async {
    _userPaused = true;
    await player.pause();
  }
}
