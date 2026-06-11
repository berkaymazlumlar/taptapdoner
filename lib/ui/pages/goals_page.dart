import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      key: const ValueKey('goals-page-root'),
      child: ValueListenableBuilder<ProgressionSnapshot>(
        valueListenable: controller.progressionSnapshotListenable,
        builder: (context, snapshot, _) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _GoalsHeader(snapshot: snapshot, strings: strings),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _ChestPanel(
                    snapshot: snapshot,
                    onOpen: controller.openChest,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _AchievementPanel(
                    snapshot: snapshot,
                    onClaim: controller.claimAchievementReward,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverToBoxAdapter(
                  child: _CollectionPanel(snapshot: snapshot),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalsHeader extends StatelessWidget {
  const _GoalsHeader({required this.snapshot, required this.strings});

  final ProgressionSnapshot snapshot;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          FaIcon(DonerIcons.goals, color: DonerColors.goldBright, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.isTurkish ? 'Hedefler' : 'Goals',
                  style: _titleStyle(context),
                ),
                const SizedBox(height: 3),
                Text(
                  '${snapshot.claimableAchievementCount} ready  |  '
                  '${snapshot.unlockedCollectionCount}/${snapshot.collections.length} collection',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _metaStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChestPanel extends StatelessWidget {
  const _ChestPanel({required this.snapshot, required this.onOpen});

  final ProgressionSnapshot snapshot;
  final Future<LastChestRewardSnapshot?> Function(ChestType type) onOpen;

  @override
  Widget build(BuildContext context) {
    return _GoalsSectionPanel(
      storageId: 'chests',
      icon: DonerIcons.chest,
      title: 'Chests',
      meta: '${snapshot.chests.totalCount} stored',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final type in ChestType.values) ...[
            _ChestRow(
              type: type,
              count: snapshot.chests.count(type),
              onOpen: () => onOpen(type),
            ),
            if (type != ChestType.values.last) const SizedBox(height: 8),
          ],
          if (snapshot.lastChestReward != null) ...[
            const SizedBox(height: 12),
            _RewardReveal(reward: snapshot.lastChestReward!),
          ],
        ],
      ),
    );
  }
}

class _AchievementPanel extends StatelessWidget {
  const _AchievementPanel({required this.snapshot, required this.onClaim});

  final ProgressionSnapshot snapshot;
  final Future<bool> Function(String achievementId) onClaim;

  @override
  Widget build(BuildContext context) {
    return _GoalsSectionPanel(
      storageId: 'achievements',
      icon: DonerIcons.prestige,
      title: 'Achievements',
      meta: '${snapshot.claimableAchievementCount} ready',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final achievement in snapshot.achievements) ...[
            _AchievementRow(achievement: achievement, onClaim: onClaim),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CollectionPanel extends StatelessWidget {
  const _CollectionPanel({required this.snapshot});

  final ProgressionSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final visibleItems = snapshot.collections.take(18).toList(growable: false);
    return _GoalsSectionPanel(
      storageId: 'collection',
      icon: DonerIcons.collection,
      title: 'Collection',
      meta:
          '${snapshot.unlockedCollectionCount}/${snapshot.collections.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in visibleItems) ...[
            _CollectionRow(item: item),
            if (item != visibleItems.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ChestRow extends StatelessWidget {
  const _ChestRow({
    required this.type,
    required this.count,
    required this.onOpen,
  });

  final ChestType type;
  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;
    final button = _GoalsActionButton(
      buttonKey: ValueKey('goals-open-${chestTypeKey(type)}-chest'),
      label: 'Open',
      onPressed: enabled ? onOpen : null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 248;
        final title = Text(
          '${_chestLabel(type)} x$count',
          maxLines: stackVertically ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: _bodyStyle(context),
        );

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: button),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 12),
            button,
          ],
        );
      },
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement, required this.onClaim});

  final AchievementProgressSnapshot achievement;
  final Future<bool> Function(String achievementId) onClaim;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _itemDecoration(achievement.canClaim),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(achievement.title, style: _bodyStyle(context)),
                ),
                Text(achievement.rewardLabel, style: _metaStyle(context)),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: achievement.progress,
                minHeight: 5,
                backgroundColor: DonerColors.panelDark,
                valueColor: AlwaysStoppedAnimation(
                  achievement.completed
                      ? DonerColors.goldBright
                      : DonerColors.tealBright,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_format(achievement.currentValue)} / ${_format(achievement.targetValue)}',
                    style: _metaStyle(context),
                  ),
                ),
                if (achievement.canClaim)
                  TextButton(
                    key: ValueKey('achievement-claim-${achievement.id}'),
                    onPressed: () => onClaim(achievement.id),
                    child: const Text('Claim'),
                  )
                else
                  Text(
                    achievement.rewardClaimed ? 'Claimed' : 'Locked',
                    style: _metaStyle(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.item});

  final CollectionItemSnapshot item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _itemDecoration(item.unlocked),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            FaIcon(
              item.unlocked ? DonerIcons.collection : DonerIcons.lock,
              color: item.unlocked
                  ? DonerColors.goldBright
                  : DonerColors.disabledText,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.unlocked ? item.name : 'Locked item',
                    style: _bodyStyle(context),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.rarity.name.toUpperCase()}  |  ${item.bonusLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _metaStyle(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardReveal extends StatelessWidget {
  const _RewardReveal({required this.reward});

  final LastChestRewardSnapshot reward;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('chest-reward-reveal'),
      decoration: BoxDecoration(
        color: DonerColors.tealPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DonerColors.tealBright),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          '${_chestLabel(reward.chestType)}: ${reward.label}',
          style: _bodyStyle(context),
        ),
      ),
    );
  }
}

