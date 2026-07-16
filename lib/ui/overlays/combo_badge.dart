import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/l10n/locale_case.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

class ComboBadge extends StatefulWidget {
  const ComboBadge({required this.snapshot, required this.scale, super.key});

  final ActivePlaySnapshot snapshot;
  final double scale;

  @override
  State<ComboBadge> createState() => _ComboBadgeState();
}

class _ComboBadgeState extends State<ComboBadge> with TickerProviderStateMixin {
  static const _idleDuration = Duration(milliseconds: 820);
  static const _pulseDuration = Duration(milliseconds: 320);

  late final AnimationController _idleController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseLift;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(vsync: this, duration: _idleDuration)
      ..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: _pulseDuration,
      value: 1,
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 58,
      ),
    ]).animate(_pulseController);
    _pulseLift = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 5.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 5.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(covariant ComboBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.snapshot.comboMultiplier > oldWidget.snapshot.comboMultiplier) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final comboIntensity = _comboMultiplierIntensity(
      widget.snapshot.comboMultiplier,
    );
    final comboName = strings
        .comboTierLabel(widget.snapshot.comboMultiplier)
        .toLocaleUpperCase(context);
    final palette = _comboTierPalette(widget.snapshot.comboMultiplier);

    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _pulseController]),
      builder: (context, _) {
        final idlePhase = _idleController.value * math.pi * 2;
        final colorPulse = Curves.easeInOut.transform(
          ((math.sin(idlePhase * 1.24) + 1) / 2).clamp(0, 1).toDouble(),
        );
        final sparklePulse = Curves.easeOutCubic.transform(
          ((math.sin(idlePhase * 2.55 + 0.6) + 1) / 2).clamp(0, 1).toDouble(),
        );
        final idleX =
            math.sin(idlePhase * 2.1) * (0.85 + comboIntensity) * widget.scale;
        final idleY =
            math.cos(idlePhase * 3.2) *
            (0.55 + (comboIntensity * 0.55)) *
            widget.scale;
        final idleTurns = math.sin(idlePhase * 1.7) * 0.0045;
        final idleScale = 1 + (math.sin(idlePhase * 2.6) * 0.006);
        final multiplierColor = Color.lerp(
          palette.primary,
          palette.highlight,
          colorPulse,
        )!;
        final nameColor = Color.lerp(
          palette.highlight,
          palette.accent,
          sparklePulse,
        )!;
        final comboColor = Color.lerp(
          palette.primary,
          const Color(0xFFFFF7DF),
          0.32 + (sparklePulse * 0.36),
        )!;
        final glowColor = Color.lerp(
          palette.glow,
          palette.highlight,
          colorPulse,
        )!;
        final multiplierStyle = DonerTypography.display(
          Theme.of(context).textTheme.titleMedium?.copyWith(
            color: multiplierColor,
            fontWeight: FontWeight.w900,
            fontSize: (28 + (comboIntensity * 10)) * widget.scale,
            letterSpacing: 0,
            height: 0.88,
          ),
        );
        final nameStyle = DonerTypography.display(
          Theme.of(context).textTheme.labelSmall?.copyWith(
            color: nameColor.withValues(alpha: 0.96),
            fontWeight: FontWeight.w900,
            fontSize: (13.6 + (comboIntensity * 2.8)) * widget.scale,
            letterSpacing: 0,
            height: 0.92,
          ),
        );
        final countStyle = DonerTypography.display(
          Theme.of(context).textTheme.labelSmall?.copyWith(
            color: comboColor.withValues(alpha: 0.92),
            fontWeight: FontWeight.w900,
            fontSize: (13.2 + (comboIntensity * 2.4)) * widget.scale,
            letterSpacing: 0,
            height: 0.94,
          ),
        );

        return Transform.translate(
          key: const ValueKey('tap-zone-combo-badge-idle'),
          offset: Offset(idleX, idleY - (_pulseLift.value * widget.scale)),
          child: Transform.rotate(
            angle: idleTurns,
            child: Transform.scale(
              scale: idleScale,
              child: Transform.scale(
                key: const ValueKey('tap-zone-combo-badge-scale'),
                scale: _pulseScale.value,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 32 * widget.scale,
                    vertical: 14 * widget.scale,
                  ),
                  child: SizedBox(
                    key: const ValueKey('tap-zone-combo-badge'),
                    width: 250 * widget.scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _OutlinedComboText(
                          _multiplier(widget.snapshot.comboMultiplier),
                          textKey: const ValueKey(
                            'tap-zone-combo-badge-multiplier',
                          ),
                          style: multiplierStyle,
                          glowColor: glowColor,
                          glowBoost: 1.0 + (sparklePulse * 0.35),
                          strokeWidth: 4.8 * widget.scale,
                        ),
                        SizedBox(height: 2 * widget.scale),
                        _OutlinedComboText(
                          comboName,
                          textKey: const ValueKey('tap-zone-combo-badge-label'),
                          style: nameStyle,
                          glowColor: glowColor,
                          glowBoost: 0.78 + (colorPulse * 0.22),
                          strokeWidth: 3.3 * widget.scale,
                        ),
                        SizedBox(height: 1 * widget.scale),
                        _OutlinedComboText(
                          'x${widget.snapshot.currentCombo}',
                          textKey: const ValueKey('tap-zone-combo-badge-count'),
                          style: countStyle,
                          glowColor: glowColor,
                          glowBoost: 0.58,
                          strokeWidth: 2.8 * widget.scale,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OutlinedComboText extends StatelessWidget {
  const _OutlinedComboText(
    this.text, {
    required this.textKey,
    required this.style,
    required this.glowColor,
    required this.glowBoost,
    required this.strokeWidth,
  });

  final String text;
  final Key textKey;
  final TextStyle style;
  final Color glowColor;
  final double glowBoost;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final outlineInset = math.max(1.0, strokeWidth * 0.45);
    final fillColor = style.color ?? const Color(0xFFFFF6DD);
    final glowBleed = math.max(18.0, strokeWidth * 7.0);
    final outlineStyle = style.copyWith(
      color: null,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = const Color(0xEA000000),
      shadows: null,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: outlineInset,
        vertical: outlineInset * 0.5,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: _BlurredComboText(
              text,
              style: style,
              color: glowColor,
              opacity: 0.34,
              blurSigma: strokeWidth * 2.6 * glowBoost,
              bleed: glowBleed,
              scale: 1.03,
            ),
          ),
          Positioned.fill(
            child: _BlurredComboText(
              text,
              style: style,
              color: glowColor,
              opacity: 0.17,
              blurSigma: strokeWidth * 5.2 * glowBoost,
              bleed: glowBleed * 1.2,
              scale: 1.06,
            ),
          ),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            textAlign: TextAlign.center,
            style: outlineStyle,
          ),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            textAlign: TextAlign.center,
            style: style.copyWith(
              color: fillColor.withValues(alpha: 0.38),
              shadows: null,
            ),
          ),
          Text(
            text,
            key: textKey,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            textAlign: TextAlign.center,
            style: style,
          ),
        ],
      ),
    );
  }
}

