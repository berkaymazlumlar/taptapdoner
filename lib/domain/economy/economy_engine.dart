import 'dart:math';

import 'package:taptapdoner/domain/branches/branch_catalog.dart';
import 'package:taptapdoner/domain/economy/currency_math.dart';
import 'package:taptapdoner/domain/economy/economy_calculator.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/game_number.dart';
import 'package:taptapdoner/domain/progression/achievement_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_catalog.dart';
import 'package:taptapdoner/domain/progression/collection_catalog.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/progression/prestige_shop_catalog.dart';
import 'package:taptapdoner/domain/progression/shop_progression_catalog.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/random_events/random_event_models.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

class PurchaseResult {
  const PurchaseResult({
    required this.success,
    required this.state,
    this.cost = 0,
    this.purchasedCount = 0,
    this.reason,
    this.milestoneGrant,
    this.milestoneGrants = const <MilestoneGrant>[],
  });

  final bool success;
  final GameState state;
  final dynamic cost;
  final int purchasedCount;
  final String? reason;
  final MilestoneGrant? milestoneGrant;
  final List<MilestoneGrant> milestoneGrants;
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
  });

  const ProductionGrant.none()
    : coins = 0,
      rawElapsed = Duration.zero,
      effectiveElapsed = Duration.zero;

  final dynamic coins;
  final Duration rawElapsed;
  final Duration effectiveElapsed;

  bool get hasReward => coins > 0;
}

class EconomyEngine {
  const EconomyEngine(this.config, {this.freePurchasesEnabled = false});

  final EconomyConfig config;
  final bool freePurchasesEnabled;

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

  dynamic upgradeCost(UpgradeDefinition definition, UpgradeState state) {
    return _effectivePurchaseCost(
      definition.costForLevel(_upgradeTotalLevel(definition, state)),
    );
  }

