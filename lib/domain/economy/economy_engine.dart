import 'dart:math';

import 'package:taptapdoner/domain/branches/branch_catalog.dart';
import 'package:taptapdoner/domain/economy/economy_calculator.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/progression/achievement_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_catalog.dart';
import 'package:taptapdoner/domain/progression/collection_catalog.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/progression/prestige_shop_catalog.dart';
import 'package:taptapdoner/domain/progression/shop_progression_catalog.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

class PurchaseResult {
  const PurchaseResult({
    required this.success,
    required this.state,
    this.cost = 0,
    this.reason,
    this.milestoneGrant,
  });

  final bool success;
  final GameState state;
  final int cost;
  final String? reason;
  final MilestoneGrant? milestoneGrant;
}

class MilestoneGrant {
  const MilestoneGrant({
    required this.key,
    required this.trackId,
    required this.itemKey,
    required this.level,
    required this.reward,
  });

  final String key;
  final UpgradeId trackId;
  final String itemKey;
  final int level;
  final MilestoneReward reward;
}

class ProductionGrant {
  const ProductionGrant({
    required this.coins,
    required this.rawElapsed,
    required this.effectiveElapsed,
    required this.rushElapsed,
  });

  const ProductionGrant.none()
    : coins = 0,
      rawElapsed = Duration.zero,
      effectiveElapsed = Duration.zero,
      rushElapsed = Duration.zero;

  final int coins;
  final Duration rawElapsed;
  final Duration effectiveElapsed;
  final Duration rushElapsed;

  bool get hasReward => coins > 0;
}

class EconomyEngine {
  const EconomyEngine(this.config);

  final EconomyConfig config;

  static const _comboMultiplierThresholds = <int, double>{
    10: 1.20,
    20: 1.40,
    30: 1.60,
    50: 2.00,
    75: 2.50,
    100: 3.00,
    150: 4.00,
    250: 5.00,
  };

  int upgradeCost(UpgradeDefinition definition, UpgradeState state) {
    return definition.costForLevel(_upgradeTotalLevel(definition, state));
  }

  bool isUpgradeMaxed(UpgradeDefinition definition, UpgradeState state) {
    return definition.isMaxLevel(_upgradeTotalLevel(definition, state));
  }

  double upgradeEffect(GameState state, UpgradeId id) {
    final baseEffect = getTrackEffectById(_activeUpgradeTracks(state), id.key);
    final milestones = state.milestones;
    final collection2Bonuses = Collection2Catalog.bonusTotalsFor(
      state.collection2,
    );
    return switch (id) {
      UpgradeId.knife =>
        baseEffect * _bonusMultiplier(milestones.tapBonusPercent),
      UpgradeId.staff =>
        baseEffect * _bonusMultiplier(milestones.passiveBonusPercent),
      UpgradeId.oven =>
        baseEffect * _bonusMultiplier(milestones.globalBonusPercent),
      UpgradeId.menu =>
        baseEffect *
            _bonusMultiplier(
              milestones.menuBonusPercent + collection2Bonuses.menuBonusPercent,
            ),
      UpgradeId.turbo =>
        baseEffect * _bonusMultiplier(milestones.turboBonusPercent),
      UpgradeId.offline =>
        (baseEffect + milestones.offlineEfficiencyBonus) *
            _bonusMultiplier(collection2Bonuses.offlineIncomeBonusPercent),
    };
  }

  double nextUpgradeEffect(GameState state, UpgradeId id) {
    final definition = config.upgrade(id);
    final totalLevel = upgradeTotalLevel(state, id);
    if (definition.isMaxLevel(totalLevel)) {
      return upgradeEffect(state, id);
    }
    final previewState = _applyUpgradeProgress(
      state,
      definition,
      id,
      nextTotalLevel: totalLevel + 1,
      claimMilestone: true,
    );
    return upgradeEffect(previewState, id);
  }

  int upgradeItemLevel(GameState state, UpgradeId id) {
    return config
        .upgrade(id)
        .itemLevelForTotalLevel(upgradeTotalLevel(state, id));
  }

  UpgradeItemDefinition currentUpgradeItem(GameState state, UpgradeId id) {
    final definition = config.upgrade(id);
    return definition.itemForLevel(upgradeTotalLevel(state, id));
  }

