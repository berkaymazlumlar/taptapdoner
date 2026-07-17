import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/domain/branches/branch_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/l10n/locale_case.dart';
import 'package:taptapdoner/services/audio/purchase_sfx_player.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class BranchPage extends StatefulWidget {
  const BranchPage({required this.controller, super.key, this.bottomInset = 0});

  final GameController controller;
  final double bottomInset;

  @override
  State<BranchPage> createState() => _BranchPageState();
}

class _BranchPageState extends State<BranchPage> {
  String? _selectedRegionId;

  Future<void> _showManagerPicker(BranchProgressSnapshot branch) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ManagerPickerSheet(controller: widget.controller, branch: branch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      key: const ValueKey('branch-page-root'),
      child: ValueListenableBuilder<BranchBoardSnapshot>(
        valueListenable: widget.controller.branchSnapshotListenable,
        builder: (context, snapshot, _) {
          final selectedRegionId =
              snapshot.regions.any((region) => region.id == _selectedRegionId)
              ? _selectedRegionId
              : (snapshot.regions.isEmpty ? null : snapshot.regions.first.id);
          final visibleBranches = selectedRegionId == null
              ? snapshot.branches
              : snapshot.branches
                    .where((branch) => branch.regionId == selectedRegionId)
                    .toList(growable: false);
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
                  child: _RegionStrip(
                    snapshot: snapshot,
                    selectedRegionId: selectedRegionId,
                    onSelected: (regionId) {
                      setState(() => _selectedRegionId = regionId);
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  22 + widget.bottomInset,
                ),
                sliver: SliverList.separated(
                  itemCount: visibleBranches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final branch = visibleBranches[index];
                    return _BranchCard(
                      key: ValueKey('branch-card-${branch.id}'),
                      branch: branch,
                      incomeActive: snapshot.incomeActive,
                      onUnlock: () async {
                        final bought = await widget.controller.unlockBranch(
                          branch.id,
                        );
                        if (bought) {
                          unawaited(PurchaseSfxPlayer.play());
                        }
                        return bought;
                      },
                      onLevelUp: () async {
                        final bought = await widget.controller.levelUpBranch(
                          branch.id,
                        );
                        if (bought) {
                          unawaited(PurchaseSfxPlayer.play());
                        }
                        return bought;
                      },
                      onManageManager: () => _showManagerPicker(branch),
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
    final title = strings.isTurkish ? 'Şubeler' : 'Branches';
    final stateLabel = snapshot.unlockedBranchCount == 0
        ? (strings.isTurkish ? 'Açık şube yok' : 'No open branches')
        : snapshot.incomeActive
        ? (strings.isTurkish ? 'Aktif' : 'Active')
        : (strings.isTurkish ? 'Dükkân Sv. 7 bekliyor' : 'Needs Shop Lv. 7');
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
                        strings.isTurkish
                            ? '${snapshot.unlockedBranchCount}/${snapshot.totalBranchCount} açık  |  Sv. ${snapshot.totalBranchLevel}'
                            : '${snapshot.unlockedBranchCount}/${snapshot.totalBranchCount} open  |  Lv ${snapshot.totalBranchLevel}',
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
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    label: strings.isTurkish ? 'Gelir' : 'Income',
                    value: formatCompactCurrencyRate(
                      context,
                      snapshot.branchIncomePerSecond,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    label: strings.isTurkish ? 'Toplam' : 'Earned',
                    value: formatCompactCurrency(
                      context,
                      snapshot.totalBranchIncomeEarned,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    label: strings.isTurkish ? 'Durum' : 'State',
                    value: stateLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionStrip extends StatelessWidget {
  const _RegionStrip({
    required this.snapshot,
    required this.selectedRegionId,
    required this.onSelected,
  });

  final BranchBoardSnapshot snapshot;
  final String? selectedRegionId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final region in snapshot.regions)
          Semantics(
            button: true,
            selected: region.id == selectedRegionId,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('branch-region-${region.id}'),
                onTap: () => onSelected(region.id),
                borderRadius: BorderRadius.circular(8),
                child: Ink(
                  decoration: BoxDecoration(
                    color: region.id == selectedRegionId
                        ? DonerColors.tealPrimary.withValues(alpha: 0.42)
                        : region.unlocked
                        ? DonerColors.tealPrimary.withValues(alpha: 0.18)
                        : DonerColors.panelDark.withValues(alpha: 0.56),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: region.id == selectedRegionId || region.completed
                          ? DonerColors.goldPrimary
                          : DonerColors.borderSoft,
                      width: region.id == selectedRegionId ? 1.6 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
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
                          style: _metaStyle(context).copyWith(
                            color: region.id == selectedRegionId
                                ? DonerColors.creamText
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    super.key,
    required this.branch,
    required this.incomeActive,
    required this.onUnlock,
    required this.onLevelUp,
    required this.onManageManager,
  });

  final BranchProgressSnapshot branch;
  final bool incomeActive;
  final Future<bool> Function() onUnlock;
  final Future<bool> Function() onLevelUp;
  final VoidCallback onManageManager;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
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
                      ? (strings.isTurkish
                            ? 'Sv. ${branch.level}/${branch.maxLevel}'
                            : 'Lv ${branch.level}/${branch.maxLevel}')
                      : (strings.isTurkish ? 'Kilitli' : 'Locked'),
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
                onManageManager: onManageManager,
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
    required this.onManageManager,
  });

  final BranchProgressSnapshot branch;
  final bool incomeActive;
  final Future<bool> Function() onLevelUp;
  final VoidCallback onManageManager;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final managerLabel =
        branch.assignedManagerName ??
        (branch.managerSlotUnlocked
            ? (branch.suggestedManagerName ??
                  (strings.isTurkish ? 'Yönetici yok' : 'No manager'))
            : (strings.isTurkish ? 'Yönetici Sv. 20' : 'Manager Lv. 20'));
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
              label: strings.isTurkish ? 'Gelir' : 'Income',
              value: incomeActive
                  ? formatCompactCurrencyRate(context, branch.incomePerSecond)
                  : (strings.isTurkish ? 'Kapalı' : 'Inactive'),
            ),
            _StatPill(
              label: strings.isTurkish ? 'Kilometre taşı' : 'Milestone',
              value:
                  '${branch.reachedMilestoneCount}/${branch.totalMilestoneCount}',
            ),
            _StatPill(
              label: strings.isTurkish ? 'Yönetici' : 'Manager',
              value: managerLabel,
            ),
          ],
        ),
        if (!branch.managerSlotUnlocked) ...[
          const SizedBox(height: 8),
          Text(
            strings.isTurkish
                ? 'Yönetici alanı Şube Sv. 20’de açılır.'
                : 'The manager slot unlocks at Branch Lv. 20.',
            style: _metaStyle(context),
          ),
        ] else if (branch.assignedManagerId == null &&
            branch.suggestedManagerId == null) ...[
          const SizedBox(height: 8),
          Text(
            strings.isTurkish
                ? 'Açılmış usta kartın yok. Usta Sandığı kazanmak için görevleri tamamla.'
                : 'You have no unlocked master cards. Complete goals to earn Chef Chests.',
            key: const ValueKey('branch-manager-empty-help'),
            style: _metaStyle(context),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BranchActionButton(
                label: branch.maxed
                    ? (strings.isTurkish ? 'Maks.' : 'Max')
                    : formatCompactCurrency(context, branch.levelUpCost),
                enabled: branch.canLevelUp,
                onPressed: branch.canLevelUp ? onLevelUp : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BranchActionButton(
                label: branch.assignedManagerName == null
                    ? (branch.managerSlotUnlocked
                          ? (strings.isTurkish
                                ? 'Yönetici Seç'
                                : 'Choose Manager')
                          : (strings.isTurkish
                                ? 'Sv. 20’de Açılır'
                                : 'Unlocks at Lv. 20'))
                    : (strings.isTurkish ? 'Değiştir' : 'Change'),
                enabled: branch.managerSlotUnlocked,
                onPressed: branch.managerSlotUnlocked ? onManageManager : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ManagerPickerSheet extends StatelessWidget {
  const _ManagerPickerSheet({required this.controller, required this.branch});

  final GameController controller;
  final BranchProgressSnapshot branch;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = controller.state;
    final collection = state.collection2;
    final unlockedStaff = Collection2Catalog.masterCards
        .where((staff) => collection.isMasterCardUnlocked(staff.id))
        .toList(growable: false);
    final assignedBranchByManager = <String, String>{};
    for (final progress in state.branches.branchProgress.values) {
      final managerId = progress.assignedManagerId;
      if (managerId == null ||
          managerId.isEmpty ||
          progress.branchId == branch.id) {
        continue;
      }
      assignedBranchByManager[managerId] =
          _branchName(progress.branchId) ?? progress.branchId;
    }
    final currentBonus = BranchCatalog.managerIncomeBonus(
      collection,
      branch.assignedManagerId,
    );
    final incomeWithoutManager = branch.incomePerSecond / (1 + currentBonus);

    return FractionallySizedBox(
      heightFactor: 0.82,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: DonerGradients.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: DonerColors.goldPrimary, width: 1.2),
          boxShadow: DonerShadows.soft,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DonerColors.borderSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const FaIcon(
                    DonerIcons.manager,
                    color: DonerColors.goldBright,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.isTurkish ? 'Yönetici Seç' : 'Choose Manager',
                          style: _titleStyle(context),
                        ),
                        Text(branch.name, style: _metaStyle(context)),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('manager-sheet-close-button'),
                    tooltip: strings.closeLabel,
                    onPressed: () => Navigator.of(context).pop(),
                    color: DonerColors.bodyText,
                    icon: const FaIcon(DonerIcons.close, size: 17),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: DonerColors.panelDark.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DonerColors.borderSoft),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    strings.isTurkish
                        ? 'Mevcut şube geliri: ${formatCompactCurrencyRate(context, branch.incomePerSecond)}\nBir usta seçerek yeni geliri ve farkı karşılaştır.'
                        : 'Current branch income: ${formatCompactCurrencyRate(context, branch.incomePerSecond)}\nChoose a master to compare the new income and difference.',
                    key: const ValueKey('manager-income-comparison'),
                    style: _metaStyle(context),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: unlockedStaff.isEmpty
                    ? _EmptyManagerState(strings: strings)
                    : ListView.separated(
                        itemCount: unlockedStaff.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final staff = unlockedStaff[index];
                          final level = collection.masterCardLevel(staff.id);
                          final bonus = BranchCatalog.managerIncomeBonus(
                            collection,
                            staff.id,
                          );
                          final projectedIncome =
                              incomeWithoutManager * (1 + bonus);
                          final difference = branch.incomePerSecond <= 0
                              ? bonus
                              : (projectedIncome / branch.incomePerSecond) - 1;
                          final assignedElsewhere =
                              assignedBranchByManager[staff.id];
                          final isCurrent =
                              branch.assignedManagerId == staff.id;
                          return _ManagerOptionCard(
                            staff: staff,
                            level: level,
                            bonus: bonus,
                            projectedIncome: projectedIncome,
                            difference: difference,
                            assignedBranchName: assignedElsewhere,
                            isCurrent: isCurrent,
                            onSelected: assignedElsewhere == null && !isCurrent
                                ? () async {
                                    final assigned = await controller
                                        .assignBranchManager(
                                          branch.id,
                                          staff.id,
                                        );
                                    if (assigned && context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
              ),
              if (branch.assignedManagerId != null) ...[
                const SizedBox(height: 10),
                _BranchActionButton(
                  label: strings.isTurkish ? 'Görevden Al' : 'Unassign',
                  enabled: true,
                  onPressed: () async {
                    final removed = await controller.unassignBranchManager(
                      branch.id,
                    );
                    if (removed && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyManagerState extends StatelessWidget {
  const _EmptyManagerState({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: _itemDecoration(false),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                DonerIcons.collection,
                color: DonerColors.goldBright,
                size: 26,
              ),
              const SizedBox(height: 10),
              Text(
                strings.isTurkish
                    ? 'Henüz açılmış usta kartın yok.'
                    : 'You do not have an unlocked master card yet.',
                textAlign: TextAlign.center,
                style: _bodyStyle(context),
              ),
              const SizedBox(height: 6),
              Text(
                strings.isTurkish
                    ? 'Görevleri tamamla, Usta Sandığı kazan ve kartları biriktir.'
                    : 'Complete goals, earn Chef Chests, and collect cards.',
                textAlign: TextAlign.center,
                style: _metaStyle(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerOptionCard extends StatelessWidget {
  const _ManagerOptionCard({
    required this.staff,
    required this.level,
    required this.bonus,
    required this.projectedIncome,
    required this.difference,
    required this.assignedBranchName,
    required this.isCurrent,
    required this.onSelected,
  });

  final MasterCard staff;
  final int level;
  final double bonus;
  final double projectedIncome;
  final double difference;
  final String? assignedBranchName;
  final bool isCurrent;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final status = isCurrent
        ? (strings.isTurkish ? 'Bu şubede görevli' : 'Assigned here')
        : assignedBranchName != null
        ? (strings.isTurkish
              ? '$assignedBranchName şubesinde görevli'
              : 'Assigned to $assignedBranchName')
        : (strings.isTurkish ? 'Atanabilir' : 'Available');
    final differencePrefix = difference >= 0 ? '+' : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('manager-option-${staff.id}'),
        onTap: onSelected,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: DonerColors.panelDark.withValues(
              alpha: onSelected == null ? 0.46 : 0.76,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent
                  ? DonerColors.goldPrimary
                  : _rarityColor(staff.rarity).withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _rarityColor(staff.rarity).withValues(alpha: 0.16),
                    border: Border.all(color: _rarityColor(staff.rarity)),
                  ),
                  child: FaIcon(
                    DonerIcons.manager,
                    size: 16,
                    color: _rarityColor(staff.rarity),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.collection2ItemName(
                          staff.id,
                          fallback: staff.name,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _bodyStyle(context),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${strings.isTurkish ? 'Sv.' : 'Lv'} $level  •  ${_rarityLabel(staff.rarity, strings.isTurkish)}  •  ${_percentLabel(bonus)}',
                        style: _metaStyle(
                          context,
                        ).copyWith(color: _rarityColor(staff.rarity)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _tinyStyle(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCompactCurrencyRate(context, projectedIncome),
                      style: _metaStrongStyle(context),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$differencePrefix${_percentLabel(difference)}',
                      key: ValueKey('manager-difference-${staff.id}'),
                      style: _tinyStyle(context).copyWith(
                        color: difference >= 0
                            ? DonerColors.tealBright
                            : DonerColors.disabledText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _percentLabel(double value) => '${(value * 100).toStringAsFixed(1)}%';

String? _branchName(String branchId) {
  for (final branch in BranchCatalog.branches) {
    if (branch.id == branchId) {
      return branch.name;
    }
  }
  return null;
}

String _rarityLabel(Rarity rarity, bool isTurkish) {
  return switch (rarity) {
    Rarity.common => isTurkish ? 'Yaygın' : 'Common',
    Rarity.rare => isTurkish ? 'Nadir' : 'Rare',
    Rarity.epic => isTurkish ? 'Destansı' : 'Epic',
    Rarity.legendary => isTurkish ? 'Efsanevi' : 'Legendary',
    Rarity.mythic => isTurkish ? 'Mitik' : 'Mythic',
  };
}

Color _rarityColor(Rarity rarity) {
  return switch (rarity) {
    Rarity.common => DonerColors.bodyText,
    Rarity.rare => DonerColors.tealBright,
    Rarity.epic => const Color(0xFFA873FF),
    Rarity.legendary => DonerColors.goldBright,
    Rarity.mythic => const Color(0xFFFF6EC7),
  };
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
                  requirement.completed
                      ? FontAwesomeIcons.check
                      : DonerIcons.lock,
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
        child: SizedBox(
          height: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label.toLocaleUpperCase(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _tinyStyle(context),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: _metaStrongStyle(context),
                  ),
                ),
              ),
            ],
          ),
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
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
