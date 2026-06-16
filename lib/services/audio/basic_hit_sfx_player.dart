import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:taptapdoner/services/audio/sfx_audio_source.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';

abstract final class BasicHitSfxPlayer {
  static const _volume = 0.70;
  static const _minRestartInterval = Duration(milliseconds: 45);
  static final AudioPlayer _player = AudioPlayer();
  static Future<void>? _initFuture;
  static Future<void>? _restartFuture;
  static var _restartRequested = false;
  static var _lastStartedAt = DateTime.fromMillisecondsSinceEpoch(0);
  static var _suppressedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  static var _generation = 0;

  static Future<void> play() async {
    if (_isSuppressed) {
      return;
    }

    _restartRequested = true;
    _restartFuture ??= _drainRestartRequests(_generation);
    await _restartFuture;
  }

  static Future<void> suppressFor(Duration duration) async {
    _generation += 1;
    _restartRequested = false;
    _suppressedUntil = DateTime.now().add(duration);
    try {
      await _player.stop();
    } catch (_) {
      // Basic hit may not have initialized yet.
    }
  }

  static Future<void> _drainRestartRequests(int generation) async {
    try {
      await _ensureReady();
      while (!_isSuppressed && _restartRequested && generation == _generation) {
        _restartRequested = false;
        final elapsed = DateTime.now().difference(_lastStartedAt);
        if (elapsed < _minRestartInterval) {
          await Future<void>.delayed(_minRestartInterval - elapsed);
        }
        if (_isSuppressed || generation != _generation) {
          return;
        }
        await _restart();
      }
    } catch (error, stack) {
      SfxAudioSource.logPlaybackFailure('basic hit', error, stack);
    } finally {
      _restartFuture = null;
      if (!_isSuppressed && _restartRequested) {
        _restartFuture ??= _drainRestartRequests(_generation);
      }
    }
  }

  static bool get _isSuppressed => DateTime.now().isBefore(_suppressedUntil);

  static Future<void> _restart() async {
    try {
      await _player.stop();
    } catch (_) {
      // The first tap can arrive before playback has started.
    }
    await _player.seek(Duration.zero);
    await _player.resume();
    _lastStartedAt = DateTime.now();
  }

  static Future<void> _ensureReady() {
    return _initFuture ??= _initializePlayer();
  }

  static Future<void> _initializePlayer() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setAudioContext(SfxAudioSource.audioContext);
      await _player.setSource(SfxAudioSource.asset(UiAssetPaths.basicHitSound));
      await _player.setVolume(_volume);
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }
}