  UpgradeItemDefinition? nextUpgradeItem(GameState state, UpgradeId id) {
    final definition = config.upgrade(id);
    return definition.nextItemForLevel(upgradeTotalLevel(state, id));
  }

  int upgradeTotalLevel(GameState state, UpgradeId id) {
    final definition = config.upgrade(id);
    return _upgradeTotalLevel(definition, state.upgrade(id));
  }

  int tapValue(GameState state, {DateTime? nowUtc}) {
    final total = _tapIncome(
      state,
      nowUtc: nowUtc,
      comboMultiplier: comboMultiplierForCount(state.stats.currentCombo, state),
      criticalMultiplier: _criticalExpectedMultiplier(state),
    );
    return max(1, total.round());
  }

  int tapValueForActivePlay(
    GameState state, {
    DateTime? nowUtc,
    double comboMultiplier = 1,
    double criticalMultiplier = 1,
  }) {
    final total = _tapIncome(
      state,
      nowUtc: nowUtc,
      comboMultiplier: comboMultiplier,
      criticalMultiplier: criticalMultiplier,
    );
    return max(1, total.round());
  }

  double passiveIncomePerSecond(
    GameState state, {
    DateTime? nowUtc,
    bool includeRush = true,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final collectionBonuses = _permanentBonuses(state);
    final temporaryBoostMultiplier =
        includeRush && state.passiveBoost.isActiveAt(now) ? 2.0 : 1.0;
    final baseIncome = calculatePassiveIncomePerSecond(
      staffEffect: _staffEffect(state),
      ovenEffect: _ovenEffect(state),
      menuEffect: _menuEffect(state),
      shopMultiplier: shopMultiplier(state),
      prestigeMultiplier: _prestigeMultiplier(state),
      collectionPassiveMultiplier:
          collectionBonuses.passiveMultiplier *
          _prestigePassiveMultiplier(state),
      collectionGlobalMultiplier:
          collectionBonuses.globalMultiplier * _prestigeGlobalMultiplier(state),
      temporaryBoostMultiplier: temporaryBoostMultiplier,
    );
    return baseIncome +
        _branchIncomePerSecond(
          state,
          collectionBonuses: collectionBonuses,
          temporaryBoostMultiplier: temporaryBoostMultiplier,
        );
  }

  double branchIncomePerSecond(
    GameState state, {
    DateTime? nowUtc,
    bool includeRush = true,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final collectionBonuses = _permanentBonuses(state);
    return _branchIncomePerSecond(
      state,
      collectionBonuses: collectionBonuses,
      temporaryBoostMultiplier:
          includeRush && state.passiveBoost.isActiveAt(now) ? 2 : 1,
    );
  }

  double offlineEfficiency(GameState state) {
    return upgradeEffect(state, UpgradeId.offline);
  }

  Duration offlineCap(GameState state) {
    return config.offlineCap +
        Duration(
          seconds: max(0, state.milestones.offlineMaxDurationSeconds.round()),
        ) +
        Duration(
          seconds: _prestigeUpgradeEffectSeconds(
            state,
            PrestigeShopCatalog.bigRegister,
          ).round(),
        );
  }

  int offlineIncome(GameState state, Duration elapsed) {
    if (elapsed <= Duration.zero) {
      return 0;
    }
    final seconds = elapsed.inMilliseconds / 1000;
    final value = calculateOfflineIncome(
      passiveIncomePerSecond: passiveIncomePerSecond(state, includeRush: false),
      offlineSeconds: seconds,
      offlineEfficiency: offlineEfficiency(state),
    );
    return max(0, value.floor());
  }

  int availablePrestigePoints(GameState state) {
    if (config.prestigeThreshold <= 0) {
      return 0;
    }
    return sqrt(
      state.prestige.runCashEarned / config.prestigeThreshold,
    ).floor();
  }

  GameState applyTap(GameState state, {DateTime? nowUtc}) {
    return _addCoins(state, tapValue(state, nowUtc: nowUtc));
  }

  Duration comboExpireDuration(GameState state) {
    final raw =
        config.comboBaseExpireDuration +
        Duration(
          milliseconds: max(
            0,
            (state.milestones.comboDurationSeconds * 1000).round(),
          ),
        ) +
        Duration(
          milliseconds:
              (_prestigeUpgradeEffectSeconds(
                        state,
                        PrestigeShopCatalog.comboMaster,
                      ) *
                      1000)
                  .round(),
        );
    if (raw > config.comboMaxExpireDuration) {
      return config.comboMaxExpireDuration;
    }
    return raw;
  }

  double comboMultiplierForCount(int comboCount, GameState state) {
    if (activeComboForCount(comboCount, state) <= 0) {
      return 1;
    }
    var multiplier = 1.0;
    for (final entry in _comboMultiplierThresholds.entries) {
      if (comboCount >= entry.key) {
        multiplier = entry.value;
      }
    }
    multiplier += state.milestones.comboMultiplierBonus;
    return min(config.comboMaxMultiplier, max(1.0, multiplier));
  }

  int activeComboForCount(int comboCount, GameState state) {
    if (!state.milestones.hasFeature('combo')) {
      return 0;
    }
    final threshold = max(1, config.comboActivationThreshold);
    return comboCount >= threshold ? comboCount : 0;
  }

  double criticalChance(GameState state) {
    if (!state.milestones.hasFeature('critical_cut')) {
      return 0;
    }
    return min(config.criticalMaxChance, _criticalChanceBeforeCap(state));
  }

  double goldenDonerIntervalMultiplier(GameState state) {
    final bonus = _prestigeUpgradePercent(
      state,
      PrestigeShopCatalog.goldenLuck,
    );
    return max(0.50, 1 - bonus);
  }

  double shopMultiplier(GameState state) {
    final level = state.shopProgression.currentShopLevel;
    final collection2Bonuses = Collection2Catalog.bonusTotalsFor(
      state.collection2,
    );
    return ShopProgressionCatalog.byLevel(level).incomeMultiplier *
        _bonusMultiplier(collection2Bonuses.shopBonusPercent);
  }

  double shopMultiplierForLevel(int level) {
    return ShopProgressionCatalog.byLevel(level).incomeMultiplier;
  }

  double prestigeShopTapBonusPercent(GameState state) {
    return _prestigeUpgradePercent(state, PrestigeShopCatalog.masterHand);
  }

  double prestigeShopPassiveBonusPercent(GameState state) {
    return _prestigeUpgradePercent(state, PrestigeShopCatalog.loyalApprentices);
  }

  double prestigeShopGlobalBonusPercent(GameState state) {
    return _prestigeUpgradePercent(state, PrestigeShopCatalog.hotOven);
  }

  double prestigeShopStartingCash(GameState state) {
    final level = state.prestige.prestigeUpgradeLevel(
      PrestigeShopCatalog.fastStart,
    );
    return (level * 100 * max(1, state.prestige.prestigeCount)).toDouble();
  }

  double prestigeUpgradeEffectValue(GameState state, String upgradeId) {
    return _prestigeUpgradeEffectSeconds(state, upgradeId);
  }

  double _prestigeUpgradePercent(GameState state, String upgradeId) {
    return _prestigeUpgradeEffectSeconds(state, upgradeId);
  }

  double _prestigeUpgradeEffectSeconds(GameState state, String upgradeId) {
    final definition = PrestigeShopCatalog.byId(upgradeId);
    if (definition == null) {
      return 0;
    }
    return state.prestige.prestigeUpgradeLevel(upgradeId) *
        definition.effectPerLevel;
  }

  double _prestigeTapMultiplier(GameState state) {
    return 1 + max(0, prestigeShopTapBonusPercent(state));
  }

  double _prestigePassiveMultiplier(GameState state) {
    return 1 + max(0, prestigeShopPassiveBonusPercent(state));
  }

  double _prestigeGlobalMultiplier(GameState state) {
    return 1 + max(0, prestigeShopGlobalBonusPercent(state));
  }

  double _branchIncomePerSecond(
    GameState state, {
    required CollectionBonusTotals collectionBonuses,
    required double temporaryBoostMultiplier,
  }) {
    if (!BranchCatalog.isBranchIncomeActive(state)) {
      return 0;
    }
    final rawBranchIncome = BranchCatalog.rawBranchIncomePerSecond(state);
    if (rawBranchIncome <= 0) {
      return 0;
    }
    return rawBranchIncome *
        _prestigeMultiplier(state) *
        collectionBonuses.passiveMultiplier *
        _prestigePassiveMultiplier(state) *
        collectionBonuses.globalMultiplier *
        _prestigeGlobalMultiplier(state) *
        temporaryBoostMultiplier;
  }

  double _criticalChanceBeforeCap(GameState state) {
    return max(
      0.0,
      config.criticalBaseChance +
          state.milestones.criticalChance +
          _prestigeUpgradePercent(state, PrestigeShopCatalog.criticalMastery),
    );
  }

  double criticalMultiplier(GameState state) {
    if (!state.milestones.hasFeature('critical_cut')) {
      return 1;
    }
    return min(
      config.criticalMaxMultiplier,
      max(
        1.0,
        config.criticalBaseMultiplier +
            state.milestones.criticalMultiplierBonus,
      ),
    );
  }

  int goldenDonerReward(GameState state, {DateTime? nowUtc}) {
    final tapBased = tapValueForActivePlay(state, nowUtc: nowUtc) * 50;
    final passiveBased = (passiveIncomePerSecond(state, nowUtc: nowUtc) * 120)
        .round();
    final reward =
        max(100, max(tapBased, passiveBased)) *
        (1 +
            state.milestones.goldenDonerRewardPercent +
            Collection2Catalog.bonusTotalsFor(
              state.collection2,
            ).goldenDonerRewardBonusPercent);
    return max(100, reward.round());
  }

  PurchaseResult buyUpgrade(GameState state, UpgradeId id) {
    final definition = config.upgrade(id);
    final current = state.upgrade(id);
    final currentTotalLevel = _upgradeTotalLevel(definition, current);
    final cost = definition.costForLevel(currentTotalLevel);
    if (definition.isMaxLevel(currentTotalLevel)) {
      return PurchaseResult(
        success: false,
        state: state,
        cost: cost,
        reason: 'max_level',
      );
    }
    if (state.cash < cost) {
      return PurchaseResult(
        success: false,
        state: state,
        cost: cost,
        reason: 'insufficient_funds',
      );
    }
    final nextTotalLevel = currentTotalLevel + 1;
    var nextState = _applyUpgradeProgress(
      state,
      definition,
      id,
      nextTotalLevel: nextTotalLevel,
      claimMilestone: true,
    ).copyWith(cash: state.cash - cost);
    final milestoneGrant = _milestoneGrantFor(
      state,
      definition,
      id,
      nextTotalLevel,
    );
    if (milestoneGrant != null) {
      nextState = _applyInstantMilestoneMoney(nextState, milestoneGrant);
    }
    return PurchaseResult(
      success: true,
      state: nextState,
      cost: cost,
      milestoneGrant: milestoneGrant,
    );
  }

  bool canStartRush(GameState state, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    return !state.rush.isActiveAt(now) && !state.rush.isCoolingDownAt(now);
  }

  GameState startRush(GameState state, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    if (!canStartRush(state, nowUtc: now)) {
      return state;
    }
    return state.copyWith(
      rush: TimedEffectState(
        endsAtUtc: now.add(_rushDuration(state)),
        cooldownEndsAtUtc: now.add(_rushCooldown(state)),
      ),
    );
  }

  GameState applyOfflineReward(
    GameState state,
    int coins, {
    required DateTime nowUtc,
  }) {
    if (coins <= 0) {
      return state.copyWith(lastActiveAtUtc: nowUtc, lastSavedAtUtc: nowUtc);
    }
    return _addCoins(state, coins).copyWith(
      pendingOfflineCash: 0,
      lastActiveAtUtc: nowUtc,
      lastSavedAtUtc: nowUtc,
    );
  }

  GameState addCoins(GameState state, int coins) {
    if (coins <= 0) {
      return state;
    }
    return _addCoins(state, coins);
  }

  GameState queueOfflineReward(
    GameState state,
    int coins, {
    required DateTime nowUtc,
  }) {
    return state.copyWith(
      pendingOfflineCash: state.pendingOfflineCash + max(0, coins),
      lastActiveAtUtc: nowUtc,
      lastSavedAtUtc: nowUtc,
    );
  }

  GameState clearPendingOfflineReward(
    GameState state, {
    required DateTime nowUtc,
  }) {
    return state.copyWith(pendingOfflineCash: 0, lastSavedAtUtc: nowUtc);
  }

  GameState checkpoint(GameState state, DateTime nowUtc) {
    return state.copyWith(lastActiveAtUtc: nowUtc, lastSavedAtUtc: nowUtc);
  }

  GameState applyPrestige(GameState state, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final earned = availablePrestigePoints(state);
    if (earned <= 0) {
      return state;
    }
    final nextPrestige = state.prestige.copyWith(
      totalPrestigePoints: state.prestige.totalPrestigePoints + earned,
      unspentPrestigePoints: state.prestige.unspentPrestigePoints + earned,
      prestigeCount: state.prestige.prestigeCount + 1,
      runCashEarned: 0,
    );
    final fastStartLevel = nextPrestige.prestigeUpgradeLevel(
      PrestigeShopCatalog.fastStart,
    );
    final startingCash = fastStartLevel <= 0
        ? 0
        : (100 * fastStartLevel * nextPrestige.prestigeCount);
    final earlyTurboLevel = nextPrestige.prestigeUpgradeLevel(
      PrestigeShopCatalog.earlyTurbo,
    );
    final earlyTurboDuration = earlyTurboLevel <= 0
        ? Duration.zero
        : Duration(
            milliseconds:
                (config.rushDuration.inMilliseconds *
                        min(1.0, earlyTurboLevel * 0.10))
                    .round(),
          );
    final chestLevel = nextPrestige.prestigeUpgradeLevel(
      PrestigeShopCatalog.masterChest,
    );
    final chestType = PrestigeShopCatalog.prestigeChestForLevel(chestLevel);
    final initial = GameState.initial(
      config,
      nowUtc: now,
      localeCode: state.localeCode,
    );
    return initial.copyWith(
      cash: startingCash,
      lifetimeCash: state.lifetimeCash,
      pendingOfflineCash: 0,
      prestige: nextPrestige,
      rush: earlyTurboDuration > Duration.zero
          ? TimedEffectState(endsAtUtc: now.add(earlyTurboDuration))
          : initial.rush,
      stats: state.stats.copyWith(currentCombo: 0, clearLastTapAtUtc: true),
      quests: StarterQuestCatalog.initialProgress(),
      achievements: state.achievements,
      collection: state.collection,
      collection2: state.collection2,
      chestInventory: chestType == null
          ? state.chestInventory
          : state.chestInventory.add(chestType),
      shopProgression: state.shopProgression.resetCurrentRun(),
      customerReputation: state.customerReputation,
      customerOrders: state.customerOrders.resetForPrestige(now),
      goals: state.goals.copyWith(
        activePrestigeRunGoals: const [],
        runGoalPrestigeCount: 0,
      ),
      branches: state.branches,
      lastActiveAtUtc: now,
      lastSavedAtUtc: now,
    );
  }

  PurchaseResult buyPrestigeUpgrade(GameState state, String upgradeId) {
    final definition = PrestigeShopCatalog.byId(upgradeId);
    if (definition == null) {
      return PurchaseResult(
        success: false,
        state: state,
        reason: 'unknown_prestige_upgrade',
      );
    }
    final currentLevel = state.prestige.prestigeUpgradeLevel(upgradeId);
    if (currentLevel >= definition.maxLevel) {
      return PurchaseResult(success: false, state: state, reason: 'max_level');
    }
    final cost = definition.costForLevel(currentLevel);
    if (state.prestige.unspentPrestigePoints < cost) {
      return PurchaseResult(
        success: false,
        state: state,
        cost: cost,
        reason: 'insufficient_prestige_points',
      );
    }
    final upgrades = Map<String, int>.from(
      state.prestige.purchasedPrestigeUpgrades,
    )..[upgradeId] = currentLevel + 1;
    return PurchaseResult(
      success: true,
      state: state.copyWith(
        prestige: state.prestige.copyWith(
          unspentPrestigePoints: state.prestige.unspentPrestigePoints - cost,
          purchasedPrestigeUpgrades: Map<String, int>.unmodifiable(upgrades),
        ),
      ),
      cost: cost,
    );
  }

  int rushTapBonus(GameState state, {DateTime? nowUtc}) {
    return _activeTurboMultiplier(state, nowUtc: nowUtc).round();
  }

  double prestigeMultiplier(GameState state) {
    return prestigeMultiplierForPoints(state.prestige.totalPrestigePoints);
  }

  double prestigeMultiplierForPoints(int prestigePoints) {
    return 1 + (max(0, prestigePoints) * config.prestigeBonusPerPoint);
  }

  double _knifeEffect(GameState state) {
    return upgradeEffect(state, UpgradeId.knife);
  }

  double _ovenEffect(GameState state) {
    return upgradeEffect(state, UpgradeId.oven);
  }

  double _menuEffect(GameState state) {
    return upgradeEffect(state, UpgradeId.menu);
  }

  double _staffEffect(GameState state) {
    return upgradeEffect(state, UpgradeId.staff);
  }

  double _activeTurboMultiplier(GameState state, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    if (!state.rush.isActiveAt(now)) {
      return 1;
    }
    return upgradeEffect(state, UpgradeId.turbo);
  }

  Duration _rushDuration(GameState state) {
    return config.rushDuration +
        Duration(
          milliseconds: max(
            0,
            (state.milestones.turboDurationSeconds * 1000).round(),
          ),
        );
  }

  Duration _rushCooldown(GameState state) {
    final reduction = min(
      0.8,
      max(
        0,
        state.milestones.turboCooldownReductionPercent +
            state.milestones.turboChargeSpeedPercent,
      ),
    );
    final milliseconds = (config.rushCooldown.inMilliseconds * (1 - reduction))
        .round();
    return Duration(milliseconds: max(1000, milliseconds));
  }

  double _criticalExpectedMultiplier(GameState state) {
    final chance = criticalChance(state);
    if (chance <= 0) {
      return 1;
    }
    final multiplier = criticalMultiplier(state);
    return 1 + (chance * (multiplier - 1));
  }

  double _tapIncome(
    GameState state, {
    DateTime? nowUtc,
    double comboMultiplier = 1,
    double criticalMultiplier = 1,
  }) {
    final activeMultiplier = min(
      config.comboCriticalMultiplierCap,
      max(1.0, comboMultiplier) * max(1.0, criticalMultiplier),
    );
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final collectionBonuses = _permanentBonuses(state);
    return calculateTapIncome(
      baseTap: config.baseTapValue.toDouble(),
      knifeEffect: _knifeEffect(state),
      ovenEffect: _ovenEffect(state),
      menuEffect: _menuEffect(state),
      shopMultiplier: shopMultiplier(state),
      prestigeMultiplier: _prestigeMultiplier(state),
      collectionTapMultiplier:
          collectionBonuses.tapMultiplier * _prestigeTapMultiplier(state),
      collectionGlobalMultiplier:
          collectionBonuses.globalMultiplier * _prestigeGlobalMultiplier(state),
      temporaryBoostMultiplier: state.passiveBoost.isActiveAt(now) ? 2 : 1,
      turboMultiplier: _activeTurboMultiplier(state, nowUtc: nowUtc),
      comboMultiplier: activeMultiplier,
    );
  }

  List<UpgradeTrack> _activeUpgradeTracks(GameState state) {
    return config.upgrades
        .map((definition) {
          return definition.trackForLevel(
            _upgradeTotalLevel(definition, state.upgrade(definition.id)),
          );
        })
        .toList(growable: false);
  }

  double _prestigeMultiplier(GameState state) {
    return prestigeMultiplier(state);
  }

  CollectionBonusTotals _permanentBonuses(GameState state) {
    final collectionBonuses = CollectionCatalog.bonusTotalsFor(
      config: config,
      claimedBonusItemIds: state.collection.claimedBonusItemIds,
    );
    final collection2Bonuses = Collection2Catalog.bonusTotalsFor(
      state.collection2,
    );
    final achievementBonuses = _achievementBonuses(state);
    return CollectionBonusTotals(
      tapBonusPercent:
          collectionBonuses.tapBonusPercent +
          collection2Bonuses.tapBonusPercent +
          achievementBonuses.tapBonusPercent,
      passiveBonusPercent:
          collectionBonuses.passiveBonusPercent +
          collection2Bonuses.passiveBonusPercent +
          achievementBonuses.passiveBonusPercent,
      globalBonusPercent:
          collectionBonuses.globalBonusPercent +
          collection2Bonuses.globalBonusPercent +
          achievementBonuses.globalBonusPercent,
    );
  }

  CollectionBonusTotals _achievementBonuses(GameState state) {
    var tap = 0.0;
    var passive = 0.0;
    var global = 0.0;
    for (final progress in state.achievements.values) {
      if (!progress.isRewardClaimed) {
        continue;
      }
      final reward = AchievementCatalog.byId[progress.achievementId]?.reward;
      if (reward == null) {
        continue;
      }
      switch (reward.type) {
        case AchievementRewardType.permanentTapBonus:
          tap += reward.amount;
        case AchievementRewardType.permanentPassiveBonus:
          passive += reward.amount;
        case AchievementRewardType.permanentGlobalBonus:
          global += reward.amount;
        case AchievementRewardType.cash:
        case AchievementRewardType.chest:
        case AchievementRewardType.cosmeticToken:
          break;
      }
    }
    return CollectionBonusTotals(
      tapBonusPercent: tap,
      passiveBonusPercent: passive,
      globalBonusPercent: global,
    );
  }

  GameState _addCoins(GameState state, int coins) {
    return state.copyWith(
      cash: state.cash + coins,
      lifetimeCash: state.lifetimeCash + coins,
      prestige: state.prestige.copyWith(
        runCashEarned: state.prestige.runCashEarned + coins,
      ),
    );
  }

  int _upgradeTotalLevel(UpgradeDefinition definition, UpgradeState state) {
    return definition.totalLevelForPosition(
      itemIndex: state.itemIndex,
      itemLevel: state.level,
    );
  }

  GameState _applyUpgradeProgress(
    GameState state,
    UpgradeDefinition definition,
    UpgradeId id, {
    required int nextTotalLevel,
    required bool claimMilestone,
  }) {
    final updatedUpgrades = Map<UpgradeId, UpgradeState>.from(state.upgrades)
      ..[id] = UpgradeState.fromTotalLevel(
        definition: definition,
        totalLevel: nextTotalLevel,
      );
    var nextState = state.copyWith(upgrades: updatedUpgrades);
    if (!claimMilestone) {
      return nextState;
    }

    final grant = _milestoneGrantFor(state, definition, id, nextTotalLevel);
    if (grant == null) {
      return nextState;
    }
    return nextState.copyWith(
      milestones: nextState.milestones.claimReward(
        key: grant.key,
        reward: grant.reward,
      ),
    );
  }

  MilestoneGrant? _milestoneGrantFor(
    GameState state,
    UpgradeDefinition definition,
    UpgradeId id,
    int nextTotalLevel,
  ) {
    final item = definition.itemForLevel(nextTotalLevel);
    final itemLevel = definition.itemLevelForTotalLevel(nextTotalLevel);
    MilestoneReward? reward;
    for (final candidate in item.milestoneRewards) {
      if (candidate.level == itemLevel) {
        reward = candidate;
        break;
      }
    }
    if (reward == null) {
      return null;
    }

    final key = milestoneKeyFor(
      trackId: id,
      itemKey: item.key,
      level: itemLevel,
    );
    if (state.milestones.hasClaimed(key)) {
      return null;
    }
    return MilestoneGrant(
      key: key,
      trackId: id,
      itemKey: item.key,
      level: itemLevel,
      reward: reward,
    );
  }

  GameState _applyInstantMilestoneMoney(GameState state, MilestoneGrant grant) {
    if (grant.reward.type != MilestoneRewardType.instantMoney ||
        grant.reward.value <= 0) {
      return state;
    }
    return _addCoins(state, grant.reward.value.round());
  }

  double _bonusMultiplier(double percent) {
    return 1 + max(0, percent);
  }
}
