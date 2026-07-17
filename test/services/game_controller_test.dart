import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/branches/branch_catalog.dart';
import 'package:taptapdoner/domain/branches/branch_models.dart';
import 'package:taptapdoner/domain/customers/customer_order_models.dart';
import 'package:taptapdoner/domain/economy/currency_math.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/goals/goal_catalog.dart';
import 'package:taptapdoner/domain/goals/goal_engine.dart';
import 'package:taptapdoner/domain/goals/goal_models.dart';
import 'package:taptapdoner/domain/progression/chest_drop_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/random_events/random_event_catalog.dart';
import 'package:taptapdoner/domain/random_events/random_event_models.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';

void main() {
  final config = EconomyConfig.standard();

  test('checkpoint then reconcile grants offline production once', () async {
    var nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller = GameController(
      config: config,
      saveRepository: _RecordingSaveRepository(),
      adService: const NoopRewardedAdService(),
      clock: () => nowUtc,
    )..hydrate(GameState.initial(config, nowUtc: nowUtc));

    expect(controller.state.lastActiveAtUtc, nowUtc);
    await controller.checkpointLifecycle();
    expect(controller.state.lastActiveAtUtc, nowUtc);

    nowUtc = nowUtc.add(const Duration(hours: 1));
    await controller.reconcileBackground();

    expect(controller.state.pendingOfflineCash, 652);
    expect(controller.state.lastActiveAtUtc, nowUtc);

    await controller.reconcileBackground();
    expect(controller.state.pendingOfflineCash, 652);
  });

  test('save operations are serialized so newer checkpoints win', () async {
    var nowUtc = DateTime.utc(2026, 4, 1, 12);
    final repository = _DelayedSaveRepository();
    final controller = GameController(
      config: config,
      saveRepository: repository,
      adService: const NoopRewardedAdService(),
      clock: () => nowUtc,
    )..hydrate(GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 100));

    await controller.buyUpgrade(UpgradeId.knife);
    nowUtc = nowUtc.add(const Duration(minutes: 10));
    await controller.checkpointLifecycle();

    expect(repository.savedStates, hasLength(2));
    expect(
      repository.savedStates.last.lastActiveAtUtc,
      DateTime.utc(2026, 4, 1, 12),
    );
    expect(
      repository.savedStates.last.lastSavedAtUtc,
      DateTime.utc(2026, 4, 1, 12, 10),
    );
  });

  test(
    'buying an upgrade saves updated track progress before returning',
    () async {
      final repository = _RecordingSaveRepository();
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller = GameController(
        config: config,
        saveRepository: repository,
        adService: const NoopRewardedAdService(),
        clock: () => nowUtc,
      )..hydrate(GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 100));

      final bought = await controller.buyUpgrade(config.upgrades.first.id);

      expect(bought, isTrue);
      expect(repository.savedState, isNotNull);
      expect(repository.savedState!.cash, lessThan(100));
      expect(
        repository.savedState!.upgrade(config.upgrades.first.id).itemIndex,
        0,
      );
      expect(repository.savedState!.upgrade(config.upgrades.first.id).level, 2);
    },
  );

  test(
    'bulk upgrade purchase saves final progress and purchase count',
    () async {
      final repository = _RecordingSaveRepository();
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller =
          GameController(
            config: config,
            saveRepository: repository,
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 1000),
          );

      final bought = await controller.buyUpgrade(UpgradeId.knife, quantity: 10);

      expect(bought, isTrue);
      expect(controller.lastPurchaseResult?.purchasedCount, 10);
      expect(controller.state.upgrade(UpgradeId.knife).level, 11);
      expect(controller.state.stats.totalUpgradesPurchased, 10);
      expect(repository.savedState?.upgrade(UpgradeId.knife).level, 11);
      expect(repository.savedState?.stats.totalUpgradesPurchased, 10);
    },
  );

  test('max upgrade purchase buys every currently affordable level', () async {
    final repository = _RecordingSaveRepository();
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller = GameController(
      config: config,
      saveRepository: repository,
      adService: const NoopRewardedAdService(),
      clock: () => nowUtc,
    )..hydrate(GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 109));

    final bought = await controller.buyMaxUpgrade(UpgradeId.knife);

    expect(bought, isTrue);
    expect(controller.lastPurchaseResult?.purchasedCount, 4);
    expect(controller.state.cash, 0);
    expect(controller.state.upgrade(UpgradeId.knife).level, 5);
    expect(repository.savedState?.upgrade(UpgradeId.knife).level, 5);
  });

  test('maxed upgrade income tick remains finite and increases cash', () {
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final maxedUpgrades = {
      for (final definition in config.upgrades)
        definition.id: UpgradeState.fromTotalLevel(
          definition: definition,
          totalLevel: definition.maxLevel,
        ),
    };
    final controller =
        GameController(
          config: config,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            cash: CurrencyMath.legacyInt64MaxCurrency,
            lifetimeCash: CurrencyMath.legacyInt64MaxCurrency,
            upgrades: maxedUpgrades,
          ),
        );

    controller.tick(const Duration(seconds: 1));

    expect(controller.passiveIncomePerSecond, isNonNegative);
    expect(
      controller.passiveIncomePerSecond,
      lessThanOrEqualTo(double.maxFinite),
    );
    expect(
      controller.state.cash,
      greaterThan(CurrencyMath.legacyInt64MaxCurrency),
    );
    expect(
      controller.state.lifetimeCash,
      greaterThan(CurrencyMath.legacyInt64MaxCurrency),
    );
  });

  test('free purchase mode upgrades without spending cash', () async {
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller = GameController(
      config: config,
      saveRepository: _RecordingSaveRepository(),
      adService: const NoopRewardedAdService(),
      clock: () => nowUtc,
      freePurchasesEnabled: true,
    )..hydrate(GameState.initial(config, nowUtc: nowUtc));

    final bought = await controller.buyUpgrade(UpgradeId.knife);

    expect(bought, isTrue);
    expect(controller.state.cash, 0);
    expect(controller.state.upgrade(UpgradeId.knife).level, 2);
  });

  test(
    'free purchase mode provides unlimited chests for debug testing',
    () async {
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller = GameController(
        config: config,
        saveRepository: _RecordingSaveRepository(),
        adService: const NoopRewardedAdService(),
        clock: () => nowUtc,
        random: _FixedRandom(0.1),
        freePurchasesEnabled: true,
      )..hydrate(GameState.initial(config, nowUtc: nowUtc));

      expect(
        controller.progressionSnapshotListenable.value.chests.count(
          ChestType.small,
        ),
        99,
      );

      final reward = await controller.openChest(ChestType.small);

      expect(reward, isNotNull);
      expect(reward!.rewardType, ChestRewardType.money);
      expect(controller.state.chestInventory.count(ChestType.small), 0);
      expect(
        controller.progressionSnapshotListenable.value.chests.count(
          ChestType.small,
        ),
        99,
      );
      expect(controller.state.stats.chestsOpened, 1);
    },
  );

  test(
    'free purchase mode buys prestige upgrades without spending points',
    () async {
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller =
          GameController(
            config: config,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
            freePurchasesEnabled: true,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              prestige: const PrestigeState(
                totalPrestigePoints: 2,
                unspentPrestigePoints: 0,
                runCashEarned: 0,
              ),
            ),
          );

      final bought = await controller.buyPrestigeUpgrade('master_hand');

      expect(bought, isTrue);
      expect(controller.state.prestige.unspentPrestigePoints, 0);
      expect(controller.state.prestige.prestigeUpgradeLevel('master_hand'), 1);
    },
  );

  test('free purchase mode unlocks branches without cash cost', () async {
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final branch = BranchCatalog.byId['main_branch']!;
    final controller =
        GameController(
          config: config,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
          freePurchasesEnabled: true,
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            lifetimeCash: branch.requiredLifetimeCash.round(),
            prestige: PrestigeState(
              totalPrestigePoints: branch.requiredPrestigeCount,
              unspentPrestigePoints: 0,
              prestigeCount: branch.requiredPrestigeCount,
              runCashEarned: 0,
            ),
            shopProgression: const ShopProgressionState(
              currentShopLevel: 7,
              highestShopLevel: 7,
              unlockedShopIds: {'street_stand', 'doner_chain'},
            ),
          ),
        );

    final bought = await controller.unlockBranch(branch.id);

    expect(bought, isTrue);
    expect(controller.state.cash, 0);
    expect(controller.state.branches.isUnlocked(branch.id), isTrue);
  });

  test(
    'starter quest chain completes, claims once, and unlocks next quest',
    () async {
      final repository = _RecordingSaveRepository();
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller = GameController(
        config: config,
        saveRepository: repository,
        adService: const NoopRewardedAdService(),
        clock: () => nowUtc,
      )..hydrate(GameState.initial(config, nowUtc: nowUtc));

      expect(
        controller.questSnapshotListenable.value?.questId,
        'starter_tap_10',
      );

      for (var i = 0; i < 10; i += 1) {
        await controller.tap();
      }

      expect(controller.questSnapshotListenable.value?.canClaim, isTrue);
      final claimedFirst = await controller.claimActiveQuestReward();

      expect(claimedFirst, isTrue);
      expect(controller.state.cash, 60);
      expect(
        controller.questSnapshotListenable.value?.questId,
        'starter_first_upgrade',
      );
      expect(controller.questSnapshotListenable.value?.canClaim, isFalse);

      final duplicateClaim = await controller.claimActiveQuestReward();
      expect(duplicateClaim, isFalse);
      expect(controller.state.cash, 60);

      final bought = await controller.buyUpgrade(UpgradeId.knife);
      expect(bought, isTrue);
      expect(controller.questSnapshotListenable.value?.canClaim, isTrue);

      await controller.claimActiveQuestReward();
      expect(controller.state.cash, 65);
      expect(
        controller.questSnapshotListenable.value?.questId,
        'starter_tap_50',
      );
      expect(
        repository.savedState?.quests['starter_tap_10']?.rewardClaimed,
        isTrue,
      );
    },
  );

  test(
    'achievement progress completes and reward can be claimed once',
    () async {
      final repository = _RecordingSaveRepository();
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller = GameController(
        config: config,
        saveRepository: repository,
        adService: const NoopRewardedAdService(),
        clock: () => nowUtc,
      )..hydrate(GameState.initial(config, nowUtc: nowUtc));

      for (var i = 0; i < 10; i += 1) {
        await controller.tap();
      }

      final progress = controller.state.achievements['tap_10'];
      expect(progress?.isCompleted, isTrue);
      expect(progress?.isRewardClaimed, isFalse);
      expect(
        controller
            .progressionSnapshotListenable
            .value
            .latestClaimableAchievement
            ?.id,
        'tap_10',
      );

      final claimed = await controller.claimAchievementReward('tap_10');
      final duplicate = await controller.claimAchievementReward('tap_10');

      expect(claimed, isTrue);
      expect(duplicate, isFalse);
      expect(controller.state.cash, 60);
      expect(controller.state.achievements['tap_10']?.isRewardClaimed, isTrue);
      expect(
        repository.savedState?.achievements['tap_10']?.isRewardClaimed,
        isTrue,
      );
    },
  );

  test(
    'opening a chest consumes inventory and applies the rolled reward',
    () async {
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller =
          GameController(
            config: config,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
            random: _FixedRandom(0.1),
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              chestInventory: const ChestInventoryState(
                counts: {ChestType.small: 1},
              ),
            ),
          );

      final reward = await controller.openChest(ChestType.small);

      expect(reward, isNotNull);
      expect(reward!.rewardType, ChestRewardType.money);
      expect(controller.state.chestInventory.count(ChestType.small), 0);
      expect(controller.state.stats.chestsOpened, 1);
      expect(controller.state.cash, greaterThan(0));
      expect(controller.state.achievements['chest_1']?.isCompleted, isTrue);
    },
  );

  test('chest drop tables contain actionable moment card rewards', () {
    final momentIds = <String>{};
    for (final type in ChestType.values) {
      final table = ChestDropCatalog.tableFor(type);
      for (final drop in table.drops.where(
        (drop) => drop.rewardType == ChestRewardType.knifeSkinShard,
      )) {
        expect(Collection2Catalog.momentCardById, contains(drop.itemId));
        momentIds.add(drop.itemId!);
      }
    }
    expect(momentIds, Collection2Catalog.momentCardById.keys.toSet());
  });

  test(
    'customer chest cards unlock customers and auto-claim completed sets',
    () async {
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller =
          GameController(
            config: config,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
            random: _FixedRandom(0.01),
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              chestInventory: const ChestInventoryState(
                counts: {ChestType.recipe: 1},
              ),
              collection2: const Collection2State(
                customerCardShards: {'customer_student_regular': 8},
                masterCardLevels: {'staff_apprentice': 1},
                unlockedDecorIds: {'decor_new_sign'},
                unlockedMomentCardIds: {'moment_first_shift'},
              ),
            ),
          );

      final reward = await controller.openChest(ChestType.recipe);

      expect(reward, isNotNull);
      expect(reward!.rewardType, ChestRewardType.recipeShard);
      expect(
        controller.state.collection2.customerCardLevel(
          'customer_student_regular',
        ),
        1,
      );
      expect(
        controller.state.collection2.customerCardCount(
          'customer_student_regular',
        ),
        1,
      );
      expect(
        controller.state.collection2.claimedSetBonuses,
        contains('street_set'),
      );
      expect(controller.state.chestInventory.count(ChestType.recipe), 0);
    },
  );

  test('temporary income boost is exposed with its remaining duration', () {
    var nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller =
        GameController(
          config: config,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            passiveBoost: TimedEffectState(
              endsAtUtc: nowUtc.add(const Duration(seconds: 120)),
            ),
          ),
        );

    expect(
      controller.activePlaySnapshotListenable.value.temporaryIncomeBoostActive,
      isTrue,
    );
    expect(
      controller
          .activePlaySnapshotListenable
          .value
          .temporaryIncomeBoostRemaining,
      const Duration(seconds: 120),
    );

    nowUtc = nowUtc.add(const Duration(seconds: 45));
    controller.tick(const Duration(seconds: 45));

    expect(
      controller.activePlaySnapshotListenable.value.temporaryIncomeBoostActive,
      isTrue,
    );
    expect(
      controller
          .activePlaySnapshotListenable
          .value
          .temporaryIncomeBoostRemaining,
      const Duration(seconds: 75),
    );

    nowUtc = nowUtc.add(const Duration(seconds: 80));
    controller.tick(const Duration(seconds: 80));

    expect(
      controller.activePlaySnapshotListenable.value.temporaryIncomeBoostActive,
      isFalse,
    );
    expect(controller.state.passiveBoost.endsAtUtc, isNull);
  });

  test('maxed collection shard duplicate overflows into reputation', () async {
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller =
        GameController(
          config: config,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
          random: _FixedRandom(0.01),
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            chestInventory: const ChestInventoryState(
              counts: {ChestType.recipe: 1},
            ),
            collection2: const Collection2State(
              customerCardLevels: {'customer_student_regular': 5},
            ),
          ),
        );

    await controller.openChest(ChestType.recipe);

    expect(
      controller.state.collection2.customerCardLevel(
        'customer_student_regular',
      ),
      5,
    );
    expect(controller.state.customerReputation.totalReputation, 3);
  });

  test('combo activates after ten taps and expires after its window', () async {
    var nowUtc = DateTime.utc(2026, 4, 1, 12);
    final comboConfig = _activePlayConfig(baseTapValue: 10);
    final controller =
        GameController(
          config: comboConfig,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(comboConfig, nowUtc: nowUtc).copyWith(
            milestones: const MilestoneState(unlockedFeatureKeys: {'combo'}),
          ),
        );

    final first = await controller.tap();
    TapOutcome ninth = first;
    for (var index = 0; index < 8; index += 1) {
      ninth = await controller.tap();
    }
    expect(controller.state.stats.maxCombo, 0);
    final tenth = await controller.tap();

    expect(first.combo, 0);
    expect(first.comboMultiplier, 1);
    expect(ninth.combo, 0);
    expect(ninth.comboMultiplier, 1);
    expect(tenth.combo, 10);
    expect(tenth.comboMultiplier, closeTo(1.20, 0.0001));
    expect(tenth.coins, greaterThan(first.coins));
    expect(controller.activePlaySnapshotListenable.value.currentCombo, 10);

    nowUtc = nowUtc.add(const Duration(seconds: 1));
    controller.tick(const Duration(seconds: 1));

    expect(controller.activePlaySnapshotListenable.value.currentCombo, 10);

    nowUtc = nowUtc.add(const Duration(milliseconds: 1));
    controller.tick(const Duration(milliseconds: 1));

    expect(controller.activePlaySnapshotListenable.value.currentCombo, 0);
  });

  test('combo multiplier bonus does not affect warmup taps', () async {
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final comboConfig = _activePlayConfig(baseTapValue: 10);
    final controller =
        GameController(
          config: comboConfig,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(comboConfig, nowUtc: nowUtc).copyWith(
            milestones: const MilestoneState(
              unlockedFeatureKeys: {'combo'},
              comboMultiplierBonus: 0.05,
            ),
          ),
        );

    final first = await controller.tap();
    for (var index = 0; index < 8; index += 1) {
      await controller.tap();
    }
    final tenth = await controller.tap();

    expect(first.combo, 0);
    expect(first.comboMultiplier, 1);
    expect(first.coins, 10);
    expect(tenth.combo, 10);
    expect(tenth.comboMultiplier, closeTo(1.25, 0.0001));
  });

  test('critical cut randomly multiplies an unlocked tap', () async {
    final criticalConfig = _activePlayConfig(
      baseTapValue: 10,
      criticalBaseChance: 1,
      criticalMaxChance: 1,
    );
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller =
        GameController(
          config: criticalConfig,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(criticalConfig, nowUtc: nowUtc).copyWith(
            milestones: const MilestoneState(
              unlockedFeatureKeys: {'critical_cut'},
            ),
          ),
        );

    final outcome = await controller.tap();

    expect(outcome.isCritical, isTrue);
    expect(outcome.criticalMultiplier, closeTo(3, 0.0001));
    expect(outcome.coins, 30);
    expect(controller.state.stats.criticalCutCount, 1);
  });

  test('customer order spawn advances only during active ticking', () async {
    var nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller =
        GameController(
          config: config,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
          random: _FixedRandom(0),
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            customerOrders: CustomerSystemState.initial(nowUtc: nowUtc)
                .copyWith(
                  lastSpawnTimeMillis: nowUtc.millisecondsSinceEpoch,
                  spawnRemainingSeconds: 1,
                  nextSpawnTimeMillis: nowUtc
                      .add(const Duration(seconds: 1))
                      .millisecondsSinceEpoch,
                ),
          ),
        );

    nowUtc = nowUtc.add(const Duration(hours: 1));
    await controller.reconcileBackground();

    expect(controller.state.customerOrders.activeOrder, isNull);
    expect(controller.state.customerOrders.spawnRemainingSeconds, 1);

    controller.tick(const Duration(seconds: 1));

    expect(controller.state.customerOrders.activeOrder, isNotNull);
    expect(
      controller.state.customerOrders.activeOrder!.customerTypeId,
      CustomerOrderCatalog.regularCustomer,
    );
  });

  test(
    'customer order completion grants reward once and unlocks reputation type',
    () async {
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final order = CustomerOrder(
        id: 'test_order',
        customerTypeId: CustomerOrderCatalog.regularCustomer,
        customerName: 'Regular Customer',
        title: 'Simple Order',
        description: 'Cut 2 doners.',
        objectiveType: OrderObjectiveType.tapCount,
        targetValue: 2,
        durationSeconds: 20,
        remainingSeconds: 20,
        rarity: OrderRarity.common,
        minShopLevel: 1,
        rewards: const [
          OrderReward(type: OrderRewardType.money, amount: 10),
          OrderReward(type: OrderRewardType.reputation, amount: 50),
        ],
      );
      final controller =
          GameController(
            config: config,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              customerOrders: CustomerSystemState.initial(nowUtc: nowUtc)
                  .copyWith(
                    activeOrder: order,
                    lastSpawnTimeMillis: nowUtc.millisecondsSinceEpoch,
                  ),
            ),
          );

      await controller.tap();
      await controller.tap();

      final cashAfterCompletion = controller.state.cash;
      expect(controller.state.customerOrders.activeOrder, isNull);
      expect(controller.state.customerOrders.completedOrderCount, 1);
      expect(
        controller.state.customerOrders.completedOrderIds,
        contains('test_order'),
      );
      expect(controller.state.customerReputation.totalReputation, 50);
      expect(controller.state.customerReputation.currentLevel, 2);
      expect(
        controller.state.customerOrders.unlockedCustomerTypeIds,
        contains(CustomerOrderCatalog.hurryCustomer),
      );

      await controller.tap();

      expect(controller.state.customerOrders.completedOrderCount, 1);
      expect(controller.state.cash, cashAfterCompletion + 1);
    },
  );

  test(
    'prestige clears active customer order but preserves reputation',
    () async {
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final order = CustomerOrder(
        id: 'prestige_order',
        customerTypeId: CustomerOrderCatalog.regularCustomer,
        customerName: 'Regular Customer',
        title: 'Simple Order',
        description: 'Cut 10 doners.',
        objectiveType: OrderObjectiveType.tapCount,
        targetValue: 10,
        durationSeconds: 20,
        remainingSeconds: 20,
        rarity: OrderRarity.common,
        minShopLevel: 1,
        rewards: const [
          OrderReward(type: OrderRewardType.reputation, amount: 1),
        ],
      );
      final controller =
          GameController(
            config: config,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              prestige: PrestigeState(
                reputation: 0,
                runCashEarned: config.prestigeThreshold,
              ),
              customerReputation: CustomerReputationState.fromTotal(50),
              customerOrders: CustomerSystemState.initial(nowUtc: nowUtc)
                  .copyWith(
                    activeOrder: order,
                    completedOrderCount: 3,
                    lastSpawnTimeMillis: nowUtc.millisecondsSinceEpoch,
                  ),
            ),
          );

      final applied = await controller.applyPrestige();

      expect(applied, isTrue);
      expect(controller.state.customerOrders.activeOrder, isNull);
      expect(controller.state.customerOrders.completedOrderCount, 3);
      expect(controller.state.customerReputation.totalReputation, 50);
      expect(controller.state.customerReputation.currentLevel, 2);
      expect(controller.state.customerOrders.spawnRemainingSeconds, 240);
    },
  );

  test(
    'random event reputation reward updates reputation and resolves event',
    () async {
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final event = RandomEventCatalog.byId['EVT_070']!;
      final controller =
          GameController(
            config: config,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              randomEvents: const RandomEventRuntimeState().markShown(
                event,
                nowUtc,
              ),
            ),
          );

      final resolution = await controller.chooseRandomEvent('decline');

      expect(resolution, isNotNull);
      expect(resolution!.effectLabel, '+1 itibar');
      expect(controller.state.customerReputation.totalReputation, 1);
      expect(controller.state.randomEvents.activeEventId, event.id);
      expect(controller.state.randomEvents.history.first.choiceKey, 'decline');
    },
  );

  test(
    'random event reputation boost affects later reputation rewards',
    () async {
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final event = RandomEventCatalog.byId['EVT_008']!;
      final order = CustomerOrder(
        id: 'event_reputation_order',
        customerTypeId: CustomerOrderCatalog.regularCustomer,
        customerName: 'Regular Customer',
        title: 'Reputation Order',
        description: 'Cut 1 doner.',
        objectiveType: OrderObjectiveType.tapCount,
        targetValue: 1,
        durationSeconds: 20,
        remainingSeconds: 20,
        rarity: OrderRarity.common,
        minShopLevel: 1,
        rewards: const [
          OrderReward(type: OrderRewardType.reputation, amount: 10),
        ],
      );
      final controller =
          GameController(
            config: config,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              cash: 1000,
              customerOrders: CustomerSystemState.initial(
                nowUtc: nowUtc,
              ).copyWith(activeOrder: order),
              randomEvents: const RandomEventRuntimeState().markShown(
                event,
                nowUtc,
              ),
            ),
          );

      final resolution = await controller.chooseRandomEvent('accept');
      await controller.tap();

      expect(resolution, isNotNull);
      expect(resolution!.effectLabel, 'İtibar +20%');
      expect(controller.state.customerReputation.totalReputation, 12);
    },
  );

  test(
    'daily and weekly goals generate on hydrate and avoid locked systems',
    () {
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller = GameController(
        config: config,
        saveRepository: _RecordingSaveRepository(),
        adService: const NoopRewardedAdService(),
        clock: () => nowUtc,
        random: const _FixedRandom(0),
      )..hydrate(GameState.initial(config, nowUtc: nowUtc));

      final dailyIds = controller.state.goals.activeDailyGoals
          .map((goal) => goal.goalId)
          .toSet();
      expect(controller.state.goals.activeDailyGoals, hasLength(3));
      expect(controller.state.goals.activeWeeklyGoals, hasLength(5));
      expect(controller.state.goals.activePrestigeRunGoals, isEmpty);
      expect(controller.state.goals.activeEventGoals, isEmpty);
      expect(
        GoalCatalog.byId[dailyIds.first]!.objectiveType,
        isNot(GoalObjectiveType.completeEvent),
      );
    },
  );

  test('goal progress completes and reward can be claimed once', () async {
    final repository = _RecordingSaveRepository();
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller =
        GameController(
          config: config,
          saveRepository: repository,
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            goals: _goalsWithDaily(
              nowUtc,
              const GoalProgress(
                goalId: 'daily_tap_300',
                targetValue: 2,
                generatedAtMillis: 1775044800000,
                expiresAtMillis: 1775131200000,
              ),
            ),
          ),
        );

    await controller.tap();
    await controller.tap();

    expect(
      controller.state.goals.progressFor('daily_tap_300')?.status,
      GoalStatus.completed,
    );

    final claimed = await controller.claimGoalReward('daily_tap_300');
    final duplicate = await controller.claimGoalReward('daily_tap_300');

    expect(claimed, isTrue);
    expect(duplicate, isFalse);
    expect(controller.state.cash, 302);
    expect(controller.state.customerReputation.totalReputation, 5);
    expect(
      controller.state.goals.progressFor('daily_tap_300')?.rewardClaimed,
      isTrue,
    );
    expect(
      repository.savedState?.goals.progressFor('daily_tap_300')?.rewardClaimed,
      isTrue,
    );
  });

  test('expired goal cannot be claimed', () async {
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller =
        GameController(
          config: config,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            goals: _goalsWithDaily(
              nowUtc,
              GoalProgress(
                goalId: 'daily_tap_300',
                currentValue: 2,
                targetValue: 2,
                status: GoalStatus.completed,
                generatedAtMillis: nowUtc.millisecondsSinceEpoch,
                expiresAtMillis: nowUtc
                    .subtract(const Duration(milliseconds: 1))
                    .millisecondsSinceEpoch,
              ),
            ),
          ),
        );

    final claimed = await controller.claimGoalReward('daily_tap_300');

    expect(claimed, isFalse);
    expect(
      controller.state.goals.progressFor('daily_tap_300')?.status,
      GoalStatus.expired,
    );
    expect(controller.state.cash, 0);
  });

  test('daily and weekly reset regenerates active goals', () async {
    var nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller =
        GameController(
          config: config,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
          random: const _FixedRandom(0),
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            goals: _goalsWithDaily(
              nowUtc,
              GoalProgress(
                goalId: 'daily_tap_300',
                currentValue: 1,
                targetValue: 2,
                generatedAtMillis: nowUtc.millisecondsSinceEpoch,
                expiresAtMillis: nowUtc
                    .add(const Duration(days: 1))
                    .millisecondsSinceEpoch,
              ),
            ),
          ),
        );

    nowUtc = DateTime.utc(2026, 4, 2, 12);
    await controller.reconcileBackground();

    expect(controller.state.goals.lastDailyResetDate, goalLocalDateKey(nowUtc));
    expect(
      controller.state.goals.activeDailyGoals.every(
        (goal) =>
            goal.currentValue == 0 &&
            goal.generatedAtMillis == nowUtc.millisecondsSinceEpoch,
      ),
      isTrue,
    );

    nowUtc = DateTime.utc(2026, 4, 6, 12);
    await controller.reconcileBackground();

    expect(controller.state.goals.lastWeeklyResetWeek, goalIsoWeekKey(nowUtc));
    expect(
      controller.state.goals.activeWeeklyGoals.every(
        (goal) => goal.generatedAtMillis == nowUtc.millisecondsSinceEpoch,
      ),
      isTrue,
    );
  });

  test('prestige generates new prestige run goals after reset', () async {
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller =
        GameController(
          config: config,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
          random: const _FixedRandom(0),
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            prestige: PrestigeState(
              reputation: 0,
              runCashEarned: config.prestigeThreshold,
            ),
          ),
        );

    expect(controller.state.goals.activePrestigeRunGoals, isEmpty);

    final applied = await controller.applyPrestige();

    expect(applied, isTrue);
    expect(controller.state.prestige.prestigeCount, 1);
    expect(controller.state.goals.activePrestigeRunGoals, hasLength(3));
    expect(controller.state.goals.runGoalPrestigeCount, 1);
  });

  test(
    'branch unlock and level up persist and record branch goal progress',
    () async {
      final repository = _RecordingSaveRepository();
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller =
          GameController(
            config: config,
            saveRepository: repository,
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              cash: 5_000_000,
              lifetimeCash: 20_000_000,
              prestige: const PrestigeState(
                reputation: 0,
                prestigeCount: 1,
                runCashEarned: 0,
              ),
              shopProgression: const ShopProgressionState(
                currentShopLevel: 7,
                highestShopLevel: 7,
                unlockedShopIds: {'street_stand', 'doner_chain'},
              ),
              goals: _goalsWithDaily(
                nowUtc,
                GoalProgress(
                  goalId: 'daily_unlock_branch_1',
                  targetValue: 1,
                  generatedAtMillis: nowUtc.millisecondsSinceEpoch,
                  expiresAtMillis: nowUtc
                      .add(const Duration(days: 1))
                      .millisecondsSinceEpoch,
                ),
              ),
            ),
          );

      final unlocked = await controller.unlockBranch('main_branch');
      final leveled = await controller.levelUpBranch('main_branch');

      expect(unlocked, isTrue);
      expect(leveled, isTrue);
      expect(
        controller.state.branches.progressFor('main_branch').isUnlocked,
        isTrue,
      );
      expect(controller.state.branches.progressFor('main_branch').level, 2);
      expect(
        controller.state.goals.progressFor('daily_unlock_branch_1')?.status,
        GoalStatus.completed,
      );
      expect(
        repository.savedState?.branches.progressFor('main_branch').level,
        2,
      );
    },
  );

  test(
    'branch managers can be changed and unassigned but not duplicated',
    () async {
      final repository = _RecordingSaveRepository();
      final nowUtc = DateTime.utc(2026, 7, 16);
      final controller =
          GameController(
            config: config,
            saveRepository: repository,
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              collection2: const Collection2State(
                masterCards: {'staff_apprentice': 0, 'staff_journeyman': 0},
                masterCardLevels: {
                  'staff_apprentice': 1,
                  'staff_journeyman': 1,
                },
              ),
              branches: const BranchSystemState(
                branchProgress: {
                  'main_branch': BranchProgress(
                    branchId: 'main_branch',
                    isUnlocked: true,
                    level: 20,
                  ),
                  'neighborhood_branch': BranchProgress(
                    branchId: 'neighborhood_branch',
                    isUnlocked: true,
                    level: 20,
                  ),
                },
              ),
            ),
          );

      expect(
        await controller.assignBranchManager('main_branch', 'staff_apprentice'),
        isTrue,
      );
      expect(
        await controller.assignBranchManager(
          'neighborhood_branch',
          'staff_apprentice',
        ),
        isFalse,
      );
      expect(
        await controller.assignBranchManager('main_branch', 'staff_journeyman'),
        isTrue,
      );
      expect(
        controller.state.branches.progressFor('main_branch').assignedManagerId,
        'staff_journeyman',
      );
      expect(await controller.unassignBranchManager('main_branch'), isTrue);
      expect(
        controller.state.branches.progressFor('main_branch').assignedManagerId,
        isNull,
      );
      expect(await controller.unassignBranchManager('main_branch'), isFalse);
      expect(
        repository.savedState?.branches
            .progressFor('main_branch')
            .assignedManagerId,
        isNull,
      );
    },
  );

  test(
    'reaching branch level 20 grants Apprentice exactly once and saves it',
    () async {
      final repository = _RecordingSaveRepository();
      final nowUtc = DateTime.utc(2026, 7, 16);
      final apprentice = Collection2Catalog.masterCardById['staff_apprentice']!;
      final controller =
          GameController(
            config: config,
            saveRepository: repository,
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
            freePurchasesEnabled: true,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              shopProgression: const ShopProgressionState(
                currentShopLevel: 7,
                highestShopLevel: 7,
                unlockedShopIds: {'street_stand', 'doner_chain'},
              ),
              branches: const BranchSystemState(
                branchProgress: {
                  'main_branch': BranchProgress(
                    branchId: 'main_branch',
                    isUnlocked: true,
                    level: 19,
                  ),
                },
              ),
            ),
          );

      expect(controller.state.collection2.masterCardLevel(apprentice.id), 0);
      expect(await controller.levelUpBranch('main_branch'), isTrue);
      expect(controller.state.collection2.masterCardLevel(apprentice.id), 1);
      expect(
        controller.state.branches.claimedBranchMilestones,
        contains(BranchCatalog.firstManagerGrantMarker),
      );
      expect(
        repository.savedState?.collection2.masterCardLevel(apprentice.id),
        1,
      );

      controller.hydrate(controller.state);
      expect(controller.state.collection2.masterCardLevel(apprentice.id), 1);
      expect(controller.state.collection2.masterCardCount(apprentice.id), 0);
    },
  );

  test(
    'level 20 migration does not grant Apprentice when staff is unlocked',
    () {
      final nowUtc = DateTime.utc(2026, 7, 16);
      final controller =
          GameController(
            config: config,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              collection2: const Collection2State(
                masterCards: {'staff_journeyman': 0},
                masterCardLevels: {'staff_journeyman': 1},
              ),
              branches: const BranchSystemState(
                branchProgress: {
                  'main_branch': BranchProgress(
                    branchId: 'main_branch',
                    isUnlocked: true,
                    level: 20,
                  ),
                },
              ),
            ),
          );

      expect(
        controller.state.collection2.masterCardLevel('staff_apprentice'),
        0,
      );
      expect(
        controller.state.branches.claimedBranchMilestones,
        contains(BranchCatalog.firstManagerGrantMarker),
      );
    },
  );

  test(
    'prestige preserves manager assignment and first-manager grant marker',
    () async {
      final nowUtc = DateTime.utc(2026, 7, 16);
      final controller =
          GameController(
            config: config,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              prestige: PrestigeState(runCashEarned: config.prestigeThreshold),
              collection2: const Collection2State(
                masterCards: {'staff_apprentice': 0},
                masterCardLevels: {'staff_apprentice': 1},
              ),
              branches: const BranchSystemState(
                branchProgress: {
                  'main_branch': BranchProgress(
                    branchId: 'main_branch',
                    isUnlocked: true,
                    level: 20,
                    assignedManagerId: 'staff_apprentice',
                  ),
                },
              ),
            ),
          );

      expect(await controller.applyPrestige(), isTrue);
      expect(
        controller.state.branches.progressFor('main_branch').assignedManagerId,
        'staff_apprentice',
      );
      expect(
        controller.state.branches.claimedBranchMilestones,
        contains(BranchCatalog.firstManagerGrantMarker),
      );
      expect(
        controller.state.collection2.masterCardLevel('staff_apprentice'),
        1,
      );
    },
  );

  test('goal eligibility blocks locked customer systems', () {
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final state = GameState.initial(config, nowUtc: nowUtc).copyWith(
      customerOrders: const CustomerSystemState(unlockedCustomerTypeIds: {}),
    );
    const engine = GoalEngine();

    expect(
      engine.isGoalEligible(
        GoalCatalog.byId['daily_customer_orders_2']!,
        state,
        config: config,
      ),
      isFalse,
    );
  });
}

