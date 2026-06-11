import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/chef_portrait_avatar.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class GameHudOverlay extends StatelessWidget {
  const GameHudOverlay({
    required this.controller,
    required this.onOpenSettings,
    super.key,
  });

  final GameController controller;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final metrics = _HudMetrics.fromContext(context);

    return SizedBox(
      height: metrics.headerHeight,
      width: double.infinity,
      child: _TopShell(
        scale: metrics.scale,
        key: const ValueKey('game-hud-panel'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TopRow(
              scale: metrics.scale,
              strings: strings,
              onOpenSettings: onOpenSettings,
            ),
            SizedBox(height: 10 * metrics.scale),
            ValueListenableBuilder<GameHudSnapshot>(
              valueListenable: controller.hudSnapshotListenable,
              builder: (context, snapshot, _) {
                return RepaintBoundary(
                  child: Row(
                    key: const ValueKey('game-hud-stat-cluster'),
                    children: [
                      Expanded(
                        child: _StatChip(
                          scale: metrics.scale,
                          label: strings.cashLabel,
                          value: formatCompactCurrency(context, snapshot.cash),
                          icon: DonerIcons.cash,
                          accentColor: DonerColors.tealPrimary,
                        ),
                      ),
                      SizedBox(width: 8 * metrics.scale),
                      Expanded(
                        child: _StatChip(
                          scale: metrics.scale,
                          label: strings.idleIncomeLabel,
                          value: formatCompactCurrencyRate(
                            context,
                            snapshot.passiveIncomePerSecond,
                          ),
                          icon: DonerIcons.idleIncome,
                          accentColor: DonerColors.orangeAccent,
                        ),
                      ),
                      SizedBox(width: 8 * metrics.scale),
                      Expanded(
                        child: _StatChip(
                          scale: metrics.scale,
                          label: strings.reputationLabel,
                          value: '${snapshot.reputation}',
                          icon: DonerIcons.reputation,
                          accentColor: DonerColors.tealBright,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HudMetrics {
  const _HudMetrics({required this.scale});

  factory _HudMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = math.min(size.width / 390.0, size.height / 884.0);
    return _HudMetrics(scale: scale);
  }

  final double scale;

  double get headerHeight => 166 * scale;
  double get shellRadius => 32 * scale;
  double get outerPadding => 16 * scale;
  double get topPadding => 12 * scale;
  double get bottomPadding => 16 * scale;
  double get rowHeight => 56 * scale;
  double get avatarSize => 52 * scale;
  double get settingsSize => 48 * scale;
  double get titleSize => 30 * scale;
  double get chipHeight => 60 * scale;
  double get chipRadius => 18 * scale;
  double get chipPaddingX => 10 * scale;
  double get chipPaddingY => 6 * scale;
  double get chipLabelSize => 10 * scale;
  double get chipValueSize => 13.5 * scale;
  double get chipIconSize => 13.5 * scale;
  double get chipGap => 8 * scale;
  double get rushBarHeight => 4 * scale;
}

class _TopShell extends StatelessWidget {
  const _TopShell({required this.child, required this.scale, super.key});

  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(32 * scale);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8 * scale, sigmaY: 8 * scale),
        child: DecoratedBox(
          key: const ValueKey('game-hud-shell-decoration'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF61150E).withValues(alpha: 0.82),
                const Color(0xFF4B0E0A).withValues(alpha: 0.76),
                const Color(0xFF3A0B08).withValues(alpha: 0.70),
              ],
            ),
            border: Border.all(
              color: DonerColors.borderPrimary.withValues(alpha: 0.56),
              width: 1.35,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 20 * scale,
                offset: Offset(0, 10 * scale),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: radius),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.08),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16 * scale,
                  12 * scale,
                  16 * scale,
                  16 * scale,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.scale,
    required this.strings,
    required this.onOpenSettings,
  });

  final double scale;
  final AppStrings strings;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56 * scale,
      child: Row(
        children: [
          ChefPortraitAvatar(size: 52 * scale),
          SizedBox(width: 12 * scale),
          Expanded(child: _BrandTitle(scale: scale)),
          SizedBox(width: 12 * scale),
          _SettingsButton(size: 48 * scale, onPressed: onOpenSettings),
        ],
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle({required this.scale});

  static const _title = 'TapTapD\u00F6ner';

  final double scale;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.berkshireSwash(
      fontSize: 33 * scale,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      height: 1,
      letterSpacing: 0,
    );

    return Semantics(
      label: _title,
      child: SizedBox(
        height: 52 * scale,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ExcludeSemantics(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, 2.4 * scale),
                    child: Text(
                      _title,
                      style: textStyle.copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeJoin = StrokeJoin.round
                          ..strokeWidth = 4.8 * scale
                          ..color = Colors.black.withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                  Text(
                    _title,
                    style: textStyle.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeJoin = StrokeJoin.round
                        ..strokeWidth = 3.6 * scale
                        ..color = DonerColors.panelDark,
                    ),
                  ),
                  Text(
                    _title,
                    style: textStyle.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeJoin = StrokeJoin.round
                        ..strokeWidth = 1.2 * scale
                        ..color = DonerColors.goldBright,
                    ),
                  ),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF7C45E),
                          Color(0xFFFFFFFF),
                          Color(0xFFD97A24),
                        ],
                        stops: [0.0, 0.2, 1.0],
                      ).createShader(bounds);
                    },
                    child: Text(
                      _title,
                      style: textStyle.copyWith(
                        color: DonerColors.goldBright,
                        shadows: [
                          Shadow(
                            color: DonerColors.goldPrimary.withValues(
                              alpha: 0.40,
                            ),
                            blurRadius: 9 * scale,
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
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.size, required this.onPressed});

  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final buttonGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF5C140E).withValues(alpha: 0.80),
        const Color(0xFF42100B).withValues(alpha: 0.72),
      ],
    );
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          splashFactory: InkRipple.splashFactory,
          onTap: onPressed,
          radius: 24 * (size / 40),
          child: Center(
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: buttonGradient,
                border: Border.all(
                  color: DonerColors.borderPrimary.withValues(alpha: 0.60),
                  width: 1.5,
                ),
                boxShadow: DonerShadows.soft,
              ),
              child: FaIcon(
                DonerIcons.settings,
                color: DonerColors.goldPrimary,
                size: 24 * (size / 40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.scale,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final double scale;
  final String label;
  final String value;
  final FaIconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final chipGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF5C140E).withValues(alpha: 0.78),
        const Color(0xFF42100B).withValues(alpha: 0.70),
      ],
    );
    return Container(
      height: 54 * scale,
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 7 * scale,
      ),
      decoration: BoxDecoration(
        gradient: chipGradient,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.62),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12 * scale,
            offset: Offset(0, 6 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: DonerTypography.body(
              Theme.of(context).textTheme.labelSmall?.copyWith(
                color: DonerColors.bodyText.withValues(alpha: 0.88),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                fontSize: 9.5 * scale,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: 1.5 * scale),
          Row(
            children: [
              FaIcon(icon, color: accentColor, size: 14 * scale),
              SizedBox(width: 4 * scale),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: DonerTypography.body(
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DonerColors.creamText,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5 * scale,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
