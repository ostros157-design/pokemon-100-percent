import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../services/pokemon_music_service.dart';

class PokemonMusicScreen extends StatefulWidget {
  const PokemonMusicScreen({super.key});

  @override
  State<PokemonMusicScreen> createState() => _PokemonMusicScreenState();
}

class _PokemonMusicScreenState extends State<PokemonMusicScreen> {
  final PokemonMusicService _music = PokemonMusicService.instance;
  AudioPlayer get _player => _music.player;
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late double _volume;
  bool _loading = false;
  bool _autoStartEnabled = true;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  bool get _isPlaying => _state == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _volume = _music.volume;
    _state = _player.state;
    _stateSubscription = _player.onPlayerStateChanged.listen((value) {
      if (mounted) setState(() => _state = value);
    });
    _durationSubscription = _player.onDurationChanged.listen((value) {
      if (mounted) setState(() => _duration = value);
    });
    _positionSubscription = _player.onPositionChanged.listen((value) {
      if (mounted) setState(() => _position = value);
    });
    unawaited(_music.configure());
    unawaited(_loadAutoStartSetting());
  }

  Future<void> _loadAutoStartSetting() async {
    final enabled = await _music.getAutoStartEnabled();
    if (mounted) setState(() => _autoStartEnabled = enabled);
  }

  Future<void> _setAutoStartEnabled(bool enabled) async {
    setState(() => _autoStartEnabled = enabled);
    await _music.setAutoStartEnabled(enabled);
  }
  Future<void> _togglePlayback() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (_isPlaying) {
        await _music.pause();
      } else {
        await _music.playOrResume();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się uruchomić muzyki offline.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _time(Duration value) {
    final m = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0;
    final current = _position.inMilliseconds.clamp(0, max.toInt()).toDouble();
    return Scaffold(
      appBar: AppBar(title: const Text('Muzyka Pokémon')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 24),
          Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF283E75), Color(0xFF7654A8), Color(0xFFDB8B78)],
              ),
            ),
            child: const Center(child: Icon(Icons.graphic_eq_rounded, size: 104, color: Colors.white)),
          ),
          const SizedBox(height: 24),
          Text('Pokémon 100% — spokojna podróż', textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Oryginalna melodia • działa całkowicie offline', textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Slider(value: current, max: max, onChanged: _duration == Duration.zero ? null : (value) async {
            await _player.seek(Duration(milliseconds: value.round()));
          }),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_time(_position)), Text(_time(_duration))]),
          const SizedBox(height: 18),
          Center(child: FilledButton.tonalIcon(
            onPressed: _loading ? null : _togglePlayback,
            icon: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
            label: Text(_loading ? 'Uruchamianie…' : _isPlaying ? 'Pauza' : 'Odtwórz'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
          )),
          const SizedBox(height: 24),
          Row(children: [
            const Icon(Icons.volume_down),
            Expanded(child: Slider(value: _volume, onChanged: (value) {
              setState(() => _volume = value);
              unawaited(_music.setVolume(value));
            })),
            const Icon(Icons.volume_up),
          ]),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: _autoStartEnabled,
              onChanged: _setAutoStartEnabled,
              secondary: const Icon(Icons.music_note),
              title: const Text('Automatyczna muzyka w tle'),
              subtitle: const Text('Uruchamiaj melodię po otwarciu aplikacji.'),
            ),
          ),
          const SizedBox(height: 8),
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Icon(Icons.offline_bolt_outlined), SizedBox(width: 12), Expanded(
              child: Text('Utwór jest zapisany wewnątrz aplikacji. Nie używa transmisji danych, nie wymaga konta ani pobierania muzyki.',
                  style: TextStyle(height: 1.45)),
            )],
          ))),
        ],
      ),
    );
  }
}