EconomyConfig _activePlayConfig({
  int baseTapValue = 1,
  double criticalBaseChance = 0.03,
  double criticalMaxChance = 0.40,
}) {
  final config = EconomyConfig.standard();
  return EconomyConfig(
    baseTapValue: baseTapValue,
    offlineCap: config.offlineCap,
    prestigeThreshold: config.prestigeThreshold,
    prestigeBonusPerPoint: config.prestigeBonusPerPoint,
    upgrades: config.upgrades,
    criticalBaseChance: criticalBaseChance,
    criticalMaxChance: criticalMaxChance,
  );
}

class _RecordingSaveRepository implements SaveRepository {
  GameState? _state;

  GameState? get savedState => _state;

  @override
  Future<void> clear() async {
    _state = null;
  }

  @override
  Future<GameState?> load(EconomyConfig config) async => _state;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }
}

class _DelayedSaveRepository implements SaveRepository {
  final List<GameState> savedStates = [];
  int _saveCount = 0;

  @override
  Future<void> clear() async {
    savedStates.clear();
  }

  @override
  Future<GameState?> load(EconomyConfig config) async => null;

  @override
  Future<void> save(GameState state) async {
    _saveCount += 1;
    final delay = _saveCount == 1
        ? const Duration(milliseconds: 40)
        : Duration.zero;
    await Future<void>.delayed(delay);
    savedStates.add(state);
  }
}

class _FixedRandom implements math.Random {
  const _FixedRandom(this.value);

  final double value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => (value * max).floor().clamp(0, max - 1);
}

GoalSystemState _goalsWithDaily(DateTime nowUtc, GoalProgress dailyGoal) {
  return GoalSystemState(
    activeDailyGoals: [dailyGoal],
    lastDailyResetDate: goalLocalDateKey(nowUtc),
    lastWeeklyResetWeek: goalIsoWeekKey(nowUtc),
  );
}
