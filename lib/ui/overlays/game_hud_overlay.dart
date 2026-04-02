import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
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
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return _TopShell(
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
                Row(
                  key: const ValueKey('game-hud-stat-cluster'),
                  children: [
                    Expanded(
                      child: _StatChip(
                        scale: metrics.scale,
                        label: strings.cashLabel,
                        value: formatCompactCurrency(
                          context,
                          controller.state.cash,
                        ),
                        icon: Icons.payments_rounded,
                        accentColor: const Color(0xFFE9C400),
                      ),
                    ),
                    SizedBox(width: 8 * metrics.scale),
                    Expanded(
                      child: _StatChip(
                        scale: metrics.scale,
                        label: strings.idleIncomeLabel,
                        value: formatCompactCurrencyRate(
                          context,
                          controller.passiveIncomePerSecond,
                        ),
                        icon: Icons.timer_rounded,
                        accentColor: const Color(0xFFE9C400),
                      ),
                    ),
                    SizedBox(width: 8 * metrics.scale),
                    Expanded(
                      child: _StatChip(
                        scale: metrics.scale,
                        label: strings.reputationLabel,
                        value: '${controller.state.prestige.reputation}',
                        icon: Icons.star_rounded,
                        accentColor: const Color(0xFFE9C400),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
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

  double get headerHeight => 147 * scale;
  double get shellRadius => 48 * scale;
  double get outerPadding => 32 * scale;
  double get topPadding => 16 * scale;
  double get bottomPadding => 18 * scale;
  double get rowHeight => 40 * scale;
  double get avatarSize => 40 * scale;
  double get settingsSize => 40 * scale;
  double get titleSize => 24 * scale;
  double get chipHeight => 56 * scale;
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
    final radius = Radius.circular(48 * scale);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20 * scale, sigmaY: 20 * scale),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: radius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF49342C).withValues(alpha: 0.78),
                const Color(0xFF2D1B14).withValues(alpha: 0.92),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F0F09).withValues(alpha: 0.52),
                blurRadius: 32 * scale,
                offset: Offset(0, 16 * scale),
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
                          Colors.white.withValues(alpha: 0.08),
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
                  32 * scale,
                  16 * scale,
                  32 * scale,
                  18 * scale,
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
      height: 40 * scale,
      child: Row(
        children: [
          ChefPortraitAvatar(size: 40 * scale),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Text(
              strings.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                fontSize: 24 * scale,
                color: const Color(0xFFE9C400),
                letterSpacing: -0.4,
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          _SettingsButton(size: 40 * scale, onPressed: onOpenSettings),
        ],
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
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onPressed,
          radius: 24 * (size / 40),
          child: Center(
            child: Icon(
              Icons.settings_rounded,
              color: Colors.white.withValues(alpha: 0.78),
              size: 24 * (size / 40),
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
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54 * scale,
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 7 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF453028),
        borderRadius: BorderRadius.circular(18 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontFamily: 'Be Vietnam Pro',
              color: const Color(0xFFD6C3B4).withValues(alpha: 0.6),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              fontSize: 9.5 * scale,
              height: 1,
            ),
          ),
          SizedBox(height: 1.5 * scale),
          Row(
            children: [
              Icon(icon, color: accentColor, size: 14 * scale),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Plus Jakarta Sans',
                    color: const Color(0xFFFDDBD0),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5 * scale,
                    height: 1,
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
