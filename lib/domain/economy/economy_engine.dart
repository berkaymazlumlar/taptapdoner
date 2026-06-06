import 'dart:math';

import 'package:taptapdoner/domain/economy/economy_calculator.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
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

  int upgradeCost(UpgradeDefinition definition, UpgradeState state) {
    return definition.costForLevel(_upgradeTotalLevel(definition, state));
  }

  bool isUpgradeMaxed(UpgradeDefinition definition, UpgradeState state) {
    return definition.isMaxLevel(_upgradeTotalLevel(definition, state));
  }

  double upgradeEffect(GameState state, UpgradeId id) {
    final baseEffect = getTrackEffectById(_activeUpgradeTracks(state), id.key);
    final milestones = state.milestones;
    return switch (id) {
      UpgradeId.knife =>
        baseEffect * _bonusMultiplier(milestones.tapBonusPercent),
      UpgradeId.staff =>
        baseEffect * _bonusMultiplier(milestones.passiveBonusPercent),
      UpgradeId.oven =>
        baseEffect * _bonusMultiplier(milestones.globalBonusPercent),
      UpgradeId.menu =>
        baseEffect * _bonusMultiplier(milestones.menuBonusPercent),
      UpgradeId.turbo =>
        baseEffect * _bonusMultiplier(milestones.turboBonusPercent),
      UpgradeId.offline => baseEffect + milestones.offlineEfficiencyBonus,
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
    final total =
        calculateTapIncome(
          baseTap: config.baseTapValue.toDouble(),
          knifeEffect: _knifeEffect(state),
          ovenEffect: _ovenEffect(state),
          menuEffect: _menuEffect(state),
          prestigeMultiplier: _prestigeMultiplier(state),
          turboMultiplier: _activeTurboMultiplier(state, nowUtc: nowUtc),
        ) *
        _criticalExpectedMultiplier(state);
    return max(1, total.round());
  }

  double passiveIncomePerSecond(
    GameState state, {
    DateTime? nowUtc,
    bool includeRush = true,
  }) {
    final baseIncome = calculatePassiveIncomePerSecond(
      staffEffect: _staffEffect(state),
      ovenEffect: _ovenEffect(state),
      menuEffect: _menuEffect(state),
      prestigeMultiplier: _prestigeMultiplier(state),
    );
    final now = (nowUtc ?? DateTime.now()).toUtc();
    return includeRush && state.passiveBoost.isActiveAt(now)
        ? baseIncome * 2
        : baseIncome;
  }

  double offlineEfficiency(GameState state) {
    return upgradeEffect(state, UpgradeId.offline);
  }

  Duration offlineCap(GameState state) {
    return config.offlineCap +
        Duration(
          seconds: max(0, state.milestones.offlineMaxDurationSeconds.round()),
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
    return GameState.initial(
      config,
      nowUtc: now,
      localeCode: state.localeCode,
    ).copyWith(
      lifetimeCash: state.lifetimeCash,
      pendingOfflineCash: 0,
      prestige: PrestigeState(
        reputation: state.prestige.reputation + earned,
        runCashEarned: 0,
      ),
      stats: state.stats.copyWith(currentCombo: 0),
      quests: state.quests,
      lastActiveAtUtc: now,
      lastSavedAtUtc: now,
    );
  }

  int rushTapBonus(GameState state, {DateTime? nowUtc}) {
    return _activeTurboMultiplier(state, nowUtc: nowUtc).round();
  }

  double prestigeMultiplier(GameState state) {
    return prestigeMultiplierForPoints(state.prestige.reputation);
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
    final chance = min(1.0, max(0.0, state.milestones.criticalChance));
    if (chance <= 0) {
      return 1;
    }
    final multiplier = max(1.0, 3 + state.milestones.criticalMultiplierBonus);
    return 1 + (chance * (multiplier - 1));
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
