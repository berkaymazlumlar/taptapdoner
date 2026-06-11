import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/economy_engine.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/progression/prestige_shop_catalog.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

void main() {
  final config = EconomyConfig.standard();
  final engine = EconomyEngine(config);
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  test('knife levels increase tap income and unlock the next item', () {
    var state = GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 50000);

    expect(engine.tapValue(state, nowUtc: nowUtc), 1);

    for (var i = 1; i < UpgradeDefinition.maxItemLevel; i += 1) {
      state = engine.buyUpgrade(state, UpgradeId.knife).state;
    }

    final knife = config.upgrade(UpgradeId.knife);
    final levelTwentyFiveEffect = engine.upgradeEffect(state, UpgradeId.knife);
    expect(state.upgrade(UpgradeId.knife).itemIndex, 0);
    expect(state.upgrade(UpgradeId.knife).level, 25);
    expect(knife.itemForLevel(24).key, 'rusty_knife');
    expect(engine.tapValue(state, nowUtc: nowUtc), 3);

    state = engine.buyUpgrade(state, UpgradeId.knife).state;

    expect(state.upgrade(UpgradeId.knife).itemIndex, 1);
    expect(state.upgrade(UpgradeId.knife).level, 1);
    expect(knife.itemForLevel(25).key, 'sharp_knife');
    expect(
      engine.upgradeEffect(state, UpgradeId.knife),
      greaterThan(levelTwentyFiveEffect),
    );
  });

  test('upgrade milestones grant rewards once at item milestone levels', () {
    var state = GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 5000);
    PurchaseResult? result;

    for (var targetLevel = 2; targetLevel <= 5; targetLevel += 1) {
      result = engine.buyUpgrade(state, UpgradeId.knife);
      expect(result.success, isTrue);
      state = result.state;
      expect(state.upgrade(UpgradeId.knife).level, targetLevel);
    }

    expect(state.upgrade(UpgradeId.knife).level, 5);
    expect(result!.milestoneGrant, isNotNull);
    expect(result.milestoneGrant!.key, 'knife_rusty_knife_5');
    expect(
      state.milestones.claimedMilestoneKeys,
      contains('knife_rusty_knife_5'),
    );
    expect(state.milestones.tapBonusPercent, closeTo(0.05, 0.0001));

    final duplicateAttempt = GameState.initial(config, nowUtc: nowUtc).copyWith(
      cash: 5000,
      upgrades: {
        ...state.upgrades,
        UpgradeId.knife: const UpgradeState(
          id: UpgradeId.knife,
          itemIndex: 0,
          level: 4,
        ),
      },
      milestones: state.milestones,
    );

    final duplicateResult = engine.buyUpgrade(
      duplicateAttempt,
      UpgradeId.knife,
    );

    expect(duplicateResult.success, isTrue);
    expect(duplicateResult.milestoneGrant, isNull);
    expect(
      duplicateResult.state.milestones.tapBonusPercent,
      closeTo(0.05, 0.0001),
    );
  });

  test('first rusty knife milestones unlock active play systems', () {
    var state = GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 50000);
    PurchaseResult? lastResult;

    while (state.upgrade(UpgradeId.knife).level < 20) {
      lastResult = engine.buyUpgrade(state, UpgradeId.knife);
      expect(lastResult.success, isTrue);
      state = lastResult.state;
    }

    expect(lastResult!.milestoneGrant!.key, 'knife_rusty_knife_20');
    expect(state.milestones.hasFeature('critical_cut'), isTrue);
    expect(state.milestones.hasFeature('combo'), isTrue);
    expect(state.milestones.hasFeature('golden_doner'), isTrue);
    expect(state.milestones.criticalChance, closeTo(0.01, 0.0001));
    expect(state.milestones.comboDurationSeconds, closeTo(0.25, 0.0001));
    expect(state.milestones.goldenDonerChance, closeTo(0.0025, 0.0001));
  });

  test('each next item starts stronger than the previous item cap', () {
    for (final upgrade in config.upgrades) {
      for (var index = 0; index < upgrade.items.length - 1; index += 1) {
        final currentCap = upgrade.items[index].effectForItemLevel(
          UpgradeDefinition.maxItemLevel,
        );
        final nextStart = upgrade.items[index + 1].effectForItemLevel(1);

        expect(
          nextStart,
          greaterThan(currentCap),
          reason:
              '${upgrade.id.key} item ${upgrade.items[index + 1].key} should beat previous Lv25',
        );
      }
    }
  });

  test(
    'staff, oven, and menu drive passive income through central formula',
    () {
      var state = GameState.initial(
        config,
        nowUtc: nowUtc,
      ).copyWith(cash: 5000);

      state = engine.buyUpgrade(state, UpgradeId.staff).state;
      expect(engine.passiveIncomePerSecond(state, nowUtc: nowUtc), 1.45);

      state = engine.buyUpgrade(state, UpgradeId.oven).state;
      state = engine.buyUpgrade(state, UpgradeId.menu).state;

      expect(
        engine.passiveIncomePerSecond(state, nowUtc: nowUtc),
        closeTo(1.45 * 1.04 * 1.035, 0.0001),
      );
    },
  );

  test('turbo multiplies tap income while passive income stays stable', () {
    final activeTurboState = GameState.initial(config, nowUtc: nowUtc).copyWith(
      rush: TimedEffectState(
        endsAtUtc: nowUtc.add(const Duration(seconds: 10)),
        cooldownEndsAtUtc: nowUtc.add(const Duration(seconds: 80)),
      ),
    );

    final idleState = activeTurboState.copyWith(rush: const TimedEffectState());

    expect(
      engine.tapValue(activeTurboState, nowUtc: nowUtc),
      engine.tapValue(idleState, nowUtc: nowUtc) * 3,
    );
    expect(
      engine.passiveIncomePerSecond(activeTurboState, nowUtc: nowUtc),
      engine.passiveIncomePerSecond(idleState, nowUtc: nowUtc),
    );
  });

  test('turbo track raises the active turbo multiplier', () {
    var state = GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 5000);
    state = engine.buyUpgrade(state, UpgradeId.turbo).state;
    state = engine.startRush(state, nowUtc: nowUtc);

    expect(engine.tapValue(state, nowUtc: nowUtc), 3);
    expect(engine.upgradeEffect(state, UpgradeId.turbo), 3.12);
  });

  test('turbo upgrade leaves idle tap multiplier at one', () {
    var state = GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 5000);
    final idleTap = engine.tapValue(state, nowUtc: nowUtc);

    state = engine.buyUpgrade(state, UpgradeId.turbo).state;

    expect(engine.tapValue(state, nowUtc: nowUtc), idleTap);
  });

  test('offline track effect changes offline reward', () {
    var state = GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 5000);
    final baseline = engine.offlineIncome(state, const Duration(hours: 1));

    state = engine.buyUpgrade(state, UpgradeId.offline).state;

    expect(baseline, 720);
    expect(
      engine.upgradeEffect(state, UpgradeId.offline),
      closeTo(0.208, 0.0001),
    );
    expect(engine.offlineIncome(state, const Duration(hours: 1)), 748);
  });

  test('prestige multiplier applies to tap and passive income', () {
    var state = GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 50000);
    for (var i = 1; i < UpgradeDefinition.maxItemLevel; i += 1) {
      state = engine.buyUpgrade(state, UpgradeId.knife).state;
    }
    state = engine.buyUpgrade(state, UpgradeId.staff).state;

    final baseTap = engine.tapValue(state, nowUtc: nowUtc);
    final basePassive = engine.passiveIncomePerSecond(state, nowUtc: nowUtc);
    final prestigeState = state.copyWith(
      prestige: const PrestigeState(reputation: 10, runCashEarned: 0),
    );

    expect(
      engine.tapValue(prestigeState, nowUtc: nowUtc),
      greaterThan(baseTap),
    );
    expect(
      engine.passiveIncomePerSecond(prestigeState, nowUtc: nowUtc),
      closeTo(basePassive * 1.5, 0.0001),
    );
  });

  test('collection permanent tap bonus is included in tap income', () {
    final highTapConfig = EconomyConfig(
      baseTapValue: 100,
      rushIncomeMultiplier: config.rushIncomeMultiplier,
      rushDuration: config.rushDuration,
      rushCooldown: config.rushCooldown,
      offlineCap: config.offlineCap,
      prestigeThreshold: config.prestigeThreshold,
      prestigeBonusPerPoint: config.prestigeBonusPerPoint,
      upgrades: config.upgrades,
    );
    final highTapEngine = EconomyEngine(highTapConfig);
    final baseState = GameState.initial(highTapConfig, nowUtc: nowUtc);
    final collectionState = baseState.copyWith(
      collection: const CollectionState(
        unlockedItemIds: {'knife_rusty_knife'},
        claimedBonusItemIds: {'knife_rusty_knife'},
      ),
    );

    expect(highTapEngine.tapValue(baseState, nowUtc: nowUtc), 100);
    expect(highTapEngine.tapValue(collectionState, nowUtc: nowUtc), 101);
  });

  test('shop level multiplier is included in tap and passive income', () {
    final highTapConfig = EconomyConfig(
      baseTapValue: 100,
      rushIncomeMultiplier: config.rushIncomeMultiplier,
      rushDuration: config.rushDuration,
      rushCooldown: config.rushCooldown,
      offlineCap: config.offlineCap,
      prestigeThreshold: config.prestigeThreshold,
      prestigeBonusPerPoint: config.prestigeBonusPerPoint,
      upgrades: config.upgrades,
    );
    final highTapEngine = EconomyEngine(highTapConfig);
    final baseState = GameState.initial(highTapConfig, nowUtc: nowUtc);
    final shopLevelTwoState = baseState.copyWith(
      shopProgression: const ShopProgressionState(
        currentShopLevel: 2,
        highestShopLevel: 2,
        unlockedShopIds: {'street_stand', 'small_buffet'},
      ),
    );

    expect(highTapEngine.tapValue(baseState, nowUtc: nowUtc), 100);
    expect(highTapEngine.tapValue(shopLevelTwoState, nowUtc: nowUtc), 105);

    final staffState = highTapEngine
        .buyUpgrade(baseState.copyWith(cash: 5000), UpgradeId.staff)
        .state;
    final staffShopState = staffState.copyWith(
      shopProgression: const ShopProgressionState(
        currentShopLevel: 2,
        highestShopLevel: 2,
        unlockedShopIds: {'street_stand', 'small_buffet'},
      ),
    );

    expect(
      highTapEngine.passiveIncomePerSecond(staffShopState, nowUtc: nowUtc),
      closeTo(
        highTapEngine.passiveIncomePerSecond(staffState, nowUtc: nowUtc) * 1.05,
        0.0001,
      ),
    );
  });

  test('prestige shop purchase spends unspent points and applies bonuses', () {
    final highTapConfig = EconomyConfig(
      baseTapValue: 100,
      rushIncomeMultiplier: config.rushIncomeMultiplier,
      rushDuration: config.rushDuration,
      rushCooldown: config.rushCooldown,
      offlineCap: config.offlineCap,
      prestigeThreshold: config.prestigeThreshold,
      prestigeBonusPerPoint: config.prestigeBonusPerPoint,
      upgrades: config.upgrades,
    );
    final highTapEngine = EconomyEngine(highTapConfig);
    final state = GameState.initial(highTapConfig, nowUtc: nowUtc).copyWith(
      prestige: const PrestigeState(
        reputation: 5,
        unspentPrestigePoints: 5,
        runCashEarned: 0,
      ),
    );

    final result = highTapEngine.buyPrestigeUpgrade(
      state,
      PrestigeShopCatalog.masterHand,
    );

    expect(result.success, isTrue);
    expect(result.cost, 1);
    expect(result.state.prestige.totalPrestigePoints, 5);
    expect(result.state.prestige.unspentPrestigePoints, 4);
    expect(
      result.state.prestige.prestigeUpgradeLevel(
        PrestigeShopCatalog.masterHand,
      ),
      1,
    );
    expect(highTapEngine.tapValue(result.state, nowUtc: nowUtc), 131);
  });

  test('prestige points use the square-root total-earned curve', () {
    final state = GameState.initial(config, nowUtc: nowUtc).copyWith(
      prestige: const PrestigeState(reputation: 16, runCashEarned: 125000000),
    );

    expect(engine.availablePrestigePoints(state), 11);
    expect(engine.prestigeMultiplier(state), closeTo(1.8, 0.0001));
    expect(engine.prestigeMultiplierForPoints(27), closeTo(2.35, 0.0001));
  });

  test(
    'prestige resets upgrade tracks and rush while preserving permanent stats',
    () {
      var state = GameState.initial(config, nowUtc: nowUtc).copyWith(
        cash: 50000,
        lifetimeCash: 2_500_000,
        pendingOfflineCash: 1200,
        prestige: const PrestigeState(reputation: 2, runCashEarned: 1_000_000),
        rush: TimedEffectState(
          endsAtUtc: nowUtc.add(const Duration(seconds: 10)),
          cooldownEndsAtUtc: nowUtc.add(const Duration(seconds: 60)),
        ),
      );

      for (var i = 0; i < UpgradeDefinition.maxItemLevel; i += 1) {
        state = engine.buyUpgrade(state, UpgradeId.knife).state;
      }

      expect(state.upgrade(UpgradeId.knife).itemIndex, 1);
      expect(state.upgrade(UpgradeId.knife).level, 1);
      expect(state.rush.isActiveAt(nowUtc), isTrue);

      final prestiged = engine.applyPrestige(state, nowUtc: nowUtc);

      expect(prestiged.cash, 0);
      expect(prestiged.pendingOfflineCash, 0);
      expect(prestiged.lifetimeCash, state.lifetimeCash);
      expect(prestiged.prestige.reputation, 3);
      expect(prestiged.prestige.totalPrestigePoints, 3);
      expect(prestiged.prestige.unspentPrestigePoints, 3);
      expect(prestiged.prestige.prestigeCount, 1);
      expect(prestiged.prestige.runCashEarned, 0);
      expect(prestiged.rush.endsAtUtc, isNull);
      expect(prestiged.rush.cooldownEndsAtUtc, isNull);
      expect(prestiged.milestones.claimedMilestoneKeys, isEmpty);
      expect(prestiged.milestones.tapBonusPercent, 0);
      for (final upgrade in prestiged.upgrades.values) {
        expect(upgrade.itemIndex, 0, reason: upgrade.id.key);
        expect(upgrade.level, 1, reason: upgrade.id.key);
      }
    },
  );

  test(
    'prestige preserves permanent phase five and prestige shop state while resetting current run',
    () {
      final quests =
          Map<String, QuestProgress>.from(StarterQuestCatalog.initialProgress())
            ..['starter_tap_10'] = const QuestProgress(
              questId: 'starter_tap_10',
              status: QuestStatus.claimed,
              currentValue: 10,
              targetValue: 10,
              rewardClaimed: true,
            );
      final state = GameState.initial(config, nowUtc: nowUtc).copyWith(
        cash: 50000,
        lifetimeCash: 2_500_000,
        pendingOfflineCash: 1200,
        prestige: const PrestigeState(
          reputation: 5,
          unspentPrestigePoints: 2,
          prestigeCount: 1,
          runCashEarned: 1_000_000,
          purchasedPrestigeUpgrades: {
            PrestigeShopCatalog.fastStart: 2,
            PrestigeShopCatalog.masterChest: 3,
          },
        ),
        shopProgression: const ShopProgressionState(
          currentShopLevel: 3,
          highestShopLevel: 4,
          unlockedShopIds: {
            'street_stand',
            'small_buffet',
            'neighborhood_doner',
            'busy_street_doner',
          },
        ),
        quests: quests,
        collection: const CollectionState(
          unlockedItemIds: {'knife_rusty_knife'},
          claimedBonusItemIds: {'knife_rusty_knife'},
        ),
      );

      final prestiged = engine.applyPrestige(state, nowUtc: nowUtc);

      expect(prestiged.cash, 400);
      expect(prestiged.pendingOfflineCash, 0);
      expect(prestiged.lifetimeCash, state.lifetimeCash);
      expect(prestiged.prestige.totalPrestigePoints, 6);
      expect(prestiged.prestige.unspentPrestigePoints, 3);
      expect(prestiged.prestige.prestigeCount, 2);
      expect(
        prestiged.prestige.purchasedPrestigeUpgrades,
        state.prestige.purchasedPrestigeUpgrades,
      );
      expect(prestiged.shopProgression.currentShopLevel, 1);
      expect(prestiged.shopProgression.highestShopLevel, 4);
      expect(prestiged.collection, state.collection);
      expect(prestiged.chestInventory.count(ChestType.master), 1);
      expect(prestiged.quests['starter_tap_10']?.status, QuestStatus.active);
    },
  );
}
