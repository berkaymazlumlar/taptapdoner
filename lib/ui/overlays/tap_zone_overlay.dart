import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/l10n/locale_case.dart';
import 'package:taptapdoner/services/audio/basic_hit_sfx_player.dart';
import 'package:taptapdoner/services/audio/critical_hit_sfx_player.dart';
import 'package:taptapdoner/ui/layout/responsive_layout_spec.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class TapZoneOverlay extends StatefulWidget {
  const TapZoneOverlay({
    required this.controller,
    required this.game,
    this.applySafeArea = true,
    super.key,
  });

  final GameController controller;
  final TapTapDonerGame game;
  final bool applySafeArea;

  @override
  State<TapZoneOverlay> createState() => _TapZoneOverlayState();
}

class _TapZoneOverlayState extends State<TapZoneOverlay>
    with TickerProviderStateMixin {
  static const _tapVisualScale = 1.30;
  static const _tapBurstLifetime = Duration(milliseconds: 280);
  static const _tapBurstFadeDuration = Duration(milliseconds: 90);
  static const _tapScaleResetDuration = Duration(milliseconds: 110);
  static const _maxComboAuraDuration = Duration(milliseconds: 780);
  static const _fallingSliceTravelDuration = Duration(milliseconds: 820);
  static const _fallingSliceFadeDuration = Duration(milliseconds: 220);
  static const _maxActiveTapBursts = 12;
  static const _maxActiveFallingSlices = 14;
  static const _tapBurstSpawnRightFactor = 0.23;
  static const _tapBurstSpawnDownFactor = 0.04;
  static const _tapBurstMinLeftPaddingFactor = 0.28;
  static const _sliceSpawnDownFactor = 0.18;
  static const _sliceMaxTravelAngleTangent = 0.5773502692; // tan(30deg)
  static const _sliceMovementCurve = Curves.easeInQuad;

  final _random = math.Random();
  double _scale = 1;
  int _nextTapBurstId = 0;
  final List<_TapBurstEntry> _tapBursts = [];
  final Set<int> _pendingRisingTapBurstIds = <int>{};
  int _nextFallingSliceId = 0;
  final List<_FallingSliceEntry> _fallingSlices = [];
  final Set<int> _pendingFallingSliceIds = <int>{};
  int? _activeTapPointerId;
  late final AnimationController _maxComboAuraController;
  late final CriticalHitSfxPlayer _criticalHitSfxPlayer;
  Timer? _scaleResetTimer;
  bool _hasScheduledTapBurstRise = false;
  bool _hasScheduledFallingSliceFall = false;
  bool _isMaxComboActive = false;
  bool _didPrecacheFallingSlices = false;

  @override
  void initState() {
    super.initState();
    _maxComboAuraController = AnimationController(
      vsync: this,
      duration: _maxComboAuraDuration,
    );
    _criticalHitSfxPlayer = CriticalHitSfxPlayer();
    widget.controller.activePlaySnapshotListenable.addListener(
      _handleActivePlayUpdate,
    );
    _syncMaxComboAura(force: true);
  }

  @override
  void didUpdateWidget(covariant TapZoneOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.activePlaySnapshotListenable.removeListener(
      _handleActivePlayUpdate,
    );
    widget.controller.activePlaySnapshotListenable.addListener(
      _handleActivePlayUpdate,
    );
    _syncMaxComboAura(force: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheFallingSlices) {
      return;
    }

    _didPrecacheFallingSlices = true;
    unawaited(precacheImage(const AssetImage(UiAssetPaths.tapDoner), context));
    for (final assetPath in UiAssetPaths.tapDonerSlices) {
      unawaited(precacheImage(AssetImage(assetPath), context));
    }
  }

  @override
  void dispose() {
    widget.controller.activePlaySnapshotListenable.removeListener(
      _handleActivePlayUpdate,
    );
    _scaleResetTimer?.cancel();
    _maxComboAuraController.dispose();
    unawaited(_criticalHitSfxPlayer.dispose());
    super.dispose();
  }

  void _handleActivePlayUpdate() {
    _syncMaxComboAura();
  }

  void _syncMaxComboAura({bool force = false}) {
    final snapshot = widget.controller.activePlaySnapshotListenable.value;
    final shouldAnimate =
        snapshot.hasCombo &&
        snapshot.comboMultiplier >= widget.controller.config.comboMaxMultiplier;
    if (!force && shouldAnimate == _isMaxComboActive) {
      return;
    }

    _isMaxComboActive = shouldAnimate;
    if (shouldAnimate) {
      _maxComboAuraController.repeat();
    } else {
      _maxComboAuraController
        ..stop()
        ..value = 0;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handleTapTargetPointerDown(
    PointerDownEvent event,
    double squareSize,
    double tapTargetSize,
  ) {
    if (_activeTapPointerId != null) {
      return;
    }
    _activeTapPointerId = event.pointer;
    unawaited(
      _handleTap(
        tapPosition: event.localPosition,
        squareSize: squareSize,
        tapTargetSize: tapTargetSize,
      ),
    );
  }

  void _handleTapTargetPointerEnd(PointerEvent event) {
    if (_activeTapPointerId != event.pointer) {
      return;
    }
    _activeTapPointerId = null;
  }

  Future<void> _handleTap({
    required Offset tapPosition,
    required double squareSize,
    required double tapTargetSize,
  }) async {
    _enqueueFallingSlice(tapPosition, squareSize, tapTargetSize);
    _pulseTapTarget();
    final outcome = await widget.controller.tap();
    if (!mounted) {
      return;
    }

    if (outcome.isCritical) {
      unawaited(
        BasicHitSfxPlayer.suppressFor(const Duration(milliseconds: 520)),
      );
      unawaited(_criticalHitSfxPlayer.playRandom());
    } else {
      unawaited(BasicHitSfxPlayer.play());
    }

    _enqueueTapBurst(
      outcome,
      tapPosition,
      squareSize,
      tapTargetSize,
      type: outcome.isCritical ? _TapBurstType.critical : _TapBurstType.normal,
    );
  }

  void _pulseTapTarget() {
    _scaleResetTimer?.cancel();
    if (_scale != 0.95) {
      setState(() => _scale = 0.95);
    }

    _scaleResetTimer = Timer(_tapScaleResetDuration, () {
      if (!mounted || _scale == 1) {
        return;
      }
      setState(() => _scale = 1);
    });
  }

  void _enqueueTapBurst(
    TapOutcome outcome,
    Offset tapPosition,
    double squareSize,
    double tapTargetSize, {
    required _TapBurstType type,
  }) {
    final id = _nextTapBurstId++;
    final effectOrigin = _offsetEffectOrigin(
      tapPosition,
      tapTargetSize,
      Offset(
        squareSize * _tapBurstSpawnRightFactor,
        squareSize * _tapBurstSpawnDownFactor,
      ),
      minX: squareSize * _tapBurstMinLeftPaddingFactor,
    );
    final entry = _TapBurstEntry(
      id: id,
      value: outcome.coins,
      type: type,
      origin: effectOrigin,
      riseDistance: squareSize * (0.08 + (_random.nextDouble() * 0.03)),
    );

    setState(() {
      _tapBursts.add(entry);
      if (_tapBursts.length > _maxActiveTapBursts) {
        _tapBursts.removeRange(0, _tapBursts.length - _maxActiveTapBursts);
      }
    });

    _pendingRisingTapBurstIds.add(id);
    _scheduleTapBurstRise();
    unawaited(_expireTapBurst(id));
  }

  void _scheduleTapBurstRise() {
    if (_hasScheduledTapBurstRise) {
      return;
    }

    _hasScheduledTapBurstRise = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasScheduledTapBurstRise = false;
      if (!mounted) {
        _pendingRisingTapBurstIds.clear();
        return;
      }
      if (_pendingRisingTapBurstIds.isEmpty) {
        return;
      }

      final pendingIds = Set<int>.of(_pendingRisingTapBurstIds);
      _pendingRisingTapBurstIds.clear();
      final hasPendingEntries = _tapBursts.any(
        (entry) => pendingIds.contains(entry.id) && !entry.isRising,
      );
      if (!hasPendingEntries) {
        return;
      }

      setState(() {
        for (var index = 0; index < _tapBursts.length; index += 1) {
          final entry = _tapBursts[index];
          if (!pendingIds.contains(entry.id) || entry.isRising) {
            continue;
          }

          _tapBursts[index] = entry.copyWith(isRising: true);
        }
      });
    });
  }

  Future<void> _expireTapBurst(int id) async {
    await Future<void>.delayed(_tapBurstLifetime - _tapBurstFadeDuration);
    if (!mounted) {
      return;
    }

    final entryIndex = _tapBursts.indexWhere((entry) => entry.id == id);
    if (entryIndex == -1) {
      return;
    }

    setState(() {
      _tapBursts[entryIndex] = _tapBursts[entryIndex].copyWith(
        isFadingOut: true,
      );
    });

    await Future<void>.delayed(_tapBurstFadeDuration);
    if (!mounted) {
      return;
    }

    setState(() {
      _tapBursts.removeWhere((entry) => entry.id == id);
    });
  }

  void _enqueueFallingSlice(
    Offset tapPosition,
    double squareSize,
    double tapTargetSize,
  ) {
    final id = _nextFallingSliceId++;
    final initialRotationTurns = (_random.nextDouble() - 0.5) * 0.22;
    final rotationDirection = _random.nextBool() ? 1.0 : -1.0;
    final verticalTravel = squareSize * (0.32 + (_random.nextDouble() * 0.18));
    final horizontalDrift =
        verticalTravel *
        ((_random.nextDouble() * 2) - 1) *
        _sliceMaxTravelAngleTangent;
    final effectOrigin = _offsetEffectOrigin(
      tapPosition,
      tapTargetSize,
      Offset(0, squareSize * _sliceSpawnDownFactor),
    );
    final entry = _FallingSliceEntry(
      id: id,
      assetPath: UiAssetPaths
          .tapDonerSlices[_random.nextInt(UiAssetPaths.tapDonerSlices.length)],
      origin: effectOrigin,
      size: squareSize * (0.17 + (_random.nextDouble() * 0.08)),
      horizontalDrift: horizontalDrift,
      fallDistance: verticalTravel,
      initialRotationTurns: initialRotationTurns,
      rotationTurns:
          initialRotationTurns +
          (rotationDirection * (0.22 + (_random.nextDouble() * 0.62))),
      startScale: 0.90 + (_random.nextDouble() * 0.24),
      endScale: 0.58 + (_random.nextDouble() * 0.42),
      movementCurve: _sliceMovementCurve,
    );

    setState(() {
      _fallingSlices.add(entry);
      if (_fallingSlices.length > _maxActiveFallingSlices) {
        _fallingSlices.removeRange(
          0,
          _fallingSlices.length - _maxActiveFallingSlices,
        );
      }
    });

    _pendingFallingSliceIds.add(id);
    _scheduleFallingSlices();
    unawaited(_expireFallingSlice(id));
  }

  void _scheduleFallingSlices() {
    if (_hasScheduledFallingSliceFall) {
      return;
    }

    _hasScheduledFallingSliceFall = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasScheduledFallingSliceFall = false;
      if (!mounted) {
        _pendingFallingSliceIds.clear();
        return;
      }
      if (_pendingFallingSliceIds.isEmpty) {
        return;
      }

      final pendingIds = Set<int>.of(_pendingFallingSliceIds);
      _pendingFallingSliceIds.clear();
      final hasPendingEntries = _fallingSlices.any(
        (entry) => pendingIds.contains(entry.id) && !entry.isFalling,
      );
      if (!hasPendingEntries) {
        return;
      }

      setState(() {
        for (var index = 0; index < _fallingSlices.length; index += 1) {
          final entry = _fallingSlices[index];
          if (!pendingIds.contains(entry.id) || entry.isFalling) {
            continue;
          }

          _fallingSlices[index] = entry.copyWith(isFalling: true);
        }
      });
    });
  }

  Future<void> _expireFallingSlice(int id) async {
    await Future<void>.delayed(
      _fallingSliceTravelDuration - _fallingSliceFadeDuration,
    );
    if (!mounted) {
      return;
    }

    final entryIndex = _fallingSlices.indexWhere((entry) => entry.id == id);
    if (entryIndex == -1) {
      return;
    }

    setState(() {
      _fallingSlices[entryIndex] = _fallingSlices[entryIndex].copyWith(
        isFadingOut: true,
      );
    });

    await Future<void>.delayed(_fallingSliceFadeDuration);
    if (!mounted) {
      return;
    }

    setState(() {
      _fallingSlices.removeWhere((entry) => entry.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final spec = ResponsiveLayoutSpec.fromSize(size);
        final squareSize = _squareSize(size, spec);
        final tapTargetSize = squareSize * _tapVisualScale;
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final tapImageCacheWidth = (tapTargetSize * devicePixelRatio).round();
        final tapBurstFontSize = math.min(38.0, squareSize * 0.118);
        final tapBurstStrokeStyle = DonerTypography.display(
          Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: tapBurstFontSize,
            height: 0.90,
            letterSpacing: -0.5,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(2.4, tapBurstFontSize * 0.09)
              ..color = DonerColors.panelDark.withValues(alpha: 0.95),
          ),
        );
        final tapBurstFillStyle = DonerTypography.display(
          Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: DonerColors.goldBright,
            fontWeight: FontWeight.w900,
            fontSize: tapBurstFontSize,
            height: 0.90,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: DonerColors.goldPrimary.withValues(alpha: 0.75),
                blurRadius: 18,
                offset: const Offset(0, 3),
              ),
              Shadow(
                color: const Color(0xFFFFF0A8).withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 0),
              ),
              Shadow(
                color: DonerColors.panelDark.withValues(alpha: 0.65),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
        final criticalTapBurstFillStyle = tapBurstFillStyle.copyWith(
          color: const Color(0xFFFFF6DD),
          fontSize: tapBurstFontSize * 1.12,
          letterSpacing: -0.3,
          shadows: [
            Shadow(
              color: const Color(0xFFFFF0B5).withValues(alpha: 0.90),
              blurRadius: 24,
              offset: const Offset(0, 0),
            ),
            Shadow(
              color: DonerColors.goldPrimary.withValues(alpha: 0.72),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            Shadow(
              color: DonerColors.orangeAccent.withValues(alpha: 0.48),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
            Shadow(
              color: DonerColors.panelDark.withValues(alpha: 0.45),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
        return Padding(
          padding: EdgeInsets.fromLTRB(
            spec.pagePadding,
            spec.sectionGap,
            spec.pagePadding,
            spec.sectionGap,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                key: const ValueKey('tap-zone-flame-aura'),
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE8B35A).withValues(alpha: 0.30),
                      const Color(0xFFD97A24).withValues(alpha: 0.10),
                      const Color(0x00160605),
                    ],
                    stops: const [0.0, 0.58, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DonerColors.goldPrimary.withValues(alpha: 0.10),
                      blurRadius: 40,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: RepaintBoundary(
                  child: SizedBox.square(
                    key: const ValueKey('tap-zone-target'),
                    dimension: tapTargetSize,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        IgnorePointer(
                          child: SizedBox.square(
                            key: const ValueKey('tap-zone-square'),
                            dimension: squareSize,
                          ),
                        ),
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _maxComboAuraController,
                            builder: (context, child) {
                              final angle =
                                  _maxComboAuraController.value * math.pi * 2;
                              final shakeX = _isMaxComboActive
                                  ? math.sin(angle * 3.1) * 3.2
                                  : 0.0;
                              final shakeY = _isMaxComboActive
                                  ? math.cos(angle * 4.3) * 2.1
                                  : 0.0;
                              final shakeRotation = _isMaxComboActive
                                  ? math.sin(angle * 2.7) * 0.018
                                  : 0.0;
                              return Transform.translate(
                                key: const ValueKey('tap-zone-max-combo-shake'),
                                offset: Offset(shakeX, shakeY),
                                child: Transform.rotate(
                                  angle: shakeRotation,
                                  child: child,
                                ),
                              );
                            },
                            child: AnimatedScale(
                              scale: _scale,
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOutBack,
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: (event) =>
                                    _handleTapTargetPointerDown(
                                      event,
                                      squareSize,
                                      tapTargetSize,
                                    ),
                                onPointerUp: _handleTapTargetPointerEnd,
                                onPointerCancel: _handleTapTargetPointerEnd,
                                child: IgnorePointer(
                                  child: Center(
                                    child: Image.asset(
                                      key: const ValueKey('tap-zone-callout'),
                                      UiAssetPaths.tapDoner,
                                      fit: BoxFit.contain,
                                      cacheWidth: tapImageCacheWidth,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (final slice in _fallingSlices)
                                  Positioned(
                                    key: ValueKey(
                                      'tap-zone-falling-slice-position-${slice.id}',
                                    ),
                                    left: slice.origin.dx - (slice.size / 2),
                                    top: slice.origin.dy - (slice.size / 2),
                                    child: TweenAnimationBuilder<Offset>(
                                      key: ValueKey(
                                        'tap-zone-falling-slice-travel-${slice.id}',
                                      ),
                                      tween: Tween<Offset>(
                                        begin: Offset.zero,
                                        end: slice.isFalling
                                            ? Offset(
                                                slice.horizontalDrift,
                                                slice.fallDistance,
                                              )
                                            : Offset.zero,
                                      ),
                                      duration: _fallingSliceTravelDuration,
                                      curve: slice.movementCurve,
                                      builder: (context, offset, child) {
                                        return Transform.translate(
                                          key: ValueKey(
                                            'tap-zone-falling-slice-${slice.id}',
                                          ),
                                          offset: offset,
                                          child: child,
                                        );
                                      },
                                      child: AnimatedOpacity(
                                        opacity: slice.isFadingOut ? 0 : 1,
                                        duration: _fallingSliceFadeDuration,
                                        curve: Curves.easeIn,
                                        child: AnimatedRotation(
                                          turns: slice.isFalling
                                              ? slice.rotationTurns
                                              : slice.initialRotationTurns,
                                          duration: _fallingSliceTravelDuration,
                                          curve: slice.movementCurve,
                                          child: AnimatedScale(
                                            scale: slice.isFalling
                                                ? slice.endScale
                                                : slice.startScale,
                                            duration:
                                                _fallingSliceTravelDuration,
                                            curve: slice.movementCurve,
                                            child: SizedBox.square(
                                              dimension: slice.size,
                                              child: Image.asset(
                                                slice.assetPath,
                                                fit: BoxFit.contain,
                                                cacheWidth:
                                                    (slice.size *
                                                            devicePixelRatio)
                                                        .round(),
                                                filterQuality:
                                                    FilterQuality.low,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                for (
                                  var index = 0;
                                  index < _tapBursts.length;
                                  index++
                                )
                                  () {
                                    final burst = _tapBursts[index];
                                    final burstKeyBase = index == 0
                                        ? 'tap-zone-cash-splash'
                                        : 'tap-zone-cash-splash-${burst.id}';

                                    return Positioned(
                                      key: ValueKey(
                                        'tap-zone-cash-splash-position-${burst.id}',
                                      ),
                                      left: burst.origin.dx,
                                      top: burst.origin.dy,
                                      child: TweenAnimationBuilder<Offset>(
                                        key: ValueKey(
                                          'tap-zone-cash-splash-rise-${burst.id}',
                                        ),
                                        tween: Tween<Offset>(
                                          begin: Offset.zero,
                                          end: burst.isRising
                                              ? Offset(0, -burst.riseDistance)
                                              : Offset.zero,
                                        ),
                                        duration: _tapBurstLifetime,
                                        curve: Curves.easeOut,
                                        builder: (context, offset, child) {
                                          return Transform.translate(
                                            key: ValueKey(
                                              'tap-zone-cash-splash-${burst.id}',
                                            ),
                                            offset: offset,
                                            child: child,
                                          );
                                        },
                                        child: AnimatedOpacity(
                                          key: index == 0
                                              ? const ValueKey(
                                                  'tap-zone-cash-splash',
                                                )
                                              : null,
                                          opacity: burst.isFadingOut ? 0 : 1,
                                          duration: _tapBurstFadeDuration,
                                          curve: Curves.easeIn,
                                          child: FractionalTranslation(
                                            translation: const Offset(
                                              -0.5,
                                              -0.5,
                                            ),
                                            child: _TapBurstAnimatedEntry(
                                              entry: burst,
                                              keyBase: burstKeyBase,
                                              child: _TapBurstLabel(
                                                text: _tapBurstText(
                                                  context,
                                                  burst,
                                                ),
                                                fillStyle: _tapBurstFillStyle(
                                                  burst.type,
                                                  normal: tapBurstFillStyle,
                                                  critical:
                                                      criticalTapBurstFillStyle,
                                                ),
                                                strokeStyle:
                                                    tapBurstStrokeStyle,
                                                keyBase: burstKeyBase,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (widget.applySafeArea) {
      return SafeArea(key: const ValueKey('tap-zone-root'), child: content);
    }

    return KeyedSubtree(key: const ValueKey('tap-zone-root'), child: content);
  }

  double _squareSize(Size size, ResponsiveLayoutSpec spec) {
    final availableWidth = size.width - (spec.pagePadding * 2);
    final availableHeight = size.height - (spec.sectionGap * 2);
    return math.min(math.min(availableWidth, availableHeight), 256.0);
  }

  Offset _offsetEffectOrigin(
    Offset tapPosition,
    double tapCanvasSize,
    Offset offset, {
    double minX = 0,
  }) {
    final shiftedPosition = tapPosition + offset;
    return Offset(
      math.max(minX, math.min(tapCanvasSize, shiftedPosition.dx)),
      math.max(0.0, math.min(tapCanvasSize, shiftedPosition.dy)),
    );
  }
}

// ignore: unused_element
class _MaxComboBacklight extends StatelessWidget {
  const _MaxComboBacklight({required this.phase, required this.diameter});

  final double phase;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final angle = phase * math.pi * 2;
    final pulse = (math.sin(angle * 2) + 1) / 2;
    final colorPhase = (math.sin(angle) + 1) / 2;
    final coreColor = Color.lerp(
      const Color(0xFFFFFFFF),
      const Color(0xFF9AD8FF),
      colorPhase,
    )!;
    final edgeColor = Color.lerp(
      const Color(0xFF2C8CFF),
      const Color(0xFFC13CFF),
      1 - colorPhase,
    )!;

    return Transform.rotate(
      angle: angle * 0.28,
      child: Transform.scale(
        scale: 0.96 + (pulse * 0.12),
        child: SizedBox.square(
          dimension: diameter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                transform: GradientRotation(angle),
                colors: [
                  const Color(0xFF147DFF).withValues(alpha: 0.10),
                  const Color(0xFFFFFFFF).withValues(alpha: 0.92),
                  const Color(0xFFC027FF).withValues(alpha: 0.48),
                  const Color(0xFF147DFF).withValues(alpha: 0.10),
                ],
                stops: const [0, 0.24, 0.58, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: edgeColor.withValues(alpha: 0.72),
                  blurRadius: 54 + (pulse * 36),
                  spreadRadius: 14 + (pulse * 12),
                ),
                BoxShadow(
                  color: coreColor.withValues(alpha: 0.92),
                  blurRadius: 28 + (pulse * 22),
                  spreadRadius: 2 + (pulse * 8),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    coreColor.withValues(alpha: 0.98),
                    const Color(0xFF79C7FF).withValues(alpha: 0.72),
                    const Color(0xFF873BFF).withValues(alpha: 0.40),
                    const Color(0x003B20A5),
                  ],
                  stops: const [0, 0.18, 0.52, 1],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _tapBurstText(BuildContext context, _TapBurstEntry entry) {
  final amount = '+${formatClickCurrency(context, entry.value)}';
  return switch (entry.type) {
    _TapBurstType.normal => amount,
    _TapBurstType.critical =>
      '${AppStrings.of(context).criticalCutLabel.toLocaleUpperCase(context)} $amount',
  };
}

TextStyle? _tapBurstFillStyle(
  _TapBurstType type, {
  required TextStyle? normal,
  required TextStyle? critical,
}) {
  return switch (type) {
    _TapBurstType.normal => normal,
    _TapBurstType.critical => critical,
  };
}

class _TapBurstEntry {
  const _TapBurstEntry({
    required this.id,
    required this.value,
    required this.type,
    required this.origin,
    required this.riseDistance,
    this.isRising = false,
    this.isFadingOut = false,
  });

  final int id;
  final dynamic value;
  final _TapBurstType type;
  final Offset origin;
  final double riseDistance;
  final bool isRising;
  final bool isFadingOut;

  _TapBurstEntry copyWith({bool? isRising, bool? isFadingOut}) {
    return _TapBurstEntry(
      id: id,
      value: value,
      type: type,
      origin: origin,
      riseDistance: riseDistance,
      isRising: isRising ?? this.isRising,
      isFadingOut: isFadingOut ?? this.isFadingOut,
    );
  }
}

enum _TapBurstType { normal, critical }

class _TapBurstAnimatedEntry extends StatelessWidget {
  const _TapBurstAnimatedEntry({
    required this.entry,
    required this.child,
    required this.keyBase,
  });

  static const _entryDuration = Duration(milliseconds: 180);
  static const _startSlide = Offset(0, 0.04);
  static const _startScale = 0.88;

  final _TapBurstEntry entry;
  final Widget child;
  final String keyBase;

  @override
  Widget build(BuildContext context) {
    if (entry.type != _TapBurstType.critical) {
      return child;
    }

    return AnimatedSlide(
      offset: entry.isRising ? Offset.zero : _startSlide,
      duration: _entryDuration,
      curve: Curves.easeOutCubic,
      child: AnimatedScale(
        key: ValueKey('$keyBase-critical-entry'),
        scale: entry.isRising ? 1 : _startScale,
        duration: _entryDuration,
        curve: Curves.easeOutBack,
        child: child,
      ),
    );
  }
}

class _TapBurstLabel extends StatelessWidget {
  const _TapBurstLabel({
    required this.text,
    required this.fillStyle,
    required this.strokeStyle,
    required this.keyBase,
  });

  final String text;
  final TextStyle? fillStyle;
  final TextStyle? strokeStyle;
  final String keyBase;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(key: ValueKey('$keyBase-stroke'), text, style: strokeStyle),
        Text(key: ValueKey('$keyBase-fill'), text, style: fillStyle),
      ],
    );
  }
}

class _FallingSliceEntry {
  const _FallingSliceEntry({
    required this.id,
    required this.assetPath,
    required this.origin,
    required this.size,
    required this.horizontalDrift,
    required this.fallDistance,
    required this.initialRotationTurns,
    required this.rotationTurns,
    required this.startScale,
    required this.endScale,
    required this.movementCurve,
    this.isFalling = false,
    this.isFadingOut = false,
  });

  final int id;
  final String assetPath;
  final Offset origin;
  final double size;
  final double horizontalDrift;
  final double fallDistance;
  final double initialRotationTurns;
  final double rotationTurns;
  final double startScale;
  final double endScale;
  final Curve movementCurve;
  final bool isFalling;
  final bool isFadingOut;

  _FallingSliceEntry copyWith({bool? isFalling, bool? isFadingOut}) {
    return _FallingSliceEntry(
      id: id,
      assetPath: assetPath,
      origin: origin,
      size: size,
      horizontalDrift: horizontalDrift,
      fallDistance: fallDistance,
      initialRotationTurns: initialRotationTurns,
      rotationTurns: rotationTurns,
      startScale: startScale,
      endScale: endScale,
      movementCurve: movementCurve,
      isFalling: isFalling ?? this.isFalling,
      isFadingOut: isFadingOut ?? this.isFadingOut,
    );
  }
}