  dynamic upgradeCostForQuantity(
    UpgradeDefinition definition,
    UpgradeState state,
    int quantity,
  ) {
    if (quantity <= 0) {
      return 0;
    }
    final currentTotalLevel = _upgradeTotalLevel(definition, state);
    final remainingLevels = max(0, definition.maxLevel - currentTotalLevel);
    final purchaseCount = min(quantity, remainingLevels);
    dynamic totalCost = 0;
    for (var offset = 0; offset < purchaseCount; offset += 1) {
      totalCost = CurrencyMath.add(
        totalCost,
        _effectivePurchaseCost(
          definition.costForLevel(currentTotalLevel + offset),
        ),
      );
    }
    return totalCost;
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

  num tapValue(GameState state, {DateTime? nowUtc}) {
    final total = _tapIncome(
      state,
      nowUtc: nowUtc,
      comboMultiplier: comboMultiplierForCount(state.stats.currentCombo, state),
      criticalMultiplier: _criticalExpectedMultiplier(state),
    );
    return max(1, CurrencyMath.roundDouble(total));
  }

  num tapValueForActivePlay(
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
    return max(1, CurrencyMath.roundDouble(total));
  }

  double passiveIncomePerSecond(
    GameState state, {
    DateTime? nowUtc,
    bool includeTemporaryBoost = true,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final collectionBonuses = _permanentBonuses(state);
    final temporaryBoostMultiplier =
        (includeTemporaryBoost && state.passiveBoost.isActiveAt(now)
            ? 2.0
            : 1.0) *
        randomEventModifierProduct(
          state.randomEvents,
          RandomEventModifierType.passiveIncome,
          nowUtc: now,
        ) *
        randomEventModifierProduct(
          state.randomEvents,
          RandomEventModifierType.globalIncome,
          nowUtc: now,
        );
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
    return CurrencyMath.clampDouble(
      baseIncome +
          _branchIncomePerSecond(
            state,
            collectionBonuses: collectionBonuses,
            temporaryBoostMultiplier: temporaryBoostMultiplier,
          ),
    );
  }

  double branchIncomePerSecond(
    GameState state, {
    DateTime? nowUtc,
    bool includeTemporaryBoost = true,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final collectionBonuses = _permanentBonuses(state);
    return CurrencyMath.clampDouble(
      _branchIncomePerSecond(
        state,
        collectionBonuses: collectionBonuses,
        temporaryBoostMultiplier:
            (includeTemporaryBoost && state.passiveBoost.isActiveAt(now)
                ? 2
                : 1) *
            randomEventModifierProduct(
              state.randomEvents,
              RandomEventModifierType.passiveIncome,
              nowUtc: now,
            ) *
            randomEventModifierProduct(
              state.randomEvents,
              RandomEventModifierType.globalIncome,
              nowUtc: now,
            ),
      ),
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

  num offlineIncome(GameState state, Duration elapsed) {
    if (elapsed <= Duration.zero) {
      return 0;
    }
    final seconds = elapsed.inMilliseconds / 1000;
    final value = calculateOfflineIncome(
      passiveIncomePerSecond: passiveIncomePerSecond(
        state,
        includeTemporaryBoost: false,
      ),
      offlineSeconds: seconds,
      offlineEfficiency: offlineEfficiency(state),
    );
    return CurrencyMath.floorDouble(value);
  }

  int availablePrestigePoints(GameState state) {
    if (config.prestigeThreshold <= 0) {
      return 0;
    }
    final earned = state.prestige.runCashEarned;
    if (earned is GameNumber) {
      final threshold = GameNumber.fromNum(config.prestigeThreshold);
      final ratio = earned / threshold;
      if (ratio.exponent >= 38) {
        return CurrencyMath.legacyInt64MaxCurrency;
      }
      return sqrt(ratio.toDouble()).floor();
    }
    return sqrt(earned / config.prestigeThreshold).floor();
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
    return CurrencyMath.clampDouble(
      rawBranchIncome *
          _prestigeMultiplier(state) *
          collectionBonuses.passiveMultiplier *
          _prestigePassiveMultiplier(state) *
          collectionBonuses.globalMultiplier *
          _prestigeGlobalMultiplier(state) *
          temporaryBoostMultiplier,
    );
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

  PurchaseResult previewUpgradePurchase(
    GameState state,
    UpgradeId id, {
    int quantity = 1,
  }) {
    return _buyUpgrade(state, id, quantity: quantity);
  }

  PurchaseResult previewMaxUpgradePurchase(GameState state, UpgradeId id) {
    final definition = config.upgrade(id);
    final current = state.upgrade(id);
    final currentTotalLevel = _upgradeTotalLevel(definition, current);
    return _buyUpgrade(
      state,
      id,
      quantity: max(0, definition.maxLevel - currentTotalLevel),
    );
  }

  PurchaseResult buyUpgrade(GameState state, UpgradeId id, {int quantity = 1}) {
    return _buyUpgrade(state, id, quantity: quantity);
  }

  PurchaseResult _buyUpgrade(
    GameState state,
    UpgradeId id, {
    required int quantity,
  }) {
    final definition = config.upgrade(id);
    final requestedQuantity = max(0, quantity);
    if (requestedQuantity <= 0) {
      return PurchaseResult(
        success: false,
        state: state,
        reason: 'invalid_quantity',
      );
    }

    var nextState = state;
    dynamic totalCost = 0;
    var purchasedCount = 0;
    final milestoneGrants = <MilestoneGrant>[];
    String? failureReason;
    num failureCost = 0;

    for (var index = 0; index < requestedQuantity; index += 1) {
      final current = nextState.upgrade(id);
      final currentTotalLevel = _upgradeTotalLevel(definition, current);
      final rawCost = definition.costForLevel(currentTotalLevel);
      final cost = _effectivePurchaseCostForState(nextState, rawCost);
      if (definition.isMaxLevel(currentTotalLevel)) {
        failureReason = 'max_level';
        failureCost = cost;
        break;
      }
      if (nextState.cash < cost) {
        failureReason = 'insufficient_funds';
        failureCost = cost;
        break;
      }

      final nextTotalLevel = currentTotalLevel + 1;
      final milestoneGrant = _milestoneGrantFor(
        nextState,
        definition,
        id,
        nextTotalLevel,
      );
      nextState = _applyUpgradeProgress(
        nextState,
        definition,
        id,
        nextTotalLevel: nextTotalLevel,
        claimMilestone: true,
      ).copyWith(cash: CurrencyMath.subtract(nextState.cash, cost));
      if (milestoneGrant != null) {
        nextState = _applyInstantMilestoneMoney(nextState, milestoneGrant);
        milestoneGrants.add(milestoneGrant);
      }
      totalCost = CurrencyMath.add(totalCost, cost);
      purchasedCount += 1;
    }

    if (purchasedCount <= 0) {
      return PurchaseResult(
        success: false,
        state: state,
        cost: failureCost,
        reason: failureReason ?? 'not_purchased',
      );
    }

    return PurchaseResult(
      success: true,
      state: nextState,
      cost: totalCost,
      purchasedCount: purchasedCount,
      reason: failureReason,
      milestoneGrant: milestoneGrants.isEmpty ? null : milestoneGrants.last,
      milestoneGrants: List<MilestoneGrant>.unmodifiable(milestoneGrants),
    );
  }

  GameState applyOfflineReward(
    GameState state,
    dynamic coins, {
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

  GameState addCoins(GameState state, dynamic coins) {
    if (coins <= 0) {
      return state;
    }
    return _addCoins(state, coins);
  }

  GameState queueOfflineReward(
    GameState state,
    dynamic coins, {
    required DateTime nowUtc,
  }) {
    return state.copyWith(
      pendingOfflineCash: CurrencyMath.add(state.pendingOfflineCash, coins),
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
    final rawCost = definition.costForLevel(currentLevel);
    final cost = _effectivePurchaseCost(rawCost);
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
      purchasedCount: 1,
    );
  }

  int _effectivePurchaseCost(int rawCost) {
    return freePurchasesEnabled ? 0 : rawCost;
  }

  num _effectivePurchaseCostForState(GameState state, int rawCost) {
    if (freePurchasesEnabled) {
      return 0;
    }
    final multiplier = randomEventModifierProduct(
      state.randomEvents,
      RandomEventModifierType.upgradeCost,
      nowUtc: DateTime.now().toUtc(),
    );
    return max(0, CurrencyMath.roundDouble(rawCost * multiplier));
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
    return upgradeEffect(state, UpgradeId.menu) *
        randomEventModifierProduct(
          state.randomEvents,
          RandomEventModifierType.menuMultiplier,
          nowUtc: DateTime.now().toUtc(),
        );
  }

  double _staffEffect(GameState state) {
    return upgradeEffect(state, UpgradeId.staff);
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
      temporaryBoostMultiplier:
          (state.passiveBoost.isActiveAt(now) ? 2 : 1) *
          randomEventModifierProduct(
            state.randomEvents,
            RandomEventModifierType.tapIncome,
            nowUtc: now,
          ) *
          randomEventModifierProduct(
            state.randomEvents,
            RandomEventModifierType.globalIncome,
            nowUtc: now,
          ),
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

  GameState _addCoins(GameState state, dynamic coins) {
    return state.copyWith(
      cash: CurrencyMath.add(state.cash, coins),
      lifetimeCash: CurrencyMath.add(state.lifetimeCash, coins),
      prestige: state.prestige.copyWith(
        runCashEarned: CurrencyMath.add(state.prestige.runCashEarned, coins),
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
    return _addCoins(state, CurrencyMath.roundDouble(grant.reward.value));
  }

  double _bonusMultiplier(double percent) {
    return 1 + max(0, percent);
  }
}
