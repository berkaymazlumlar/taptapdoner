import 'package:audioplayers/audioplayers.dart';
import 'package:taptapdoner/services/audio/sfx_audio_source.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';

abstract final class PurchaseSfxPlayer {
  static const _volume = 0.82;
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play() async {
    try {
      await _player.stop();
    } catch (_) {
      // The first purchase can arrive before the player has an active source.
    }

    try {
      await _player.play(
        SfxAudioSource.asset(UiAssetPaths.buySound),
        ctx: SfxAudioSource.audioContext,
        volume: _volume,
      );
    } catch (error, stack) {
      SfxAudioSource.logPlaybackFailure('purchase', error, stack);
    }
  }
}
