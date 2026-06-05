import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/doner_game_primitives.dart';
import 'package:taptapdoner/ui/widgets/stitch_bottom_sheet_primitives.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

enum PrestigePagePresentation { sheet, tab }

class PrestigePage extends StatelessWidget {
  const PrestigePage({
    required this.controller,
    super.key,
    this.onOpenKitchen,
    this.onOpenShop,
    this.onBack,
    this.onPrestigeApplied,
    this.presentation = PrestigePagePresentation.sheet,
  });

  final GameController controller;
  final VoidCallback? onOpenKitchen;
  final VoidCallback? onOpenShop;
  final VoidCallback? onBack;
  final Future<void> Function()? onPrestigeApplied;
  final PrestigePagePresentation presentation;

  @override
  Widget build(BuildContext context) {
    final isTab = presentation == PrestigePagePresentation.tab;

    return Material(
      key: const ValueKey('prestige-sheet-surface'),
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            StitchBottomSheetSurface(
              maxWidth: isTab ? double.infinity : null,
              maxHeight: isTab ? double.infinity : null,
              backgroundGradient: DonerGradients.sheet,
              borderRadius: isTab ? BorderRadius.zero : null,
              showBorder: !isTab,
              showShadow: !isTab,
              child: ValueListenableBuilder<PrestigeSnapshot>(
                valueListenable: controller.prestigeSnapshotListenable,
                builder: (context, snapshot, _) {
                  final strings = AppStrings.of(context);
                  final availablePoints = snapshot.availablePoints;
                  final progress = _prestigeProgress(snapshot);
                  final progressPercent = (progress * 100).round();
                  final canPrestige = availablePoints > 0;
                  final Future<void> Function()? prestigeAction = canPrestige
                      ? () async {
                          final applied = await controller.applyPrestige();
                          if (!applied) {
                            return;
                          }
                          if (onPrestigeApplied != null) {
                            await onPrestigeApplied!();
                          } else if (context.mounted) {
                            Navigator.of(context).maybePop();
                          }
                        }
                      : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isTab)
                        const StitchSheetHandle(
                          key: ValueKey('prestige-sheet-handle'),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20.w,
                          isTab ? 12.h : 0,
                          20.w,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              strings.prestigeTitle,
                              key: const ValueKey('prestige-sheet-title'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily:
                                    RoastedTypography.headlineFontFamily,
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                letterSpacing: 0,
                                color: DonerColors.goldPrimary,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.52),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              strings.prestigeConfirm.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: RoastedTypography.bodyFontFamily,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: 1.5,
                                color: DonerColors.bodyText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            key: const ValueKey('prestige-card-stack'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: 12.h),
                              _PrestigeHeroCard(
                                snapshot: snapshot,
                                progress: progress,
                                progressPercent: progressPercent,
                                showInlineAction: isTab,
                                actionEnabled: canPrestige,
                                onPrestigePressed: prestigeAction,
                              ),
                              SizedBox(height: 12.h),
                              _PrestigeChecklistCard(
                                key: const ValueKey('prestige-resets-card'),
                                title: 'What Resets',
                                items: snapshot.resetItems,
                                icon: DonerIcons.reset,
                                accent: DonerColors.orangeAccent,
                              ),
                              SizedBox(height: 12.h),
                              _PrestigeChecklistCard(
                                key: const ValueKey('prestige-stays-card'),
                                title: 'What Stays',
                                items: snapshot.keptItems,
                                icon: DonerIcons.shield,
                                accent: DonerColors.tealBright,
                              ),
                              SizedBox(height: 12.h),
                            ],
                          ),
                        ),
                      ),
                      if (!isTab)
                        _PrestigeActionFooter(
                          enabled: canPrestige,
                          onPrestigePressed: prestigeAction,
                          onClosePressed:
                              onBack ??
                              onOpenKitchen ??
                              onOpenShop ??
                              () => Navigator.of(context).maybePop(),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrestigeHeroCard extends StatelessWidget {
  const _PrestigeHeroCard({
    required this.snapshot,
    required this.progress,
    required this.progressPercent,
    required this.showInlineAction,
    required this.actionEnabled,
    required this.onPrestigePressed,
  });

  final PrestigeSnapshot snapshot;
  final double progress;
  final int progressPercent;
  final bool showInlineAction;
  final bool actionEnabled;
  final Future<void> Function()? onPrestigePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('prestige-summary-card'),
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: DonerColors.borderPrimary.withValues(alpha: 0.86),
          width: 1.5,
        ),
        boxShadow: DonerShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DonerColors.goldPrimary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: DonerColors.borderPrimary),
                ),
                child: FaIcon(
                  DonerIcons.prestige,
                  size: 18.sp,
                  color: DonerColors.goldPrimary,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POINTS TO GAIN',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: RoastedTypography.bodyFontFamily,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 1.0,
                        color: DonerColors.goldPrimary,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _signedPoints(snapshot.pointsToGain),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: RoastedTypography.headlineFontFamily,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: DonerColors.creamText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showInlineAction) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 132.w),
                child: _PrestigePrimaryButton(
                  key: const ValueKey('prestige-action-button'),
                  enabled: actionEnabled,
                  onPressed: onPrestigePressed,
                  height: 40.h,
                  fontSize: 12.sp,
                  iconSize: 15.sp,
                  horizontalPadding: 10.w,
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          _PrestigeCompactMetricStrip(
            metrics: [
              _PrestigeMetricData(
                label: 'Earned',
                value: formatCompactCurrency(
                  context,
                  snapshot.currentTotalEarned,
                ),
              ),
              _PrestigeMetricData(
                label: 'Current',
                value: _multiplier(snapshot.currentMultiplier),
              ),
              _PrestigeMetricData(
                label: 'After',
                value: _multiplier(snapshot.newMultiplier),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'PROGRESS TO NEXT POINT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: RoastedTypography.bodyFontFamily,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: DonerColors.bodyText.withValues(alpha: 0.95),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '$progressPercent%',
                style: TextStyle(
                  fontFamily: RoastedTypography.bodyFontFamily,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w900,
                  color: DonerColors.goldBright,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          _PrestigeProgressBar(value: progress),
        ],
      ),
    );
  }
}

