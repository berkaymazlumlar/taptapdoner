import 'dart:math' as math;

import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

enum AchievementCategory {
  tap,
  money,
  upgrade,
  staff,
  offline,
  prestige,
  collection,
  shop,
  event,
}

enum AchievementRewardType {
  cash,
  chest,
  permanentTapBonus,
  permanentPassiveBonus,
  permanentGlobalBonus,
  cosmeticToken,
}

enum ChestType { small, master, gold, recipe, staff, decor, prestige }

enum ChestRewardType {
  money,
  reputation,
  temporaryIncomeBoost,
  cosmeticToken,
  recipeShard,
  staffCardShard,
  decorShard,
  knifeSkinShard,
  prestigeShard,
  permanentTapBonus,
  permanentPassiveBonus,
  permanentGlobalBonus,
}

enum CollectionCategory { knife, staff, oven, menu, offline, badges }

enum Rarity { common, rare, epic, legendary, mythic }

enum PermanentBonusType { tap, passive, global }

class AchievementReward {
  const AchievementReward({
    required this.type,
    this.amount = 0,
    this.chestType,
  });

  final AchievementRewardType type;
  final double amount;
  final ChestType? chestType;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    required this.reward,
    this.isHidden = false,
  }) : assert(targetValue > 0, 'targetValue must be positive.');

  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final double targetValue;
  final AchievementReward reward;
  final bool isHidden;
}

class ChestReward {
  const ChestReward({
    required this.rewardType,
    required this.amount,
    this.durationSeconds,
    this.itemId,
    this.rarity = Rarity.common,
  });

  final ChestRewardType rewardType;
  final double amount;
  final int? durationSeconds;
  final String? itemId;
  final Rarity rarity;
}

class PermanentBonus {
  const PermanentBonus({required this.type, required this.percent});

  final PermanentBonusType type;
  final double percent;
}

class CollectionItem {
  const CollectionItem({
    required this.id,
    required this.category,
    required this.name,
    required this.iconKey,
    required this.rarity,
    required this.unlockCondition,
    this.permanentBonus,
  });

  final String id;
  final CollectionCategory category;
  final String name;
  final String iconKey;
  final Rarity rarity;
  final String unlockCondition;
  final PermanentBonus? permanentBonus;
}

class CollectionBonusTotals {
  const CollectionBonusTotals({
    this.tapBonusPercent = 0,
    this.passiveBonusPercent = 0,
    this.globalBonusPercent = 0,
  });

  final double tapBonusPercent;
  final double passiveBonusPercent;
  final double globalBonusPercent;

  double get tapMultiplier => 1 + math.max(0, tapBonusPercent);
  double get passiveMultiplier => 1 + math.max(0, passiveBonusPercent);
  double get globalMultiplier => 1 + math.max(0, globalBonusPercent);
}

String chestTypeKey(ChestType type) {
  return switch (type) {
    ChestType.small => 'small',
    ChestType.master => 'master',
    ChestType.gold => 'gold',
    ChestType.recipe => 'recipe',
    ChestType.staff => 'staff',
    ChestType.decor => 'decor',
    ChestType.prestige => 'prestige',
  };
}

ChestType? chestTypeFromKey(String key) {
  return switch (key) {
    'small' => ChestType.small,
    'master' => ChestType.master,
    'gold' => ChestType.gold,
    'recipe' => ChestType.recipe,
    'staff' => ChestType.staff,
    'decor' || 'shop' => ChestType.decor,
    'prestige' => ChestType.prestige,
    _ => null,
  };
}

String collectionItemId(UpgradeId upgradeId, String itemKey) {
  return '${upgradeId.key}_$itemKey';
}
