import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/audio/purchase_sfx_player.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/doner_game_primitives.dart';
import 'package:taptapdoner/ui/widgets/stitch_bottom_sheet_primitives.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

enum ShopPagePresentation { sheet, tab }

class ShopPage extends StatelessWidget {
  const ShopPage({
    required this.controller,
    required this.onOpenKitchen,
    required this.onOpenPrestige,
    super.key,
    this.onBack,
    this.presentation = ShopPagePresentation.sheet,
  });

  final GameController controller;
  final VoidCallback onOpenKitchen;
  final VoidCallback onOpenPrestige;
  final VoidCallback? onBack;
  final ShopPagePresentation presentation;

  @override
  Widget build(BuildContext context) {
    final isTab = presentation == ShopPagePresentation.tab;
    final closeAction = onBack ?? onOpenKitchen;

    return Material(
      key: const ValueKey('shop-sheet-surface'),
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          StitchBottomSheetSurface(
            maxWidth: isTab ? double.infinity : null,
            maxHeight: isTab ? double.infinity : null,
            borderRadius: isTab ? BorderRadius.zero : null,
            showBorder: !isTab,
            showShadow: !isTab,
            child: ValueListenableBuilder<ShopSnapshot>(
              valueListenable: controller.shopSnapshotListenable,
              builder: (context, snapshot, _) {
                final levelUp = controller.consumeShopLevelUpSnapshot();
                if (levelUp != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      _showShopLevelUpDialog(context, levelUp);
                    }
                  });
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxWidth < 360 ||
                        constraints.maxHeight < 700;
                    final horizontalPadding = compact ? 20.w : 24.w;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isTab) const StitchSheetHandle(),
                        Expanded(
                          child: _ShopContent(
                            controller: controller,
                            snapshot: snapshot,
                            horizontalPadding: horizontalPadding,
                            compact: compact,
                            isTab: isTab,
                            onClose: closeAction,
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

void _showShopLevelUpDialog(
  BuildContext context,
  ShopLevelUpSnapshot snapshot,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        key: const ValueKey('shop-level-up-popup'),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            gradient: DonerGradients.card,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: DonerColors.goldPrimary.withValues(alpha: 0.88),
              width: 1.6,
            ),
            boxShadow: DonerShadows.soft,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  FaIcon(
                    DonerIcons.shop,
                    color: DonerColors.goldPrimary,
                    size: 22.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'SHOP LEVEL UP',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: RoastedTypography.headlineFontFamily,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        color: DonerColors.goldPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                '${snapshot.previousLevelName} -> ${snapshot.currentLevelName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: RoastedTypography.bodyFontFamily,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: DonerColors.creamText,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Unlocked: ${snapshot.unlockLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: RoastedTypography.bodyFontFamily,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: DonerColors.bodyText,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Income x${snapshot.incomeMultiplier.toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: RoastedTypography.bodyFontFamily,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: DonerColors.tealBright,
                ),
              ),
              SizedBox(height: 14.h),
              DonerGameButton(
                label: 'OK',
                icon: DonerIcons.shield,
                enabled: true,
                onPressed: () => Navigator.of(context).maybePop(),
                height: 42.h,
                pill: true,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ShopContent extends StatelessWidget {
  const _ShopContent({
    required this.controller,
    required this.snapshot,
    required this.horizontalPadding,
    required this.compact,
    required this.isTab,
    required this.onClose,
  });

  final GameController controller;
  final ShopSnapshot snapshot;
  final double horizontalPadding;
  final bool compact;
  final bool isTab;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShopScrollHeader(
          snapshot: snapshot,
          strings: strings,
          horizontalPadding: horizontalPadding,
          compact: compact,
          isTab: isTab,
          onClose: onClose,
        ),
        Expanded(
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  88.h,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ShopProgressionCard(snapshot: snapshot.progression),
                      SizedBox(height: 12.h),
                      StitchSheetSectionDivider(label: strings.upgradesTitle),
                      SizedBox(height: 8.h),
                      for (final upgrade in controller.upgrades)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: _UpgradeCard(
                            controller: controller,
                            shopSnapshot: snapshot,
                            upgrade: upgrade,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShopProgressionCard extends StatelessWidget {
  const _ShopProgressionCard({required this.snapshot});

  final ShopProgressionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final nextName = snapshot.nextName;
    return Container(
      key: const ValueKey('shop-progression-card'),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: DonerColors.borderPrimary.withValues(alpha: 0.78),
          width: 1.4,
        ),
        boxShadow: DonerShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DonerColors.goldPrimary.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                  border: Border.all(color: DonerColors.borderPrimary),
                ),
                child: FaIcon(
                  DonerIcons.shop,
                  size: 14.sp,
                  color: DonerColors.goldPrimary,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHOP LEVEL ${snapshot.currentLevel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: RoastedTypography.bodyFontFamily,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: DonerColors.goldPrimary,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      snapshot.currentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: RoastedTypography.headlineFontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: 0,
                        color: DonerColors.creamText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerLeft,
            child: _ShopBonusPill(
              label: 'Income',
              value: 'x${snapshot.incomeMultiplier.toStringAsFixed(2)}',
            ),
          ),
          SizedBox(height: 10.h),
          if (nextName == null)
            Text(
              'Max shop level reached',
              style: TextStyle(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: DonerColors.bodyText,
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Next: Lv. ${snapshot.nextLevel} $nextName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: RoastedTypography.bodyFontFamily,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w900,
                      color: DonerColors.bodyText,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '${snapshot.completedRequirements}/${snapshot.requirements.length}',
                  style: TextStyle(
                    fontFamily: RoastedTypography.bodyFontFamily,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: DonerColors.tealBright,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            for (final requirement in snapshot.requirements.take(4))
              Padding(
                padding: EdgeInsets.only(bottom: 5.h),
                child: Row(
                  children: [
                    FaIcon(
                      requirement.completed
                          ? DonerIcons.shield
                          : DonerIcons.lock,
                      size: 10.sp,
                      color: requirement.completed
                          ? DonerColors.tealBright
                          : DonerColors.bodyText.withValues(alpha: 0.65),
                    ),
                    SizedBox(width: 7.w),
                    Expanded(
                      child: Text(
                        requirement.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: RoastedTypography.bodyFontFamily,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: requirement.completed
                              ? DonerColors.creamText
                              : DonerColors.bodyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ShopBonusPill extends StatelessWidget {
  const _ShopBonusPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 70.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: DonerColors.panelDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: DonerColors.borderSoft),
      ),
      child: Column(
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
          SizedBox(height: 2.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.headlineFontFamily,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              height: 1,
              color: DonerColors.goldPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopScrollHeader extends StatelessWidget {
  const _ShopScrollHeader({
    required this.snapshot,
    required this.strings,
    required this.horizontalPadding,
    required this.compact,
    required this.isTab,
    required this.onClose,
  });

  final ShopSnapshot snapshot;
  final AppStrings strings;
  final double horizontalPadding;
  final bool compact;
  final bool isTab;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final titleHeight = compact ? 28.sp : 32.sp;
    final titleRowHeight = isTab ? titleHeight : math.max(40.w, titleHeight);

    final headerBody = DecoratedBox(
      decoration: _shopHeaderDecoration(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          isTab ? (compact ? 12.h : 16.h) : 0,
          horizontalPadding,
          compact ? 10.h : 12.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: titleRowHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      strings.shopTitle.toUpperCase(),
                      key: const ValueKey('shop-sheet-title'),
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
                  if (!isTab) SizedBox(width: 52.w),
                ],
              ),
            ),
            SizedBox(height: compact ? 8.h : 10.h),
            SizedBox(
              key: const ValueKey('shop-stat-row'),
              height: _shopStatRowHeight(compact),
              child: Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      icon: DonerIcons.cash,
                      label: strings.cashLabel,
                      value: _cash(context, snapshot.hud.cash),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _StatChip(
                      icon: DonerIcons.idleIncome,
                      label: strings.idleIncomeLabel,
                      value:
                          '${formatCompactDecimal(context, snapshot.hud.passiveIncomePerSecond)}/s',
                      iconColor: DonerColors.orangeAccent,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _StatChip(
                      icon: DonerIcons.reputation,
                      label: strings.reputationLabel,
                      value: snapshot.hud.reputation.toString(),
                      iconColor: DonerColors.tealBright,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(child: headerBody),
        if (!isTab)
          Positioned(
            top: 0,
            right: horizontalPadding,
            child: KeyedSubtree(
              key: const ValueKey('shop-sheet-close-button'),
              child: StitchSheetCloseButton(onPressed: onClose),
            ),
          ),
      ],
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.controller,
    required this.shopSnapshot,
    required this.upgrade,
  });

  final GameController controller;
  final ShopSnapshot shopSnapshot;
  final UpgradeDefinition upgrade;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final upgradeSnapshot = shopSnapshot.upgrades[upgrade.id]!;
    final maxed = upgradeSnapshot.maxed;
    final canAfford = upgradeSnapshot.canAfford;
    final currentItemName = strings.upgradeItemName(
      upgrade.id,
      upgradeSnapshot.currentItemKey,
    );
    final unlocksNextItem =
        upgradeSnapshot.unlocksNextItem && upgradeSnapshot.nextItemKey != null;
    final nextItemName = upgradeSnapshot.nextItemKey == null
        ? null
        : strings.upgradeItemName(upgrade.id, upgradeSnapshot.nextItemKey!);
    final nextMilestoneItemName = upgradeSnapshot.nextMilestoneItemKey == null
        ? null
        : strings.upgradeItemName(
            upgrade.id,
            upgradeSnapshot.nextMilestoneItemKey!,
          );
    final nextMilestoneReward = upgradeSnapshot.nextMilestoneReward;
    final nextMilestoneRewardText = nextMilestoneReward == null
        ? null
        : strings.milestoneRewardLabel(nextMilestoneReward);
    final nextMilestoneText =
        nextMilestoneItemName == null ||
            upgradeSnapshot.nextMilestoneLevel == null
        ? strings.upgradeMaxLevelLabel
        : strings.upgradeMilestonePreview(
            nextMilestoneItemName,
            upgradeSnapshot.nextMilestoneLevel!,
            nextMilestoneRewardText,
          );
    final nextItemPreviewValue = nextItemName == null
        ? strings.upgradeMaxLevelLabel
        : '$nextItemName Lv. 1';
    final nextItemPreviewEffect = upgradeSnapshot.nextItemEffect == null
        ? null
        : _effect(context, upgrade, upgradeSnapshot.nextItemEffect!);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final isSpecialState = maxed || unlocksNextItem;
        final actionLabel = maxed
            ? 'MAX'
            : !canAfford
            ? strings.insufficientFundsLabel
            : unlocksNextItem
            ? strings.upgradeTierUpAction
            : strings.upgradeLevelUpAction;
        final levelText =
            'Lv. ${upgradeSnapshot.itemLevel}/${upgradeSnapshot.maxItemLevel}';
        final tierText =
            '${strings.upgradeTierLabel} ${upgradeSnapshot.currentItemTier}';
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.upgradeName(upgrade.id),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle(
                isSpecialState
                    ? DonerColors.goldPrimary
                    : DonerColors.creamText,
                size: compact ? 14 : 15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              currentItemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle(
                DonerColors.goldBright,
                size: compact ? 10 : 11,
              ).copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              '$tierText - $levelText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle(
                DonerColors.bodyText.withValues(alpha: 0.92),
                size: compact ? 9.5 : 10,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        );
        final nextBlock = maxed
            ? _MaxStateBlock(
                key: ValueKey('shop-upgrade-max-${upgrade.id.key}'),
                label: strings.upgradeMaxLevelLabel,
              )
            : unlocksNextItem && nextItemName != null
            ? _NextTierPreview(
                key: ValueKey('shop-upgrade-next-item-${upgrade.id.key}'),
                icon: _upgradeIcon(upgrade.id),
                label: '${strings.upgradeNextTierLabel}:',
                itemName: '$nextItemName Lv. 1',
                effect: _effect(context, upgrade, upgradeSnapshot.nextEffect),
              )
            : _EffectBlock(
                label: '${strings.upgradeNextLevelLabel}:',
                value: _effect(context, upgrade, upgradeSnapshot.nextEffect),
                subdued: true,
              );

        return Container(
          key: ValueKey('shop-upgrade-card-${upgrade.id.key}'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: DonerGradients.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSpecialState
                  ? DonerColors.goldPrimary.withValues(alpha: 0.70)
                  : upgradeSnapshot.purchased
                  ? DonerColors.goldPrimary.withValues(alpha: 0.38)
                  : DonerColors.borderSoft.withValues(alpha: 0.72),
              width: 1.2,
            ),
            boxShadow: isSpecialState ? DonerShadows.goldGlow : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _UpgradeIcon(
                    icon: _upgradeIcon(upgrade.id),
                    owned: upgradeSnapshot.purchased || isSpecialState,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: titleBlock),
                  const SizedBox(width: 8),
                  _UpgradeActionButton(
                    key: ValueKey('shop-upgrade-button-${upgrade.id.key}'),
                    label: actionLabel,
                    enabled: canAfford,
                    maxed: maxed,
                    highlighted: unlocksNextItem,
                    width: compact ? 82 : 104,
                    onTap: canAfford
                        ? () {
                            unawaited(
                              _buyUpgradeWithFeedback(
                                context,
                                controller,
                                upgrade,
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: _EffectBlock(
                      label: '${strings.upgradeEffectName(upgrade.id)}:',
                      value: _effect(
                        context,
                        upgrade,
                        upgradeSnapshot.currentEffect,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: nextBlock),
                  if (!maxed) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: _CostBlock(
                        label: '${strings.upgradeCostLabel}:',
                        value: _cash(context, upgradeSnapshot.cost),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _InfoBlock(
                      key: ValueKey(
                        'shop-upgrade-next-milestone-${upgrade.id.key}',
                      ),
                      label: '${strings.upgradeNextMilestoneLabel}:',
                      value: nextMilestoneText,
                      highlighted: !maxed,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _InfoBlock(
                      key: ValueKey(
                        'shop-upgrade-next-preview-${upgrade.id.key}',
                      ),
                      label: '${strings.upgradeNextItemPreviewLabel}:',
                      value: nextItemPreviewValue,
                      detail: nextItemPreviewEffect,
                      highlighted: unlocksNextItem,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    super.key,
    this.detail,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final String? detail;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? DonerColors.goldPrimary.withValues(alpha: 0.12)
            : DonerColors.panelDark.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: highlighted
              ? DonerColors.goldPrimary.withValues(alpha: 0.36)
              : DonerColors.borderSoft.withValues(alpha: 0.48),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.bodyFontFamily,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              height: 1,
              color: DonerColors.bodyText.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.headlineFontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1,
              color: highlighted
                  ? DonerColors.goldBright
                  : DonerColors.creamText,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                height: 1,
                color: DonerColors.goldPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EffectBlock extends StatelessWidget {
  const _EffectBlock({
    required this.label,
    required this.value,
    this.subdued = false,
  });

  final String label;
  final String value;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: subdued
            ? DonerColors.panelDark.withValues(alpha: 0.74)
            : DonerColors.panelDark.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.48),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.bodyFontFamily,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              height: 1,
              color: DonerColors.bodyText.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.headlineFontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1,
              color: subdued ? DonerColors.goldBright : DonerColors.goldPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextTierPreview extends StatelessWidget {
  const _NextTierPreview({
    required this.icon,
    required this.label,
    required this.itemName,
    required this.effect,
    super.key,
  });

  final FaIconData icon;
  final String label;
  final String itemName;
  final String effect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: DonerColors.goldPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DonerColors.goldPrimary.withValues(alpha: 0.36),
        ),
      ),
      child: Row(
        children: [
          _MiniUpgradeIcon(icon: icon),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: RoastedTypography.bodyFontFamily,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: DonerColors.goldPrimary.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: RoastedTypography.headlineFontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: DonerColors.creamText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  effect,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: RoastedTypography.bodyFontFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: DonerColors.goldBright,
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

class _MaxStateBlock extends StatelessWidget {
  const _MaxStateBlock({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: DonerColors.goldPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DonerColors.goldPrimary.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          FaIcon(DonerIcons.prestige, size: 13, color: DonerColors.goldPrimary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: RoastedTypography.headlineFontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                height: 1,
                color: DonerColors.goldPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostBlock extends StatelessWidget {
  const _CostBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: DonerColors.panelDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.54),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.bodyFontFamily,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              height: 1,
              color: DonerColors.bodyText.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.headlineFontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1,
              color: DonerColors.creamText,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeActionButton extends StatelessWidget {
  const _UpgradeActionButton({
    required this.label,
    required this.enabled,
    required this.maxed,
    required this.highlighted,
    required this.onTap,
    super.key,
    this.width = double.infinity,
  });

  final String label;
  final bool enabled;
  final bool maxed;
  final bool highlighted;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final actionable = enabled && !maxed;
    final textColor = actionable
        ? DonerColors.creamText
        : DonerColors.disabledText;
    final radius = BorderRadius.circular(10);

    return SizedBox(
      width: width,
      child: Opacity(
        opacity: actionable ? 1 : 0.78,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            onTap: actionable ? onTap : null,
            borderRadius: radius,
            child: Ink(
              height: 32,
              decoration: BoxDecoration(
                gradient: actionable || highlighted
                    ? DonerGradients.activeButton
                    : DonerGradients.disabledButton,
                borderRadius: radius,
                border: Border.all(
                  color: actionable
                      ? DonerColors.goldPrimary
                      : const Color(0xFF6B5447),
                  width: actionable ? 1.2 : 1,
                ),
                boxShadow: actionable ? DonerShadows.goldGlow : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: RoastedTypography.bodyFontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                        height: 1,
                        color: textColor,
                      ),
                    ),
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

class _MiniUpgradeIcon extends StatelessWidget {
  const _MiniUpgradeIcon({required this.icon});

  final FaIconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DonerColors.panelDark.withValues(alpha: 0.80),
        shape: BoxShape.circle,
        border: Border.all(color: DonerColors.borderSoft),
      ),
      child: Center(
        child: FaIcon(icon, size: 11, color: DonerColors.goldPrimary),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = DonerColors.tealPrimary,
  });

  final FaIconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 48.h),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.78),
          width: 1.2,
        ),
        boxShadow: DonerShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          FaIcon(icon, size: 14.r, color: iconColor),
          SizedBox(width: 5.w),
          Expanded(
            child: FittedBox(
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
                      fontSize: 7.5.sp,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: DonerColors.bodyText.withValues(alpha: 0.72),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: RoastedTypography.headlineFontFamily,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      color: DonerColors.creamText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeIcon extends StatelessWidget {
  const _UpgradeIcon({required this.icon, required this.owned});

  final FaIconData icon;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    return DonerIconMedallion(
      icon: icon,
      size: 42,
      iconSize: 18,
      backgroundColor: owned ? DonerColors.tealPrimary : DonerColors.panelDark,
      iconColor: owned ? DonerColors.goldBright : DonerColors.bodyText,
    );
  }
}

TextStyle _titleStyle(Color color, {double size = 18}) => TextStyle(
  fontFamily: RoastedTypography.headlineFontFamily,
  fontSize: size,
  fontWeight: FontWeight.w900,
  height: 1.1,
  letterSpacing: 0,
  color: color,
);

TextStyle _bodyStyle(Color color, {double size = 12}) => TextStyle(
  fontFamily: RoastedTypography.bodyFontFamily,
  fontSize: size,
  fontWeight: FontWeight.w600,
  height: 1.2,
  color: color,
);

String _cash(BuildContext context, num value) =>
    formatCompactCurrency(context, value);

String _effect(BuildContext context, UpgradeDefinition upgrade, double value) {
  final strings = AppStrings.of(context);
  final effectName = strings.upgradeEffectName(upgrade.id).toLowerCase();
  return switch (upgrade.id) {
    UpgradeId.staff =>
      '+${_compactEffectNumber(context, value)}${strings.isTurkish ? '/sn' : '/s'} $effectName',
    UpgradeId.offline => '%${(value * 100).round()} $effectName',
    _ => '${_multiplier(value)} $effectName',
  };
}

String _multiplier(double value) => 'x${value.toStringAsFixed(2)}';

String _compactEffectNumber(BuildContext context, double value) {
  if (value.abs() < 10) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }
  return formatCompactNumber(context, value.round());
}

Future<void> _buyUpgradeWithFeedback(
  BuildContext context,
  GameController controller,
  UpgradeDefinition upgrade,
) async {
  final strings = AppStrings.of(context);
  final before = controller.state.upgrade(upgrade.id);
  final beforeItemIndex = before.itemIndex
      .clamp(0, upgrade.items.length - 1)
      .toInt();
  final previousItemName = strings.upgradeItemName(
    upgrade.id,
    upgrade.items[beforeItemIndex].key,
  );

  final bought = await controller.buyUpgrade(upgrade.id);
  if (!bought) {
    return;
  }

  unawaited(PurchaseSfxPlayer.play());
  if (!context.mounted) {
    return;
  }

  final after = controller.state.upgrade(upgrade.id);
  final milestoneGrant = controller.lastPurchaseResult?.milestoneGrant;
  if (milestoneGrant != null) {
    final itemName = strings.upgradeItemName(
      upgrade.id,
      milestoneGrant.itemKey,
    );
    final reward = strings.milestoneRewardLabel(milestoneGrant.reward);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: DonerColors.panelPrimary,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.milestoneUnlockTitle,
                style: TextStyle(
                  fontFamily: RoastedTypography.headlineFontFamily,
                  fontWeight: FontWeight.w900,
                  color: DonerColors.goldPrimary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '$itemName Lv. ${milestoneGrant.level}',
                style: TextStyle(
                  fontFamily: RoastedTypography.bodyFontFamily,
                  fontWeight: FontWeight.w800,
                  color: DonerColors.creamText,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                reward,
                style: TextStyle(
                  fontFamily: RoastedTypography.headlineFontFamily,
                  fontWeight: FontWeight.w900,
                  color: DonerColors.goldBright,
                ),
              ),
            ],
          ),
        ),
      );
    return;
  }

  if (after.itemIndex <= before.itemIndex) {
    return;
  }

  final afterItemIndex = after.itemIndex
      .clamp(0, upgrade.items.length - 1)
      .toInt();
  final afterSnapshot =
      controller.shopSnapshotListenable.value.upgrades.containsKey(upgrade.id)
      ? controller.shopSnapshotListenable.value.upgrades[upgrade.id]
      : null;
  final unlockedItemName = strings.upgradeItemName(
    upgrade.id,
    afterSnapshot?.currentItemKey ?? upgrade.items[afterItemIndex].key,
  );
  final newEffect = _effect(
    context,
    upgrade,
    afterSnapshot?.currentEffect ??
        upgrade.items[afterItemIndex].effectForItemLevel(after.level),
  );

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DonerColors.panelPrimary,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.upgradeUnlockTitle,
              style: TextStyle(
                fontFamily: RoastedTypography.headlineFontFamily,
                fontWeight: FontWeight.w900,
                color: DonerColors.goldPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              strings.upgradeItemTransition(previousItemName, unlockedItemName),
              style: TextStyle(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontWeight: FontWeight.w800,
                color: DonerColors.creamText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              strings.upgradeNewEffectLabel,
              style: TextStyle(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: DonerColors.bodyText,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              newEffect,
              style: TextStyle(
                fontFamily: RoastedTypography.headlineFontFamily,
                fontWeight: FontWeight.w900,
                color: DonerColors.goldBright,
              ),
            ),
          ],
        ),
      ),
    );
}

FaIconData _upgradeIcon(UpgradeId id) => switch (id) {
  UpgradeId.knife => DonerIcons.upgradeKnife,
  UpgradeId.oven => DonerIcons.upgradeOven,
  UpgradeId.staff => DonerIcons.upgradeStaff,
  UpgradeId.menu => DonerIcons.upgradeMenu,
  UpgradeId.turbo => DonerIcons.upgradeTurbo,
  UpgradeId.offline => DonerIcons.upgradeOffline,
};

double _shopStatRowHeight(bool compact) => compact ? 52.h : 56.h;

BoxDecoration _shopHeaderDecoration() => BoxDecoration(
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
