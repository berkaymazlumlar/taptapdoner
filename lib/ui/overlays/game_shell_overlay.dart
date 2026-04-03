import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/ui/overlays/action_dock_overlay.dart';
import 'package:taptapdoner/ui/overlays/game_hud_overlay.dart';
import 'package:taptapdoner/ui/overlays/tap_zone_overlay.dart';
import 'package:taptapdoner/ui/widgets/game_bottom_nav_bar.dart';

class GameShellOverlay extends StatelessWidget {
  const GameShellOverlay({
    required this.controller,
    required this.game,
    required this.onOpenShop,
    required this.onOpenPrestige,
    required this.onOpenSettings,
    super.key,
  });

  final GameController controller;
  final TapTapDonerGame game;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPrestige;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final metrics = _ShellMetrics.fromContext(context);
    final padding = MediaQuery.paddingOf(context);

    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameHudOverlay(
              controller: controller,
              onOpenSettings: onOpenSettings,
            ),
            SizedBox(height: metrics.mainTopGap),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: TapZoneOverlay(
                      controller: controller,
                      game: game,
                      applySafeArea: false,
                    ),
                  ),
                  Positioned(
                    top: metrics.rushButtonTopInset,
                    right: metrics.rushButtonSideInset,
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        return RushShortcutButton(
                          scale: metrics.scale,
                          enabled: controller.canStartRush,
                          onPressed: controller.canStartRush
                              ? () => controller.startRush()
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: metrics.mainBottomGap),
            ActionDockOverlay(controller: controller),
            GameBottomNavBar(
              activeTab: GameBottomNavTab.kitchen,
              onOpenKitchen: () {},
              onOpenShop: onOpenShop,
              onOpenPrestige: onOpenPrestige,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellMetrics {
  const _ShellMetrics({required this.scale});

  factory _ShellMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = math.min(size.width / 390.0, size.height / 884.0);
    return _ShellMetrics(scale: scale);
  }

  final double scale;

  double get mainTopGap => 32 * scale;
  double get mainBottomGap => 0;
  double get rushButtonTopInset => 10 * scale;
  double get rushButtonSideInset => 24 * scale;
}
