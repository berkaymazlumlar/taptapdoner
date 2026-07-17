import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/overlays/combo_badge.dart';
import 'package:taptapdoner/ui/overlays/customer_order_overlay.dart';
import 'package:taptapdoner/ui/overlays/game_hud_overlay.dart';
import 'package:taptapdoner/ui/overlays/random_event_overlay.dart';
import 'package:taptapdoner/ui/overlays/settings_overlay.dart';
import 'package:taptapdoner/ui/overlays/starter_quest_overlay.dart';
import 'package:taptapdoner/ui/overlays/tap_zone_overlay.dart';
import 'package:taptapdoner/ui/pages/branch_page.dart';
import 'package:taptapdoner/ui/pages/goals_page.dart';
import 'package:taptapdoner/ui/pages/prestige_page.dart';
import 'package:taptapdoner/ui/pages/shop_page.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';
import 'package:taptapdoner/ui/widgets/game_bottom_nav_bar.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class GameShellOverlay extends StatefulWidget {
  const GameShellOverlay({required this.controller, super.key});

  final GameController controller;

  @override
  State<GameShellOverlay> createState() => _GameShellOverlayState();
}

class _GameShellOverlayState extends State<GameShellOverlay> {
  GameBottomNavTab _activeTab = GameBottomNavTab.kitchen;
  bool _settingsVisible = false;
  _ProgressionOverlayPage? _progressionOverlay;

  void _selectTab(GameBottomNavTab tab) {
    if (!mounted || _activeTab == tab) {
      return;
    }
    if (tab == GameBottomNavTab.prestige) {
      widget.controller.markPrestigeScreenOpened();
    }
    _prepareTab(tab);

    setState(() {
      _activeTab = tab;
      _settingsVisible = false;
      _progressionOverlay = null;
    });
  }

  void _prepareTab(GameBottomNavTab tab) {
    switch (tab) {
      case GameBottomNavTab.kitchen:
        widget.controller.prepareKitchenView();
        break;
      case GameBottomNavTab.shop:
        widget.controller.prepareShopView();
        break;
      case GameBottomNavTab.branches:
        widget.controller.prepareBranchView();
        break;
      case GameBottomNavTab.collection:
      case GameBottomNavTab.goals:
      case GameBottomNavTab.chests:
        widget.controller.prepareGoalsView();
        break;
      case GameBottomNavTab.prestige:
        widget.controller.preparePrestigeView();
        break;
    }
  }

  void _openSettings() {
    setState(() {
      _settingsVisible = true;
      _progressionOverlay = null;
    });
  }

  void _closeSettings() {
    setState(() {
      _settingsVisible = false;
    });
  }

  void _openProgressionOverlay(_ProgressionOverlayPage page) {
    widget.controller.prepareGoalsView();
    setState(() {
      _settingsVisible = false;
      _progressionOverlay = page;
    });
  }

