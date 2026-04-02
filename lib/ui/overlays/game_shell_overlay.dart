import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/ui/overlays/action_dock_overlay.dart';
import 'package:taptapdoner/ui/overlays/game_hud_overlay.dart';
import 'package:taptapdoner/ui/overlays/tap_zone_overlay.dart';

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
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return _BottomNavBar(
                  scale: metrics.scale,
                  onOpenShop: onOpenShop,
                  onOpenPrestige: onOpenPrestige,
                );
              },
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

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.scale,
    required this.onOpenShop,
    required this.onOpenPrestige,
  });

  final double scale;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPrestige;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(48 * scale);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2D1B14),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30 * scale,
              offset: Offset(0, -12 * scale),
            ),
          ],
        ),
        child: SizedBox(
          key: const ValueKey('bottom-nav-shell'),
          height: 96 * scale,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: _ActiveKitchenPill(
                    key: const ValueKey('bottom-nav-kitchen-button'),
                    scale: scale,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _NavItem(
                    key: const ValueKey('bottom-nav-shop-button'),
                    scale: scale,
                    icon: Icons.storefront_rounded,
                    label: 'Shop',
                    onTap: onOpenShop,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _NavItem(
                    key: const ValueKey('bottom-nav-prestige-button'),
                    scale: scale,
                    icon: Icons.workspace_premium_rounded,
                    label: 'Prestige',
                    onTap: onOpenPrestige,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveKitchenPill extends StatelessWidget {
  const _ActiveKitchenPill({required this.scale, super.key});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -2 * scale),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          15 * scale,
          10 * scale,
          15 * scale,
          11 * scale,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9C400), Color(0xFFFFB870)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE9C400).withValues(alpha: 0.35),
              blurRadius: 18 * scale,
              offset: Offset(0, 8 * scale),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_rounded,
              color: const Color(0xFF2D1B14),
              size: 26 * scale,
            ),
            SizedBox(height: 1.5 * scale),
            Text(
              'Kitchen',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFamily: 'Be Vietnam Pro',
                color: const Color(0xFF2D1B14),
                fontWeight: FontWeight.w900,
                fontSize: 9.5 * scale,
                letterSpacing: 1.4,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.scale,
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final double scale;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFFE0C0B4).withValues(alpha: 0.6),
              size: 28 * scale,
            ),
            SizedBox(height: 4 * scale),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFamily: 'Be Vietnam Pro',
                color: const Color(0xFFE0C0B4).withValues(alpha: 0.6),
                fontWeight: FontWeight.w900,
                fontSize: 10 * scale,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
