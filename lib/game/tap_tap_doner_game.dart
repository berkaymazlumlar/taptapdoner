import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/overlay_ids.dart';
import 'package:taptapdoner/game/components/doner_kitchen_backdrop.dart';

class TapTapDonerGame extends FlameGame {
  TapTapDonerGame({required this.controller});

  final GameController controller;
  DonerKitchenBackdrop? _backdrop;

  DonerKitchenBackdrop get backdrop => _backdrop!;

  @override
  Future<void> onLoad() async {
    final backdrop = DonerKitchenBackdrop();
    _backdrop = backdrop;
    await add(backdrop);
  }

  @override
  Color backgroundColor() => const Color(0xFF160605);

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
}
