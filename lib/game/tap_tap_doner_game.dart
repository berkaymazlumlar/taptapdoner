import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/overlay_ids.dart';
import 'package:taptapdoner/game/components/doner_kitchen_backdrop.dart';

class TapTapDonerGame extends FlameGame {
  TapTapDonerGame({required this.controller});

  final GameController controller;
  final ValueNotifier<int> _fpsListenable = ValueNotifier<int>(0);
  DonerKitchenBackdrop? _backdrop;
  int _frameCount = 0;
  double _fpsSampleElapsed = 0;

  DonerKitchenBackdrop get backdrop => _backdrop!;
  ValueListenable<int> get fpsListenable => _fpsListenable;

  @override
  Future<void> onLoad() async {
    final backdrop = DonerKitchenBackdrop();
    _backdrop = backdrop;
    await add(backdrop);
  }

  @override
  Color backgroundColor() => const Color(0xFF160605);

  @override
  void update(double dt) {
    _trackFps(dt);
    super.update(dt);
  }

  @override
  void onRemove() {
    _fpsListenable.dispose();
    super.onRemove();
  }

  void showExclusiveOverlay(String overlayId) {
    for (final id in OverlayIds.modal) {
      if (id != overlayId) {
        overlays.remove(id);
      }
    }
    overlays.add(overlayId);
  }

  void toggleModal(String overlayId) {
    if (overlays.isActive(overlayId)) {
      overlays.remove(overlayId);
      return;
    }
    showExclusiveOverlay(overlayId);
  }

  void closeModal(String overlayId) {
    overlays.remove(overlayId);
  }

  void _trackFps(double dt) {
    _frameCount += 1;
    _fpsSampleElapsed += dt;
    if (_fpsSampleElapsed < 0.5) {
      return;
    }

    final nextFps = (_frameCount / _fpsSampleElapsed).round();
    if (_fpsListenable.value != nextFps) {
      _fpsListenable.value = nextFps;
    }
    _frameCount = 0;
    _fpsSampleElapsed = 0;
  }
}
