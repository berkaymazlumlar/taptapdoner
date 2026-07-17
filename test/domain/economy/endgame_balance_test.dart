import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/economy_engine.dart';
import 'package:taptapdoner/domain/economy/game_number.dart';
import 'package:taptapdoner/domain/progression/prestige_shop_catalog.dart';
import 'package:taptapdoner/domain/progression/shop_progression_catalog.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

void main() {
  test('low-click continuous play reaches endgame in 35-50 active hours', () {
    final simulation = _EndgameSimulation();

    simulation.play(const Duration(days: 3650));

    expect(simulation.isComplete, isTrue);
    expect(
      simulation.activePlay,
      allOf(
        greaterThanOrEqualTo(const Duration(hours: 35)),
        lessThanOrEqualTo(const Duration(hours: 50)),
      ),
    );

    final shop10At = simulation.checkpoints
        .firstWhere((checkpoint) => checkpoint.shopLevel >= 10)
        .activePlay;
    final lateGameShare =
        (simulation.activePlay - shop10At).inSeconds /
        simulation.activePlay.inSeconds;
    expect(lateGameShare, greaterThanOrEqualTo(0.25));
  });

  test('ten-minute daily sessions reach endgame in 30-45 days', () {
    final simulation = _EndgameSimulation();
    var day = 1;

    while (!simulation.isComplete && day <= 3650) {
      if (day > 1) {
        final offlineIncome = simulation.engine.offlineIncome(
          simulation.state,
          const Duration(hours: 23, minutes: 50),
        );
        simulation.state = simulation.engine.addCoins(
          simulation.state,
          offlineIncome,
        );
      }
      simulation.play(const Duration(minutes: 10));
      if (!simulation.isComplete) {
        day += 1;
      }
    }

    expect(simulation.isComplete, isTrue);
    expect(day, inInclusiveRange(30, 45));
  });
}

const _runTargets = <double>[
  1e6,
  1e9,
  1e10,
  1e11,
  1e12,
  1e13,
  1e6,
  1e14,
  1e6,
  1e6,
  1e15,
];

class _EndgameCheckpoint {
  const _EndgameCheckpoint({required this.shopLevel, required this.activePlay});

  final int shopLevel;
  final Duration activePlay;
}

class _EndgameSimulation {
  _EndgameSimulation()
    : config = EconomyConfig.standard(),
      engine = EconomyEngine(EconomyConfig.standard()) {
    state = GameState.initial(config, nowUtc: DateTime.utc(2026));
  }

  final EconomyConfig config;
  final EconomyEngine engine;
  late GameState state;
  final List<_EndgameCheckpoint> checkpoints = <_EndgameCheckpoint>[];
  int _targetIndex = 0;
  Duration activePlay = Duration.zero;

  bool get isComplete => _targetIndex >= _runTargets.length;

  void play(Duration budget) {
    var usedSeconds = 0;
    while (!isComplete && usedSeconds < budget.inSeconds) {
      _buyAffordableUpgrades();
      _refreshShopLevel();

      final earned = _asDouble(state.prestige.runCashEarned);
      final target = _runTargets[_targetIndex];
      if (earned >= target) {
        checkpoints.add(
          _EndgameCheckpoint(
            shopLevel: state.shopProgression.currentShopLevel,
            activePlay: activePlay + Duration(seconds: usedSeconds),
          ),
        );
        _targetIndex += 1;
        if (isComplete) {
          break;
        }
        state = engine.applyPrestige(state, nowUtc: DateTime.utc(2026));
        state = _spendIncomePrestigePoints(state);
        continue;
      }

      final rate = _activeIncomePerSecond(state);
      final cheapest = _cheapestUpgradeCost();
      final cash = _asDouble(state.cash);
      final untilPurchase = cheapest == null
          ? double.infinity
          : math.max(0.0, cheapest - cash);
      final untilTarget = math.max(0.0, target - earned);
      var stepSeconds = math.max(
        1,
        (math.min(untilPurchase, untilTarget) / math.max(rate, 1e-9)).ceil(),
      );
      stepSeconds = math.min(stepSeconds, budget.inSeconds - usedSeconds);
      state = engine.addCoins(state, (rate * stepSeconds).floor());
      usedSeconds += stepSeconds;
    }
    activePlay += Duration(seconds: usedSeconds);
  }

  double _activeIncomePerSecond(GameState value) {
    return engine.passiveIncomePerSecond(value) +
        (engine.tapValue(value).toDouble() * 0.5);
  }

  double? _cheapestUpgradeCost() {
    double? result;
    for (final definition in config.upgrades) {
      final current = state.upgrade(definition.id);
      if (engine.isUpgradeMaxed(definition, current)) {
        continue;
      }
      final cost = (engine.upgradeCost(definition, current) as num).toDouble();
      if (result == null || cost < result) {
        result = cost;
      }
    }
    return result;
  }

  void _buyAffordableUpgrades() {
    while (true) {
      UpgradeDefinition? choice;
      double? cheapest;
      for (final definition in config.upgrades) {
        final current = state.upgrade(definition.id);
        if (engine.isUpgradeMaxed(definition, current)) {
          continue;
        }
        final cost = (engine.upgradeCost(definition, current) as num)
            .toDouble();
        if (state.cash >= cost && (cheapest == null || cost < cheapest)) {
          choice = definition;
          cheapest = cost;
        }
      }
      if (choice == null) {
        return;
      }
      final result = engine.buyUpgrade(state, choice.id);
      if (!result.success) {
        return;
      }
      state = result.state;
    }
  }

  void _refreshShopLevel() {
    final eligible = ShopProgressionCatalog.eligibleLevel(state, config);
    if (eligible <= state.shopProgression.currentShopLevel) {
      return;
    }
    state = state.copyWith(
      shopProgression: state.shopProgression.unlockThroughLevel(eligible),
      stats: state.stats.copyWith(shopLevel: eligible),
    );
  }

  GameState _spendIncomePrestigePoints(GameState value) {
    var next = value;
    const upgradeIds = <String>[
      PrestigeShopCatalog.loyalApprentices,
      PrestigeShopCatalog.hotOven,
      PrestigeShopCatalog.masterHand,
    ];
    while (true) {
      String? bestId;
      var bestScore = 0.0;
      final baseRate = _activeIncomePerSecond(next);
      for (final id in upgradeIds) {
        final preview = engine.buyPrestigeUpgrade(next, id);
        if (!preview.success) {
          continue;
        }
        final gain = _activeIncomePerSecond(preview.state) - baseRate;
        final score = gain / math.max(1, (preview.cost as num).toDouble());
        if (score > bestScore) {
          bestScore = score;
          bestId = id;
        }
      }
      if (bestId == null) {
        return next;
      }
      next = engine.buyPrestigeUpgrade(next, bestId).state;
    }
  }
}

double _asDouble(Object value) {
  return value is GameNumber ? value.toDouble() : (value as num).toDouble();
}
