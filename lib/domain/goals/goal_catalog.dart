import 'package:taptapdoner/domain/goals/goal_models.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';

abstract final class GoalCatalog {
  static const dailyGoalCount = 3;
  static const weeklyGoalCount = 5;
  static const prestigeRunGoalCount = 3;
  static const eventGoalCount = 2;

  static const dailyGoals = <GoalDefinition>[
    GoalDefinition(
      id: 'daily_tap_300',
      title: 'Cut 300 Doners',
      description: 'Cut 300 doners today.',
      category: GoalCategory.daily,
      objectiveType: GoalObjectiveType.tapCount,
      targetValue: 300,
      weight: 8,
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 300),
        GoalReward(type: GoalRewardType.reputation, amount: 5),
      ],
    ),
    GoalDefinition(
      id: 'daily_buy_upgrade_5',
      title: 'Buy 5 Upgrades',
      description: 'Buy any 5 upgrades today.',
      category: GoalCategory.daily,
      objectiveType: GoalObjectiveType.buyUpgrades,
      targetValue: 5,
      weight: 7,
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 450),
        GoalReward(type: GoalRewardType.reputation, amount: 5),
      ],
    ),
    GoalDefinition(
      id: 'daily_customer_orders_2',
      title: 'Serve 2 Customers',
      description: 'Complete 2 customer orders today.',
      category: GoalCategory.daily,
      objectiveType: GoalObjectiveType.completeCustomerOrders,
      targetValue: 2,
      weight: 5,
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 600),
        GoalReward(type: GoalRewardType.reputation, amount: 10),
      ],
    ),
    GoalDefinition(
      id: 'daily_open_chest_1',
      title: 'Open 1 Chest',
      description: 'Open any chest today.',
      category: GoalCategory.daily,
      objectiveType: GoalObjectiveType.openChests,
      targetValue: 1,
      weight: 3,
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 500),
        GoalReward(type: GoalRewardType.reputation, amount: 5),
      ],
    ),
    GoalDefinition(
      id: 'daily_critical_10',
      title: 'Land 10 Critical Cuts',
      description: 'Trigger 10 critical cuts today.',
      category: GoalCategory.daily,
      objectiveType: GoalObjectiveType.triggerCritical,
      targetValue: 10,
      weight: 4,
      requiredFeatureKeys: {'critical_cut'},
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 700),
        GoalReward(type: GoalRewardType.reputation, amount: 8),
      ],
    ),
    GoalDefinition(
      id: 'daily_combo_20',
      title: 'Reach 20 Combo',
      description: 'Reach a 20 combo today.',
      category: GoalCategory.daily,
      objectiveType: GoalObjectiveType.reachCombo,
      targetValue: 20,
      weight: 4,
      requiredFeatureKeys: {'combo'},
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 650),
        GoalReward(type: GoalRewardType.reputation, amount: 8),
      ],
    ),
    GoalDefinition(
      id: 'daily_reputation_50',
      title: 'Gain 50 Reputation',
      description: 'Gain 50 customer reputation today.',
      category: GoalCategory.daily,
      objectiveType: GoalObjectiveType.gainReputation,
      targetValue: 50,
      weight: 3,
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 900),
        GoalReward(
          type: GoalRewardType.chest,
          amount: 1,
          chestType: ChestType.staff,
        ),
      ],
    ),
    GoalDefinition(
      id: 'daily_unlock_branch_1',
      title: 'Open 1 Branch',
      description: 'Open any branch today.',
      category: GoalCategory.daily,
      objectiveType: GoalObjectiveType.unlockBranches,
      targetValue: 1,
      minShopLevel: 7,
      minPrestigeCount: 1,
      weight: 3,
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 2500),
        GoalReward(type: GoalRewardType.reputation, amount: 20),
      ],
    ),
    GoalDefinition(
      id: 'daily_branch_level_3',
      title: 'Upgrade Branches 3 Times',
      description: 'Buy 3 branch levels today.',
      category: GoalCategory.daily,
      objectiveType: GoalObjectiveType.upgradeBranchLevels,
      targetValue: 3,
      minShopLevel: 7,
      minPrestigeCount: 1,
      weight: 3,
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 3000),
        GoalReward(type: GoalRewardType.staffCardShard, amount: 2),
      ],
    ),
  ];

  static const weeklyGoals = <GoalDefinition>[
    GoalDefinition(
      id: 'weekly_tap_5000',
      title: 'Cut 5,000 Doners',
      description: 'Cut 5,000 doners this week.',
      category: GoalCategory.weekly,
      objectiveType: GoalObjectiveType.tapCount,
      targetValue: 5000,
      weight: 8,
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 5000),
        GoalReward(type: GoalRewardType.reputation, amount: 30),
      ],
    ),
    GoalDefinition(
      id: 'weekly_customer_orders_50',
      title: 'Serve 50 Customers',
      description: 'Complete 50 customer orders this week.',
      category: GoalCategory.weekly,
      objectiveType: GoalObjectiveType.completeCustomerOrders,
      targetValue: 50,
      weight: 5,
      rewards: [
        GoalReward(
          type: GoalRewardType.chest,
          amount: 1,
          chestType: ChestType.staff,
        ),
        GoalReward(type: GoalRewardType.reputation, amount: 50),
      ],
    ),
    GoalDefinition(
      id: 'weekly_open_chests_20',
      title: 'Open 20 Chests',
      description: 'Open 20 chests this week.',
      category: GoalCategory.weekly,
      objectiveType: GoalObjectiveType.openChests,
      targetValue: 20,
      weight: 4,
      rewards: [
        GoalReward(
          type: GoalRewardType.chest,
          amount: 1,
          chestType: ChestType.prestige,
        ),
      ],
    ),
    GoalDefinition(
      id: 'weekly_do_prestige_1',
      title: 'Do 1 Prestige',
      description: 'Prestige once this week.',
      category: GoalCategory.weekly,
      objectiveType: GoalObjectiveType.doPrestige,
      targetValue: 1,
      weight: 2,
      rewards: [
        GoalReward(
          type: GoalRewardType.chest,
          amount: 1,
          chestType: ChestType.gold,
        ),
        GoalReward(type: GoalRewardType.prestigePoint, amount: 1),
      ],
    ),
    GoalDefinition(
      id: 'weekly_milestones_3',
      title: 'Complete 3 Milestones',
      description: 'Complete 3 upgrade milestones this week.',
      category: GoalCategory.weekly,
      objectiveType: GoalObjectiveType.completeMilestones,
      targetValue: 3,
      weight: 5,
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 3500),
        GoalReward(
          type: GoalRewardType.chest,
          amount: 1,
          chestType: ChestType.recipe,
        ),
      ],
    ),
    GoalDefinition(
      id: 'weekly_reputation_500',
      title: 'Gain 500 Reputation',
      description: 'Gain 500 customer reputation this week.',
      category: GoalCategory.weekly,
      objectiveType: GoalObjectiveType.gainReputation,
      targetValue: 500,
      weight: 3,
      rewards: [
        GoalReward(
          type: GoalRewardType.chest,
          amount: 1,
          chestType: ChestType.decor,
        ),
        GoalReward(type: GoalRewardType.reputation, amount: 75),
      ],
    ),
    GoalDefinition(
      id: 'weekly_critical_100',
      title: 'Land 100 Critical Cuts',
      description: 'Trigger 100 critical cuts this week.',
      category: GoalCategory.weekly,
      objectiveType: GoalObjectiveType.triggerCritical,
      targetValue: 100,
      weight: 4,
      requiredFeatureKeys: {'critical_cut'},
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 4000),
        GoalReward(type: GoalRewardType.reputation, amount: 40),
      ],
    ),
    GoalDefinition(
      id: 'weekly_branch_total_50',
      title: 'Reach 50 Total Branch Levels',
      description: 'Reach 50 total levels across branches this week.',
      category: GoalCategory.weekly,
      objectiveType: GoalObjectiveType.reachTotalBranchLevel,
      targetValue: 50,
      minShopLevel: 7,
      minPrestigeCount: 1,
      weight: 3,
      rewards: [
        GoalReward(type: GoalRewardType.reputation, amount: 70),
        GoalReward(type: GoalRewardType.prestigeShard, amount: 3),
      ],
    ),
    GoalDefinition(
      id: 'weekly_branch_milestones_2',
      title: 'Reach 2 Branch Milestones',
      description: 'Reach 2 branch level milestones this week.',
      category: GoalCategory.weekly,
      objectiveType: GoalObjectiveType.reachBranchMilestones,
      targetValue: 2,
      minShopLevel: 7,
      minPrestigeCount: 1,
      weight: 2,
      rewards: [
        GoalReward(type: GoalRewardType.reputation, amount: 80),
        GoalReward(type: GoalRewardType.staffCardShard, amount: 4),
      ],
    ),
    GoalDefinition(
      id: 'weekly_complete_branch_region_1',
      title: 'Complete 1 Region',
      description: 'Unlock every branch in a region this week.',
      category: GoalCategory.weekly,
      objectiveType: GoalObjectiveType.completeBranchRegions,
      targetValue: 1,
      minShopLevel: 7,
      minPrestigeCount: 1,
      weight: 1,
      rewards: [
        GoalReward(type: GoalRewardType.reputation, amount: 120),
        GoalReward(type: GoalRewardType.prestigePoint, amount: 1),
      ],
    ),
  ];

  static const prestigeRunGoals = <GoalDefinition>[
    GoalDefinition(
      id: 'run_earn_100000',
      title: 'Earn 100,000 This Run',
      description: 'Earn 100,000 cash before the next prestige.',
      category: GoalCategory.prestigeRun,
      objectiveType: GoalObjectiveType.earnMoney,
      targetValue: 100000,
      minPrestigeCount: 1,
      weight: 5,
      rewards: [
        GoalReward(type: GoalRewardType.prestigePoint, amount: 1),
        GoalReward(type: GoalRewardType.reputation, amount: 25),
      ],
    ),
    GoalDefinition(
      id: 'run_customer_orders_5',
      title: 'Serve 5 Customers This Run',
      description: 'Complete 5 customer orders before the next prestige.',
      category: GoalCategory.prestigeRun,
      objectiveType: GoalObjectiveType.completeCustomerOrders,
      targetValue: 5,
      minPrestigeCount: 1,
      weight: 4,
      rewards: [
        GoalReward(type: GoalRewardType.reputation, amount: 35),
        GoalReward(
          type: GoalRewardType.chest,
          amount: 1,
          chestType: ChestType.prestige,
        ),
      ],
    ),
    GoalDefinition(
      id: 'run_combo_100',
      title: 'Reach 100 Combo This Run',
      description: 'Reach a 100 combo before the next prestige.',
      category: GoalCategory.prestigeRun,
      objectiveType: GoalObjectiveType.reachCombo,
      targetValue: 100,
      minPrestigeCount: 1,
      weight: 3,
      requiredFeatureKeys: {'combo'},
      rewards: [
        GoalReward(type: GoalRewardType.reputation, amount: 30),
        GoalReward(
          type: GoalRewardType.temporaryBoost,
          amount: 2,
          durationSeconds: 120,
        ),
      ],
    ),
    GoalDefinition(
      id: 'run_milestones_10',
      title: 'Complete 10 Milestones This Run',
      description: 'Complete 10 upgrade milestones before the next prestige.',
      category: GoalCategory.prestigeRun,
      objectiveType: GoalObjectiveType.completeMilestones,
      targetValue: 10,
      minPrestigeCount: 1,
      weight: 4,
      rewards: [
        GoalReward(type: GoalRewardType.reputation, amount: 40),
        GoalReward(
          type: GoalRewardType.chest,
          amount: 1,
          chestType: ChestType.decor,
        ),
      ],
    ),
    GoalDefinition(
      id: 'run_branch_levels_10',
      title: 'Buy 10 Branch Levels This Run',
      description: 'Buy 10 branch levels before the next prestige.',
      category: GoalCategory.prestigeRun,
      objectiveType: GoalObjectiveType.upgradeBranchLevels,
      targetValue: 10,
      minShopLevel: 7,
      minPrestigeCount: 1,
      weight: 3,
      rewards: [
        GoalReward(type: GoalRewardType.reputation, amount: 60),
        GoalReward(type: GoalRewardType.prestigeShard, amount: 4),
      ],
    ),
    GoalDefinition(
      id: 'run_assign_branch_manager_1',
      title: 'Assign 1 Branch Manager',
      description: 'Assign a staff card as a branch manager this run.',
      category: GoalCategory.prestigeRun,
      objectiveType: GoalObjectiveType.assignBranchManager,
      targetValue: 1,
      minShopLevel: 7,
      minPrestigeCount: 1,
      weight: 1,
      rewards: [
        GoalReward(type: GoalRewardType.reputation, amount: 75),
        GoalReward(type: GoalRewardType.money, amount: 5000),
      ],
    ),
  ];

  static const eventGoals = <GoalDefinition>[
    GoalDefinition(
      id: 'event_cut_100',
      title: 'Event Cuts',
      description: 'Cut 100 doners during an active event.',
      category: GoalCategory.event,
      objectiveType: GoalObjectiveType.tapCount,
      targetValue: 100,
      weight: 4,
      requiredFeatureKeys: {'events'},
      rewards: [
        GoalReward(type: GoalRewardType.money, amount: 1000),
        GoalReward(type: GoalRewardType.reputation, amount: 15),
      ],
    ),
    GoalDefinition(
      id: 'event_complete_1',
      title: 'Complete 1 Event',
      description: 'Complete an active event objective.',
      category: GoalCategory.event,
      objectiveType: GoalObjectiveType.completeEvent,
      targetValue: 1,
      weight: 3,
      requiredFeatureKeys: {'events'},
      rewards: [
        GoalReward(
          type: GoalRewardType.chest,
          amount: 1,
          chestType: ChestType.master,
        ),
      ],
    ),
  ];

  static const allDefinitions = <GoalDefinition>[
    ...dailyGoals,
    ...weeklyGoals,
    ...prestigeRunGoals,
    ...eventGoals,
  ];

  static final byId = Map<String, GoalDefinition>.unmodifiable({
    for (final definition in allDefinitions) definition.id: definition,
  });

  static List<GoalDefinition> definitionsFor(GoalCategory category) {
    return switch (category) {
      GoalCategory.daily => dailyGoals,
      GoalCategory.weekly => weeklyGoals,
      GoalCategory.prestigeRun => prestigeRunGoals,
      GoalCategory.event => eventGoals,
      GoalCategory.starter || GoalCategory.lifetime => const <GoalDefinition>[],
    };
  }
}
