import 'dart:math';

import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/stations/station_catalog.dart';
import 'package:taptapdoner/domain/stations/upgrade_catalog.dart';

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

  int stationCost(StationDefinition definition, StationState state) {
    final price = definition.baseCost * pow(definition.costGrowth, state.level);
    return price.floor();
  }

  bool isStationUnlocked(GameState state, StationDefinition definition) {
    return state.lifetimeCash >= definition.unlockAtLifetimeCash ||
        state.station(definition.id).level > 0;
  }

  int tapValue(GameState state, {DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final tapBonus = _flatTapBonus(state);
    final tapMultiplier = _tapMultiplier(state);
    final globalMultiplier = _globalIncomeMultiplier(state);
    final rushMultiplier = state.rush.isActiveAt(now)
        ? config.rushIncomeMultiplier
        : 1.0;
    final total =
        (config.baseTapValue + tapBonus) *
        tapMultiplier *
        globalMultiplier *
        rushMultiplier;
    return max(1, total.round());
  }

  double passiveIncomePerSecond(
    GameState state, {
    DateTime? nowUtc,
    bool includeRush = true,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final passiveMultiplier = _passiveIncomeMultiplier(state);
    final globalMultiplier = _globalIncomeMultiplier(state);
    final rushMultiplier = includeRush && state.rush.isActiveAt(now)
        ? config.rushIncomeMultiplier
        : 1;

    var total = 0.0;
    for (final definition in config.stations) {
      final level = state.station(definition.id).level;
      if (level <= 0) {
        continue;
      }
      total +=
          level *
          definition.baseIncomePerSecond *
          passiveMultiplier *
          globalMultiplier *
          rushMultiplier;
    }
    return total;
  }

  double stationIncomePerSecond(
    GameState state,
    StationId id, {
    DateTime? nowUtc,
    bool includeRush = true,
  }) {
    final definition = config.station(id);
    final level = state.station(id).level;
    if (level <= 0) {
      return 0;
    }
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final passiveMultiplier = _passiveIncomeMultiplier(state);
    final globalMultiplier = _globalIncomeMultiplier(state);
    final rushMultiplier = includeRush && state.rush.isActiveAt(now)
        ? config.rushIncomeMultiplier
        : 1;
    return level *
        definition.baseIncomePerSecond *
        passiveMultiplier *
        globalMultiplier *
        rushMultiplier;
  }

  int availablePrestigePoints(GameState state) {
    return state.prestige.runCashEarned ~/ config.prestigeThreshold;
  }

  GameState applyTap(GameState state, {DateTime? nowUtc}) {
    return _addCoins(state, tapValue(state, nowUtc: nowUtc));
  }

  PurchaseResult buyStationLevel(GameState state, StationId id) {
    final definition = config.station(id);
    if (!isStationUnlocked(state, definition)) {
      return PurchaseResult(success: false, state: state, reason: 'locked');
    }
    final station = state.station(id);
    final cost = stationCost(definition, station);
    if (state.cash < cost) {
      return PurchaseResult(
        success: false,
        state: state,
        cost: cost,
        reason: 'insufficient_funds',
      );
    }
    final updatedStations = Map<StationId, StationState>.from(state.stations)
      ..[id] = station.copyWith(level: station.level + 1);
    return PurchaseResult(
      success: true,
      state: state.copyWith(cash: state.cash - cost, stations: updatedStations),
      cost: cost,
    );
  }

  PurchaseResult buyUpgrade(GameState state, UpgradeId id) {
    final definition = config.upgrade(id);
    final current = state.upgrade(id);
    if (current.purchased) {
      return PurchaseResult(
        success: false,
        state: state,
        cost: definition.cost,
        reason: 'already_purchased',
      );
    }
    if (state.cash < definition.cost) {
      return PurchaseResult(
        success: false,
        state: state,
        cost: definition.cost,
        reason: 'insufficient_funds',
      );
    }
    final updatedUpgrades = Map<UpgradeId, UpgradeState>.from(state.upgrades)
      ..[id] = current.copyWith(purchased: true);
    return PurchaseResult(
      success: true,
      state: state.copyWith(
        cash: state.cash - definition.cost,
        upgrades: updatedUpgrades,
      ),
      cost: definition.cost,
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
    final upgrade = config.upgrade(UpgradeId.rushTraining);
    final hasRushTraining = state.upgrade(UpgradeId.rushTraining).purchased;
    final duration = hasRushTraining
        ? config.rushDuration + upgrade.rushDurationBonus
        : config.rushDuration;
    final cooldownReduction = hasRushTraining
        ? upgrade.rushCooldownReduction
        : Duration.zero;
    final cooldown = config.rushCooldown - cooldownReduction;
    return state.copyWith(
      rush: TimedEffectState(
        endsAtUtc: now.add(duration),
        cooldownEndsAtUtc: now.add(cooldown),
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
    final now = (nowUtc ?? DateTime.now()).toUtc();
    return state.rush.isActiveAt(now) ? config.rushIncomeMultiplier.round() : 1;
  }

  double _tapMultiplier(GameState state) {
    var multiplier = 1.0;
    if (state.upgrade(UpgradeId.sharpKnife).purchased) {
      multiplier *= config.upgrade(UpgradeId.sharpKnife).tapMultiplier;
    }
    return multiplier;
  }

  int _flatTapBonus(GameState state) {
    if (!state.upgrade(UpgradeId.tapGloves).purchased) {
      return 0;
    }
    return config.upgrade(UpgradeId.tapGloves).flatTapBonus;
  }

  double _passiveIncomeMultiplier(GameState state) {
    var multiplier = 1.0;
    if (state.upgrade(UpgradeId.greaseMaintenance).purchased) {
      multiplier *= config
          .upgrade(UpgradeId.greaseMaintenance)
          .passiveMultiplier;
    }
    return multiplier;
  }

  double _globalIncomeMultiplier(GameState state) {
    var multiplier = 1.0;
    if (state.upgrade(UpgradeId.brandBoard).purchased) {
      multiplier *= config.upgrade(UpgradeId.brandBoard).globalIncomeMultiplier;
    }
    multiplier *=
        1 + (state.prestige.reputation * config.prestigeBonusPerPoint);
    return multiplier;
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
}
