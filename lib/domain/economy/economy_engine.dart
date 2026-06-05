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
  });

  final bool success;
  final GameState state;
  final int cost;
  final String? reason;
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
    return getTrackEffectById(_activeUpgradeTracks(state), id.key);
  }

  double nextUpgradeEffect(GameState state, UpgradeId id) {
    final definition = config.upgrade(id);
    final totalLevel = upgradeTotalLevel(state, id);
    if (definition.isMaxLevel(totalLevel)) {
      return definition.effectForLevel(totalLevel);
    }
    return definition.effectForLevel(totalLevel + 1);
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
    final total = calculateTapIncome(
      baseTap: config.baseTapValue.toDouble(),
      knifeEffect: _knifeEffect(state),
      ovenEffect: _ovenEffect(state),
      menuEffect: _menuEffect(state),
      prestigeMultiplier: _prestigeMultiplier(state),
      turboMultiplier: _activeTurboMultiplier(state, nowUtc: nowUtc),
    );
    return max(1, total.round());
  }

  double passiveIncomePerSecond(
    GameState state, {
    DateTime? nowUtc,
    bool includeRush = true,
  }) {
    return calculatePassiveIncomePerSecond(
      staffEffect: _staffEffect(state),
      ovenEffect: _ovenEffect(state),
      menuEffect: _menuEffect(state),
      prestigeMultiplier: _prestigeMultiplier(state),
    );
  }

  double offlineEfficiency(GameState state) {
    return upgradeEffect(state, UpgradeId.offline);
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
    final updatedUpgrades = Map<UpgradeId, UpgradeState>.from(state.upgrades)
      ..[id] = UpgradeState.fromTotalLevel(
        definition: definition,
        totalLevel: nextTotalLevel,
      );
    return PurchaseResult(
      success: true,
      state: state.copyWith(cash: state.cash - cost, upgrades: updatedUpgrades),
      cost: cost,
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
        endsAtUtc: now.add(config.rushDuration),
        cooldownEndsAtUtc: now.add(config.rushCooldown),
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
}
