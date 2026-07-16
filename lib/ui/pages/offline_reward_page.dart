import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/l10n/locale_case.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/doner_game_primitives.dart';
import 'package:taptapdoner/ui/widgets/stitch_bottom_sheet_primitives.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class OfflineRewardPage extends StatelessWidget {
  const OfflineRewardPage({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('offline-reward-popup-panel'),
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final pendingReward = controller.state.pendingOfflineCash;
          final doubledReward = pendingReward * 2;

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 360 || constraints.maxHeight < 620;
              final horizontalPadding = compact ? 16.w : 18.w;
              final radius = BorderRadius.circular(22.r);

              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: DonerGradients.sheet,
                  borderRadius: radius,
                  border: Border.all(
                    color: DonerColors.borderPrimary.withValues(alpha: 0.78),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.44),
                      blurRadius: 32.r,
                      offset: Offset(0, 14.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OfflineRewardHeader(compact: compact),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            12.h,
                            horizontalPadding,
                            12.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              StitchSheetSectionDivider(
                                label: AppStrings.of(
                                  context,
                                ).offlineSummaryTitle,
                              ),
                              SizedBox(height: 10.h),
                              _RewardSummaryCard(pendingReward: pendingReward),
                              SizedBox(height: 10.h),
                              _AdOfferCard(
                                doubledReward: doubledReward,
                                compact: compact,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _OfflineActionBar(
                        controller: controller,
                        horizontalPadding: horizontalPadding,
                        compact: compact,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OfflineRewardHeader extends StatelessWidget {
  const _OfflineRewardHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final titleHeight = compact ? 25.sp : 29.sp;

    return DecoratedBox(
      decoration: _offlineHeaderDecoration(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, compact ? 14.h : 16.h, 18.w, 13.h),
        child: SizedBox(
          height: titleHeight,
          child: Text(
            strings.offlineTitle.toLocaleUpperCase(context),
            key: const ValueKey('offline-reward-popup-title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.headlineFontFamily,
              fontSize: titleHeight,
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
        ),
      ),
    );
  }
}

class _RewardSummaryCard extends StatelessWidget {
  const _RewardSummaryCard({required this.pendingReward});

  final dynamic pendingReward;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final amount = formatCompactCurrency(context, pendingReward);

    return DonerPanel(
      key: const ValueKey('offline-reward-summary-card'),
      borderColor: DonerColors.goldPrimary.withValues(alpha: 0.52),
      shadow: DonerShadows.goldGlow,
      borderRadius: BorderRadius.circular(14.r),
      padding: EdgeInsets.all(14.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DonerIconMedallion(
            icon: DonerIcons.upgradeOffline,
            size: 54.r,
            iconSize: 22.r,
            backgroundColor: DonerColors.orangeAccent,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.offlineAmount(amount),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: RoastedTypography.headlineFontFamily,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0,
                    color: DonerColors.goldPrimary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  strings.offlineSummary(24),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: RoastedTypography.bodyFontFamily,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: DonerColors.bodyText,
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

class _AdOfferCard extends StatelessWidget {
  const _AdOfferCard({required this.doubledReward, required this.compact});

  final dynamic doubledReward;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final doubledAmount = formatCompactCurrency(context, doubledReward);

    return Container(
      key: const ValueKey('offline-reward-ad-offer-card'),
      padding: EdgeInsets.all(compact ? 12.r : 14.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6F3A0B),
            Color(0xFFA86113),
            Color(0xFFE1AD4B),
            Color(0xFF7A3B0D),
          ],
          stops: [0.0, 0.38, 0.68, 1.0],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: DonerColors.goldPrimary.withValues(alpha: 0.70),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: DonerColors.goldPrimary.withValues(alpha: 0.20),
            blurRadius: 18.r,
            offset: Offset(0, 7.h),
          ),
          BoxShadow(
            color: DonerColors.goldBright.withValues(alpha: 0.18),
            blurRadius: 14.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DoubleRewardBadge(compact: compact),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.offlineDoubleOfferTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: RoastedTypography.headlineFontFamily,
                        fontSize: compact ? 15.sp : 16.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: 0,
                        color: DonerColors.goldPrimary,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      strings.offlineDoubleOfferBody(doubledAmount),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: RoastedTypography.bodyFontFamily,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: DonerColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            key: const ValueKey('offline-reward-double-amount-badge'),
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              gradient: DonerGradients.activeButton,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: DonerColors.goldBright.withValues(alpha: 0.76),
              ),
              boxShadow: DonerShadows.goldGlow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  DonerIcons.cash,
                  size: 14.r,
                  color: DonerColors.goldBright,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+ $doubledAmount',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: RoastedTypography.headlineFontFamily,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: 0,
                        color: DonerColors.creamText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _PreviewPill(
                  icon: DonerIcons.shield,
                  label: strings.offlineAdPreviewLabel,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _RewardActionButton(
                  key: const ValueKey('offline-reward-ad-placeholder-button'),
                  label: strings.watchAdDoubleLabel,
                  icon: DonerIcons.rewardAd,
                  enabled: true,
                  primary: true,
                  height: 42.h,
                  onPressed: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoubleRewardBadge extends StatelessWidget {
  const _DoubleRewardBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 54.r : 60.r;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: DonerGradients.secondaryAction,
        border: Border.all(color: DonerColors.goldBright, width: 2),
        boxShadow: DonerShadows.goldGlow,
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 7.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '2x',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: RoastedTypography.headlineFontFamily,
                    fontSize: compact ? 20.sp : 23.sp,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    letterSpacing: 0,
                    color: DonerColors.creamText,
                  ),
                ),
                Text(
                  'BONUS',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: RoastedTypography.bodyFontFamily,
                    fontSize: 7.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: DonerColors.goldBright,
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

class _OfflineActionBar extends StatelessWidget {
  const _OfflineActionBar({
    required this.controller,
    required this.horizontalPadding,
    required this.compact,
  });

  final GameController controller;
  final double horizontalPadding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DonerColors.panelDark.withValues(alpha: 0.94),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18.r,
            offset: Offset(0, -8.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          10.h,
          horizontalPadding,
          compact ? 12.h : 14.h,
        ),
        child: Row(
          children: [
            Expanded(
              child: _RewardActionButton(
                key: const ValueKey('offline-reward-dismiss-button'),
                label: strings.dismissLabel,
                icon: DonerIcons.close,
                enabled: true,
                primary: false,
                onPressed: () => unawaited(controller.dismissOfflineReward()),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _RewardActionButton(
                key: const ValueKey('offline-reward-claim-button'),
                label: strings.claimLabel,
                icon: DonerIcons.cash,
                enabled: true,
                primary: true,
                onPressed: () => unawaited(controller.claimOfflineReward()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  const _PreviewPill({required this.icon, required this.label});

  final FaIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: DonerColors.panelDark.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.58),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 13.r, color: DonerColors.tealBright),
          SizedBox(width: 7.w),
          Flexible(
            child: Text(
              label.toLocaleUpperCase(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w900,
                height: 1,
                color: DonerColors.bodyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardActionButton extends StatelessWidget {
  const _RewardActionButton({
    required this.label,
    required this.enabled,
    required this.primary,
    required this.onPressed,
    super.key,
    this.icon,
    this.height,
  });

  final String label;
  final bool enabled;
  final bool primary;
  final VoidCallback? onPressed;
  final FaIconData? icon;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10.r);
    final textColor = enabled
        ? DonerColors.creamText
        : DonerColors.disabledText;
    final gradient = enabled && primary ? DonerGradients.activeButton : null;
    final backgroundColor = enabled
        ? DonerColors.panelPrimary
        : DonerColors.disabledBg.withValues(alpha: 0.76);

    return Opacity(
      opacity: enabled ? 1 : 0.78,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashFactory: InkRipple.splashFactory,
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: Ink(
            height: height ?? 48.h,
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? backgroundColor : null,
              borderRadius: radius,
              border: Border.all(
                color: enabled
                    ? primary
                          ? DonerColors.goldPrimary
                          : DonerColors.borderSoft
                    : const Color(0xFF6B5447),
                width: enabled && primary ? 1.5 : 1,
              ),
              boxShadow: enabled && primary ? DonerShadows.goldGlow : null,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    FaIcon(
                      icon,
                      size: 15.r,
                      color: enabled && primary
                          ? DonerColors.goldBright
                          : textColor,
                    ),
                    SizedBox(width: 7.w),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label.toLocaleUpperCase(context),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: RoastedTypography.bodyFontFamily,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                          height: 1,
                          color: textColor,
                        ),
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

BoxDecoration _offlineHeaderDecoration() => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      DonerColors.panelSecondary,
      DonerColors.panelPrimary,
      DonerColors.panelDark,
    ],
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.28),
      blurRadius: 18.r,
      offset: Offset(0, 8.h),
    ),
  ],
);