  void _closeProgressionOverlay() {
    setState(() {
      _progressionOverlay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final bottomNavInset = RoastedFooterTrayMetrics.height;

    return SizedBox.expand(
      child: ColoredBox(
        color: DonerColors.bgPrimary,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(top: padding.top),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Offstage(
                    offstage: _activeTab != GameBottomNavTab.kitchen,
                    child: TickerMode(
                      enabled: _activeTab == GameBottomNavTab.kitchen,
                      child: _KitchenTabPage(
                        controller: widget.controller,
                        onOpenGoals: () => _openProgressionOverlay(
                          _ProgressionOverlayPage.achievements,
                        ),
                        onOpenChests: () => _openProgressionOverlay(
                          _ProgressionOverlayPage.chests,
                        ),
                        onOpenSettings: _openSettings,
                        bottomInset: bottomNavInset,
                        active: _activeTab == GameBottomNavTab.kitchen,
                      ),
                    ),
                  ),
                  if (_activeTab != GameBottomNavTab.kitchen)
                    _buildActiveTab(bottomInset: bottomNavInset),
                ],
              ),
            ),
            if (_settingsVisible == false && _progressionOverlay == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomNav(),
              ),
            if (kDebugMode)
              Positioned(
                right: 12,
                bottom: bottomNavInset + 12,
                child: _DebugRandomEventButton(
                  onPressed: () {
                    widget.controller.showDebugRandomEvent();
                  },
                ),
              ),
            if (_settingsVisible)
              SettingsOverlay(
                controller: widget.controller,
                onClose: _closeSettings,
              ),
            if (_progressionOverlay case final page?)
              _ProgressionOverlay(
                controller: widget.controller,
                page: page,
                onClose: _closeProgressionOverlay,
              ),
            ValueListenableBuilder<RandomEventSnapshot?>(
              valueListenable: widget.controller.randomEventSnapshotListenable,
              builder: (context, snapshot, _) {
                if (snapshot == null ||
                    _settingsVisible ||
                    _progressionOverlay != null) {
                  return const SizedBox.shrink();
                }
                return RandomEventOverlay(
                  controller: widget.controller,
                  snapshot: snapshot,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab({double bottomInset = 0}) {
    switch (_activeTab) {
      case GameBottomNavTab.kitchen:
        return const SizedBox.shrink();
      case GameBottomNavTab.shop:
        return KeyedSubtree(
          key: const ValueKey('shop-tab-root'),
          child: ShopPage(
            controller: widget.controller,
            onOpenKitchen: () => _selectTab(GameBottomNavTab.kitchen),
            onOpenPrestige: () => _selectTab(GameBottomNavTab.prestige),
            onBack: () => _selectTab(GameBottomNavTab.kitchen),
            bottomInset: bottomInset,
            presentation: ShopPagePresentation.tab,
          ),
        );
      case GameBottomNavTab.branches:
        return KeyedSubtree(
          key: const ValueKey('branches-tab-root'),
          child: BranchPage(
            controller: widget.controller,
            bottomInset: bottomInset,
          ),
        );
      case GameBottomNavTab.goals:
        return KeyedSubtree(
          key: const ValueKey('goals-tab-root'),
          child: GoalsPage(
            controller: widget.controller,
            bottomInset: bottomInset,
          ),
        );
      case GameBottomNavTab.chests:
        return KeyedSubtree(
          key: const ValueKey('chests-tab-root'),
          child: ChestPage(
            controller: widget.controller,
            bottomInset: bottomInset,
          ),
        );
      case GameBottomNavTab.collection:
        return KeyedSubtree(
          key: const ValueKey('collection-tab-root'),
          child: CollectionPage(
            controller: widget.controller,
            bottomInset: bottomInset,
          ),
        );
      case GameBottomNavTab.prestige:
        return KeyedSubtree(
          key: const ValueKey('prestige-tab-root'),
          child: PrestigePage(
            controller: widget.controller,
            onOpenKitchen: () => _selectTab(GameBottomNavTab.kitchen),
            onOpenShop: () => _selectTab(GameBottomNavTab.shop),
            onBack: () => _selectTab(GameBottomNavTab.kitchen),
            onPrestigeApplied: () async {
              _selectTab(GameBottomNavTab.kitchen);
            },
            bottomInset: bottomInset,
            presentation: PrestigePagePresentation.tab,
          ),
        );
    }
  }

  Widget _buildBottomNav() {
    return GameBottomNavBar(
      activeTab: _activeTab,
      onOpenKitchen: () => _selectTab(GameBottomNavTab.kitchen),
      onOpenShop: () => _selectTab(GameBottomNavTab.shop),
      onOpenBranches: () => _selectTab(GameBottomNavTab.branches),
      onOpenCollection: () => _selectTab(GameBottomNavTab.collection),
      onOpenPrestige: () => _selectTab(GameBottomNavTab.prestige),
    );
  }
}

enum _ProgressionOverlayPage { achievements, chests }

class _ProgressionOverlay extends StatelessWidget {
  const _ProgressionOverlay({
    required this.controller,
    required this.page,
    required this.onClose,
  });

  final GameController controller;
  final _ProgressionOverlayPage page;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey('${page.name}-overlay-root'),
      decoration: const BoxDecoration(gradient: DonerGradients.sheet),
      child: switch (page) {
        _ProgressionOverlayPage.achievements => GoalsPage(
          controller: controller,
          onClose: onClose,
        ),
        _ProgressionOverlayPage.chests => ChestPage(
          controller: controller,
          onClose: onClose,
        ),
      },
    );
  }
}

class _MaxComboCinematicOverlay extends StatefulWidget {
  const _MaxComboCinematicOverlay({
    required this.snapshot,
    required this.controller,
  });

  final ActivePlaySnapshot snapshot;
  final GameController controller;

  @override
  State<_MaxComboCinematicOverlay> createState() =>
      _MaxComboCinematicOverlayState();
}

class _MaxComboCinematicOverlayState extends State<_MaxComboCinematicOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();
  final List<_CinematicHit> _hits = <_CinematicHit>[];
  int _nextHitId = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDonerTap() async {
    final outcome = await widget.controller.tap();
    if (!mounted) return;
    final id = _nextHitId++;
    setState(() {
      _hits.add(
        _CinematicHit(
          id: id,
          amount: outcome.coins,
          isCritical: outcome.isCritical,
          slicePath:
              UiAssetPaths.tapDonerSlices[_random.nextInt(
                UiAssetPaths.tapDonerSlices.length,
              )],
          drift: (_random.nextDouble() - 0.5) * 150,
          rotation: (_random.nextDouble() - 0.5) * 1.4,
        ),
      );
    });
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted) setState(() => _hits.removeWhere((hit) => hit.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final donerSize = math.min(screenSize.width * 0.78, 330.0);
    final verticalOffset = screenSize.height * 0.055;
    final comboScale = math.min(screenSize.width / 390, 1.0);

    return SizedBox.expand(
      child: ColoredBox(
        key: const ValueKey('max-combo-total-blackout'),
        color: Colors.black,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final angle = _controller.value * math.pi * 2;
            final pulse = (math.sin(angle * 2) + 1) / 2;
            final colorMix = (math.sin(angle * 0.82) + 1) / 2;
            final shake = Offset(
              math.sin(angle * 3.3) * 4.2,
              math.cos(angle * 4.7) * 2.8,
            );
            final glowColor = Color.lerp(
              const Color(0xFF168CFF),
              const Color(0xFFD62CFF),
              colorMix,
            )!;

            return Transform.translate(
              offset: Offset(0, verticalOffset),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (var index = 0; index < 10; index++)
                    Positioned(
                      key: ValueKey('max-combo-money-rain-$index'),
                      left:
                          ((index * 83.0) % screenSize.width) -
                          20 +
                          (math.sin(angle + index) * 16),
                      top:
                          (((_controller.value + (index / 10)) % 1.0) *
                              (screenSize.height + 150)) -
                          110,
                      child: Opacity(
                        opacity: 0.42 + ((index % 3) * 0.12),
                        child: Transform.rotate(
                          angle: angle * (index.isEven ? 0.32 : -0.25) + index,
                          child: Image.asset(
                            UiAssetPaths.moneyRainBills[index %
                                UiAssetPaths.moneyRainBills.length],
                            width: 48 + ((index % 3) * 9),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: CustomPaint(
                      key: const ValueKey('max-combo-light-rays'),
                      painter: _MaxComboLightPainter(
                        phase: _controller.value,
                        center: Offset(
                          screenSize.width / 2,
                          (screenSize.height / 2) - verticalOffset,
                        ),
                        radius: donerSize * (0.50 + (pulse * 0.06)),
                      ),
                    ),
                  ),
                  Container(
                    width: donerSize * (1.04 + pulse * 0.09),
                    height: donerSize * (1.16 + pulse * 0.11),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.98),
                          const Color(0xFFA8DEFF).withValues(alpha: 0.68),
                          glowColor.withValues(alpha: 0.32),
                          glowColor.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.15, 0.42, 0.72, 1],
                      ),
                    ),
                  ),
                  SizedBox.square(
                    dimension: donerSize * 1.28,
                    child: CustomPaint(
                      key: const ValueKey('max-combo-orbiting-light-arcs'),
                      painter: _MaxComboOrbitPainter(
                        phase: _controller.value,
                        hitEnergy: _hits.isEmpty ? 0 : 1,
                        criticalFlash: _hits.any((hit) => hit.isCritical),
                      ),
                    ),
                  ),
                  Transform.translate(
                    key: const ValueKey('max-combo-doner-shake'),
                    offset: shake,
                    child: Transform.rotate(
                      angle: math.sin(angle * 2.9) * 0.022,
                      child: Container(
                        width: donerSize,
                        height: donerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.34),
                              glowColor.withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.54, 1],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.82),
                              blurRadius: 34 + pulse * 22,
                              spreadRadius: 1 + pulse * 3,
                            ),
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.78),
                              blurRadius: 68 + pulse * 32,
                              spreadRadius: 3 + pulse * 5,
                            ),
                          ],
                        ),
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (_) => unawaited(_handleDonerTap()),
                          child: Padding(
                            padding: EdgeInsets.all(donerSize * 0.015),
                            child: Image.asset(
                              UiAssetPaths.tapDoner,
                              key: const ValueKey('max-combo-glowing-doner'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final hit in _hits) ...[
                    TweenAnimationBuilder<Offset>(
                      key: ValueKey('max-combo-slice-${hit.id}'),
                      tween: Tween(
                        begin: Offset.zero,
                        end: Offset(hit.drift, 250),
                      ),
                      duration: const Duration(milliseconds: 820),
                      curve: Curves.easeInQuad,
                      builder: (context, offset, child) => Transform.translate(
                        offset: offset,
                        child: Transform.rotate(
                          angle: hit.rotation,
                          child: child,
                        ),
                      ),
                      child: Image.asset(
                        hit.slicePath,
                        width: donerSize * 0.20,
                      ),
                    ),
                    TweenAnimationBuilder<Offset>(
                      key: ValueKey('max-combo-hit-${hit.id}'),
                      tween: Tween(
                        begin: const Offset(65, 5),
                        end: const Offset(75, -80),
                      ),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, offset, child) =>
                          Transform.translate(offset: offset, child: child),
                      child: Text(
                        '${hit.isCritical ? 'CRITICAL! ' : ''}+${formatClickCurrency(context, hit.amount)}',
                        style: DonerTypography.display(
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: hit.isCritical
                                ? Colors.white
                                : DonerColors.goldBright,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: hit.isCritical
                                    ? const Color(0xFFB64CFF)
                                    : const Color(0xFF168CFF),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  Positioned(
                    top: math.max(36.0, screenSize.height * 0.09),
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: ComboBadge(
                          key: const ValueKey('max-combo-visible-badge'),
                          snapshot: widget.snapshot,
                          scale: comboScale,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CinematicHit {
  const _CinematicHit({
    required this.id,
    required this.amount,
    required this.isCritical,
    required this.slicePath,
    required this.drift,
    required this.rotation,
  });

  final int id;
  final dynamic amount;
  final bool isCritical;
  final String slicePath;
  final double drift;
  final double rotation;
}

class _MaxComboOrbitPainter extends CustomPainter {
  const _MaxComboOrbitPainter({
    required this.phase,
    required this.hitEnergy,
    required this.criticalFlash,
  });

  final double phase;
  final double hitEnergy;
  final bool criticalFlash;

  static const _colors = [
    Color(0xFF36A8FF),
    Color(0xFFFFFFFF),
    Color(0xFFC44BFF),
    Color(0xFF8AD8FF),
    Color(0xFFFFFFFF),
    Color(0xFF8B45FF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide * 0.405;
    final speedBoost = 1 + (hitEnergy * 0.7);

    _drawOrbitLayer(
      canvas,
      center,
      radius: baseRadius,
      rotation: phase * math.pi * 2 * 0.72 * speedBoost,
      direction: 1,
      count: 16,
      strokeWidth: 2.4,
      alpha: 0.94,
    );
    _drawOrbitLayer(
      canvas,
      center,
      radius: baseRadius * 1.12,
      rotation: phase * math.pi * 2 * 0.43 * speedBoost,
      direction: -1,
      count: 11,
      strokeWidth: 1.45,
      alpha: 0.70,
    );
    _drawSparks(canvas, center, baseRadius);
  }

  void _drawOrbitLayer(
    Canvas canvas,
    Offset center, {
    required double radius,
    required double rotation,
    required double direction,
    required int count,
    required double strokeWidth,
    required double alpha,
  }) {
    for (var index = 0; index < count; index++) {
      final angle =
          rotation * direction +
          (index * math.pi * 2 / count) +
          (math.sin((phase * math.pi * 2) + index) * 0.08);
      final rayDirection = Offset(math.cos(angle), math.sin(angle));
      final lineLength = radius * (0.12 + ((index % 4) * 0.035));
      final innerRadius = radius * (0.92 + ((index % 3) * 0.025));
      final start = center + rayDirection * innerRadius;
      final end = start + rayDirection * lineLength;
      final shimmer =
          0.62 +
          (((math.sin(phase * math.pi * 4 + index * 1.7) + 1) / 2) * 0.38);
      final color = criticalFlash
          ? Colors.white
          : _colors[index % _colors.length];
      final visibleColor = color.withValues(alpha: alpha * shimmer);

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = visibleColor.withValues(alpha: visibleColor.a * 0.62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 4.2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = visibleColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + (hitEnergy * 0.7)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawSparks(Canvas canvas, Offset center, double radius) {
    for (var index = 0; index < 7; index++) {
      final sparkPhase = (phase * (0.75 + index * 0.035) + index / 7) % 1;
      final angle = sparkPhase * math.pi * 2 * (index.isEven ? 1 : -1);
      final distance = radius * (1.02 + ((index % 3) * 0.09));
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final color = criticalFlash
          ? Colors.white
          : _colors[(index + 2) % _colors.length];
      canvas.drawCircle(
        position,
        1.4 + ((index % 2) * 0.8) + (hitEnergy * 0.7),
        Paint()
          ..color = color.withValues(alpha: 0.72)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MaxComboOrbitPainter oldDelegate) =>
      phase != oldDelegate.phase ||
      hitEnergy != oldDelegate.hitEnergy ||
      criticalFlash != oldDelegate.criticalFlash;
}

class _MaxComboLightPainter extends CustomPainter {
  const _MaxComboLightPainter({
    required this.phase,
    required this.center,
    required this.radius,
  });

  final double phase;
  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFF168CFF),
      Color(0xFFFFFFFF),
      Color(0xFFD62CFF),
      Color(0xFF76C8FF),
      Color(0xFFFFFFFF),
      Color(0xFF9A32FF),
    ];
    for (var index = 0; index < colors.length; index++) {
      final rayAngle =
          (phase * math.pi * 2 * (index.isEven ? 0.42 : -0.34)) +
          (index * math.pi / 3);
      final direction = Offset(math.cos(rayAngle), math.sin(rayAngle));
      final perpendicular = Offset(-direction.dy, direction.dx);
      final inner = radius * 0.42;
      final outer = radius * (1.38 + ((index % 2) * 0.22));
      final halfWidth = radius * (0.055 + ((index % 3) * 0.018));
      final path = Path()
        ..moveTo(
          center.dx + direction.dx * inner + perpendicular.dx * halfWidth,
          center.dy + direction.dy * inner + perpendicular.dy * halfWidth,
        )
        ..lineTo(
          center.dx + direction.dx * outer,
          center.dy + direction.dy * outer,
        )
        ..lineTo(
          center.dx + direction.dx * inner - perpendicular.dx * halfWidth,
          center.dy + direction.dy * inner - perpendicular.dy * halfWidth,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            center + direction * inner,
            center + direction * outer,
            [colors[index].withValues(alpha: 0.72), Colors.transparent],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MaxComboLightPainter oldDelegate) =>
      phase != oldDelegate.phase ||
      center != oldDelegate.center ||
      radius != oldDelegate.radius;
}

class _DebugRandomEventButton extends StatelessWidget {
  const _DebugRandomEventButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DonerColors.panelDark.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DonerColors.tealBright, width: 1.1),
        boxShadow: DonerShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('debug-random-event-button'),
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  DonerIcons.info,
                  size: 12,
                  color: DonerColors.tealBright,
                ),
                const SizedBox(width: 6),
                Text(
                  'Event',
                  style: DonerTypography.body(
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: DonerColors.creamText,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KitchenTabPage extends StatefulWidget {
  const _KitchenTabPage({
    required this.controller,
    required this.onOpenGoals,
    required this.onOpenChests,
    required this.onOpenSettings,
    required this.bottomInset,
    required this.active,
  });

  final GameController controller;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenChests;
  final VoidCallback onOpenSettings;
  final double bottomInset;
  final bool active;

  @override
  State<_KitchenTabPage> createState() => _KitchenTabPageState();
}

class _KitchenTabPageState extends State<_KitchenTabPage> {
  late final TapTapDonerGame _game;
  bool _questPanelVisible = false;

  @override
  void initState() {
    super.initState();
    _game = TapTapDonerGame(controller: widget.controller);
    if (!widget.active) {
      _game.pauseEngine();
    }
  }

  @override
  void didUpdateWidget(covariant _KitchenTabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) {
      return;
    }
    if (widget.active) {
      _game.resumeEngine();
    } else {
      _game.pauseEngine();
    }
  }

  void _toggleQuestPanel() {
    setState(() {
      _questPanelVisible = !_questPanelVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _ShellMetrics.fromContext(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        GameWidget<TapTapDonerGame>(game: _game),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameHudOverlay(
              controller: widget.controller,
              onOpenGoals: widget.onOpenGoals,
              onOpenSettings: widget.onOpenSettings,
            ),
            SizedBox(height: 6 * metrics.scale),
            CustomerOrderOverlay(controller: widget.controller),
            SizedBox(height: metrics.mainTopGap),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: TapZoneOverlay(
                      controller: widget.controller,
                      game: _game,
                      applySafeArea: false,
                    ),
                  ),
                  Positioned(
                    top: metrics.questPanelTopInset,
                    right: metrics.questButtonSideInset,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      reverseDuration: const Duration(milliseconds: 130),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.92,
                              end: 1,
                            ).animate(animation),
                            alignment: Alignment.topRight,
                            child: child,
                          ),
                        );
                      },
                      child: _questPanelVisible
                          ? StarterQuestOverlay(
                              key: const ValueKey('starter-quest-panel-open'),
                              controller: widget.controller,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('starter-quest-panel-closed'),
                            ),
                    ),
                  ),
                  Positioned(
                    top: metrics.questButtonTopInset,
                    right: metrics.questButtonSideInset,
                    child: ValueListenableBuilder<QuestSnapshot?>(
                      valueListenable:
                          widget.controller.questSnapshotListenable,
                      builder: (context, snapshot, _) {
                        return ValueListenableBuilder<GoalBoardSnapshot>(
                          valueListenable:
                              widget.controller.goalSnapshotListenable,
                          builder: (context, goalSnapshot, _) {
                            final hasDailyGoals =
                                goalSnapshot.dailyGoals.isNotEmpty;
                            final canClaimDaily = goalSnapshot.dailyGoals.any(
                              (goal) => goal.canClaim,
                            );
                            return QuestShortcutButton(
                              scale: metrics.scale,
                              enabled: snapshot != null || hasDailyGoals,
                              active: _questPanelVisible,
                              canClaim:
                                  (snapshot?.canClaim ?? false) ||
                                  canClaimDaily,
                              onPressed: snapshot != null || hasDailyGoals
                                  ? _toggleQuestPanel
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (!_questPanelVisible)
                    Positioned(
                      top: metrics.chestButtonTopInset,
                      right: metrics.questButtonSideInset,
                      child: ChestShortcutButton(
                        scale: metrics.scale,
                        onPressed: widget.onOpenChests,
                      ),
                    ),
                  Positioned(
                    left: metrics.progressionPopupSideInset,
                    right: metrics.progressionPopupSideInset,
                    bottom: metrics.progressionPopupBottomInset,
                    child: _AchievementPopup(
                      controller: widget.controller,
                      scale: metrics.scale,
                    ),
                  ),
                  Positioned(
                    top: metrics.comboTopInset,
                    left: 0,
                    right: 0,
                    child: ValueListenableBuilder<ActivePlaySnapshot>(
                      valueListenable:
                          widget.controller.activePlaySnapshotListenable,
                      builder: (context, snapshot, _) {
                        return IgnorePointer(
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              reverseDuration: const Duration(
                                milliseconds: 210,
                              ),
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    ...previousChildren,
                                    ?currentChild,
                                  ],
                                );
                              },
                              transitionBuilder: _activeBadgeTransition,
                              child: snapshot.hasCombo
                                  ? ComboBadge(
                                      key: const ValueKey(
                                        'combo-badge-visible',
                                      ),
                                      snapshot: snapshot,
                                      scale: metrics.scale,
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('combo-badge-hidden'),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: metrics.activeEffectsSideInset,
                    bottom: metrics.activeEffectsBottomInset,
                    child: ValueListenableBuilder<ActivePlaySnapshot>(
                      valueListenable:
                          widget.controller.activePlaySnapshotListenable,
                      builder: (context, snapshot, _) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          reverseDuration: const Duration(milliseconds: 170),
                          transitionBuilder: _activeBadgeTransition,
                          child: snapshot.activeEffects.isNotEmpty
                              ? _ActiveEffectsPanel(
                                  key: const ValueKey('active-effects-panel'),
                                  effects: snapshot.activeEffects,
                                  scale: metrics.scale,
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('active-effects-hidden'),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: widget.bottomInset),
          ],
        ),
      ],
    );
  }
}

Widget _activeBadgeTransition(Widget child, Animation<double> animation) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  );
  final fade = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  return FadeTransition(
    opacity: fade,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.16),
        end: Offset.zero,
      ).animate(curved),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
        child: child,
      ),
    ),
  );
}

class _ActiveEffectsPanel extends StatefulWidget {
  const _ActiveEffectsPanel({
    required this.effects,
    required this.scale,
    super.key,
  });

  final List<ActiveEffectSnapshot> effects;
  final double scale;

  @override
  State<_ActiveEffectsPanel> createState() => _ActiveEffectsPanelState();
}

class _ActiveEffectsPanelState extends State<_ActiveEffectsPanel> {
  bool _positiveExpanded = false;
  bool _negativeExpanded = false;

  @override
  Widget build(BuildContext context) {
    final positive = widget.effects
        .where((effect) => effect.isPositive)
        .toList(growable: false);
    final negative = widget.effects
        .where((effect) => !effect.isPositive)
        .toList(growable: false);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 176 * widget.scale),
      child: Column(
        key: const ValueKey('active-effects-panel-column'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (positive.isNotEmpty)
            _ActiveEffectGroup(
              key: const ValueKey('active-effects-positive-group'),
              title: 'Avantajlar',
              effects: positive,
              expanded: _positiveExpanded,
              positive: true,
              scale: widget.scale,
              onToggle: () {
                setState(() {
                  _positiveExpanded = !_positiveExpanded;
                });
              },
            ),
          if (positive.isNotEmpty && negative.isNotEmpty)
            SizedBox(height: 6 * widget.scale),
          if (negative.isNotEmpty)
            _ActiveEffectGroup(
              key: const ValueKey('active-effects-negative-group'),
              title: 'Dezavantajlar',
              effects: negative,
              expanded: _negativeExpanded,
              positive: false,
              scale: widget.scale,
              onToggle: () {
                setState(() {
                  _negativeExpanded = !_negativeExpanded;
                });
              },
            ),
        ],
      ),
    );
  }
}

class _ActiveEffectGroup extends StatelessWidget {
  const _ActiveEffectGroup({
    required this.title,
    required this.effects,
    required this.expanded,
    required this.positive,
    required this.scale,
    required this.onToggle,
    super.key,
  });

  final String title;
  final List<ActiveEffectSnapshot> effects;
  final bool expanded;
  final bool positive;
  final double scale;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final accent = positive ? DonerColors.tealBright : DonerColors.orangeAccent;
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF22110E).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(color: accent.withValues(alpha: 0.78), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10 * scale,
              offset: Offset(0, 4 * scale),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey(
                  positive
                      ? 'active-effects-positive-toggle'
                      : 'active-effects-negative-toggle',
                ),
                borderRadius: BorderRadius.circular(8 * scale),
                onTap: onToggle,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * scale,
                    vertical: 6 * scale,
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        positive
                            ? DonerIcons.positiveEffect
                            : DonerIcons.negativeEffect,
                        color: accent,
                        size: 12 * scale,
                      ),
                      SizedBox(width: 6 * scale),
                      Expanded(
                        child: Text(
                          '$title (${effects.length})',
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DonerTypography.body(
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: DonerColors.creamText,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5 * scale,
                              letterSpacing: 0,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0 : -0.25,
                        duration: const Duration(milliseconds: 160),
                        child: FaIcon(
                          DonerIcons.expand,
                          color: accent,
                          size: 11 * scale,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: EdgeInsets.fromLTRB(
                  6 * scale,
                  0,
                  6 * scale,
                  6 * scale,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final effect in effects) ...[
                      _ActiveEffectBadge(
                        key: ValueKey(
                          effect.id == 'passive_boost'
                              ? 'active-income-boost-badge'
                              : 'active-effect-badge-${effect.id}',
                        ),
                        effect: effect,
                        scale: scale,
                      ),
                      if (effect != effects.last) SizedBox(height: 4 * scale),
                    ],
                  ],
                ),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 160),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveEffectBadge extends StatelessWidget {
  const _ActiveEffectBadge({
    required this.effect,
    required this.scale,
    super.key,
  });

  final ActiveEffectSnapshot effect;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final timer = formatShortDuration(effect.remaining);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 3 * scale),
      child: Row(
        children: [
          Expanded(
            child: Text(
              effect.label,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DonerTypography.body(
                Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: DonerColors.creamText,
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5 * scale,
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
          Text(
            timer,
            key: ValueKey(
              effect.id == 'passive_boost'
                  ? 'active-income-boost-timer'
                  : 'active-effect-timer-${effect.id}',
            ),
            maxLines: 1,
            style: DonerTypography.body(
              Theme.of(context).textTheme.labelSmall?.copyWith(
                color: DonerColors.goldBright,
                fontWeight: FontWeight.w900,
                fontSize: 10.5 * scale,
                letterSpacing: 0,
                height: 1,
              ),
            ),
          ),
        ],
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

  double get mainTopGap => 10 * scale;
  double get questButtonTopInset => 8 * scale;
  double get questButtonSideInset => 22 * scale;
  double get questPanelTopInset => questButtonTopInset + (64 * scale);
  double get chestButtonTopInset => questButtonTopInset + (64 * scale);
  double get progressionPopupSideInset => 22 * scale;
  double get progressionPopupBottomInset => 12 * scale;
  double get comboTopInset => 4 * scale;
  double get activeEffectsSideInset => 12 * scale;
  double get activeEffectsBottomInset => 12 * scale;
}

class _AchievementPopup extends StatefulWidget {
  const _AchievementPopup({required this.controller, required this.scale});

  final GameController controller;
  final double scale;

  @override
  State<_AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<_AchievementPopup> {
  static const _autoClaimDelay = Duration(seconds: 4);

  Timer? _autoClaimTimer;
  String? _scheduledAchievementId;

  @override
  void initState() {
    super.initState();
    widget.controller.progressionSnapshotListenable.addListener(
      _syncAutoClaimTimer,
    );
    _syncAutoClaimTimer();
  }

  @override
  void didUpdateWidget(covariant _AchievementPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.progressionSnapshotListenable.removeListener(
      _syncAutoClaimTimer,
    );
    _autoClaimTimer?.cancel();
    _scheduledAchievementId = null;
    widget.controller.progressionSnapshotListenable.addListener(
      _syncAutoClaimTimer,
    );
    _syncAutoClaimTimer();
  }

  @override
  void dispose() {
    widget.controller.progressionSnapshotListenable.removeListener(
      _syncAutoClaimTimer,
    );
    _autoClaimTimer?.cancel();
    super.dispose();
  }

  void _syncAutoClaimTimer() {
    final achievementId = widget
        .controller
        .progressionSnapshotListenable
        .value
        .latestClaimableAchievement
        ?.id;
    if (achievementId == null) {
      _autoClaimTimer?.cancel();
      _autoClaimTimer = null;
      _scheduledAchievementId = null;
      return;
    }
    if (_scheduledAchievementId == achievementId &&
        _autoClaimTimer?.isActive == true) {
      return;
    }
    _autoClaimTimer?.cancel();
    _scheduledAchievementId = achievementId;
    _autoClaimTimer = Timer(_autoClaimDelay, () {
      unawaited(widget.controller.claimAchievementReward(achievementId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgressionSnapshot>(
      valueListenable: widget.controller.progressionSnapshotListenable,
      builder: (context, snapshot, _) {
        final achievement = snapshot.latestClaimableAchievement;
        if (achievement == null) {
          return const SizedBox.shrink();
        }
        return DecoratedBox(
          key: const ValueKey('achievement-popup-card'),
          decoration: BoxDecoration(
            gradient: DonerGradients.activeButton,
            borderRadius: BorderRadius.circular(8 * widget.scale),
            border: Border.all(color: DonerColors.goldBright, width: 1.4),
            boxShadow: DonerShadows.soft,
          ),
          child: Padding(
            padding: EdgeInsets.all(10 * widget.scale),
            child: Row(
              children: [
                FaIcon(
                  DonerIcons.goals,
                  color: DonerColors.creamText,
                  size: 18 * widget.scale,
                ),
                SizedBox(width: 8 * widget.scale),
                Expanded(
                  child: Text(
                    achievement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DonerTypography.body(
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: DonerColors.creamText,
                        fontWeight: FontWeight.w900,
                        fontSize: 12 * widget.scale,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  key: ValueKey('achievement-popup-claim-${achievement.id}'),
                  onPressed: () =>
                      widget.controller.claimAchievementReward(achievement.id),
                  child: Text(AppStrings.of(context).claimLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
