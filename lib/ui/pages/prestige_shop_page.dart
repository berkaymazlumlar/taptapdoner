import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/audio/purchase_sfx_player.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/doner_game_primitives.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class PrestigeShopPage extends StatelessWidget {
  const PrestigeShopPage({required this.controller, super.key, this.onBack});

  final GameController controller;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: DonerColors.bgPrimary,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: DonerGradients.sheet),
        child: SafeArea(
          child: ValueListenableBuilder<PrestigeSnapshot>(
            valueListenable: controller.prestigeSnapshotListenable,
            builder: (context, snapshot, _) {
              return Column(
                key: const ValueKey('prestige-shop-page-root'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38.w,
                                    height: 38.w,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: DonerColors.tealBright.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: DonerColors.tealBright
                                            .withValues(alpha: 0.42),
                                      ),
                                    ),
                                    child: FaIcon(
                                      DonerIcons.shop,
                                      size: 16.sp,
                                      color: DonerColors.tealBright,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      'Prestige Shop',
                                      key: const ValueKey(
                                        'prestige-shop-page-title',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: RoastedTypography
                                            .headlineFontFamily,
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                        color: DonerColors.goldPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                strings.prestigeConfirm,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: RoastedTypography.bodyFontFamily,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: DonerColors.bodyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        _PrestigeShopCloseButton(
                          onPressed:
                              onBack ?? () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _PrestigeShopSummaryCard(snapshot: snapshot),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var index = 0;
                            index < snapshot.shopUpgrades.length;
                            index += 1
                          ) ...[
                            _PrestigeShopUpgradeCard(
                              upgrade: snapshot.shopUpgrades[index],
                              onBuy: () async {
                                final bought = await controller
                                    .buyPrestigeUpgrade(
                                      snapshot.shopUpgrades[index].id,
                                    );
                                if (bought) {
                                  unawaited(PurchaseSfxPlayer.play());
                                }
                              },
                            ),
                            if (index != snapshot.shopUpgrades.length - 1)
                              SizedBox(height: 8.h),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrestigeShopSummaryCard extends StatelessWidget {
  const _PrestigeShopSummaryCard({required this.snapshot});

  final PrestigeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: DonerColors.borderPrimary.withValues(alpha: 0.78),
          width: 1.5,
        ),
        boxShadow: DonerShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: _PrestigeShopMetric(
              label: 'Unspent Points',
              value: formatCompactNumber(context, snapshot.unspentPoints),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _PrestigeShopMetric(
              label: 'Total Points',
              value: formatCompactNumber(context, snapshot.reputation),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _PrestigeShopMetric(
              label: 'Runs',
              value: snapshot.prestigeCount.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestigeShopMetric extends StatelessWidget {
  const _PrestigeShopMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 54.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: DonerColors.panelDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.54),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.bodyFontFamily,
              fontSize: 8.sp,
              fontWeight: FontWeight.w800,
              color: DonerColors.bodyText,
            ),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: RoastedTypography.headlineFontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
                color: DonerColors.creamText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestigeShopUpgradeCard extends StatelessWidget {
  const _PrestigeShopUpgradeCard({required this.upgrade, required this.onBuy});

  final PrestigeShopUpgradeSnapshot upgrade;
  final Future<void> Function() onBuy;

  @override
  Widget build(BuildContext context) {
    final buttonText = upgrade.maxed ? 'MAX' : '${upgrade.cost} pts';
    return Container(
      key: ValueKey('prestige-shop-upgrade-${upgrade.id}'),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: DonerColors.borderPrimary.withValues(alpha: 0.76),
          width: 1.4,
        ),
        boxShadow: DonerShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${upgrade.name} Lv. ${upgrade.level}/${upgrade.maxLevel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: RoastedTypography.bodyFontFamily,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        color: DonerColors.creamText,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      upgrade.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: RoastedTypography.bodyFontFamily,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: DonerColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              SizedBox(
                width: 88.w,
                child: DonerGameButton(
                  key: ValueKey('prestige-shop-buy-button-${upgrade.id}'),
                  label: buttonText,
                  icon: DonerIcons.prestige,
                  enabled: upgrade.canAfford,
                  onPressed: upgrade.canAfford
                      ? () async {
                          await onBuy();
                        }
                      : null,
                  height: 38.h,
                  pill: true,
                  fontSize: 10.sp,
                  iconSize: 12.sp,
                  horizontalPadding: 8.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: DonerColors.panelDark.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: DonerColors.borderSoft.withValues(alpha: 0.50),
              ),
            ),
            child: Text(
              upgrade.maxed
                  ? upgrade.currentEffectLabel
                  : '${upgrade.currentEffectLabel} -> ${upgrade.nextEffectLabel}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: DonerColors.tealBright,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestigeShopCloseButton extends StatelessWidget {
  const _PrestigeShopCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('prestige-shop-page-close-button'),
        splashFactory: InkRipple.splashFactory,
        borderRadius: BorderRadius.circular(999.r),
        onTap: onPressed,
        child: Ink(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: DonerColors.panelDark.withValues(alpha: 0.82),
            shape: BoxShape.circle,
            border: Border.all(color: DonerColors.borderSoft),
          ),
          child: Center(
            child: FaIcon(
              DonerIcons.close,
              size: 15.sp,
              color: DonerColors.bodyText,
            ),
          ),
        ),
      ),
    );
  }
}