class _PrestigeMetricData {
  const _PrestigeMetricData({required this.label, required this.value});

  final String label;
  final String value;
}

class _PrestigeCompactMetricStrip extends StatelessWidget {
  const _PrestigeCompactMetricStrip({required this.metrics});

  final List<_PrestigeMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 6.w;
        final itemWidth = (constraints.maxWidth - (spacing * 2)) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: 6.h,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _PrestigeCompactMetricChip(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _PrestigeCompactMetricChip extends StatelessWidget {
  const _PrestigeCompactMetricChip({required this.metric});

  final _PrestigeMetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 44.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: DonerColors.panelDark.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.46),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.bodyFontFamily,
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: 0.5,
              color: DonerColors.bodyText,
            ),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: RoastedTypography.headlineFontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                height: 1,
                color: DonerColors.creamText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestigeProgressBar extends StatelessWidget {
  const _PrestigeProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return DonerProgressBar(value: value);
  }
}

class _PrestigeChecklistCard extends StatelessWidget {
  const _PrestigeChecklistCard({
    required this.title,
    required this.items,
    required this.icon,
    required this.accent,
    super.key,
  });

  final String title;
  final List<String> items;
  final FaIconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: DonerColors.borderPrimary.withValues(alpha: 0.78),
          width: 1.5,
        ),
        boxShadow: DonerShadows.soft,
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withValues(alpha: 0.42)),
                ),
                alignment: Alignment.center,
                child: FaIcon(icon, size: 16.sp, color: accent),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: RoastedTypography.headlineFontFamily,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: DonerColors.goldPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          for (var index = 0; index < items.length; index += 1) ...[
            _PrestigeChecklistRow(item: items[index], accent: accent),
            if (index != items.length - 1) SizedBox(height: 6.h),
          ],
        ],
      ),
    );
  }
}

class _PrestigeChecklistRow extends StatelessWidget {
  const _PrestigeChecklistRow({required this.item, required this.accent});

  final String item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 3.h),
          child: FaIcon(DonerIcons.diamond, size: 8.sp, color: accent),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            item,
            style: TextStyle(
              fontFamily: RoastedTypography.bodyFontFamily,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              height: 1.22,
              color: DonerColors.bodyText,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrestigeActionFooter extends StatelessWidget {
  const _PrestigeActionFooter({
    required this.enabled,
    required this.onPrestigePressed,
    required this.onClosePressed,
  });

  final bool enabled;
  final Future<void> Function()? onPrestigePressed;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrestigePrimaryButton(
            key: const ValueKey('prestige-action-button'),
            enabled: enabled,
            onPressed: onPrestigePressed,
          ),
          SizedBox(height: 8.h),
          _PrestigeCloseButton(
            key: const ValueKey('prestige-close-button'),
            onPressed: onClosePressed,
          ),
        ],
      ),
    );
  }
}

class _PrestigePrimaryButton extends StatelessWidget {
  const _PrestigePrimaryButton({
    required this.enabled,
    required this.onPressed,
    super.key,
    this.height,
    this.fontSize,
    this.iconSize,
    this.horizontalPadding,
  });

  final bool enabled;
  final Future<void> Function()? onPressed;
  final double? height;
  final double? fontSize;
  final double? iconSize;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return DonerGameButton(
      label: 'PRESTIGE',
      icon: DonerIcons.prestige,
      enabled: enabled,
      onPressed: enabled
          ? () async {
              await onPressed?.call();
            }
          : null,
      height: height ?? 52.h,
      pill: true,
      fontSize: fontSize,
      iconSize: iconSize,
      horizontalPadding: horizontalPadding,
    );
  }
}

class _PrestigeCloseButton extends StatelessWidget {
  const _PrestigeCloseButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashFactory: InkRipple.splashFactory,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999.r),
        child: Ink(
          height: 42.h,
          decoration: BoxDecoration(
            color: DonerColors.panelDark.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(
              color: DonerColors.borderSoft.withValues(alpha: 0.58),
            ),
          ),
          child: Center(
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 2.0,
                color: DonerColors.bodyText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _prestigeProgress(PrestigeSnapshot snapshot) {
  final threshold = snapshot.threshold;
  if (threshold <= 0) {
    return 0;
  }

  final points = snapshot.pointsToGain;
  final currentPointCash = points * points * threshold;
  final nextPoints = points + 1;
  final nextPointCash = nextPoints * nextPoints * threshold;
  if (nextPointCash <= currentPointCash) {
    return 0;
  }

  return ((snapshot.currentTotalEarned - currentPointCash) /
          (nextPointCash - currentPointCash))
      .clamp(0.0, 1.0)
      .toDouble();
}

String _signedPoints(int points) => points > 0 ? '+$points' : '0';

String _multiplier(double value) => 'x${value.toStringAsFixed(2)}';
