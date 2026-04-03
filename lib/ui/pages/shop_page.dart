import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/stations/station_catalog.dart';
import 'package:taptapdoner/domain/stations/upgrade_catalog.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/stitch_bottom_sheet_primitives.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({
    required this.controller,
    required this.onOpenKitchen,
    required this.onOpenPrestige,
    super.key,
    this.onBack,
  });

  final GameController controller;
  final VoidCallback onOpenKitchen;
  final VoidCallback onOpenPrestige;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final closeAction = onBack ?? onOpenKitchen;

    return Material(
      key: const ValueKey('shop-sheet-surface'),
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _SheetGlow()),
          StitchBottomSheetSurface(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final strings = AppStrings.of(context);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxWidth < 360 ||
                        constraints.maxHeight < 700;
                    final horizontalPadding = compact ? 20.w : 24.w;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const StitchSheetHandle(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            compact ? 8.h : 10.h,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings.shopTitle.toUpperCase(),
                                      key: const ValueKey('shop-sheet-title'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: RoastedTypography.headlineFontFamily,
                                        fontSize: compact ? 28.sp : 30.sp,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                        letterSpacing: -0.4,
                                        color: RoastedColors.primary,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'STATIONS AND UPGRADES',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: RoastedTypography.bodyFontFamily,
                                        fontSize: compact ? 11.sp : 12.sp,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                        letterSpacing: 2.2,
                                        color: RoastedColors.secondary.withValues(alpha: 0.60),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              KeyedSubtree(
                                key: const ValueKey('shop-sheet-close-button'),
                                child: StitchSheetCloseButton(onPressed: closeAction),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: SizedBox(
                            height: compact ? 56.h : 60.h,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _StatChip(
                                    icon: Icons.payments_rounded,
                                    label: strings.cashLabel,
                                    value: _cash(context, controller.state.cash),
                                  ),
                                  SizedBox(width: 12.w),
                                  _StatChip(
                                    icon: Icons.timer_rounded,
                                    label: 'Idle/Sec',
                                    value:
                                        '${formatCompactDecimal(context, controller.passiveIncomePerSecond)}/s',
                                    iconColor: RoastedColors.secondary,
                                  ),
                                  SizedBox(width: 12.w),
                                  _StatChip(
                                    icon: Icons.military_tech_rounded,
                                    label: strings.reputationLabel,
                                    value: controller.state.prestige.reputation.toString(),
                                    iconColor: RoastedColors.tertiary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 10.h : 12.h),
                        Expanded(
                          child: _ShopContent(
                            controller: controller,
                            horizontalPadding: horizontalPadding,
                            compact: compact,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopContent extends StatelessWidget {
  const _ShopContent({
    required this.controller,
    required this.horizontalPadding,
    required this.compact,
  });

  final GameController controller;
  final double horizontalPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            88.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StitchSheetSectionDivider(label: 'Stations'),
              SizedBox(height: 16.h),
              for (final station in controller.stations)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _StationCard(
                    controller: controller,
                    station: station,
                  ),
                ),
              SizedBox(height: 10.h),
              const StitchSheetSectionDivider(label: 'Upgrades'),
              SizedBox(height: 16.h),
              for (final upgrade in controller.upgrades)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _UpgradeCard(
                    controller: controller,
                    upgrade: upgrade,
                  ),
                ),
            ],
          ),
        ),
        IgnorePointer(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 78.h,
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    RoastedColors.surface.withValues(alpha: 0),
                    RoastedColors.surfaceContainer.withValues(alpha: 0.90),
                    RoastedColors.surfaceContainer,
                  ],
                ),
              ),
              child: Text(
                'TAP TAP DONER',
                style: TextStyle(
                  fontFamily: RoastedTypography.headlineFontFamily,
                  fontSize: compact ? 16.sp : 18.sp,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 6,
                  color: RoastedColors.primary.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.controller, required this.station});

  final GameController controller;
  final StationDefinition station;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final unlocked = controller.isStationUnlocked(station.id);
    final state = controller.state.station(station.id);
    final cost = controller.stationCost(station.id);
    final canAfford = unlocked && controller.state.cash >= cost;
    final income = controller.stationIncomePerSecond(station.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 292;
        final showTopLevelBadge = unlocked && !compact;
        final body = _CardShell(
          locked: !unlocked,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StationIconBadge(
                    icon: _stationIcon(station.id),
                    locked: !unlocked,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.stationName(station.id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _titleStyle(
                            unlocked
                                ? RoastedColors.onSurface
                                : const Color(0xFF91837A),
                          ),
                        ),
                        if (showTopLevelBadge) ...[
                          SizedBox(height: 8.h),
                          _LevelBadge(level: state.level),
                        ],
                        SizedBox(height: 4.h),
                        Text(
                          strings.stationDescription(station.id),
                          maxLines: compact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: _bodyStyle(
                            unlocked
                                ? RoastedColors.onSurfaceVariant
                                : const Color(0xFF6A5C54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              if (unlocked)
                Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!showTopLevelBadge) _LevelBadge(level: state.level),
                    Text('+${_rate(context, income)}', style: _minorStyle()),
                    _GoldButton(
                      label:
                          '${strings.buyLabel.toUpperCase()} ${_cash(context, cost)}',
                      enabled: canAfford,
                      onTap: canAfford
                          ? () => controller.buyStation(station.id)
                          : null,
                    ),
                  ],
                )
              else
                _LockedPill(label: _lockText(context, strings, station)),
            ],
          ),
        );

        return KeyedSubtree(
          key: ValueKey('shop-station-card-${station.id.key}'),
          child: unlocked
              ? body
              : Opacity(
                  opacity: 0.82,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
                    child: body,
                  ),
                ),
        );
      },
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.controller, required this.upgrade});

  final GameController controller;
  final UpgradeDefinition upgrade;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = controller.state.upgrade(upgrade.id);
    final owned = state.purchased;
    final canAfford = !owned && controller.state.cash >= upgrade.cost;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 292;
        final trailing = owned
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: RoastedColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  strings.boughtLabel.toUpperCase(),
                  style: _badgeStyle(),
                ),
              )
            : _BrownButton(
                label: _cash(context, upgrade.cost),
                enabled: canAfford,
                onTap: canAfford
                    ? () => controller.buyUpgrade(upgrade.id)
                    : null,
              );

        return Container(
          key: ValueKey('shop-upgrade-card-${upgrade.id.key}'),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: RoastedColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: owned
                  ? RoastedColors.primary.withValues(alpha: 0.20)
                  : RoastedColors.outlineVariant.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UpgradeIcon(icon: _upgradeIcon(upgrade.id), owned: owned),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _UpgradeText(upgrade: upgrade, owned: owned),
                  ),
                ],
              ),
              SizedBox(height: compact ? 12.h : 14.h),
              trailing,
            ],
          ),
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, required this.locked});

  final Widget child;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: locked
            ? RoastedColors.surfaceContainerLow
            : RoastedColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: locked
              ? Colors.white.withValues(alpha: 0.05)
              : RoastedColors.outlineVariant.withValues(alpha: 0.10),
        ),
      ),
      child: child,
    );
  }
}

