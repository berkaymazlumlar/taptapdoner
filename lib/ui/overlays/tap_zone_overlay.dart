import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
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
    with SingleTickerProviderStateMixin {
  static const _tapVisualScale = 1.45;
  static const _tapBurstLifetime = Duration(milliseconds: 280);
  static const _tapBurstFadeDuration = Duration(milliseconds: 90);
  static const _rushAuraDuration = Duration(milliseconds: 900);
  static const _fallingSliceTravelDuration = Duration(milliseconds: 520);
  static const _fallingSliceFadeDuration = Duration(milliseconds: 180);
  static const _tapBurstSpawnRightFactor = 0.08;
  static const _tapBurstSpawnLiftFactor = 0.22;
  static const _sliceSpawnLeftFactor = 0.08;
  static const _sliceSpawnDropFactor = 0.08;

  final _random = math.Random();
  double _scale = 1;
  int _nextTapBurstId = 0;
  final List<_TapBurstEntry> _tapBursts = [];
  int _nextFallingSliceId = 0;
  final List<_FallingSliceEntry> _fallingSlices = [];
  late final AnimationController _rushAuraController;
  bool _isRushAuraActive = false;
  bool _didPrecacheFallingSlices = false;

  @override
  void initState() {
    super.initState();
    _rushAuraController = AnimationController(
      vsync: this,
      duration: _rushAuraDuration,
    );
    widget.controller.rushSnapshotListenable.addListener(_handleRushUpdate);
    _syncRushAura(force: true);
  }

  @override
  void didUpdateWidget(covariant TapZoneOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.rushSnapshotListenable.removeListener(
      _handleRushUpdate,
    );
    widget.controller.rushSnapshotListenable.addListener(_handleRushUpdate);
    _syncRushAura(force: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheFallingSlices) {
      return;
    }

    _didPrecacheFallingSlices = true;
    for (final assetPath in UiAssetPaths.tapDonerSlices) {
      unawaited(precacheImage(AssetImage(assetPath), context));
    }
  }

  @override
  void dispose() {
    widget.controller.rushSnapshotListenable.removeListener(_handleRushUpdate);
    _rushAuraController.dispose();
    super.dispose();
  }

  void _handleRushUpdate() {
    _syncRushAura();
  }

  void _syncRushAura({bool force = false}) {
    final shouldAnimate =
        widget.controller.rushSnapshotListenable.value.isActive;
    if (!force && shouldAnimate == _isRushAuraActive) {
      return;
    }

    _isRushAuraActive = shouldAnimate;
    if (shouldAnimate) {
      _rushAuraController.repeat(reverse: true);
    } else {
      _rushAuraController
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
    unawaited(
      _handleTap(
        tapPosition: event.localPosition,
        squareSize: squareSize,
        tapTargetSize: tapTargetSize,
      ),
    );
  }

  Future<void> _handleTap({
    required Offset tapPosition,
    required double squareSize,
    required double tapTargetSize,
  }) async {
    final tapBurstValue = widget.controller.tapValue;
    _enqueueTapBurst(tapBurstValue, tapPosition, squareSize, tapTargetSize);
    _enqueueFallingSlice(tapPosition, squareSize, tapTargetSize);
    setState(() => _scale = 0.95);
    await widget.controller.tap();
    if (!mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 110));
    if (!mounted) {
      return;
    }

    setState(() => _scale = 1);
  }

  void _enqueueTapBurst(
    int value,
    Offset tapPosition,
    double squareSize,
    double tapTargetSize,
  ) {
    final id = _nextTapBurstId++;
    final effectOrigin = _offsetEffectOrigin(
      tapPosition,
      tapTargetSize,
      Offset(
        squareSize * _tapBurstSpawnRightFactor,
        -(squareSize * _tapBurstSpawnLiftFactor),
      ),
    );
    final entry = _TapBurstEntry(
      id: id,
      value: value,
      origin: effectOrigin,
      riseDistance: squareSize * (0.14 + (_random.nextDouble() * 0.05)),
    );

    setState(() {
      _tapBursts.add(entry);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final entryIndex = _tapBursts.indexWhere(
        (candidate) => candidate.id == id,
      );
      if (entryIndex == -1) {
        return;
      }

      setState(() {
        _tapBursts[entryIndex] = _tapBursts[entryIndex].copyWith(
          isRising: true,
        );
      });
    });

    unawaited(_expireTapBurst(id));
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
    final effectOrigin = _offsetEffectOrigin(
      tapPosition,
      tapTargetSize,
      Offset(
        -(squareSize * _sliceSpawnLeftFactor),
        squareSize * _sliceSpawnDropFactor,
      ),
    );
    final entry = _FallingSliceEntry(
      id: id,
      assetPath: UiAssetPaths
          .tapDonerSlices[_random.nextInt(UiAssetPaths.tapDonerSlices.length)],
      origin: effectOrigin,
      size: squareSize * (0.17 + (_random.nextDouble() * 0.08)),
      horizontalDrift: (_random.nextDouble() - 0.5) * squareSize * 0.20,
      fallDistance: squareSize * (0.34 + (_random.nextDouble() * 0.18)),
      rotationTurns: (_random.nextDouble() - 0.5) * 0.24,
    );

    setState(() {
      _fallingSlices.add(entry);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final entryIndex = _fallingSlices.indexWhere(
        (candidate) => candidate.id == id,
      );
      if (entryIndex == -1) {
        return;
      }

      setState(() {
        _fallingSlices[entryIndex] = _fallingSlices[entryIndex].copyWith(
          isFalling: true,
        );
      });
    });

    unawaited(_expireFallingSlice(id));
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
        final tapBurstFontSize = math.min(36.0, squareSize * 0.112);
        final tapBurstStrokeStyle = DonerTypography.body(
          Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: tapBurstFontSize,
            letterSpacing: 0.4,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(2.2, tapBurstFontSize * 0.08)
              ..color = DonerColors.panelDark.withValues(alpha: 0.95),
          ),
        );
        final tapBurstFillStyle = DonerTypography.body(
          Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: DonerColors.goldBright,
            fontWeight: FontWeight.w900,
            fontSize: tapBurstFontSize,
            letterSpacing: 0.4,
            shadows: [
              Shadow(
                color: DonerColors.goldPrimary.withValues(alpha: 0.75),
                blurRadius: 18,
                offset: const Offset(0, 3),
              ),
              Shadow(
                color: const Color(0xFFFFF0A8).withValues(alpha: 0.45),
                blurRadius: 10,
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
              AnimatedBuilder(
                animation: _rushAuraController,
                builder: (context, child) {
                  final pulse = Curves.easeInOut.transform(
                    _rushAuraController.value,
                  );
                  final scale = _isRushAuraActive ? 1.06 + (pulse * 0.16) : 1.0;
                  final coreAlpha = _isRushAuraActive
                      ? 0.30 + (pulse * 0.16)
                      : 0.30;
                  final outerAlpha = _isRushAuraActive
                      ? 0.10 + (pulse * 0.12)
                      : 0.10;

                  return Transform.scale(
                    key: const ValueKey('tap-zone-flame-aura'),
                    scale: scale,
                    child: Container(
                      width: size.width,
                      height: size.height,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(
                              0xFFE8B35A,
                            ).withValues(alpha: coreAlpha),
                            const Color(
                              0xFFD97A24,
                            ).withValues(alpha: outerAlpha),
                            const Color(0x00160605),
                          ],
                          stops: const [0.0, 0.58, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DonerColors.goldPrimary.withValues(
                              alpha: _isRushAuraActive
                                  ? 0.10 + (pulse * 0.12)
                                  : 0.10,
                            ),
                            blurRadius: _isRushAuraActive
                                ? 40 + (pulse * 16)
                                : 40,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (final slice in _fallingSlices)
                                  AnimatedPositioned(
                                    key: ValueKey(
                                      'tap-zone-falling-slice-${slice.id}',
                                    ),
                                    duration: _fallingSliceTravelDuration,
                                    curve: Curves.easeIn,
                                    left:
                                        slice.origin.dx -
                                        (slice.size / 2) +
                                        (slice.isFalling
                                            ? slice.horizontalDrift
                                            : 0),
                                    top:
                                        slice.origin.dy -
                                        (slice.size / 2) +
                                        (slice.isFalling
                                            ? slice.fallDistance
                                            : 0),
                                    child: AnimatedOpacity(
                                      opacity: slice.isFadingOut ? 0 : 1,
                                      duration: _fallingSliceFadeDuration,
                                      curve: Curves.easeIn,
                                      child: AnimatedRotation(
                                        turns: slice.isFalling
                                            ? slice.rotationTurns
                                            : 0,
                                        duration: _fallingSliceTravelDuration,
                                        curve: Curves.easeIn,
                                        child: AnimatedScale(
                                          scale: slice.isFalling ? 0.9 : 1,
                                          duration: _fallingSliceTravelDuration,
                                          curve: Curves.easeIn,
                                          child: SizedBox.square(
                                            dimension: slice.size,
                                            child: Image.asset(
                                              slice.assetPath,
                                              fit: BoxFit.contain,
                                              cacheWidth:
                                                  (slice.size *
                                                          devicePixelRatio)
                                                      .round(),
                                              filterQuality: FilterQuality.low,
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
                                  AnimatedPositioned(
                                    key: ValueKey(
                                      'tap-zone-cash-splash-${_tapBursts[index].id}',
                                    ),
                                    duration: _tapBurstLifetime,
                                    curve: Curves.easeOut,
                                    left: _tapBursts[index].origin.dx,
                                    top:
                                        _tapBursts[index].origin.dy -
                                        (_tapBursts[index].isRising
                                            ? _tapBursts[index].riseDistance
                                            : 0),
                                    child: AnimatedOpacity(
                                      key: index == 0
                                          ? const ValueKey(
                                              'tap-zone-cash-splash',
                                            )
                                          : null,
                                      opacity: _tapBursts[index].isFadingOut
                                          ? 0
                                          : 1,
                                      duration: _tapBurstFadeDuration,
                                      curve: Curves.easeIn,
                                      child: FractionalTranslation(
                                        translation: const Offset(-0.5, -0.5),
                                        child: _TapBurstLabel(
                                          text:
                                              '+${formatCompactCurrency(context, _tapBursts[index].value)}',
                                          fillStyle: tapBurstFillStyle,
                                          strokeStyle: tapBurstStrokeStyle,
                                        ),
                                      ),
                                    ),
                                  ),
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
    Offset offset,
  ) {
    final shiftedPosition = tapPosition + offset;
    return Offset(
      math.max(0.0, math.min(tapCanvasSize, shiftedPosition.dx)),
      math.max(0.0, math.min(tapCanvasSize, shiftedPosition.dy)),
    );
  }
}

class _TapBurstEntry {
  const _TapBurstEntry({
    required this.id,
    required this.value,
    required this.origin,
    required this.riseDistance,
    this.isRising = false,
    this.isFadingOut = false,
  });

  final int id;
  final int value;
  final Offset origin;
  final double riseDistance;
  final bool isRising;
  final bool isFadingOut;

  _TapBurstEntry copyWith({bool? isRising, bool? isFadingOut}) {
    return _TapBurstEntry(
      id: id,
      value: value,
      origin: origin,
      riseDistance: riseDistance,
      isRising: isRising ?? this.isRising,
      isFadingOut: isFadingOut ?? this.isFadingOut,
    );
  }
}

class _TapBurstLabel extends StatelessWidget {
  const _TapBurstLabel({
    required this.text,
    required this.fillStyle,
    required this.strokeStyle,
  });

  final String text;
  final TextStyle? fillStyle;
  final TextStyle? strokeStyle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(text, style: strokeStyle),
        Text(text, style: fillStyle),
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
    required this.rotationTurns,
    this.isFalling = false,
    this.isFadingOut = false,
  });

  final int id;
  final String assetPath;
  final Offset origin;
  final double size;
  final double horizontalDrift;
  final double fallDistance;
  final double rotationTurns;
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
      rotationTurns: rotationTurns,
      isFalling: isFalling ?? this.isFalling,
      isFadingOut: isFadingOut ?? this.isFadingOut,
    );
  }
}
