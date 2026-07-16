import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/l10n/locale_case.dart';
import 'package:taptapdoner/services/audio/purchase_sfx_player.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';
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
    this.bottomInset = 0,
    this.presentation = ShopPagePresentation.sheet,
  });

  final GameController controller;
  final VoidCallback onOpenKitchen;
  final VoidCallback onOpenPrestige;
  final VoidCallback? onBack;
  final double bottomInset;
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
                            bottomInset: bottomInset,
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
      final strings = AppStrings.of(context);
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
                      strings.shopLevelUpTitle.toLocaleUpperCase(context),
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
                '${strings.shopUnlockedLabel}: ${snapshot.unlockLabel}',
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
                '${strings.shopIncomeLabel} x${snapshot.incomeMultiplier.toStringAsFixed(2)}',
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
                label: strings.closeLabel,
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
    required this.bottomInset,
    required this.onClose,
  });

  final GameController controller;
  final ShopSnapshot snapshot;
  final double horizontalPadding;
  final bool compact;
  final bool isTab;
  final double bottomInset;
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
                  88.h + (isTab ? bottomInset : 0),
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
    final strings = AppStrings.of(context);
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
                      '${strings.shopLevelLabel.toLocaleUpperCase(context)} ${snapshot.currentLevel}',
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
              label: strings.shopIncomeLabel,
              value: 'x${snapshot.incomeMultiplier.toStringAsFixed(2)}',
            ),
          ),
          SizedBox(height: 10.h),
          if (nextName == null)
            Text(
              strings.shopMaxLevelLabel,
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
                    '${strings.shopNextLabel}: ${strings.levelLabel}. ${snapshot.nextLevel} $nextName',
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
                          ? FontAwesomeIcons.check
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
                      strings.shopTitle.toLocaleUpperCase(context),
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
                      value: formatCompactCurrencyRate(
                        context,
                        snapshot.hud.passiveIncomePerSecond,
                      ),
                      iconColor: DonerColors.orangeAccent,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _StatChip(
                      icon: DonerIcons.reputation,
                      label: strings.reputationLabel,
                      value: formatCompactNumber(
                        context,
                        snapshot.hud.reputation,
                      ),
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
        final currentItemAssetPath = _upgradeAssetPath(
          upgrade.id,
          upgradeSnapshot.currentItemKey,
        );
        final nextItemAssetPath = upgradeSnapshot.nextItemKey == null
            ? null
            : _upgradeAssetPath(upgrade.id, upgradeSnapshot.nextItemKey!);
        final accentColor = _upgradeAccent(upgrade.id);
        final showcaseOwned = upgradeSnapshot.purchased || isSpecialState;
        final borderColor = isSpecialState
            ? DonerColors.goldPrimary.withValues(alpha: 0.58)
            : upgradeSnapshot.purchased
            ? accentColor.withValues(alpha: 0.34)
            : DonerColors.borderSoft.withValues(alpha: 0.68);
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.upgradeName(upgrade.id).toLocaleUpperCase(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle(
                isSpecialState
                    ? DonerColors.goldPrimary
                    : DonerColors.bodyText.withValues(alpha: 0.84),
                size: compact ? 8.7 : 9.2,
              ).copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.1),
            ),
            const SizedBox(height: 4),
            Text(
              currentItemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle(
                DonerColors.creamText,
                size: compact ? 16.5 : 18,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _UpgradeHeaderPill(
                  label: tierText,
                  accentColor: accentColor,
                  highlighted: true,
                ),
                _UpgradeHeaderPill(label: levelText, accentColor: accentColor),
              ],
            ),
            const SizedBox(height: 10),
            if (maxed)
              _UpgradeActionButton(
                key: ValueKey('shop-upgrade-button-${upgrade.id.key}'),
                label: actionLabel,
                enabled: canAfford,
                maxed: maxed,
                highlighted: unlocksNextItem,
                onTap: null,
              )
            else
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _UpgradeActionButton(
                      key: ValueKey('shop-upgrade-button-${upgrade.id.key}'),
                      label: actionLabel,
                      enabled: canAfford,
                      maxed: maxed,
                      highlighted: unlocksNextItem,
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
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _UpgradeActionButton(
                      key: ValueKey('shop-upgrade-button-10-${upgrade.id.key}'),
                      label: strings.upgradeBuyTenAction,
                      enabled: upgradeSnapshot.canAffordTen,
                      maxed: maxed,
                      highlighted: false,
                      fontSize: 10,
                      onTap: upgradeSnapshot.canAffordTen
                          ? () {
                              unawaited(
                                _buyUpgradeWithFeedback(
                                  context,
                                  controller,
                                  upgrade,
                                  quantity: 10,
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _UpgradeActionButton(
                      key: ValueKey(
                        'shop-upgrade-button-max-${upgrade.id.key}',
                      ),
                      label: strings.upgradeBuyMaxAction,
                      enabled: upgradeSnapshot.maxAffordableQuantity > 0,
                      maxed: maxed,
                      highlighted: upgradeSnapshot.maxAffordableQuantity > 1,
                      fontSize: 10,
                      onTap: upgradeSnapshot.maxAffordableQuantity > 0
                          ? () {
                              unawaited(
                                _buyUpgradeWithFeedback(
                                  context,
                                  controller,
                                  upgrade,
                                  buyMax: true,
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                ],
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
                assetPath: nextItemAssetPath,
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  accentColor.withValues(alpha: 0.07),
                  DonerColors.panelSecondary,
                ),
                Color.alphaBlend(
                  accentColor.withValues(alpha: 0.03),
                  DonerColors.panelPrimary,
                ),
                DonerColors.panelDark,
              ],
            ),
            border: Border.all(color: borderColor, width: 1.3),
            boxShadow: [
              ...DonerShadows.soft,
              if (isSpecialState) ...DonerShadows.goldGlow,
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(
                  top: compact ? -30 : -36,
                  left: compact ? -18 : -26,
                  child: _UpgradeCardGlow(
                    size: compact ? 118 : 142,
                    color: accentColor.withValues(
                      alpha: showcaseOwned ? 0.16 : 0.10,
                    ),
                  ),
                ),
                Positioned(
                  bottom: compact ? -64 : -70,
                  right: compact ? -42 : -48,
                  child: _UpgradeCardGlow(
                    size: compact ? 156 : 190,
                    color: DonerColors.goldPrimary.withValues(
                      alpha: isSpecialState ? 0.10 : 0.05,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: compact ? 120 : 134,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _UpgradeIcon(
                            icon: _upgradeIcon(upgrade.id),
                            assetPath: currentItemAssetPath,
                            owned: showcaseOwned,
                            accentColor: accentColor,
                            compact: compact,
                            badgeLabel: 'T${upgradeSnapshot.currentItemTier}',
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: titleBlock),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              borderColor.withValues(alpha: 0.58),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _EffectBlock(
                              label:
                                  '${strings.upgradeEffectName(upgrade.id)}:',
                              value: _effect(
                                context,
                                upgrade,
                                upgradeSnapshot.currentEffect,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: nextBlock),
                          if (!maxed) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CostBlock(
                                label: '${strings.upgradeCostLabel}:',
                                value: _cash(context, upgradeSnapshot.cost),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UpgradeCardGlow extends StatelessWidget {
  const _UpgradeCardGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _UpgradeHeaderPill extends StatelessWidget {
  const _UpgradeHeaderPill({
    required this.label,
    required this.accentColor,
    this.highlighted = false,
  });

  final String label;
  final Color accentColor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final fill = highlighted
        ? Color.alphaBlend(
            accentColor.withValues(alpha: 0.10),
            DonerColors.panelDark,
          )
        : DonerColors.panelDark.withValues(alpha: 0.78);
    final border = highlighted
        ? accentColor.withValues(alpha: 0.28)
        : DonerColors.borderSoft.withValues(alpha: 0.52);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: RoastedTypography.bodyFontFamily,
          fontSize: 8.6,
          fontWeight: FontWeight.w900,
          height: 1,
          color: highlighted ? DonerColors.creamText : DonerColors.bodyText,
        ),
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
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: subdued
              ? [
                  DonerColors.panelSecondary.withValues(alpha: 0.36),
                  DonerColors.panelDark.withValues(alpha: 0.82),
                ]
              : [
                  DonerColors.panelSecondary.withValues(alpha: 0.44),
                  DonerColors.panelDark.withValues(alpha: 0.92),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.42),
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
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
              height: 1,
              color: DonerColors.bodyText.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.headlineFontFamily,
              fontSize: 11.2,
              fontWeight: FontWeight.w900,
              height: 1,
              color: subdued ? DonerColors.bodyText : DonerColors.goldPrimary,
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
    this.assetPath,
    required this.label,
    required this.itemName,
    required this.effect,
    super.key,
  });

  final FaIconData icon;
  final String? assetPath;
  final String label;
  final String itemName;
  final String effect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              DonerColors.goldPrimary.withValues(alpha: 0.08),
              DonerColors.panelSecondary,
            ),
            DonerColors.panelDark.withValues(alpha: 0.90),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DonerColors.goldPrimary.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          _MiniUpgradeIcon(icon: icon, assetPath: assetPath),
          const SizedBox(width: 8),
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
                    fontSize: 8.8,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: DonerColors.bodyText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: RoastedTypography.headlineFontFamily,
                    fontSize: 11.2,
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
                    fontSize: 9.2,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: DonerColors.goldPrimary,
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
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              DonerColors.goldPrimary.withValues(alpha: 0.08),
              DonerColors.panelSecondary,
            ),
            DonerColors.panelDark.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DonerColors.goldPrimary.withValues(alpha: 0.18),
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
                fontSize: 11,
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

class _CostBlock extends StatelessWidget {
  const _CostBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DonerColors.panelSecondary.withValues(alpha: 0.38),
            DonerColors.panelDark.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.44),
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
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
              height: 1,
              color: DonerColors.bodyText.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: RoastedTypography.headlineFontFamily,
              fontSize: 11.2,
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
    this.fontSize = 11,
    super.key,
  });

  final String label;
  final bool enabled;
  final bool maxed;
  final bool highlighted;
  final VoidCallback? onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final actionable = enabled && !maxed;
    final textColor = actionable
        ? DonerColors.creamText
        : DonerColors.disabledText;
    final radius = BorderRadius.circular(10);

    return SizedBox(
      width: double.infinity,
      child: Opacity(
        opacity: actionable ? 1 : 0.78,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: InkRipple.splashFactory,
            onTap: actionable ? onTap : null,
            borderRadius: radius,
            child: Ink(
              height: 38,
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
                      label.toLocaleUpperCase(context),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: RoastedTypography.bodyFontFamily,
                        fontSize: fontSize,
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
  const _MiniUpgradeIcon({required this.icon, this.assetPath});

  final FaIconData icon;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DonerColors.panelSecondary.withValues(alpha: 0.42),
            DonerColors.panelDark.withValues(alpha: 0.94),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DonerColors.borderSoft),
      ),
      child: Center(
        child: _UpgradeIconGraphic(
          icon: icon,
          assetPath: assetPath,
          size: 24,
          iconColor: DonerColors.goldPrimary,
        ),
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
                    label.toLocaleUpperCase(context),
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
  const _UpgradeIcon({
    required this.icon,
    required this.owned,
    required this.accentColor,
    this.assetPath,
    this.badgeLabel,
    this.compact = false,
  });

  final FaIconData icon;
  final bool owned;
  final Color accentColor;
  final String? assetPath;
  final String? badgeLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final frameWidth = compact ? 92.0 : 106.0;
    final frameHeight = compact ? 102.0 : 116.0;
    final iconColor = owned ? DonerColors.creamText : DonerColors.bodyText;
    final borderColor = owned
        ? DonerColors.goldPrimary
        : DonerColors.borderSoft;
    final frameStart = Color.alphaBlend(
      accentColor.withValues(alpha: 0.18),
      DonerColors.panelSecondary,
    );
    final frameEnd = Color.alphaBlend(
      accentColor.withValues(alpha: 0.04),
      DonerColors.panelDark,
    );
    final iconSize = compact ? 62.0 : 76.0;

    return Container(
      width: frameWidth,
      height: frameHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [frameStart, frameEnd, DonerColors.panelDark],
        ),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          ...DonerShadows.soft,
          if (owned)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (badgeLabel != null && badgeLabel!.isNotEmpty)
            Positioned(
              top: 8,
              left: 8,
              child: _UpgradeHeaderPill(
                label: badgeLabel!,
                accentColor: accentColor,
                highlighted: true,
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
              child: _UpgradeIconGraphic(
                icon: icon,
                assetPath: assetPath,
                size: iconSize,
                iconColor: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeIconGraphic extends StatelessWidget {
  const _UpgradeIconGraphic({
    required this.icon,
    required this.size,
    required this.iconColor,
    this.assetPath,
  });

  final FaIconData icon;
  final String? assetPath;
  final double size;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (assetPath == null) {
      return FaIcon(icon, size: size, color: iconColor);
    }

    return Image.asset(
      assetPath!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return FaIcon(icon, size: size, color: iconColor);
      },
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
  final effectName = strings
      .upgradeEffectName(upgrade.id)
      .toLocaleLowerCase(context);
  return switch (upgrade.id) {
    UpgradeId.staff =>
      '+${_compactEffectNumber(context, value)}${strings.isTurkish ? '/sn' : '/s'} $effectName',
    UpgradeId.offline => '%${(value * 100).round()} $effectName',
    _ => '${_multiplier(value)} $effectName',
  };
}

String _multiplier(double value) => 'x${value.toStringAsFixed(2)}';

String _compactEffectNumber(BuildContext context, double value) {
  if (value.isFinite && value.abs() < 10) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }
  return formatCompactNumber(context, value);
}

Future<void> _buyUpgradeWithFeedback(
  BuildContext context,
  GameController controller,
  UpgradeDefinition upgrade, {
  int quantity = 1,
  bool buyMax = false,
}) async {
  final strings = AppStrings.of(context);
  final before = controller.state.upgrade(upgrade.id);
  final beforeItemIndex = before.itemIndex
      .clamp(0, upgrade.items.length - 1)
      .toInt();
  final previousItemName = strings.upgradeItemName(
    upgrade.id,
    upgrade.items[beforeItemIndex].key,
  );

  final bought = buyMax
      ? await controller.buyMaxUpgrade(upgrade.id)
      : await controller.buyUpgrade(upgrade.id, quantity: quantity);
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
  UpgradeId.offline => DonerIcons.upgradeOffline,
};

Color _upgradeAccent(UpgradeId id) => switch (id) {
  UpgradeId.knife => const Color(0xFF8E7A61),
  UpgradeId.oven => const Color(0xFF8D5D44),
  UpgradeId.staff => const Color(0xFF9C845F),
  UpgradeId.menu => const Color(0xFF8B5A48),
  UpgradeId.offline => const Color(0xFF7F6B5D),
};

String? _upgradeAssetPath(UpgradeId id, String itemKey) => switch ((
  id,
  itemKey,
)) {
  (UpgradeId.knife, 'rusty_knife') => UiAssetPaths.upgradeRustyKnife,
  (UpgradeId.knife, 'sharp_knife') => UiAssetPaths.upgradeSharpKnife,
  (UpgradeId.knife, 'double_knife') => UiAssetPaths.upgradeDoubleKnife,
  (UpgradeId.knife, 'electric_knife') => UiAssetPaths.upgradeElectricKnife,
  (UpgradeId.knife, 'golden_knife') => UiAssetPaths.upgradeGoldenKnife,
  (UpgradeId.knife, 'flaming_knife') => UiAssetPaths.upgradeFlamingKnife,
  (UpgradeId.knife, 'laser_knife') => UiAssetPaths.upgradeLaserKnife,
  (UpgradeId.knife, 'doner_excalibur') => UiAssetPaths.upgradeDonerExcalibur,
  _ => null,
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
