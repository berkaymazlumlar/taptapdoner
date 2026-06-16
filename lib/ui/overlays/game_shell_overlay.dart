import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/overlays/action_dock_overlay.dart';
import 'package:taptapdoner/ui/overlays/combo_badge.dart';
import 'package:taptapdoner/ui/overlays/customer_order_overlay.dart';
import 'package:taptapdoner/ui/overlays/game_hud_overlay.dart';
import 'package:taptapdoner/ui/overlays/settings_overlay.dart';
import 'package:taptapdoner/ui/overlays/starter_quest_overlay.dart';
import 'package:taptapdoner/ui/overlays/tap_zone_overlay.dart';
import 'package:taptapdoner/ui/pages/branch_page.dart';
import 'package:taptapdoner/ui/pages/goals_page.dart';
import 'package:taptapdoner/ui/pages/prestige_page.dart';
import 'package:taptapdoner/ui/pages/shop_page.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/game_bottom_nav_bar.dart';

class GameShellOverlay extends StatefulWidget {
  const GameShellOverlay({required this.controller, super.key});

  final GameController controller;

  @override
  State<GameShellOverlay> createState() => _GameShellOverlayState();
}

class _GameShellOverlayState extends State<GameShellOverlay> {
  GameBottomNavTab _activeTab = GameBottomNavTab.kitchen;
  bool _settingsVisible = false;

  void _selectTab(GameBottomNavTab tab) {
    if (!mounted || _activeTab == tab) {
      return;
    }
    if (tab == GameBottomNavTab.prestige) {
      widget.controller.markPrestigeScreenOpened();
    }
    _prepareTab(tab);

    setState(() {
      _activeTab = tab;
      _settingsVisible = false;
    });
  }

  void _prepareTab(GameBottomNavTab tab) {
    switch (tab) {
      case GameBottomNavTab.kitchen:
        widget.controller.prepareKitchenView();
        break;
      case GameBottomNavTab.shop:
        widget.controller.prepareShopView();
        break;
      case GameBottomNavTab.branches:
        widget.controller.prepareBranchView();
        break;
      case GameBottomNavTab.goals:
        widget.controller.prepareGoalsView();
        break;
      case GameBottomNavTab.prestige:
        widget.controller.preparePrestigeView();
        break;
    }
  }

  void _openSettings() {
    setState(() {
      _settingsVisible = true;
    });
  }

  void _closeSettings() {
    setState(() {
      _settingsVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return SizedBox.expand(
      child: ColoredBox(
        color: DonerColors.bgPrimary,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: padding.top,
                bottom: padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildActiveTab()),
                  _buildBottomNav(),
                ],
              ),
            ),
            if (_settingsVisible)
              SettingsOverlay(
                controller: widget.controller,
                onClose: _closeSettings,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_activeTab) {
      case GameBottomNavTab.kitchen:
        return _KitchenTabPage(
          controller: widget.controller,
          onOpenSettings: _openSettings,
        );
      case GameBottomNavTab.shop:
        return KeyedSubtree(
          key: const ValueKey('shop-tab-root'),
          child: ShopPage(
            controller: widget.controller,
            onOpenKitchen: () => _selectTab(GameBottomNavTab.kitchen),
            onOpenPrestige: () => _selectTab(GameBottomNavTab.prestige),
            onBack: () => _selectTab(GameBottomNavTab.kitchen),
            presentation: ShopPagePresentation.tab,
          ),
        );
      case GameBottomNavTab.branches:
        return KeyedSubtree(
          key: const ValueKey('branches-tab-root'),
          child: BranchPage(controller: widget.controller),
        );
      case GameBottomNavTab.goals:
        return KeyedSubtree(
          key: const ValueKey('goals-tab-root'),
          child: GoalsPage(controller: widget.controller),
        );
      case GameBottomNavTab.prestige:
        return KeyedSubtree(
          key: const ValueKey('prestige-tab-root'),
          child: PrestigePage(
            controller: widget.controller,
            onOpenKitchen: () => _selectTab(GameBottomNavTab.kitchen),
            onOpenShop: () => _selectTab(GameBottomNavTab.shop),
            onBack: () => _selectTab(GameBottomNavTab.kitchen),
            onPrestigeApplied: () async {
              _selectTab(GameBottomNavTab.kitchen);
            },
            presentation: PrestigePagePresentation.tab,
          ),
        );
    }
  }

  Widget _buildBottomNav() {
    return GameBottomNavBar(
      activeTab: _activeTab,
      onOpenKitchen: () => _selectTab(GameBottomNavTab.kitchen),
      onOpenShop: () => _selectTab(GameBottomNavTab.shop),
      onOpenBranches: () => _selectTab(GameBottomNavTab.branches),
      onOpenGoals: () => _selectTab(GameBottomNavTab.goals),
      onOpenPrestige: () => _selectTab(GameBottomNavTab.prestige),
    );
  }
}

class _KitchenTabPage extends StatefulWidget {
  const _KitchenTabPage({
    required this.controller,
    required this.onOpenSettings,
  });

  final GameController controller;
  final VoidCallback onOpenSettings;

  @override
  State<_KitchenTabPage> createState() => _KitchenTabPageState();
}

class _KitchenTabPageState extends State<_KitchenTabPage> {
  late final TapTapDonerGame _game;
  bool _questPanelVisible = false;

  @override
  void initState() {
    super.initState();
    _game = TapTapDonerGame(controller: widget.controller);
  }

