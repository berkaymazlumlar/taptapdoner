import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/domain/progression/chest_drop_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/l10n/locale_case.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({required this.controller, super.key, this.bottomInset = 0});

  final GameController controller;
  final double bottomInset;

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
                  child: _AchievementPanel(
                    snapshot: snapshot,
                    onClaim: controller.claimAchievementReward,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 8 + bottomInset)),
            ],
          );
        },
      ),
    );
  }
}

class ChestPage extends StatelessWidget {
  const ChestPage({required this.controller, super.key, this.bottomInset = 0});

  final GameController controller;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      key: const ValueKey('chest-page-root'),
      child: ValueListenableBuilder<ProgressionSnapshot>(
        valueListenable: controller.progressionSnapshotListenable,
        builder: (context, snapshot, _) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _FeatureHeader(
                    icon: DonerIcons.chest,
                    title: strings.isTurkish ? 'Sandıklar' : 'Chests',
                    subtitle: strings.isTurkish
                        ? '${snapshot.chests.totalCount} sandık açılmaya hazır'
                        : '${snapshot.chests.totalCount} chests ready to open',
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 20 + bottomInset),
                sliver: SliverToBoxAdapter(
                  child: _ChestPanel(
                    snapshot: snapshot,
                    onOpen: controller.openChest,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CollectionPage extends StatelessWidget {
  const CollectionPage({
    required this.controller,
    super.key,
    this.bottomInset = 0,
  });

  final GameController controller;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      key: const ValueKey('collection-page-root'),
      child: ValueListenableBuilder<ProgressionSnapshot>(
        valueListenable: controller.progressionSnapshotListenable,
        builder: (context, snapshot, _) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _FeatureHeader(
                    icon: DonerIcons.collection,
                    title: strings.isTurkish ? 'Koleksiyon' : 'Collection',
                    subtitle:
                        '${snapshot.unlockedCollectionCount}/${snapshot.totalCollectionCount} '
                        '${strings.isTurkish ? 'parça keşfedildi' : 'items discovered'}',
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 20 + bottomInset),
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
                  strings.isTurkish ? 'Başarımlar' : 'Achievements',
                  style: _titleStyle(context),
                ),
                const SizedBox(height: 3),
                Text(
                  '${snapshot.claimableAchievementCount} ready  |  '
                  '${snapshot.achievements.length} achievements',
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

class _FeatureHeader extends StatelessWidget {
  const _FeatureHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final FaIconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DonerGradients.activeButton,
              border: Border.all(color: DonerColors.goldPrimary, width: 1.5),
              boxShadow: DonerShadows.soft,
            ),
            child: FaIcon(icon, color: DonerColors.creamText, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _titleStyle(context)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
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
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final type in ChestType.values) ...[
            _ChestRow(
              key: ValueKey('goals-chest-row-${chestTypeKey(type)}'),
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
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final achievement in snapshot.achievements) ...[
            _AchievementRow(achievement: achievement, onClaim: onClaim),
            if (achievement != snapshot.achievements.last)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CollectionPanel extends StatefulWidget {
  const _CollectionPanel({required this.snapshot});

  final ProgressionSnapshot snapshot;

  @override
  State<_CollectionPanel> createState() => _CollectionPanelState();
}

class _CollectionPanelState extends State<_CollectionPanel> {
  int _selectedTab = 1;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _CollectionTabButton(
                label: 'Legacy',
                selected: _selectedTab == 0,
                onPressed: () => setState(() => _selectedTab = 0),
              ),
              _CollectionTabButton(
                label: 'Recipes',
                selected: _selectedTab == 1,
                onPressed: () => setState(() => _selectedTab = 1),
              ),
              _CollectionTabButton(
                label: 'Staff',
                selected: _selectedTab == 2,
                onPressed: () => setState(() => _selectedTab = 2),
              ),
              _CollectionTabButton(
                label: 'Decor',
                selected: _selectedTab == 3,
                onPressed: () => setState(() => _selectedTab = 3),
              ),
              _CollectionTabButton(
                label: 'Skins',
                selected: _selectedTab == 4,
                onPressed: () => setState(() => _selectedTab = 4),
              ),
              _CollectionTabButton(
                label: 'Sets',
                selected: _selectedTab == 5,
                onPressed: () => setState(() => _selectedTab = 5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._selectedRows(snapshot),
        ],
      ),
    );
  }

  List<Widget> _selectedRows(ProgressionSnapshot snapshot) {
    switch (_selectedTab) {
      case 0:
        final visibleItems = snapshot.collections.take(18).toList();
        return _spacedRows([
          for (final item in visibleItems) _CollectionRow(item: item),
        ]);
      case 1:
        return _spacedRows([
          for (final item in snapshot.recipeCollections)
            _Collection2Row(item: item),
        ]);
      case 2:
        return _spacedRows([
          for (final item in snapshot.staffCollections)
            _Collection2Row(item: item, showDropSources: true),
        ]);
      case 3:
        return _spacedRows([
          for (final item in snapshot.decorCollections)
            _Collection2Row(item: item),
        ]);
      case 4:
        return _spacedRows([
          for (final item in snapshot.knifeSkinCollections)
            _Collection2Row(item: item),
        ]);
      default:
        return _spacedRows([
          for (final item in snapshot.collectionSets)
            _CollectionSetRow(item: item),
        ]);
    }
  }

  List<Widget> _spacedRows(List<Widget> rows) {
    if (rows.isEmpty) {
      return [
        DecoratedBox(
          decoration: _itemDecoration(false),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text('Empty', style: _metaStyle(context)),
          ),
        ),
      ];
    }
    return [
      for (var index = 0; index < rows.length; index += 1) ...[
        rows[index],
        if (index != rows.length - 1) const SizedBox(height: 8),
      ],
    ];
  }
}

class _CollectionTabButton extends StatelessWidget {
  const _CollectionTabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(58, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: selected
            ? DonerColors.goldPrimary
            : DonerColors.panelDark.withValues(alpha: 0.55),
        foregroundColor: selected
            ? DonerColors.panelDark
            : DonerColors.bodyText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _ChestRow extends StatefulWidget {
  const _ChestRow({
    super.key,
    required this.type,
    required this.count,
    required this.onOpen,
  });

  final ChestType type;
  final int count;
  final Future<LastChestRewardSnapshot?> Function() onOpen;

  @override
  State<_ChestRow> createState() => _ChestRowState();
}

class _ChestRowState extends State<_ChestRow> with TickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 1000);
  static const _spinDuration = Duration(milliseconds: 5400);
  static const _settleDuration = Duration(milliseconds: 2300);
  static const _resultPulseDuration = Duration(milliseconds: 720);
  static const _switchDuration = Duration(milliseconds: 360);
  static const _switchOutDuration = Duration(milliseconds: 280);

  late final AnimationController _spinController;
  late final AnimationController _resultController;
  LastChestRewardSnapshot? _targetReward;
  bool _opening = false;
  bool _resultVisible = false;
  bool _detailsExpanded = false;
  int _spinSeed = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: _spinDuration);
    _resultController = AnimationController(
      vsync: this,
      duration: _resultPulseDuration,
    );
  }

  @override
  void didUpdateWidget(covariant _ChestRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _spinController.reset();
      _resultController.reset();
      _targetReward = null;
      _opening = false;
      _resultVisible = false;
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _handleOpen() {
    if (_opening || widget.count <= 0) {
      return;
    }
    setState(() {
      _opening = true;
      _targetReward = null;
      _resultVisible = false;
      _spinSeed += 1;
    });
    _spinController.reset();
    _resultController.reset();
    unawaited(_openAndSpin());
  }

  Future<void> _openAndSpin() async {
    LastChestRewardSnapshot? reward;
    try {
      await Future<void>.delayed(_introDuration);
      if (!mounted || !_opening) {
        return;
      }
      reward = await widget.onOpen();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'goals page',
          context: ErrorDescription('while opening a chest'),
        ),
      );
      if (mounted) {
        setState(() {
          _opening = false;
          _targetReward = null;
          _resultVisible = false;
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }
    if (reward == null) {
      setState(() {
        _opening = false;
        _targetReward = null;
        _resultVisible = false;
      });
      return;
    }

    setState(() {
      _targetReward = reward;
    });
    await _spinController.forward(from: 0);
    if (!mounted) {
      return;
    }
    setState(() {
      _resultVisible = true;
    });
    _resultController.repeat(reverse: true);
    await Future<void>.delayed(_settleDuration);
    if (!mounted) {
      return;
    }
    _resultController
      ..stop()
      ..reset();
    setState(() {
      _opening = false;
      _resultVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final transitionHeight = _chestTransitionHeight(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: _switchDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: _switchDuration,
                  reverseDuration: _switchOutDuration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final fadeAnimation = CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.08, 1, curve: Curves.easeOutQuad),
                      reverseCurve: const Interval(
                        0,
                        0.72,
                        curve: Curves.easeInQuad,
                      ),
                    );
                    final isRoulette = child is _ChestRouletteBar;
                    final scaleAnimation =
                        Tween<double>(
                          begin: isRoulette ? 0.94 : 1.035,
                          end: 1,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: isRoulette
                                ? Curves.easeOutBack
                                : Curves.easeOutCubic,
                            reverseCurve: Curves.easeInCubic,
                          ),
                        );
                    return FadeTransition(
                      opacity: fadeAnimation,
                      child: ScaleTransition(
                        scale: scaleAnimation,
                        alignment: Alignment.center,
                        child: child,
                      ),
                    );
                  },
                  child: _opening
                      ? _ChestRouletteBar(
                          height: transitionHeight,
                          type: widget.type,
                          targetReward: _targetReward,
                          animation: _spinController,
                          resultAnimation: _resultController,
                          resultVisible: _resultVisible,
                          seed: _spinSeed,
                        )
                      : KeyedSubtree(
                          key: ValueKey(
                            'goals-chest-idle-${chestTypeKey(widget.type)}',
                          ),
                          child: _buildIdleRow(
                            context,
                            height: transitionHeight,
                          ),
                        ),
                ),
              ),
            ),
            if (!_opening && _detailsExpanded) ...[
              const SizedBox(height: 8),
              _ChestContentsDetail(type: widget.type),
            ],
          ],
        );
      },
    );
  }

  Widget _buildIdleRow(BuildContext context, {required double height}) {
    final enabled = widget.count > 0;
    final button = _GoalsActionButton(
      buttonKey: ValueKey('goals-open-${chestTypeKey(widget.type)}-chest'),
      label: 'Open',
      onPressed: enabled ? _handleOpen : null,
    );
    final detailButton = IconButton(
      key: ValueKey('goals-chest-details-${chestTypeKey(widget.type)}'),
      tooltip: AppStrings.of(context).isTurkish
          ? 'Olası ödüller'
          : 'Possible rewards',
      onPressed: () => setState(() => _detailsExpanded = !_detailsExpanded),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: AnimatedRotation(
        turns: _detailsExpanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 180),
        child: const FaIcon(DonerIcons.expand, size: 13),
      ),
      color: _detailsExpanded ? DonerColors.goldBright : DonerColors.bodyText,
    );
    return SizedBox(
      height: height,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackVertically = constraints.maxWidth < 248;
            final title = Text(
              '${_localizedChestLabel(context, widget.type)} x${widget.count}',
              maxLines: stackVertically ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: _bodyStyle(context),
            );

            if (stackVertically) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [detailButton, const SizedBox(width: 4), button],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: 4),
                detailButton,
                const SizedBox(width: 4),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChestRouletteBar extends StatelessWidget {
  const _ChestRouletteBar({
    required this.height,
    required this.type,
    required this.targetReward,
    required this.animation,
    required this.resultAnimation,
    required this.resultVisible,
    required this.seed,
  });

  static const double _itemWidth = 86;
  static const double _itemGap = 8;
  static const int _itemCount = 38;
  static const int _targetIndex = 31;
  static const double _defaultHeight = 58;
  static const Curve _spinCurve = _ChestSpinCurve();

  final double height;
  final ChestType type;
  final LastChestRewardSnapshot? targetReward;
  final Animation<double> animation;
  final Animation<double> resultAnimation;
  final bool resultVisible;
  final int seed;

  static double get _stride => _itemWidth + _itemGap;

  @override
  Widget build(BuildContext context) {
    final rewards = _rouletteRewards();
    final sequenceWidth = _itemWidth * _itemCount + _itemGap * (_itemCount - 1);
    return SizedBox(
      key: ValueKey('goals-chest-roulette-${chestTypeKey(type)}'),
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DonerColors.panelDark.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DonerColors.goldPrimary),
          boxShadow: DonerShadows.goldGlow,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stopOffset =
                _targetIndex * _stride +
                _itemWidth / 2 -
                constraints.maxWidth / 2;
            return Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ClipRect(
                      child: AnimatedBuilder(
                        animation: animation,
                        child: SizedBox(
                          width: sequenceWidth,
                          child: Row(
                            children: [
                              for (
                                var index = 0;
                                index < rewards.length;
                                index++
                              ) ...[
                                _RouletteRewardCard(
                                  key:
                                      resultVisible &&
                                          targetReward != null &&
                                          index == _targetIndex
                                      ? ValueKey(
                                          'goals-chest-roulette-result-${chestTypeKey(type)}',
                                        )
                                      : null,
                                  reward: rewards[index],
                                  revealAnimation: resultAnimation,
                                  highlighted:
                                      resultVisible &&
                                      targetReward != null &&
                                      index == _targetIndex,
                                ),
                                if (index != rewards.length - 1)
                                  const SizedBox(width: _itemGap),
                              ],
                            ],
                          ),
                        ),
                        builder: (context, child) {
                          final spinValue = _spinCurve.transform(
                            animation.value,
                          );
                          return OverflowBox(
                            alignment: Alignment.centerLeft,
                            minWidth: sequenceWidth,
                            maxWidth: sequenceWidth,
                            child: Transform.translate(
                              offset: Offset(-stopOffset * spinValue, 0),
                              child: child,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: [
                            DonerColors.panelDark.withValues(alpha: 0.82),
                            DonerColors.panelDark.withValues(alpha: 0),
                            DonerColors.panelDark.withValues(alpha: 0),
                            DonerColors.panelDark.withValues(alpha: 0.82),
                          ],
                          stops: const [0, 0.16, 0.84, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: DonerColors.goldBright,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: DonerShadows.goldGlow,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_ChestRouletteReward> _rouletteRewards() {
    final base = ChestDropCatalog.tableFor(
      type,
    ).drops.map(_rouletteRewardFromDrop).toList(growable: false);
    final fallback = base.isEmpty
        ? const _ChestRouletteReward(
            rewardType: ChestRewardType.money,
            label: 'Cash',
            rarity: Rarity.common,
          )
        : base.first;
    final rewards = List<_ChestRouletteReward>.generate(_itemCount, (index) {
      if (base.isEmpty) {
        return fallback;
      }
      return base[(index + seed) % base.length];
    });
    final target = targetReward;
    if (target != null) {
      rewards[_targetIndex] = _rouletteRewardFromSnapshot(target, type);
    }
    return rewards;
  }
}

class _ChestContentsDetail extends StatelessWidget {
  const _ChestContentsDetail({required this.type});

  final ChestType type;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final table = ChestDropCatalog.tableFor(type);
    final totalWeight = table.drops.fold<int>(
      0,
      (total, drop) => total + drop.weight,
    );
    return DecoratedBox(
      key: ValueKey('goals-chest-contents-${chestTypeKey(type)}'),
      decoration: _itemDecoration(false),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.isTurkish ? 'OLASI ÖDÜLLER' : 'POSSIBLE REWARDS',
              style: _metaStyle(
                context,
              ).copyWith(color: DonerColors.goldBright),
            ),
            const SizedBox(height: 7),
            for (var index = 0; index < table.drops.length; index += 1) ...[
              _ChestDropDetailRow(
                drop: table.drops[index],
                probability: table.drops[index].weight / totalWeight,
              ),
              if (index != table.drops.length - 1) const SizedBox(height: 5),
            ],
            if (type == ChestType.staff) ...[
              const SizedBox(height: 9),
              Text(
                strings.isTurkish
                    ? 'Kaynak: Günlük 50 itibar ve haftalık 50 müşteri hedefleri.'
                    : 'Source: Daily 50 reputation and weekly 50 customers goals.',
                key: const ValueKey('staff-chest-goal-source'),
                style: _metaStyle(
                  context,
                ).copyWith(color: DonerColors.tealBright),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChestDropDetailRow extends StatelessWidget {
  const _ChestDropDetailRow({required this.drop, required this.probability});

  final WeightedDrop drop;
  final double probability;

  @override
  Widget build(BuildContext context) {
    final isStaff = drop.rewardType == ChestRewardType.staffCardShard;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(
          _rouletteRewardIcon(drop.rewardType),
          size: 12,
          color: isStaff ? DonerColors.tealBright : DonerColors.bodyText,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _chestDropDetailLabel(context, drop),
            style: _metaStyle(context).copyWith(
              color: isStaff ? DonerColors.tealBright : DonerColors.bodyText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatProbability(probability),
          style: _metaStyle(context).copyWith(
            color: isStaff ? DonerColors.tealBright : DonerColors.goldBright,
          ),
        ),
      ],
    );
  }
}

class _RouletteRewardCard extends StatelessWidget {
  const _RouletteRewardCard({
    super.key,
    required this.reward,
    required this.revealAnimation,
    required this.highlighted,
  });

  final _ChestRouletteReward reward;
  final Animation<double> revealAnimation;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final accent = _rarityColor(reward.rarity);
    return AnimatedBuilder(
      animation: revealAnimation,
      builder: (context, child) {
        final pulse = highlighted
            ? Curves.easeInOut.transform(revealAnimation.value)
            : 0.0;
        final highlightColor = Color.lerp(
          accent,
          DonerColors.goldBright,
          0.45 + pulse * 0.35,
        )!;
        final borderColor = highlighted ? highlightColor : accent;
        final scale = highlighted ? 1.03 + pulse * 0.055 : 1.0;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: _ChestRouletteBar._itemWidth,
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: highlighted
                    ? DonerColors.panelDark.withValues(alpha: 0.98)
                    : DonerColors.panelDark.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: highlighted ? 2 + pulse : 1.1,
                ),
                boxShadow: highlighted
                    ? [
                        BoxShadow(
                          color: highlightColor.withValues(alpha: 0.45),
                          blurRadius: 14 + pulse * 8,
                          spreadRadius: 1 + pulse,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.16),
                          blurRadius: 8,
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: Row(
                  children: [
                    FaIcon(
                      _rouletteRewardIcon(reward.rewardType),
                      color: borderColor,
                      size: highlighted ? 16 : 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reward.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DonerTypography.body(
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: DonerColors.creamText,
                            fontSize: 10,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChestRouletteReward {
  const _ChestRouletteReward({
    required this.rewardType,
    required this.label,
    required this.rarity,
  });

  final ChestRewardType rewardType;
  final String label;
  final Rarity rarity;
}

class _ChestSpinCurve extends Curve {
  const _ChestSpinCurve();

  @override
  double transformInternal(double t) {
    if (t <= 0) {
      return 0;
    }
    if (t >= 1) {
      return 1;
    }

    const accelerationTime = 0.34;
    const accelerationDistance = 0.58;
    if (t < accelerationTime) {
      final local = t / accelerationTime;
      return accelerationDistance * Curves.easeInCubic.transform(local);
    }

    final local = (t - accelerationTime) / (1 - accelerationTime);
    final deceleration = Curves.easeOutQuart.transform(local);
    return accelerationDistance + (1 - accelerationDistance) * deceleration;
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
                    '${_format(context, achievement.currentValue)} / ${_format(context, achievement.targetValue)}',
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
                    '${item.rarity.name.toLocaleUpperCase(context)}  |  ${item.bonusLabel}',
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

class _Collection2Row extends StatelessWidget {
  const _Collection2Row({required this.item, this.showDropSources = false});

  final Collection2ItemSnapshot item;
  final bool showDropSources;

  @override
  Widget build(BuildContext context) {
    final maxed = item.unlocked && item.level >= item.maxLevel;
    final status = item.maxLevel > 1
        ? 'Lv ${item.level}/${item.maxLevel}'
        : item.equipped
        ? 'Equipped'
        : item.unlocked
        ? 'Unlocked'
        : '${item.currentShards}/${item.requiredShards}';
    return DecoratedBox(
      decoration: _itemDecoration(item.unlocked),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                  child: Text(
                    item.unlocked
                        ? item.name
                        : 'Locked ${_kindLabel(item.kind)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _bodyStyle(context),
                  ),
                ),
                const SizedBox(width: 8),
                Text(status, style: _metaStyle(context)),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: maxed ? 1 : item.progress,
                minHeight: 5,
                backgroundColor: DonerColors.panelDark,
                valueColor: AlwaysStoppedAnimation(
                  item.unlocked
                      ? DonerColors.goldBright
                      : DonerColors.tealBright,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${item.rarity.name.toLocaleUpperCase(context)}  |  ${item.bonusLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _metaStyle(context),
            ),
            if (showDropSources) ...[
              const SizedBox(height: 7),
              Text(
                _staffDropSourceLabel(context, item.id),
                key: ValueKey('staff-drop-sources-${item.id}'),
                style: _metaStyle(
                  context,
                ).copyWith(color: DonerColors.tealBright),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollectionSetRow extends StatelessWidget {
  const _CollectionSetRow({required this.item});

  final CollectionSetSnapshot item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _itemDecoration(item.claimed),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                FaIcon(
                  item.claimed ? DonerIcons.collection : DonerIcons.lock,
                  color: item.claimed
                      ? DonerColors.goldBright
                      : DonerColors.disabledText,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _bodyStyle(context),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.claimed
                      ? 'Active'
                      : item.completed
                      ? 'Ready'
                      : 'Locked',
                  style: _metaStyle(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.bonusLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _metaStyle(context),
            ),
            const SizedBox(height: 3),
            Text(
              item.requirementLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _metaStyle(context),
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

_ChestRouletteReward _rouletteRewardFromDrop(WeightedDrop drop) {
  return _ChestRouletteReward(
    rewardType: drop.rewardType,
    label: _rouletteDropLabel(drop),
    rarity: drop.rarity,
  );
}

_ChestRouletteReward _rouletteRewardFromSnapshot(
  LastChestRewardSnapshot reward,
  ChestType chestType,
) {
  return _ChestRouletteReward(
    rewardType: reward.rewardType,
    label: _rouletteSnapshotLabel(reward),
    rarity: _rouletteSnapshotRarity(reward, chestType),
  );
}

String _rouletteDropLabel(WeightedDrop drop) {
  return switch (drop.rewardType) {
    ChestRewardType.money => 'Cash',
    ChestRewardType.reputation => 'Rep +${formatNumberWithUnits(drop.amount)}',
    ChestRewardType.temporaryIncomeBoost => 'Income x${drop.amount}',
    ChestRewardType.cosmeticToken =>
      'Token x${formatNumberWithUnits(drop.amount)}',
    ChestRewardType.recipeShard =>
      'Recipe x${formatNumberWithUnits(drop.amount)}',
    ChestRewardType.staffCardShard =>
      'Staff x${formatNumberWithUnits(drop.amount)}',
    ChestRewardType.decorShard =>
      'Decor x${formatNumberWithUnits(drop.amount)}',
    ChestRewardType.knifeSkinShard =>
      'Skin x${formatNumberWithUnits(drop.amount)}',
    ChestRewardType.prestigeShard =>
      'Prestige x${formatNumberWithUnits(drop.amount)}',
    ChestRewardType.permanentTapBonus => 'Tap +${drop.amount}%',
    ChestRewardType.permanentPassiveBonus => 'Passive +${drop.amount}%',
    ChestRewardType.permanentGlobalBonus => 'Global +${drop.amount}%',
  };
}

String _rouletteSnapshotLabel(LastChestRewardSnapshot reward) {
  return switch (reward.rewardType) {
    ChestRewardType.money => '+${formatNumberWithUnits(reward.amount)} cash',
    ChestRewardType.reputation =>
      '+${formatNumberWithUnits(reward.amount)} rep',
    ChestRewardType.temporaryIncomeBoost ||
    ChestRewardType.cosmeticToken ||
    ChestRewardType.recipeShard ||
    ChestRewardType.staffCardShard ||
    ChestRewardType.decorShard ||
    ChestRewardType.knifeSkinShard ||
    ChestRewardType.prestigeShard ||
    ChestRewardType.permanentTapBonus ||
    ChestRewardType.permanentPassiveBonus ||
    ChestRewardType.permanentGlobalBonus => reward.label,
  };
}

Rarity _rouletteSnapshotRarity(
  LastChestRewardSnapshot reward,
  ChestType chestType,
) {
  Rarity? firstMatchingType;
  for (final drop in ChestDropCatalog.tableFor(chestType).drops) {
    if (drop.rewardType != reward.rewardType) {
      continue;
    }
    firstMatchingType ??= drop.rarity;
    if (_dropAmountMatchesReward(drop, reward)) {
      return drop.rarity;
    }
  }
  return firstMatchingType ?? Rarity.common;
}

bool _dropAmountMatchesReward(
  WeightedDrop drop,
  LastChestRewardSnapshot reward,
) {
  if (reward.rewardType == ChestRewardType.money) {
    return true;
  }
  final amount = _isPermanentPercentReward(reward.rewardType)
      ? drop.amount / 100
      : drop.amount.toDouble();
  return amount == reward.amount;
}

bool _isPermanentPercentReward(ChestRewardType rewardType) {
  return switch (rewardType) {
    ChestRewardType.permanentTapBonus ||
    ChestRewardType.permanentPassiveBonus ||
    ChestRewardType.permanentGlobalBonus => true,
    ChestRewardType.money ||
    ChestRewardType.reputation ||
    ChestRewardType.temporaryIncomeBoost ||
    ChestRewardType.cosmeticToken ||
    ChestRewardType.recipeShard ||
    ChestRewardType.staffCardShard ||
    ChestRewardType.decorShard ||
    ChestRewardType.knifeSkinShard ||
    ChestRewardType.prestigeShard => false,
  };
}

FaIconData _rouletteRewardIcon(ChestRewardType rewardType) {
  return switch (rewardType) {
    ChestRewardType.money => DonerIcons.cash,
    ChestRewardType.reputation => DonerIcons.reputation,
    ChestRewardType.temporaryIncomeBoost => DonerIcons.idleIncome,
    ChestRewardType.cosmeticToken => DonerIcons.diamond,
    ChestRewardType.recipeShard ||
    ChestRewardType.staffCardShard ||
    ChestRewardType.decorShard => DonerIcons.collection,
    ChestRewardType.knifeSkinShard => DonerIcons.upgradeKnife,
    ChestRewardType.prestigeShard ||
    ChestRewardType.permanentTapBonus ||
    ChestRewardType.permanentPassiveBonus ||
    ChestRewardType.permanentGlobalBonus => DonerIcons.prestige,
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

double _chestTransitionHeight(double maxWidth) {
  if (maxWidth < 248) {
    return 92;
  }
  return _ChestRouletteBar._defaultHeight;
}

String _chestLabel(ChestType type) {
  return switch (type) {
    ChestType.small => 'Small Chest',
    ChestType.master => 'Master Chest',
    ChestType.gold => 'Gold Chest',
    ChestType.recipe => 'Recipe Chest',
    ChestType.staff => 'Staff Chest',
    ChestType.decor => 'Decor Chest',
    ChestType.prestige => 'Prestige Chest',
  };
}

String _localizedChestLabel(BuildContext context, ChestType type) {
  if (!AppStrings.of(context).isTurkish) {
    return _chestLabel(type);
  }
  return switch (type) {
    ChestType.small => 'Küçük Sandık',
    ChestType.master => 'Usta Sandığı',
    ChestType.gold => 'Altın Sandık',
    ChestType.recipe => 'Tarif Sandığı',
    ChestType.staff => 'Personel Sandığı',
    ChestType.decor => 'Dekor Sandığı',
    ChestType.prestige => 'Prestij Sandığı',
  };
}

String _staffDropSourceLabel(BuildContext context, String staffId) {
  final sources = <String>[];
  for (final type in ChestType.values) {
    final table = ChestDropCatalog.tableFor(type);
    final totalWeight = table.drops.fold<int>(
      0,
      (total, drop) => total + drop.weight,
    );
    final matchingWeight = table.drops
        .where(
          (drop) =>
              drop.rewardType == ChestRewardType.staffCardShard &&
              drop.itemId == staffId,
        )
        .fold<int>(0, (total, drop) => total + drop.weight);
    if (matchingWeight > 0 && totalWeight > 0) {
      sources.add(
        '${_localizedChestLabel(context, type)} '
        '(${_formatProbability(matchingWeight / totalWeight)})',
      );
    }
  }
  final prefix = AppStrings.of(context).isTurkish
      ? 'Nereden elde edilir?'
      : 'Where to get it?';
  final unavailable = AppStrings.of(context).isTurkish
      ? 'Henüz sandık kaynağı yok.'
      : 'No chest source yet.';
  return '$prefix ${sources.isEmpty ? unavailable : sources.join(' • ')}';
}

String _chestDropDetailLabel(BuildContext context, WeightedDrop drop) {
  final strings = AppStrings.of(context);
  final itemName = _collection2ItemName(drop.itemId);
  final amount = formatNumberWithUnits(drop.amount);
  return switch (drop.rewardType) {
    ChestRewardType.money =>
      strings.isTurkish ? '$amount para' : '$amount cash',
    ChestRewardType.reputation =>
      strings.isTurkish ? '$amount itibar' : '$amount reputation',
    ChestRewardType.temporaryIncomeBoost =>
      strings.isTurkish
          ? '${drop.amount}x gelir (${drop.durationSeconds ?? 0} sn)'
          : '${drop.amount}x income (${drop.durationSeconds ?? 0}s)',
    ChestRewardType.cosmeticToken =>
      strings.isTurkish ? '$amount kozmetik jetonu' : '$amount cosmetic token',
    ChestRewardType.recipeShard =>
      strings.isTurkish
          ? '$itemName • $amount tarif parçası'
          : '$itemName • $amount recipe shards',
    ChestRewardType.staffCardShard =>
      strings.isTurkish
          ? '$itemName • $amount personel kartı'
          : '$itemName • $amount staff cards',
    ChestRewardType.decorShard =>
      strings.isTurkish
          ? '$itemName • $amount dekor parçası'
          : '$itemName • $amount decor shards',
    ChestRewardType.knifeSkinShard =>
      strings.isTurkish
          ? '$itemName • $amount bıçak görünümü parçası'
          : '$itemName • $amount knife skin shards',
    ChestRewardType.prestigeShard =>
      strings.isTurkish ? '$amount prestij parçası' : '$amount prestige shards',
    ChestRewardType.permanentTapBonus =>
      strings.isTurkish
          ? 'Kalıcı dokunma +%$amount'
          : 'Permanent tap +$amount%',
    ChestRewardType.permanentPassiveBonus =>
      strings.isTurkish
          ? 'Kalıcı pasif +%$amount'
          : 'Permanent passive +$amount%',
    ChestRewardType.permanentGlobalBonus =>
      strings.isTurkish
          ? 'Kalıcı genel +%$amount'
          : 'Permanent global +$amount%',
  };
}

String _collection2ItemName(String? itemId) {
  if (itemId == null) {
    return '—';
  }
  for (final item in Collection2Catalog.recipes) {
    if (item.id == itemId) return item.name;
  }
  for (final item in Collection2Catalog.staffCards) {
    if (item.id == itemId) return item.name;
  }
  for (final item in Collection2Catalog.decorItems) {
    if (item.id == itemId) return item.name;
  }
  for (final item in Collection2Catalog.knifeSkins) {
    if (item.id == itemId) return item.name;
  }
  return itemId;
}

String _formatProbability(double probability) {
  final percent = probability * 100;
  return percent == percent.roundToDouble()
      ? '%${percent.toStringAsFixed(0)}'
      : '%${percent.toStringAsFixed(1)}';
}

String _kindLabel(Collection2ItemKind kind) {
  return switch (kind) {
    Collection2ItemKind.recipe => 'recipe',
    Collection2ItemKind.staff => 'staff',
    Collection2ItemKind.decor => 'decor',
    Collection2ItemKind.knifeSkin => 'skin',
    Collection2ItemKind.setBonus => 'set',
  };
}

String _format(BuildContext context, double value) {
  if (value.abs() >= 1000) {
    return formatCompactNumber(context, value);
  }
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
