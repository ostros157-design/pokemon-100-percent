import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/pokemon_music_data.dart';

/// One app-wide player: playback survives navigation between screens.
class PokemonMusicService with WidgetsBindingObserver {
  PokemonMusicService._();

  static final PokemonMusicService instance = PokemonMusicService._();

  final AudioPlayer player = AudioPlayer();
  double volume = 0.65;
  Future<void>? _configureFuture;
  bool _observingLifecycle = false;
  bool _resumeAfterLifecyclePause = false;

  static const _autoStartKey = 'pokemon_background_music_autostart';

  Future<void> configure() async {
    if (_configureFuture != null) {
      await _configureFuture;
      return;
    }

    final future = _configurePlayer();
    _configureFuture = future;
    try {
      await future;
    } catch (_) {
      _configureFuture = null;
      rethrow;
    }
  }

  Future<void> _configurePlayer() async {
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(volume);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(_pauseForLifecycle());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_resumeAfterLifecycle());
    }
  }

  Future<void> _pauseForLifecycle() async {
    if (player.state != PlayerState.playing) return;
    _resumeAfterLifecyclePause = true;
    try {
      await player.pause();
    } catch (_) {
      _resumeAfterLifecyclePause = false;
    }
  }

  Future<void> _resumeAfterLifecycle() async {
    if (!_resumeAfterLifecyclePause) return;
    _resumeAfterLifecyclePause = false;
    if (player.state != PlayerState.paused) return;
    try {
      await player.resume();
    } catch (_) {
      // A temporary audio interruption must not prevent the app from opening.
    }
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

  Future<void> playOrResume() async {
    await configure();
    _resumeAfterLifecyclePause = false;
    if (player.state == PlayerState.paused) {
      await player.resume();
    } else if (player.state != PlayerState.playing) {
      await player.play(BytesSource(pokemonOfflineMusicBytes));
    }
  }

  Future<void> pause() async {
    _resumeAfterLifecyclePause = false;
    await player.pause();
  }
}