class _UpgradeText extends StatelessWidget {
  const _UpgradeText({required this.upgrade, required this.owned});

  final UpgradeDefinition upgrade;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.upgradeName(upgrade.id),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _titleStyle(
            owned ? RoastedColors.primary : RoastedColors.onSurface,
            size: 16,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          strings.upgradeDescription(upgrade.id),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _bodyStyle(
            owned
                ? RoastedColors.primary.withValues(alpha: 0.62)
                : RoastedColors.onSurfaceVariant,
            size: 11,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = RoastedColors.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 44.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: RoastedColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: RoastedColors.outlineVariant.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.r, color: iconColor),
          SizedBox(width: 8.w),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: RoastedTypography.bodyFontFamily,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: RoastedColors.onSurfaceVariant.withValues(
                      alpha: 0.72,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: RoastedTypography.headlineFontFamily,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: RoastedColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationIconBadge extends StatelessWidget {
  const _StationIconBadge({required this.icon, required this.locked});

  final IconData icon;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64.w,
      height: 64.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: RoastedColors.surfaceContainerLowest.withValues(
          alpha: locked ? 0.90 : 1,
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Icon(
        icon,
        size: 30.sp,
        color: locked ? const Color(0xFF766760) : RoastedColors.primary,
      ),
    );
  }
}

class _UpgradeIcon extends StatelessWidget {
  const _UpgradeIcon({required this.icon, required this.owned});

  final IconData icon;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.w,
      height: 48.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: owned
            ? RoastedColors.primary.withValues(alpha: 0.14)
            : RoastedColors.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 22.sp,
        color: owned ? RoastedColors.primary : RoastedColors.secondary,
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: RoastedColors.primary.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text('LV $level', style: _badgeStyle()),
    );
  }
}