class _GoalsActionButton extends StatelessWidget {
  const _GoalsActionButton({
    required this.buttonKey,
    required this.label,
    this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 88, minHeight: 40),
      child: ElevatedButton(
        key: buttonKey,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: DonerColors.goldPrimary,
          foregroundColor: DonerColors.panelDark,
          disabledBackgroundColor: DonerColors.borderSoft,
          disabledForegroundColor: DonerColors.disabledText,
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _GoalsSectionPanel extends StatefulWidget {
  const _GoalsSectionPanel({
    required this.storageId,
    required this.icon,
    required this.title,
    required this.child,
    this.meta,
  });

  final String storageId;
  final FaIconData icon;
  final String title;
  final Widget child;
  final String? meta;

  @override
  State<_GoalsSectionPanel> createState() => _GoalsSectionPanelState();
}

class _GoalsSectionPanelState extends State<_GoalsSectionPanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _expanded ? DonerColors.goldPrimary : DonerColors.borderSoft,
          width: 1.2,
        ),
        boxShadow: DonerShadows.soft,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
        ),
        child: ExpansionTile(
          key: ValueKey('goals-section-${widget.storageId}'),
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: const Border(),
          collapsedShape: const Border(),
          onExpansionChanged: (expanded) {
            setState(() {
              _expanded = expanded;
            });
          },
          leading: FaIcon(
            widget.icon,
            color: _expanded ? DonerColors.goldBright : DonerColors.bodyText,
            size: 18,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(widget.title, style: _sectionStyle(context)),
              ),
              if (widget.meta != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.meta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: _metaStyle(context),
                  ),
                ),
              ],
            ],
          ),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: FaIcon(
              DonerIcons.expand,
              key: ValueKey('goals-section-toggle-${widget.storageId}'),
              size: 14,
              color: _expanded ? DonerColors.goldBright : DonerColors.bodyText,
            ),
          ),
          children: [widget.child],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DonerColors.borderSoft, width: 1.2),
        boxShadow: DonerShadows.soft,
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

BoxDecoration _itemDecoration(bool highlighted) {
  return BoxDecoration(
    color: DonerColors.panelDark.withValues(alpha: highlighted ? 0.72 : 0.48),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: highlighted ? DonerColors.goldPrimary : DonerColors.borderSoft,
    ),
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

TextStyle _sectionStyle(BuildContext context) {
  return DonerTypography.body(
    Theme.of(context).textTheme.titleMedium?.copyWith(
      color: DonerColors.creamText,
      fontWeight: FontWeight.w900,
    ),
  );
}

TextStyle _bodyStyle(BuildContext context) {
  return DonerTypography.body(
    Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: DonerColors.creamText,
      fontWeight: FontWeight.w800,
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

String _chestLabel(ChestType type) {
  return switch (type) {
    ChestType.small => 'Small Chest',
    ChestType.master => 'Master Chest',
    ChestType.gold => 'Gold Chest',
  };
}

String _format(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
