import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/audio/purchase_sfx_player.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class BranchPage extends StatelessWidget {
  const BranchPage({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      key: const ValueKey('branch-page-root'),
      child: ValueListenableBuilder<BranchBoardSnapshot>(
        valueListenable: controller.branchSnapshotListenable,
        builder: (context, snapshot, _) {
          return CustomScrollView(
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _BranchHeader(snapshot: snapshot, strings: strings),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _RegionStrip(snapshot: snapshot),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                sliver: SliverList.separated(
                  itemCount: snapshot.branches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final branch = snapshot.branches[index];
                    return _BranchCard(
                      branch: branch,
                      incomeActive: snapshot.incomeActive,
                      onUnlock: () async {
                        final bought = await controller.unlockBranch(branch.id);
                        if (bought) {
                          unawaited(PurchaseSfxPlayer.play());
                        }
                        return bought;
                      },
                      onLevelUp: () async {
                        final bought = await controller.levelUpBranch(
                          branch.id,
                        );
                        if (bought) {
                          unawaited(PurchaseSfxPlayer.play());
                        }
                        return bought;
                      },
                      onAssignManager: () => controller
                          .assignFirstAvailableBranchManager(branch.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BranchHeader extends StatelessWidget {
  const _BranchHeader({required this.snapshot, required this.strings});

  final BranchBoardSnapshot snapshot;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final title = strings.isTurkish ? 'Subeler' : 'Branches';
    final stateLabel = snapshot.incomeActive
        ? (strings.isTurkish ? 'Aktif' : 'Active')
        : (strings.isTurkish ? 'Shop Lv. 7 bekliyor' : 'Needs Shop Lv. 7');
    return DecoratedBox(
      decoration: _panelDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FaIcon(DonerIcons.branch, color: DonerColors.goldBright),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _titleStyle(context)),
                      const SizedBox(height: 3),
                      Text(
                        '${snapshot.unlockedBranchCount}/${snapshot.totalBranchCount} open  |  Lv ${snapshot.totalBranchLevel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _metaStyle(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(
                  label: strings.isTurkish ? 'Gelir' : 'Income',
                  value: formatCompactCurrencyRate(
                    context,
                    snapshot.branchIncomePerSecond,
                  ),
                ),
                _StatPill(
                  label: strings.isTurkish ? 'Toplam' : 'Earned',
                  value: formatCompactCurrency(
                    context,
                    snapshot.totalBranchIncomeEarned,
                  ),
                ),
                _StatPill(label: 'State', value: stateLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionStrip extends StatelessWidget {
  const _RegionStrip({required this.snapshot});

  final BranchBoardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final region in snapshot.regions)
          DecoratedBox(
            decoration: BoxDecoration(
              color: region.unlocked
                  ? DonerColors.tealPrimary.withValues(alpha: 0.24)
                  : DonerColors.panelDark.withValues(alpha: 0.56),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: region.completed
                    ? DonerColors.goldPrimary
                    : DonerColors.borderSoft,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    region.unlocked ? DonerIcons.city : DonerIcons.lock,
                    size: 13,
                    color: region.unlocked
                        ? DonerColors.goldBright
                        : DonerColors.disabledText,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${region.name} ${region.unlockedBranchCount}/${region.totalBranchCount}',
                    style: _metaStyle(context),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.incomeActive,
    required this.onUnlock,
    required this.onLevelUp,
    required this.onAssignManager,
  });

  final BranchProgressSnapshot branch;
  final bool incomeActive;
  final Future<bool> Function() onUnlock;
  final Future<bool> Function() onLevelUp;
  final Future<bool> Function() onAssignManager;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _itemDecoration(branch.unlocked),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: branch.unlocked
                        ? DonerColors.tealPrimary.withValues(alpha: 0.30)
                        : DonerColors.panelDark,
                    border: Border.all(color: DonerColors.borderSoft),
                  ),
                  child: FaIcon(
                    branch.unlocked ? DonerIcons.branch : DonerIcons.lock,
                    color: branch.unlocked
                        ? DonerColors.goldBright
                        : DonerColors.disabledText,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _bodyStyle(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${branch.cityName}  |  ${branch.regionName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _metaStyle(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  branch.unlocked
                      ? 'Lv ${branch.level}/${branch.maxLevel}'
                      : 'Locked',
                  style: _metaStyle(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (branch.unlocked)
              _UnlockedBranchBody(
                branch: branch,
                incomeActive: incomeActive,
                onLevelUp: onLevelUp,
                onAssignManager: onAssignManager,
              )
            else
              _LockedBranchBody(branch: branch, onUnlock: onUnlock),
          ],
        ),
      ),
    );
  }
}

class _UnlockedBranchBody extends StatelessWidget {
  const _UnlockedBranchBody({
    required this.branch,
    required this.incomeActive,
    required this.onLevelUp,
    required this.onAssignManager,
  });

  final BranchProgressSnapshot branch;
  final bool incomeActive;
  final Future<bool> Function() onLevelUp;
  final Future<bool> Function() onAssignManager;

  @override
  Widget build(BuildContext context) {
    final managerLabel =
        branch.assignedManagerName ??
        (branch.managerSlotUnlocked
            ? (branch.suggestedManagerName ?? 'No manager')
            : 'Manager Lv. 20');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: branch.levelProgress,
            minHeight: 5,
            backgroundColor: DonerColors.panelDark,
            valueColor: const AlwaysStoppedAnimation(DonerColors.goldBright),
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatPill(
              label: 'Income',
              value: incomeActive
                  ? formatCompactCurrencyRate(context, branch.incomePerSecond)
                  : '0/s',
            ),
            _StatPill(
              label: 'Milestone',
              value:
                  '${branch.reachedMilestoneCount}/${branch.totalMilestoneCount}',
            ),
            _StatPill(label: 'Manager', value: managerLabel),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BranchActionButton(
                label: branch.maxed
                    ? 'Max'
                    : formatCompactCurrency(context, branch.levelUpCost),
                enabled: branch.canLevelUp,
                onPressed: branch.canLevelUp ? onLevelUp : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BranchActionButton(
                label: branch.assignedManagerName == null
                    ? 'Assign'
                    : 'Managed',
                enabled: branch.canAssignManager,
                onPressed: branch.canAssignManager ? onAssignManager : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LockedBranchBody extends StatelessWidget {
  const _LockedBranchBody({required this.branch, required this.onUnlock});

  final BranchProgressSnapshot branch;
  final Future<bool> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          branch.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _metaStyle(context),
        ),
        const SizedBox(height: 8),
        for (final requirement in branch.requirements.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                FaIcon(
                  requirement.completed ? DonerIcons.shield : DonerIcons.lock,
                  size: 11,
                  color: requirement.completed
                      ? DonerColors.tealBright
                      : DonerColors.disabledText,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    requirement.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _metaStyle(context),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 7),
        Align(
          alignment: Alignment.centerRight,
          child: _BranchActionButton(
            label: formatCompactCurrency(context, branch.unlockCost),
            enabled: branch.canUnlock,
            onPressed: branch.canUnlock ? onUnlock : null,
            width: 132,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DonerColors.panelDark.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DonerColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: _tinyStyle(context)),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _metaStrongStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchActionButton extends StatelessWidget {
  const _BranchActionButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.width,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 38,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: DonerColors.goldPrimary,
          foregroundColor: DonerColors.panelDark,
          disabledBackgroundColor: DonerColors.borderSoft,
          disabledForegroundColor: DonerColors.disabledText,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    gradient: DonerGradients.card,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: DonerColors.borderSoft, width: 1.2),
    boxShadow: DonerShadows.soft,
  );
}

BoxDecoration _itemDecoration(bool highlighted) {
  return BoxDecoration(
    color: DonerColors.panelDark.withValues(alpha: highlighted ? 0.72 : 0.50),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: highlighted ? DonerColors.goldPrimary : DonerColors.borderSoft,
      width: 1.15,
    ),
    boxShadow: DonerShadows.soft,
  );
}

TextStyle _titleStyle(BuildContext context) {
  return DonerTypography.body(
    Theme.of(context).textTheme.titleLarge?.copyWith(
      color: DonerColors.creamText,
      fontWeight: FontWeight.w900,
    ),
  );
}

TextStyle _bodyStyle(BuildContext context) {
  return DonerTypography.body(
    Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: DonerColors.creamText,
      fontWeight: FontWeight.w900,
    ),
  );
}

TextStyle _metaStrongStyle(BuildContext context) {
  return DonerTypography.body(
    Theme.of(context).textTheme.labelMedium?.copyWith(
      color: DonerColors.goldBright,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    ),
  );
}

TextStyle _metaStyle(BuildContext context) {
  return DonerTypography.body(
    Theme.of(context).textTheme.labelSmall?.copyWith(
      color: DonerColors.bodyText,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
  );
}

TextStyle _tinyStyle(BuildContext context) {
  return DonerTypography.body(
    Theme.of(context).textTheme.labelSmall?.copyWith(
      color: DonerColors.mutedText,
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: 0,
    ),
  );
}
