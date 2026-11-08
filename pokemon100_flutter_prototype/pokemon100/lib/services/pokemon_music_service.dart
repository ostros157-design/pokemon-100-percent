import 'package:audioplayers/audioplayers.dart';

import '../data/pokemon_music_data.dart';

/// One app-wide player: playback survives navigation between screens.
class PokemonMusicService {
  PokemonMusicService._();

  static final PokemonMusicService instance = PokemonMusicService._();

  final AudioPlayer player = AudioPlayer();
  double volume = 0.65;
  bool _configured = false;

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

  Future<void> playOrResume() async {
    await configure();
    if (player.state == PlayerState.paused) {
      await player.resume();
    } else if (player.state != PlayerState.playing) {
      await player.play(BytesSource(pokemonOfflineMusicBytes));
    }
  }

  Future<void> pause() => player.pause();
}
