import 'package:taptapdoner/domain/progression/faz5_models.dart';

abstract final class AchievementCatalog {
  static const achievements = <Achievement>[
    Achievement(
      id: 'tap_10',
      title: 'First Cut',
      description: 'Cut 10 doners.',
      category: AchievementCategory.tap,
      targetValue: 10,
      reward: AchievementReward(type: AchievementRewardType.cash, amount: 50),
    ),
    Achievement(
      id: 'tap_100',
      title: 'Fast Hands',
      description: 'Cut 100 doners.',
      category: AchievementCategory.tap,
      targetValue: 100,
      reward: AchievementReward(
        type: AchievementRewardType.chest,
        chestType: ChestType.small,
      ),
    ),
    Achievement(
      id: 'money_100',
      title: 'First 100',
      description: 'Earn 100 cash in total.',
      category: AchievementCategory.money,
      targetValue: 100,
      reward: AchievementReward(type: AchievementRewardType.cash, amount: 100),
    ),
    Achievement(
      id: 'money_1000',
      title: 'Busy Counter',
      description: 'Earn 1,000 cash in total.',
      category: AchievementCategory.money,
      targetValue: 1000,
      reward: AchievementReward(
        type: AchievementRewardType.chest,
        chestType: ChestType.small,
      ),
    ),
    Achievement(
      id: 'upgrade_1',
      title: 'First Upgrade',
      description: 'Buy any upgrade.',
      category: AchievementCategory.upgrade,
      targetValue: 1,
      reward: AchievementReward(type: AchievementRewardType.cash, amount: 75),
    ),
    Achievement(
      id: 'upgrade_10',
      title: 'Kitchen Investor',
      description: 'Buy 10 upgrades.',
      category: AchievementCategory.upgrade,
      targetValue: 10,
      reward: AchievementReward(
        type: AchievementRewardType.chest,
        chestType: ChestType.master,
      ),
    ),
    Achievement(
      id: 'staff_1',
      title: 'First Apprentice',
      description: 'Start passive income with staff.',
      category: AchievementCategory.staff,
      targetValue: 1,
      reward: AchievementReward(type: AchievementRewardType.cash, amount: 150),
    ),
    Achievement(
      id: 'combo_15',
      title: 'Combo Cook',
      description: 'Reach a 15 combo.',
      category: AchievementCategory.event,
      targetValue: 15,
      reward: AchievementReward(type: AchievementRewardType.cash, amount: 200),
    ),
    Achievement(
      id: 'critical_3',
      title: 'Sharp Timing',
      description: 'Land 3 critical cuts.',
      category: AchievementCategory.event,
      targetValue: 3,
      reward: AchievementReward(type: AchievementRewardType.cash, amount: 250),
    ),
    Achievement(
      id: 'chest_1',
      title: 'Chest Opener',
      description: 'Open 1 chest.',
      category: AchievementCategory.event,
      targetValue: 1,
      reward: AchievementReward(type: AchievementRewardType.cash, amount: 300),
    ),
    Achievement(
      id: 'collection_5',
      title: 'Collector',
      description: 'Unlock 5 collection items.',
      category: AchievementCategory.collection,
      targetValue: 5,
      reward: AchievementReward(
        type: AchievementRewardType.permanentGlobalBonus,
        amount: 0.01,
      ),
    ),
    Achievement(
      id: 'prestige_1',
      title: 'Fresh Start',
      description: 'Earn your first reputation point.',
      category: AchievementCategory.prestige,
      targetValue: 1,
      reward: AchievementReward(
        type: AchievementRewardType.permanentTapBonus,
        amount: 0.01,
      ),
    ),
  ];

  static final byId = Map<String, Achievement>.unmodifiable({
    for (final achievement in achievements) achievement.id: achievement,
  });
}
