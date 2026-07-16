import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/l10n/locale_case.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/chef_portrait_avatar.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class GameHudOverlay extends StatelessWidget {
  const GameHudOverlay({
    required this.controller,
    required this.onOpenGoals,
    required this.onOpenSettings,
    super.key,
  });

  final GameController controller;
  final VoidCallback onOpenGoals;
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
              onOpenGoals: onOpenGoals,
              onOpenSettings: onOpenSettings,
            ),
            SizedBox(height: 6 * metrics.scale),
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
                          value: formatCompactNumber(
                            context,
                            snapshot.reputation,
                          ),
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

  double get headerHeight => 122 * scale;
  double get shellRadius => 24 * scale;
  double get outerPadding => 14 * scale;
  double get topPadding => 9 * scale;
  double get bottomPadding => 11 * scale;
  double get rowHeight => 42 * scale;
  double get avatarSize => 40 * scale;
  double get settingsSize => 38 * scale;
  double get titleSize => 26 * scale;
  double get chipHeight => 40 * scale;
  double get chipRadius => 12 * scale;
  double get chipPaddingX => 8 * scale;
  double get chipPaddingY => 5 * scale;
  double get chipLabelSize => 8.2 * scale;
  double get chipValueSize => 12 * scale;
  double get chipIconSize => 12 * scale;
  double get chipGap => 6 * scale;
}

class _TopShell extends StatelessWidget {
  const _TopShell({required this.child, required this.scale, super.key});

  final Widget child;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(24 * scale);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: radius),
      child: DecoratedBox(
        key: const ValueKey('game-hud-shell-decoration'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF61150E).withValues(alpha: 0.88),
              const Color(0xFF4B0E0A).withValues(alpha: 0.82),
              const Color(0xFF3A0B08).withValues(alpha: 0.76),
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
                14 * scale,
                9 * scale,
                14 * scale,
                11 * scale,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.scale,
    required this.strings,
    required this.onOpenGoals,
    required this.onOpenSettings,
  });

  final double scale;
  final AppStrings strings;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42 * scale,
      child: Row(
        children: [
          ChefPortraitAvatar(size: 40 * scale),
          SizedBox(width: 10 * scale),
          Expanded(child: _BrandTitle(scale: scale)),
          SizedBox(width: 8 * scale),
          _HeaderActionButton(
            buttonKey: const ValueKey('hud-goals-button'),
            size: 38 * scale,
            icon: DonerIcons.goals,
            tooltip: strings.isTurkish ? 'Hedefler' : 'Goals',
            onPressed: onOpenGoals,
          ),
          SizedBox(width: 7 * scale),
          _HeaderActionButton(
            buttonKey: const ValueKey('hud-settings-button'),
            size: 38 * scale,
            icon: DonerIcons.settings,
            tooltip: strings.settingsTitle,
            onPressed: onOpenSettings,
          ),
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
      fontSize: 27 * scale,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      height: 1,
      letterSpacing: 0,
    );

    return Semantics(
      label: _title,
      child: SizedBox(
        height: 38 * scale,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ExcludeSemantics(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, 1.8 * scale),
                    child: Text(
                      _title,
                      style: textStyle.copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeJoin = StrokeJoin.round
                          ..strokeWidth = 4.0 * scale
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
                        ..strokeWidth = 3.0 * scale
                        ..color = DonerColors.panelDark,
                    ),
                  ),
                  Text(
                    _title,
                    style: textStyle.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeJoin = StrokeJoin.round
                        ..strokeWidth = 1.0 * scale
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

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.buttonKey,
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Key buttonKey;
  final double size;
  final FaIconData icon;
  final String tooltip;
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
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        key: buttonKey,
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
                  icon,
                  color: DonerColors.goldPrimary,
                  size: 22 * (size / 40),
                ),
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
      height: 40 * scale,
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 5 * scale),
      decoration: BoxDecoration(
        gradient: chipGradient,
        borderRadius: BorderRadius.circular(12 * scale),
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
            label.toLocaleUpperCase(context),
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
                letterSpacing: 0.9,
                fontSize: 8.2 * scale,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: 1 * scale),
          Row(
            children: [
              FaIcon(icon, color: accentColor, size: 12 * scale),
              SizedBox(width: 3 * scale),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: DonerTypography.body(
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DonerColors.creamText,
                        fontWeight: FontWeight.w800,
                        fontSize: 12 * scale,
                        height: 1,
                      ),
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
