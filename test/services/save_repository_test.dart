import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taptapdoner/domain/branches/branch_models.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/goals/goal_models.dart';
import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/progression/prestige_shop_catalog.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/services/save/shared_preferences_save_repository.dart';

void main() {
  final config = EconomyConfig.standard();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save repository round-trips state', () async {
    final knife = config.upgrade(UpgradeId.knife);
    final repository = SharedPreferencesSaveRepository();
    final quests =
        Map<String, QuestProgress>.from(StarterQuestCatalog.initialProgress())
          ..['starter_tap_10'] = const QuestProgress(
            questId: 'starter_tap_10',
            status: QuestStatus.claimed,
            currentValue: 10,
            targetValue: 10,
            rewardClaimed: true,
          );
    final state =
        GameState.initial(
          config,
          nowUtc: DateTime.utc(2026, 4, 1, 12),
          localeCode: 'tr',
        ).copyWith(
          cash: 1234,
          pendingOfflineCash: 87,
          prestige: const PrestigeState(
            reputation: 4,
            unspentPrestigePoints: 2,
            prestigeCount: 1,
            runCashEarned: 7500,
            purchasedPrestigeUpgrades: {PrestigeShopCatalog.masterHand: 1},
          ),
          milestones: const MilestoneState(
            claimedMilestoneKeys: {'knife_rusty_knife_5'},
            unlockedFeatureKeys: {'critical_cut'},
            tapBonusPercent: 0.05,
            chests: 1,
          ),
          stats: const GameStatsState(
            tapCount: 12,
            totalUpgradesPurchased: 1,
            criticalCutCount: 2,
            maxCombo: 4,
          ),
          goldenDoner: GoldenDonerState(
            activeUntilUtc: DateTime.utc(2026, 4, 1, 12, 0, 5),
            nextSpawnAtUtc: DateTime.utc(2026, 4, 1, 12, 2),
            lastSpawnAtUtc: DateTime.utc(2026, 4, 1, 12),
            requiredHits: 10,
            currentHits: 3,
            rewardPreview: 500,
          ),
          quests: quests,
          achievements: {
            for (final entry in GameState.initial(config).achievements.entries)
              entry.key: entry.key == 'tap_10'
                  ? const AchievementProgress(
                      achievementId: 'tap_10',
                      currentValue: 10,
                      isCompleted: true,
                      isRewardClaimed: true,
                    )
                  : entry.value,
          },
          collection: const CollectionState(
            unlockedItemIds: {'knife_rusty_knife'},
            claimedBonusItemIds: {'knife_rusty_knife'},
          ),
          collection2: const Collection2State(
            recipeShards: {'recipe_chicken_doner': 4},
            recipeLevels: {'recipe_chicken_doner': 1},
            staffCards: {'staff_apprentice': 2},
            staffCardLevels: {'staff_apprentice': 1},
            decorShards: {'decor_new_sign': 3},
            unlockedDecorIds: {'decor_new_sign'},
            equippedDecorIds: {'decor_new_sign'},
            knifeSkinShards: {'knife_skin_rusty': 1},
            unlockedKnifeSkinIds: {'knife_skin_rusty'},
            equippedKnifeSkinId: 'knife_skin_rusty',
            claimedSetBonuses: {'street_set'},
            prestigeShards: 6,
          ),
          chestInventory: const ChestInventoryState(
            counts: {ChestType.small: 2, ChestType.master: 1},
          ),
          shopProgression: const ShopProgressionState(
            currentShopLevel: 2,
            highestShopLevel: 3,
            unlockedShopIds: {
              'street_stand',
              'small_buffet',
              'neighborhood_doner',
            },
          ),
          goals: const GoalSystemState(
            activeDailyGoals: [
              GoalProgress(
                goalId: 'daily_tap_300',
                currentValue: 12,
                targetValue: 300,
                generatedAtMillis: 1775044800000,
                expiresAtMillis: 1775131200000,
              ),
            ],
            activeWeeklyGoals: [
              GoalProgress(
                goalId: 'weekly_tap_5000',
                currentValue: 1000,
                targetValue: 5000,
                generatedAtMillis: 1775044800000,
                expiresAtMillis: 1775476800000,
              ),
            ],
            activePrestigeRunGoals: [
              GoalProgress(
                goalId: 'run_earn_100000',
                currentValue: 7500,
                targetValue: 100000,
                generatedAtMillis: 1775044800000,
              ),
            ],
            activeEventGoals: [
              GoalProgress(
                goalId: 'event_complete_1',
                currentValue: 0,
                targetValue: 1,
                generatedAtMillis: 1775044800000,
              ),
            ],
            lastDailyResetDate: '2026-04-01',
            lastWeeklyResetWeek: '2026-W14',
            runGoalPrestigeCount: 1,
          ),
          branches: const BranchSystemState(
            branchProgress: {
              'main_branch': BranchProgress(
                branchId: 'main_branch',
                isUnlocked: true,
                level: 12,
                assignedManagerId: 'staff_apprentice',
              ),
              'neighborhood_branch': BranchProgress(
                branchId: 'neighborhood_branch',
              ),
            },
            unlockedRegionIds: {'local'},
            claimedBranchMilestones: {'main_branch:10'},
            totalBranchIncomeEarned: 123.5,
          ),
          upgrades: {
            for (final definition in config.upgrades)
              definition.id: definition.id == UpgradeId.knife
                  ? UpgradeState.fromTotalLevel(
                      definition: knife,
                      totalLevel: 30,
                    )
                  : UpgradeState.fromTotalLevel(
                      definition: definition,
                      totalLevel: 0,
                    ),
          },
        );

    await repository.save(state);
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('taptapdoner.save')!;
    final loaded = await repository.load(config);

    expect(raw, contains('"id":"knife"'));
    expect(raw, contains('"itemIndex":1'));
    expect(raw, contains('"level":6'));
    expect(raw, contains('"claimedMilestones":["knife_rusty_knife_5"]'));
    expect(raw, contains('"tapCount":12'));
    expect(raw, contains('"goldenDoner"'));
    expect(raw, contains('"currentHits":3'));
    expect(raw, contains('"questId":"starter_tap_10"'));
    expect(raw, contains('"rewardClaimed":true'));
    expect(raw, contains('"achievementId":"tap_10"'));
    expect(raw, contains('"collection"'));
    expect(raw, contains('"collection2"'));
    expect(raw, contains('"recipe_chicken_doner"'));
    expect(raw, contains('"chestInventory"'));
    expect(raw, contains('"shopProgression"'));
    expect(raw, contains('"goals"'));
    expect(raw, contains('"daily_tap_300"'));
    expect(raw, contains('"branches"'));
    expect(raw, contains('"main_branch"'));
    expect(raw, contains('"totalBranchIncomeEarned":123.5'));
    expect(raw, contains('"unspentPrestigePoints":2'));
    expect(raw, contains('"master_hand":1'));
    expect(raw, isNot(contains('stations')));
    expect(raw, isNot(contains('baseCost')));
    expect(raw, isNot(contains('tiers')));
    expect(loaded, isNotNull);
    expect(loaded!.cash, 1234);
    expect(loaded.pendingOfflineCash, 87);
    expect(loaded.localeCode, 'tr');
    expect(loaded.prestige.totalPrestigePoints, 4);
    expect(loaded.prestige.unspentPrestigePoints, 2);
    expect(loaded.prestige.prestigeCount, 1);
    expect(
      loaded.prestige.prestigeUpgradeLevel(PrestigeShopCatalog.masterHand),
      1,
    );
    expect(loaded.prestige.runCashEarned, 7500);
    expect(loaded.upgrade(UpgradeId.knife).itemIndex, 1);
    expect(loaded.upgrade(UpgradeId.knife).level, 6);
    expect(
      loaded.milestones.claimedMilestoneKeys,
      contains('knife_rusty_knife_5'),
    );
    expect(loaded.milestones.unlockedFeatureKeys, contains('critical_cut'));
    expect(loaded.milestones.tapBonusPercent, closeTo(0.05, 0.0001));
    expect(loaded.milestones.chests, 1);
    expect(loaded.stats.tapCount, 12);
    expect(loaded.stats.totalUpgradesPurchased, 1);
    expect(loaded.stats.criticalCutCount, 2);
    expect(loaded.stats.maxCombo, 4);
    expect(loaded.goldenDoner.currentHits, 3);
    expect(loaded.goldenDoner.requiredHits, 10);
    expect(loaded.goldenDoner.rewardPreview, 500);
    expect(
      loaded.goldenDoner.activeUntilUtc,
      DateTime.utc(2026, 4, 1, 12, 0, 5),
    );
    expect(loaded.quests['starter_tap_10']?.status, QuestStatus.claimed);
    expect(loaded.quests['starter_tap_10']?.rewardClaimed, isTrue);
    expect(loaded.achievements['tap_10']?.isRewardClaimed, isTrue);
    expect(loaded.collection.unlockedItemIds, contains('knife_rusty_knife'));
    expect(
      loaded.collection.claimedBonusItemIds,
      contains('knife_rusty_knife'),
    );
    expect(loaded.collection2.recipeShards['recipe_chicken_doner'], 4);
    expect(loaded.collection2.recipeLevels['recipe_chicken_doner'], 1);
    expect(loaded.collection2.staffCards['staff_apprentice'], 2);
    expect(loaded.collection2.staffCardLevels['staff_apprentice'], 1);
    expect(loaded.collection2.unlockedDecorIds, contains('decor_new_sign'));
    expect(loaded.collection2.equippedDecorIds, contains('decor_new_sign'));
    expect(
      loaded.collection2.unlockedKnifeSkinIds,
      contains('knife_skin_rusty'),
    );
    expect(loaded.collection2.equippedKnifeSkinId, 'knife_skin_rusty');
    expect(loaded.collection2.claimedSetBonuses, contains('street_set'));
    expect(loaded.collection2.prestigeShards, 6);
    expect(loaded.chestInventory.count(ChestType.small), 2);
    expect(loaded.chestInventory.count(ChestType.master), 1);
    expect(loaded.shopProgression.currentShopLevel, 2);
    expect(loaded.shopProgression.highestShopLevel, 3);
    expect(
      loaded.shopProgression.unlockedShopIds,
      contains('neighborhood_doner'),
    );
    expect(loaded.goals.activeDailyGoals.single.goalId, 'daily_tap_300');
    expect(loaded.goals.activeDailyGoals.single.currentValue, 12);
    expect(loaded.goals.activeWeeklyGoals.single.goalId, 'weekly_tap_5000');
    expect(
      loaded.goals.activePrestigeRunGoals.single.goalId,
      'run_earn_100000',
    );
    expect(loaded.goals.activeEventGoals.single.goalId, 'event_complete_1');
    expect(loaded.goals.lastDailyResetDate, '2026-04-01');
    expect(loaded.goals.lastWeeklyResetWeek, '2026-W14');
    expect(loaded.goals.runGoalPrestigeCount, 1);
    expect(loaded.branches.progressFor('main_branch').isUnlocked, isTrue);
    expect(loaded.branches.progressFor('main_branch').level, 12);
    expect(
      loaded.branches.progressFor('main_branch').assignedManagerId,
      'staff_apprentice',
    );
    expect(loaded.branches.unlockedRegionIds, contains('local'));
    expect(loaded.branches.claimedBranchMilestones, contains('main_branch:10'));
    expect(loaded.branches.totalBranchIncomeEarned, 123.5);
  });

  test('corrupt payload returns null', () async {
    SharedPreferences.setMockInitialValues({'taptapdoner.save': '{bad json'});
    final repository = SharedPreferencesSaveRepository();

    final loaded = await repository.load(config);

    expect(loaded, isNull);
  });

  test(
    'unknown ids and legacy stations are ignored while known upgrades survive',
    () async {
      SharedPreferences.setMockInitialValues({
        'taptapdoner.save':
            '''
      {
        "schemaVersion": 1,
        "cash": 0,
        "lifetimeCash": 0,
        "pendingOfflineCash": 0,
        "stations": [
          {"id":"donerSpit","level":3},
          {"id":"futureStation","level":9}
        ],
        "upgrades": [
          {"id":"${config.upgrades.first.id.key}","purchased":true},
          {"id":"futureUpgrade","purchased":true}
        ],
        "prestige": {"reputation": 0, "runCashEarned": 0},
        "rush": {},
        "lastActiveAtUtc": "2026-04-01T12:00:00.000Z",
        "lastSavedAtUtc": "2026-04-01T12:00:00.000Z",
        "localeCode": "en"
      }
      ''',
      });
      final repository = SharedPreferencesSaveRepository();

      final loaded = await repository.load(config);

      expect(loaded, isNotNull);
      expect(loaded!.toJson().containsKey('stations'), isFalse);
      expect(loaded.upgrade(config.upgrades.first.id).purchased, isTrue);
    },
  );

  test('missing upgrade list creates default upgrade progress', () async {
    SharedPreferences.setMockInitialValues({
      'taptapdoner.save': '''
      {
        "schemaVersion": 3,
        "cash": 55,
        "lifetimeCash": 55,
        "pendingOfflineCash": 0,
        "stations": [],
        "prestige": {"reputation": 4, "runCashEarned": 500},
        "rush": {},
        "lastActiveAtUtc": "2026-04-01T12:00:00.000Z",
        "lastSavedAtUtc": "2026-04-01T12:00:00.000Z",
        "localeCode": "en"
      }
      ''',
    });
    final repository = SharedPreferencesSaveRepository();

    final loaded = await repository.load(config);

    expect(loaded, isNotNull);
    expect(loaded!.cash, 55);
    for (final upgrade in config.upgrades) {
      expect(loaded.upgrade(upgrade.id).itemIndex, 0, reason: upgrade.id.key);
      expect(loaded.upgrade(upgrade.id).level, 1, reason: upgrade.id.key);
    }
  });

  test(
    'invalid upgrade progress is clamped and unknown tracks are ignored',
    () async {
      SharedPreferences.setMockInitialValues({
        'taptapdoner.save': '''
      {
        "schemaVersion": 3,
        "cash": 0,
        "lifetimeCash": 0,
        "pendingOfflineCash": 0,
        "stations": [],
        "upgrades": [
          {"id":"knife","itemIndex":-4,"level":0},
          {"id":"oven","itemIndex":999,"level":999},
          {"id":"staff","itemIndex":1,"level":999},
          {"id":"futureUpgrade","itemIndex":1,"level":4}
        ],
        "prestige": {"reputation": 0, "runCashEarned": 0},
        "rush": {},
        "lastActiveAtUtc": "2026-04-01T12:00:00.000Z",
        "lastSavedAtUtc": "2026-04-01T12:00:00.000Z",
        "localeCode": "en"
      }
      ''',
      });
      final repository = SharedPreferencesSaveRepository();

      final loaded = await repository.load(config);

      expect(loaded, isNotNull);
      expect(loaded!.upgrade(UpgradeId.knife).itemIndex, 0);
      expect(loaded.upgrade(UpgradeId.knife).level, 1);
      expect(
        loaded.upgrade(UpgradeId.oven).itemIndex,
        config.upgrade(UpgradeId.oven).items.length - 1,
      );
      expect(
        loaded.upgrade(UpgradeId.oven).level,
        config.upgrade(UpgradeId.oven).items.last.maxLevel,
      );
      expect(loaded.upgrade(UpgradeId.staff).itemIndex, 1);
      expect(
        loaded.upgrade(UpgradeId.staff).level,
        config.upgrade(UpgradeId.staff).items[1].maxLevel,
      );
      expect(loaded.upgrade(UpgradeId.menu).itemIndex, 0);
      expect(loaded.upgrade(UpgradeId.menu).level, 1);
    },
  );

  test(
    'old upgrade saves migrate without losing money or prestige data',
    () async {
      SharedPreferences.setMockInitialValues({
        'taptapdoner.save': '''
      {
        "schemaVersion": 2,
        "cash": 12345,
        "lifetimeCash": 999999,
        "pendingOfflineCash": 432,
        "stations": [],
        "upgrades": [
          {"id":"knife","level":10},
          {"id":"rushTraining","purchased":true}
        ],
        "prestige": {"reputation": 7, "runCashEarned": 7654321},
        "rush": {},
        "lastActiveAtUtc": "2026-04-01T12:00:00.000Z",
        "lastSavedAtUtc": "2026-04-01T12:00:00.000Z",
        "localeCode": "tr"
      }
      ''',
      });
      final repository = SharedPreferencesSaveRepository();

      final loaded = await repository.load(config);

      expect(loaded, isNotNull);
      expect(loaded!.cash, 12345);
      expect(loaded.lifetimeCash, 999999);
      expect(loaded.pendingOfflineCash, 432);
      expect(loaded.prestige.reputation, 7);
      expect(loaded.prestige.runCashEarned, 7654321);
      expect(loaded.localeCode, 'tr');
      expect(loaded.upgrade(UpgradeId.knife).itemIndex, 0);
      expect(loaded.upgrade(UpgradeId.knife).level, 10);
      expect(loaded.upgrade(UpgradeId.turbo).itemIndex, 0);
      expect(loaded.upgrade(UpgradeId.turbo).level, 2);
    },
  );
}
