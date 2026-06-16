import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract final class SfxAudioSource {
  static final AudioContext audioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  static AssetSource asset(String assetPath) {
    return AssetSource(
      _assetSourceKey(assetPath),
      mimeType: _mimeType(assetPath),
    );
  }

  static void logPlaybackFailure(String label, Object error, StackTrace stack) {
    if (!kDebugMode) {
      return;
    }

    debugPrint('SFX playback failed for $label: $error');
    debugPrintStack(stackTrace: stack);
  }

  static String _assetSourceKey(String assetPath) {
    const assetPrefix = 'assets/';
    if (assetPath.startsWith(assetPrefix)) {
      return assetPath.substring(assetPrefix.length);
    }

    return assetPath;
  }

  static String? _mimeType(String assetPath) {
    final lowerPath = assetPath.toLowerCase();
    if (lowerPath.endsWith('.mp3')) {
      return 'audio/mpeg';
    }
    if (lowerPath.endsWith('.m4a')) {
      return 'audio/mp4';
    }
    if (lowerPath.endsWith('.wav')) {
      return 'audio/wav';
    }

    return null;
  }
}