class _LockedPill extends StatelessWidget {
  const _LockedPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: RoastedColors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, size: 16.sp, color: RoastedColors.secondary),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: RoastedColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ButtonShell(
      enabled: enabled,
      onTap: onTap,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [RoastedColors.primary, RoastedColors.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(999.r),
        boxShadow: [
          BoxShadow(
            color: RoastedColors.primary.withValues(alpha: 0.20),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: RoastedTypography.headlineFontFamily,
          fontSize: 12.sp,
          fontWeight: FontWeight.w900,
          height: 1,
          color: RoastedColors.onPrimary,
        ),
      ),
    );
  }
}

class _BrownButton extends StatelessWidget {
  const _BrownButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ButtonShell(
      enabled: enabled,
      onTap: onTap,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [RoastedColors.secondary, RoastedColors.onSecondaryContainer],
        ),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: RoastedTypography.headlineFontFamily,
          fontSize: 10.sp,
          fontWeight: FontWeight.w900,
          height: 1,
          color: RoastedColors.onSecondaryFixed,
        ),
      ),
    );
  }
}

class _ButtonShell extends StatelessWidget {
  const _ButtonShell({
    required this.enabled,
    required this.onTap,
    required this.decoration,
    required this.child,
  });

  final bool enabled;
  final VoidCallback? onTap;
  final BoxDecoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999.r),
          child: Ink(
            decoration: decoration,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetGlow extends StatelessWidget {
  const _SheetGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 160.h,
            right: -42.w,
            child: _GlowBlob(
              size: 180.w,
              color: RoastedColors.secondary.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: 240.h,
            left: -54.w,
            child: _GlowBlob(
              size: 200.w,
              color: RoastedColors.primary.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

TextStyle _titleStyle(Color color, {double size = 18}) => TextStyle(
  fontFamily: RoastedTypography.headlineFontFamily,
  fontSize: size.sp,
  fontWeight: FontWeight.w700,
  height: 1.1,
  color: color,
);

TextStyle _bodyStyle(Color color, {double size = 12}) => TextStyle(
  fontFamily: RoastedTypography.bodyFontFamily,
  fontSize: size.sp,
  fontWeight: FontWeight.w500,
  height: 1.2,
  color: color,
);

TextStyle _minorStyle() => TextStyle(
  fontFamily: RoastedTypography.bodyFontFamily,
  fontSize: 12.sp,
  fontWeight: FontWeight.w700,
  height: 1,
  color: RoastedColors.secondary,
);

TextStyle _badgeStyle() => TextStyle(
  fontFamily: RoastedTypography.bodyFontFamily,
  fontSize: 10.sp,
  fontWeight: FontWeight.w900,
  height: 1,
  color: RoastedColors.primary,
);

String _lockText(
  BuildContext context,
  AppStrings strings,
  StationDefinition station,
) {
  if (station.id == StationId.cashDesk) {
    return 'Requires ${AppStrings.of(context).stationName(StationId.prepStation)} ${strings.levelLabel} 10';
  }
  return strings.lockedUntil(_cash(context, station.unlockAtLifetimeCash));
}

String _cash(BuildContext context, num value) =>
    '\$${formatCompactNumber(context, value)}';

String _rate(BuildContext context, num value) {
  final text = value.abs() < 10
      ? value.toStringAsFixed(value % 1 == 0 ? 0 : 1)
      : formatCompactNumber(context, value.round());
  return '\$$text/s';
}

IconData _stationIcon(StationId id) => switch (id) {
  StationId.donerSpit => Icons.restaurant_rounded,
  StationId.prepStation => Icons.ramen_dining_rounded,
  StationId.drinkFridge => Icons.kitchen_rounded,
  StationId.cashDesk => Icons.point_of_sale_rounded,
  StationId.courierScooter => Icons.moped_rounded,
};

IconData _upgradeIcon(UpgradeId id) => switch (id) {
  UpgradeId.tapGloves => Icons.pan_tool_alt_rounded,
  UpgradeId.sharpKnife => Icons.content_cut_rounded,
  UpgradeId.greaseMaintenance => Icons.oil_barrel_rounded,
  UpgradeId.brandBoard => Icons.campaign_rounded,
  UpgradeId.rushTraining => Icons.bolt_rounded,
};

const List<double> _grayscaleMatrix = [
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];
