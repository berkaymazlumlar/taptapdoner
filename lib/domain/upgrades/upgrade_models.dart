enum UpgradeTrackType { knife, oven, staff, menu, turbo, offline }

enum UpgradeEffectType {
  tapMultiplier,
  globalIncomeMultiplier,
  passiveIncome,
  menuMultiplier,
  turboMultiplier,
  offlineEfficiency,
}

enum MilestoneRewardType {
  tapBonusPercent,
  passiveBonusPercent,
  globalBonusPercent,
  menuBonusPercent,
  criticalChance,
  criticalMultiplier,
  comboDuration,
  comboMultiplier,
  turboBonusPercent,
  turboChargeSpeed,
  turboDuration,
  turboCooldownReduction,
  offlineEfficiency,
  offlineMaxDuration,
  offlineAdRewardPercent,
  goldenDonerChance,
  goldenDonerRewardPercent,
  tipChance,
  tipValuePercent,
  specialOrderChance,
  instantMoney,
  chest,
  cosmeticToken,
  collectionUnlock,
  featureUnlock,
}

const defaultUpgradeMilestoneRewards = [
  MilestoneReward(
    level: 5,
    type: MilestoneRewardType.tapBonusPercent,
    value: 0.05,
    labelKey: 'milestone_5',
  ),
  MilestoneReward(
    level: 10,
    type: MilestoneRewardType.globalBonusPercent,
    value: 0.01,
    labelKey: 'milestone_10',
  ),
  MilestoneReward(
    level: 15,
    type: MilestoneRewardType.passiveBonusPercent,
    value: 0.05,
    labelKey: 'milestone_15',
  ),
  MilestoneReward(
    level: 20,
    type: MilestoneRewardType.goldenDonerChance,
    value: 0.0025,
    labelKey: 'milestone_20',
  ),
  MilestoneReward(
    level: 25,
    type: MilestoneRewardType.chest,
    quantity: 1,
    labelKey: 'milestone_25',
  ),
];

class MilestoneReward {
  const MilestoneReward({
    required this.level,
    required this.type,
    this.value = 0,
    this.quantity = 0,
    this.labelKey = '',
    this.featureKey,
    this.collectionKey,
  }) : assert(level >= 1, 'level must be at least 1.'),
       assert(quantity >= 0, 'quantity cannot be negative.');

  final int level;
  final MilestoneRewardType type;
  final double value;
  final int quantity;
  final String labelKey;
  final String? featureKey;
  final String? collectionKey;

  @override
  bool operator ==(Object other) {
    return other is MilestoneReward &&
        level == other.level &&
        type == other.type &&
        value == other.value &&
        quantity == other.quantity &&
        labelKey == other.labelKey &&
        featureKey == other.featureKey &&
        collectionKey == other.collectionKey;
  }

  @override
  int get hashCode => Object.hash(
    level,
    type,
    value,
    quantity,
    labelKey,
    featureKey,
    collectionKey,
  );
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
