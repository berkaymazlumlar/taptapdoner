import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/economy_engine.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

void main() {
  test('early and first-prestige economy stay inside target windows', () {
    final config = EconomyConfig.standard();
    final engine = EconomyEngine(config);
    final timeline = _simulateActivePlay(config, engine);

    expect(
      timeline.firstUpgradeReachable,
      _between(const Duration(seconds: 5), const Duration(seconds: 15)),
    );
    expect(
      timeline.firstStaffReachable,
      _between(
        const Duration(minutes: 3),
        const Duration(minutes: 5, seconds: 15),
      ),
    );
    expect(timeline.firstOvenReachable, lessThanOrEqualTo(25.minutes));
    expect(
      timeline.firstItemTransition,
      _between(const Duration(minutes: 60), const Duration(minutes: 90)),
    );
    expect(
      timeline.firstPrestige,
      _between(const Duration(hours: 4), const Duration(hours: 7)),
    );
    expect(
      timeline.longestUpgradeGapBeforeOneHour,
      lessThanOrEqualTo(5.minutes),
    );
    expect(
      timeline.categoriesBoughtBeforeOneHour.length,
      greaterThanOrEqualTo(4),
    );
  });
}

_BalanceTimeline _simulateActivePlay(
  EconomyConfig config,
  EconomyEngine engine,
) {
  final now = DateTime.utc(2026, 4, 1, 12);
  var state = GameState.initial(config, nowUtc: now);
  var passiveCarry = 0.0;
  var tapCarry = 0.0;
  var elapsed = Duration.zero;

  Duration? firstUpgradeReachable;
  Duration? firstStaffReachable;
  Duration? firstOvenReachable;
  Duration? firstItemTransition;
  Duration? firstPrestige;
  var longestUpgradeGapBeforeOneHour = Duration.zero;
  var lastUpgradePurchase = Duration.zero;
  final categoriesBoughtBeforeOneHour = <UpgradeId>{};

  while (elapsed <= const Duration(hours: 24)) {
    final tickNow = now.add(elapsed);

    tapCarry += 0.5;
    while (tapCarry >= 1) {
      state = engine.applyTap(state, nowUtc: tickNow);
      tapCarry -= 1;
    }

    passiveCarry += engine.passiveIncomePerSecond(state, nowUtc: tickNow);
    final passiveCoins = passiveCarry.floor();
    if (passiveCoins > 0) {
      passiveCarry -= passiveCoins;
      state = engine.addCoins(state, passiveCoins);
    }

    firstUpgradeReachable ??= _canAffordAnyUpgrade(config, engine, state)
        ? elapsed
        : null;
    firstStaffReachable ??=
        _canAffordUpgrade(config, engine, state, UpgradeId.staff)
        ? elapsed
        : null;
    firstOvenReachable ??=
        _canAffordUpgrade(config, engine, state, UpgradeId.oven)
        ? elapsed
        : null;

    var bought = true;
    while (bought) {
      bought = false;
      UpgradeDefinition? choice;
      num choiceCost = 0;
      for (final upgrade in config.upgrades) {
        final upgradeState = state.upgrade(upgrade.id);
        if (engine.isUpgradeMaxed(upgrade, upgradeState)) {
          continue;
        }
        final cost = engine.upgradeCost(upgrade, upgradeState);
        if (state.cash < cost) {
          continue;
        }
        if (choice == null || cost < choiceCost) {
          choice = upgrade;
          choiceCost = cost;
        }
      }
      if (choice == null) {
        break;
      }

      final before = state.upgrade(choice.id);
      final result = engine.buyUpgrade(state, choice.id);
      if (!result.success) {
        break;
      }
      state = result.state;
      bought = true;

      if (elapsed <= 60.minutes) {
        categoriesBoughtBeforeOneHour.add(choice.id);
        final gap = elapsed - lastUpgradePurchase;
        if (gap > longestUpgradeGapBeforeOneHour) {
          longestUpgradeGapBeforeOneHour = gap;
        }
        lastUpgradePurchase = elapsed;
      }

      if (state.upgrade(choice.id).itemIndex > before.itemIndex) {
        firstItemTransition ??= elapsed;
      }
    }

    if (firstPrestige == null && engine.availablePrestigePoints(state) > 0) {
      firstPrestige = elapsed;
      break;
    }

    elapsed += const Duration(seconds: 1);
  }

  return _BalanceTimeline(
    firstUpgradeReachable: firstUpgradeReachable ?? Duration.zero,
    firstStaffReachable: firstStaffReachable ?? Duration.zero,
    firstOvenReachable: firstOvenReachable ?? Duration.zero,
    firstItemTransition: firstItemTransition ?? Duration.zero,
    firstPrestige: firstPrestige ?? Duration.zero,
    longestUpgradeGapBeforeOneHour: longestUpgradeGapBeforeOneHour,
    categoriesBoughtBeforeOneHour: categoriesBoughtBeforeOneHour,
  );
}

bool _canAffordAnyUpgrade(
  EconomyConfig config,
  EconomyEngine engine,
  GameState state,
) {
  return config.upgrades.any((upgrade) {
    final upgradeState = state.upgrade(upgrade.id);
    return !engine.isUpgradeMaxed(upgrade, upgradeState) &&
        state.cash >= engine.upgradeCost(upgrade, upgradeState);
  });
}

bool _canAffordUpgrade(
  EconomyConfig config,
  EconomyEngine engine,
  GameState state,
  UpgradeId id,
) {
  final upgrade = config.upgrade(id);
  final upgradeState = state.upgrade(id);
  return !engine.isUpgradeMaxed(upgrade, upgradeState) &&
      state.cash >= engine.upgradeCost(upgrade, upgradeState);
}

Matcher _between(Duration min, Duration max) {
  return allOf(greaterThanOrEqualTo(min), lessThanOrEqualTo(max));
}

class _BalanceTimeline {
  const _BalanceTimeline({
    required this.firstUpgradeReachable,
    required this.firstStaffReachable,
    required this.firstOvenReachable,
    required this.firstItemTransition,
    required this.firstPrestige,
    required this.longestUpgradeGapBeforeOneHour,
    required this.categoriesBoughtBeforeOneHour,
  });

  final Duration firstUpgradeReachable;
  final Duration firstStaffReachable;
  final Duration firstOvenReachable;
  final Duration firstItemTransition;
  final Duration firstPrestige;
  final Duration longestUpgradeGapBeforeOneHour;
  final Set<UpgradeId> categoriesBoughtBeforeOneHour;
}

extension on int {
  Duration get minutes => Duration(minutes: this);
}
