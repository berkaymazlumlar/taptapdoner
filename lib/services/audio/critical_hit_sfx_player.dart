import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:taptapdoner/services/audio/sfx_audio_source.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';

final class CriticalHitSfxPlayer {
  CriticalHitSfxPlayer({
    math.Random? random,
    List<String> assetPaths = UiAssetPaths.criticalHitSounds,
    double volume = 0.85,
    int poolSize = 3,
  }) : _random = random ?? math.Random(),
       _assetPaths = List.unmodifiable(assetPaths),
       _volume = volume.clamp(0, 1).toDouble(),
       _poolSize = math.max(1, poolSize);

  final math.Random _random;
  final List<String> _assetPaths;
  final double _volume;
  final int _poolSize;
  final List<AudioPlayer> _players = <AudioPlayer>[];
  Future<void>? _initFuture;
  int _nextPlayerIndex = 0;
  bool _disposed = false;

  Future<void> playRandom() async {
    if (_disposed || _assetPaths.isEmpty) {
      return;
    }

    final assetPath = _assetPaths[_random.nextInt(_assetPaths.length)];
    try {
      await _ensureReady();
      if (_disposed || _players.isEmpty) {
        return;
      }

      final player = _players[_nextPlayerIndex];
      _nextPlayerIndex = (_nextPlayerIndex + 1) % _players.length;
      await player.stop();
      await player.play(
        SfxAudioSource.asset(assetPath),
        ctx: SfxAudioSource.audioContext,
        volume: _volume,
      );
    } catch (error, stack) {
      SfxAudioSource.logPlaybackFailure('critical hit', error, stack);
    }
  }

  Future<void> _ensureReady() {
    return _initFuture ??= _initializePool();
  }

  Future<void> _initializePool() async {
    try {
      for (var index = _players.length; index < _poolSize; index += 1) {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setAudioContext(SfxAudioSource.audioContext);
        await player.setVolume(_volume);
        _players.add(player);
      }
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    final players = List<AudioPlayer>.of(_players);
    _players.clear();
    await Future.wait(players.map((player) => player.dispose()));
  }
}
