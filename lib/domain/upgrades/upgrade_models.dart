enum UpgradeTrackType { knife, oven, staff, menu, turbo, offline }

enum UpgradeEffectType {
  tapMultiplier,
  globalIncomeMultiplier,
  passiveIncome,
  menuMultiplier,
  turboMultiplier,
  offlineEfficiency,
}

const defaultUpgradeMilestoneRewards = [
  MilestoneReward(level: 5, labelKey: 'milestone_5'),
  MilestoneReward(level: 10, labelKey: 'milestone_10'),
  MilestoneReward(level: 15, labelKey: 'milestone_15'),
  MilestoneReward(level: 20, labelKey: 'milestone_20'),
  MilestoneReward(level: 25, labelKey: 'milestone_25'),
];

class MilestoneReward {
  const MilestoneReward({required this.level, required this.labelKey})
    : assert(level >= 1, 'level must be at least 1.');

  final int level;
  final String labelKey;
}

class UpgradeTrack {
  const UpgradeTrack({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.effectType,
    required this.itemIndex,
    required this.level,
    required this.tiers,
  }) : assert(itemIndex >= 0, 'itemIndex cannot be negative.'),
       assert(level >= 1, 'level must be at least 1.');

  final String id;
  final String title;
  final String description;
  final UpgradeTrackType type;
  final UpgradeEffectType effectType;

  /// Current item index in the item chain.
  /// Example: 0 = Pasli Bicak, 1 = Keskin Bicak.
  final int itemIndex;

  /// Current level of the active item.
  /// Must be between 1 and the current tier maxLevel.
  final int level;

  final List<UpgradeItemTier> tiers;

  UpgradeTrack copyWith({
    String? id,
    String? title,
    String? description,
    UpgradeTrackType? type,
    UpgradeEffectType? effectType,
    int? itemIndex,
    int? level,
    List<UpgradeItemTier>? tiers,
  }) {
    return UpgradeTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      effectType: effectType ?? this.effectType,
      itemIndex: itemIndex ?? this.itemIndex,
      level: level ?? this.level,
      tiers: tiers ?? this.tiers,
    );
  }
}

class UpgradeItemTier {
  const UpgradeItemTier({
    required this.id,
    required this.name,
    required this.description,
    required this.iconKey,
    required this.tier,
    required this.iconPath,
    required this.baseCost,
    required this.costMultiplier,
    required this.baseEffect,
    required this.levelEffect,
    this.maxLevel = 25,
    this.milestoneRewards = defaultUpgradeMilestoneRewards,
  }) : assert(baseCost >= 0, 'baseCost cannot be negative.'),
       assert(costMultiplier > 0, 'costMultiplier must be positive.'),
       assert(maxLevel >= 1, 'maxLevel must be at least 1.'),
       assert(tier >= 1, 'tier must be at least 1.');

  final String id;
  final String name;
  final String description;
  final String iconKey;
  final int tier;
  final String iconPath;

  /// First upgrade cost of this item.
  final double baseCost;

  /// Cost multiplier inside the same item.
  final double costMultiplier;

  /// Base effect of item at Lv.1.
  final double baseEffect;

  /// Additional effect gained per level.
  final double levelEffect;

  final int maxLevel;
  final List<MilestoneReward> milestoneRewards;
}