  void _toggleQuestPanel() {
    setState(() {
      _questPanelVisible = !_questPanelVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _ShellMetrics.fromContext(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        GameWidget<TapTapDonerGame>(game: _game),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameHudOverlay(
              controller: widget.controller,
              onOpenSettings: widget.onOpenSettings,
            ),
            SizedBox(height: 6 * metrics.scale),
            CustomerOrderOverlay(controller: widget.controller),
            SizedBox(height: metrics.mainTopGap),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: TapZoneOverlay(
                      controller: widget.controller,
                      game: _game,
                      applySafeArea: false,
                    ),
                  ),
                  Positioned(
                    top: metrics.questPanelTopInset,
                    right: metrics.questButtonSideInset,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      reverseDuration: const Duration(milliseconds: 130),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.92,
                              end: 1,
                            ).animate(animation),
                            alignment: Alignment.topRight,
                            child: child,
                          ),
                        );
                      },
                      child: _questPanelVisible
                          ? StarterQuestOverlay(
                              key: const ValueKey('starter-quest-panel-open'),
                              controller: widget.controller,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('starter-quest-panel-closed'),
                            ),
                    ),
                  ),
                  Positioned(
                    top: metrics.rushButtonTopInset,
                    right: metrics.rushButtonSideInset,
                    child: ValueListenableBuilder<RushSnapshot>(
                      valueListenable: widget.controller.rushSnapshotListenable,
                      builder: (context, snapshot, _) {
                        return RushShortcutButton(
                          scale: metrics.scale,
                          enabled: snapshot.canStart,
                          onPressed: snapshot.canStart
                              ? () => widget.controller.startRush()
                              : null,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: metrics.questButtonTopInset,
                    right: metrics.questButtonSideInset,
                    child: ValueListenableBuilder<QuestSnapshot?>(
                      valueListenable:
                          widget.controller.questSnapshotListenable,
                      builder: (context, snapshot, _) {
                        return QuestShortcutButton(
                          scale: metrics.scale,
                          enabled: snapshot != null,
                          active: _questPanelVisible,
                          canClaim: snapshot?.canClaim ?? false,
                          onPressed: snapshot != null
                              ? _toggleQuestPanel
                              : null,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: metrics.progressionPopupSideInset,
                    right: metrics.questButtonSideInset + (68 * metrics.scale),
                    bottom: metrics.progressionPopupBottomInset,
                    child: _AchievementPopup(
                      controller: widget.controller,
                      scale: metrics.scale,
                    ),
                  ),
                  Positioned(
                    top: metrics.comboTopInset,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: ValueListenableBuilder<ActivePlaySnapshot>(
                          valueListenable:
                              widget.controller.activePlaySnapshotListenable,
                          builder: (context, snapshot, _) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              reverseDuration: const Duration(
                                milliseconds: 210,
                              ),
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                              transitionBuilder: (child, animation) {
                                final curved = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutBack,
                                  reverseCurve: Curves.easeInCubic,
                                );
                                final fade = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                  reverseCurve: Curves.easeIn,
                                );
                                return FadeTransition(
                                  opacity: fade,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, -0.16),
                                      end: Offset.zero,
                                    ).animate(curved),
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: 0.86,
                                        end: 1,
                                      ).animate(curved),
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: snapshot.hasCombo
                                  ? ComboBadge(
                                      key: const ValueKey(
                                        'combo-badge-visible',
                                      ),
                                      snapshot: snapshot,
                                      scale: metrics.scale,
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('combo-badge-hidden'),
                                    ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: metrics.mainBottomGap),
          ],
        ),
      ],
    );
  }
}

class _ShellMetrics {
  const _ShellMetrics({required this.scale});

  factory _ShellMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scale = math.min(size.width / 390.0, size.height / 884.0);
    return _ShellMetrics(scale: scale);
  }

  final double scale;

  double get mainTopGap => 10 * scale;
  double get mainBottomGap => 0;
  double get rushButtonTopInset => 8 * scale;
  double get rushButtonSideInset => 22 * scale;
  double get questButtonTopInset => rushButtonTopInset + (64 * scale);
  double get questButtonSideInset => rushButtonSideInset;
  double get questPanelTopInset => questButtonTopInset + (64 * scale);
  double get progressionPopupSideInset => 22 * scale;
  double get progressionPopupBottomInset => 12 * scale;
  double get comboTopInset => 4 * scale;
}

class _AchievementPopup extends StatelessWidget {
  const _AchievementPopup({required this.controller, required this.scale});

  final GameController controller;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgressionSnapshot>(
      valueListenable: controller.progressionSnapshotListenable,
      builder: (context, snapshot, _) {
        final achievement = snapshot.latestClaimableAchievement;
        if (achievement == null) {
          return const SizedBox.shrink();
        }
        return DecoratedBox(
          key: const ValueKey('achievement-popup-card'),
          decoration: BoxDecoration(
            gradient: DonerGradients.activeButton,
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(color: DonerColors.goldBright, width: 1.4),
            boxShadow: DonerShadows.soft,
          ),
          child: Padding(
            padding: EdgeInsets.all(10 * scale),
            child: Row(
              children: [
                FaIcon(
                  DonerIcons.goals,
                  color: DonerColors.creamText,
                  size: 18 * scale,
                ),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: Text(
                    achievement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DonerTypography.body(
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: DonerColors.creamText,
                        fontWeight: FontWeight.w900,
                        fontSize: 12 * scale,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  key: ValueKey('achievement-popup-claim-${achievement.id}'),
                  onPressed: () =>
                      controller.claimAchievementReward(achievement.id),
                  child: Text(AppStrings.of(context).claimLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