class _BlurredComboText extends StatelessWidget {
  const _BlurredComboText(
    this.text, {
    required this.style,
    required this.color,
    required this.opacity,
    required this.blurSigma,
    required this.bleed,
    required this.scale,
  });

  final String text;
  final TextStyle style;
  final Color color;
  final double opacity;
  final double blurSigma;
  final double bleed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: OverflowBox(
          minWidth: 0,
          minHeight: 0,
          maxWidth: 520,
          maxHeight: 180,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: bleed,
              vertical: bleed * 0.55,
            ),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
              ),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: style.copyWith(color: color, shadows: null),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _multiplier(double value) => 'x${value.toStringAsFixed(2)}';

double _comboMultiplierIntensity(double multiplier) {
  const minMultiplier = 1.0;
  const maxVisibleMultiplier = 3.0;
  return ((multiplier - minMultiplier) / (maxVisibleMultiplier - minMultiplier))
      .clamp(0, 1)
      .toDouble();
}

_ComboTierPalette _comboTierPalette(double multiplier) {
  if (multiplier >= 4.0) {
    return const _ComboTierPalette(
      primary: Color(0xFFE7D0FF),
      highlight: Color(0xFFFFFFFF),
      accent: Color(0xFFB96DFF),
      glow: Color(0xFF7B43FF),
    );
  }
  if (multiplier >= 3.0) {
    return const _ComboTierPalette(
      primary: Color(0xFFFFD46E),
      highlight: Color(0xFFFFF7C4),
      accent: Color(0xFFFFA33E),
      glow: Color(0xFFFFB02E),
    );
  }
  if (multiplier >= 2.0) {
    return const _ComboTierPalette(
      primary: Color(0xFFFFA65C),
      highlight: Color(0xFFFFF1BA),
      accent: Color(0xFFFF5A2A),
      glow: Color(0xFFFF6A21),
    );
  }
  if (multiplier >= 1.4) {
    return const _ComboTierPalette(
      primary: Color(0xFFFFB25B),
      highlight: Color(0xFFFFF0B5),
      accent: Color(0xFFE94D1D),
      glow: Color(0xFFD97A24),
    );
  }
  if (multiplier >= 1.1) {
    return const _ComboTierPalette(
      primary: Color(0xFFFFC66B),
      highlight: Color(0xFFFFF6DD),
      accent: Color(0xFF1EB5AE),
      glow: Color(0xFFE8B35A),
    );
  }
  return const _ComboTierPalette(
    primary: Color(0xFFFFC57D),
    highlight: Color(0xFFFFF0D0),
    accent: Color(0xFFE8A86A),
    glow: Color(0xFFD97A24),
  );
}

class _ComboTierPalette {
  const _ComboTierPalette({
    required this.primary,
    required this.highlight,
    required this.accent,
    required this.glow,
  });

  final Color primary;
  final Color highlight;
  final Color accent;
  final Color glow;
}
