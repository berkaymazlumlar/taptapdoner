import 'dart:math' as math;

import 'package:taptapdoner/domain/upgrades/upgrade_definitions.dart'
    as upgrade_tracks;
import 'package:taptapdoner/domain/upgrades/upgrade_logic.dart'
    as upgrade_track_logic;
import 'package:taptapdoner/domain/upgrades/upgrade_models.dart';

export 'package:taptapdoner/domain/upgrades/upgrade_definitions.dart';
export 'package:taptapdoner/domain/upgrades/upgrade_logic.dart';
export 'package:taptapdoner/domain/upgrades/upgrade_models.dart';

enum UpgradeId { knife, oven, staff, menu, turbo, offline }

extension UpgradeIdKey on UpgradeId {
  String get key => switch (this) {
    UpgradeId.knife => 'knife',
    UpgradeId.oven => 'oven',
    UpgradeId.staff => 'staff',
    UpgradeId.menu => 'menu',
    UpgradeId.turbo => 'turbo',
    UpgradeId.offline => 'offline',
  };
}

enum UpgradeEffectKind { multiplier, passiveIncome, efficiency }

UpgradeId? upgradeIdFromKey(String key) {
  for (final value in UpgradeId.values) {
    if (value.key == key) {
      return value;
    }
  }

  return switch (key) {
    'tapGloves' || 'sharpKnife' => UpgradeId.knife,
    'greaseMaintenance' => UpgradeId.oven,
    'brandBoard' => UpgradeId.menu,
    'rushTraining' => UpgradeId.turbo,
    _ => null,
  };
}

int legacyUpgradeLevelForKey(String key, {required bool purchased}) {
  if (!purchased) {
    return 0;
  }
  return switch (key) {
    'tapGloves' => 1,
    'sharpKnife' => 10,
    'greaseMaintenance' => 4,
    'brandBoard' => 10,
    'rushTraining' => 1,
    _ => 1,
  };
}

class UpgradeItemDefinition {
  const UpgradeItemDefinition({
    required this.key,
    required this.tier,
    required this.effectAtLevel1,
    required this.effectPerLevel,
    required this.baseCost,
    required this.costMultiplier,
    this.milestoneRewards = defaultUpgradeMilestoneRewards,
    this.maxLevel = UpgradeDefinition.maxItemLevel,
  });

  factory UpgradeItemDefinition.fromTier(
    UpgradeItemTier tier, {
    required UpgradeId upgradeId,
  }) {
    return UpgradeItemDefinition(
      key: tier.id,
      tier: tier.tier,
      effectAtLevel1: tier.baseEffect,
      effectPerLevel: tier.levelEffect,
      baseCost: tier.baseCost,
      costMultiplier: tier.costMultiplier,
      milestoneRewards: milestoneRewardsForUpgradeItem(upgradeId, tier),
      maxLevel: tier.maxLevel,
    );
  }

  final String key;
  final int tier;
  final double effectAtLevel1;
  final double effectPerLevel;
  final double baseCost;
  final double costMultiplier;
  final List<MilestoneReward> milestoneRewards;
  final int maxLevel;

  double effectForItemLevel(int itemLevel) {
    if (itemLevel <= 0) {
      return 0;
    }
    final clampedLevel = math.min(itemLevel, maxLevel);
    return effectAtLevel1 + ((clampedLevel - 1) * effectPerLevel);
  }

  int costForItemLevel(int itemLevel) {
    final clampedLevel = math.min(math.max(itemLevel, 1), maxLevel);
    final value = baseCost * math.pow(costMultiplier, clampedLevel - 1);
    return math.max(1, value.floor());
  }

  UpgradeItemTier toTier() {
    return UpgradeItemTier(
      id: key,
      name: key,
      description: '',
      iconKey: key,
      tier: tier,
      iconPath: '',
      baseCost: baseCost,
      costMultiplier: costMultiplier,
      baseEffect: effectAtLevel1,
      levelEffect: effectPerLevel,
      maxLevel: maxLevel,
      milestoneRewards: milestoneRewards,
    );
  }
}

class UpgradeDefinition {
  const UpgradeDefinition({
    required this.id,
    required this.effectKind,
    required this.baseCost,
    required this.costGrowth,
    required this.baselineEffect,
    required this.items,
  });

  factory UpgradeDefinition.fromTrack(UpgradeTrack track) {
    final id = upgradeIdFromKey(track.id);
    if (id == null) {
      throw ArgumentError.value(track.id, 'track.id', 'Unknown upgrade track.');
    }

    return UpgradeDefinition(
      id: id,
      effectKind: _effectKindFor(track.effectType),
      baseCost: upgrade_track_logic.getUpgradeCost(track).floor(),
      costGrowth: upgrade_track_logic.getCurrentItem(track).costMultiplier,
      baselineEffect: upgrade_track_logic.getCurrentEffect(track),
      items: track.tiers
          .map((tier) => UpgradeItemDefinition.fromTier(tier, upgradeId: id))
          .toList(),
    );
  }

  static const maxItemLevel = 25;

  final UpgradeId id;
  final UpgradeEffectKind effectKind;
  final int baseCost;
  final double costGrowth;
  final double baselineEffect;
  final List<UpgradeItemDefinition> items;

  int get maxLevel => math.max(0, _totalTrackLevels - 1);

  bool isMaxLevel(int totalLevel) => totalLevel >= maxLevel;

  int normalizedLevel(int totalLevel) {
    if (totalLevel <= 0) {
      return 0;
    }
    return math.min(totalLevel, maxLevel);
  }

  int itemIndexForLevel(int totalLevel) {
    return _positionForLevel(totalLevel).itemIndex;
  }

  int itemLevelForTotalLevel(int totalLevel) {
    return _positionForLevel(totalLevel).itemLevel;
  }

  int totalLevelForPosition({required int itemIndex, required int itemLevel}) {
    if (items.isEmpty) {
      throw StateError('Upgrade $id has no items.');
    }

    final clampedItemIndex = math.min(math.max(itemIndex, 0), items.length - 1);
    final clampedItemLevel = math.min(
      math.max(itemLevel, 1),
      items[clampedItemIndex].maxLevel,
    );
    var totalLevel = clampedItemLevel - 1;
    for (var index = 0; index < clampedItemIndex; index += 1) {
      totalLevel += items[index].maxLevel;
    }
    return normalizedLevel(totalLevel);
  }

  UpgradeItemDefinition itemForLevel(int totalLevel) {
    return items[itemIndexForLevel(totalLevel)];
  }

  UpgradeItemDefinition? nextItemForLevel(int totalLevel) {
    final nextIndex = itemIndexForLevel(totalLevel) + 1;
    if (nextIndex >= items.length) {
      return null;
    }
    return items[nextIndex];
  }

  MilestoneReward? nextMilestoneForLevel(int totalLevel) {
    final position = _positionForLevel(totalLevel);
    final currentItem = items[position.itemIndex];
    for (final reward in currentItem.milestoneRewards) {
      if (reward.level > position.itemLevel) {
        return reward;
      }
    }

    final nextIndex = position.itemIndex + 1;
    if (position.itemLevel >= currentItem.maxLevel &&
        nextIndex < items.length &&
        items[nextIndex].milestoneRewards.isNotEmpty) {
      return items[nextIndex].milestoneRewards.first;
    }

    return null;
  }

  UpgradeItemDefinition? nextMilestoneItemForLevel(int totalLevel) {
    final position = _positionForLevel(totalLevel);
    final currentItem = items[position.itemIndex];
    if (currentItem.milestoneRewards.any(
      (reward) => reward.level > position.itemLevel,
    )) {
      return currentItem;
    }

    final nextIndex = position.itemIndex + 1;
    if (position.itemLevel >= currentItem.maxLevel &&
        nextIndex < items.length) {
      return items[nextIndex];
    }

    return null;
  }

  double effectForLevel(int totalLevel) {
    final track = trackForLevel(totalLevel);
    return upgrade_track_logic.getCurrentEffect(track);
  }

  int costForLevel(int totalLevel) {
    final level = normalizedLevel(totalLevel);
    if (isMaxLevel(level)) {
      return 0;
    }
    final position = _positionForLevel(level);
    final item = items[position.itemIndex];
    if (position.itemLevel >= item.maxLevel) {
      final nextItem = nextItemForLevel(level);
      if (nextItem != null) {
        return math.max(1, nextItem.baseCost.floor());
      }
    }
    return item.costForItemLevel(position.itemLevel);
  }

  UpgradeTrack trackForLevel(int totalLevel) {
    final position = _positionForLevel(totalLevel);
    return UpgradeTrack(
      id: id.key,
      title: id.key,
      description: '',
      type: _trackTypeFor(id),
      effectType: _effectTypeFor(id),
      itemIndex: position.itemIndex,
      level: position.itemLevel,
      tiers: items.map((item) => item.toTier()).toList(growable: false),
    );
  }

  int get _totalTrackLevels {
    return items.fold(0, (total, item) => total + item.maxLevel);
  }

  _UpgradeTrackPosition _positionForLevel(int totalLevel) {
    if (items.isEmpty) {
      throw StateError('Upgrade $id has no items.');
    }

    var trackLevelOrdinal = normalizedLevel(totalLevel) + 1;
    for (var index = 0; index < items.length; index += 1) {
      final item = items[index];
      if (trackLevelOrdinal <= item.maxLevel) {
        return _UpgradeTrackPosition(
          itemIndex: index,
          itemLevel: trackLevelOrdinal,
        );
      }
      trackLevelOrdinal -= item.maxLevel;
    }

    return _UpgradeTrackPosition(
      itemIndex: items.length - 1,
      itemLevel: items.last.maxLevel,
    );
  }
}

String milestoneKeyFor({
  required UpgradeId trackId,
  required String itemKey,
  required int level,
}) {
  return '${trackId.key}_${itemKey}_$level';
}

List<MilestoneReward> milestoneRewardsForUpgradeItem(
  UpgradeId upgradeId,
  UpgradeItemTier tier,
) {
  final itemKey = tier.id;
  final completionCollectionKey = '${upgradeId.key}_$itemKey';

  switch (upgradeId) {
    case UpgradeId.knife:
      if (itemKey == 'rusty_knife') {
        return [
          const MilestoneReward(
            level: 5,
            type: MilestoneRewardType.tapBonusPercent,
            value: 0.05,
            labelKey: 'rustyKnife5',
          ),
          const MilestoneReward(
            level: 10,
            type: MilestoneRewardType.criticalChance,
            value: 0.01,
            labelKey: 'rustyKnife10',
            featureKey: 'critical_cut',
          ),
          const MilestoneReward(
            level: 15,
            type: MilestoneRewardType.comboDuration,
            value: 0.25,
            labelKey: 'rustyKnife15',
            featureKey: 'combo',
          ),
          const MilestoneReward(
            level: 20,
            type: MilestoneRewardType.goldenDonerChance,
            value: 0.0025,
            labelKey: 'rustyKnife20',
            featureKey: 'golden_doner',
          ),
          MilestoneReward(
            level: 25,
            type: MilestoneRewardType.chest,
            quantity: 1,
            labelKey: 'rustyKnife25',
            featureKey: 'unlock_sharp_knife',
            collectionKey: completionCollectionKey,
          ),
        ];
      }
      return [
        const MilestoneReward(
          level: 5,
          type: MilestoneRewardType.tapBonusPercent,
          value: 0.05,
        ),
        const MilestoneReward(
          level: 10,
          type: MilestoneRewardType.criticalChance,
          value: 0.01,
          featureKey: 'critical_cut',
        ),
        const MilestoneReward(
          level: 15,
          type: MilestoneRewardType.comboDuration,
          value: 0.25,
          featureKey: 'combo',
        ),
        const MilestoneReward(
          level: 20,
          type: MilestoneRewardType.goldenDonerChance,
          value: 0.0025,
          featureKey: 'golden_doner',
        ),
        MilestoneReward(
          level: 25,
          type: MilestoneRewardType.chest,
          quantity: 1,
          collectionKey: completionCollectionKey,
        ),
      ];
    case UpgradeId.staff:
      return [
        const MilestoneReward(
          level: 5,
          type: MilestoneRewardType.passiveBonusPercent,
          value: 0.05,
        ),
        const MilestoneReward(
          level: 10,
          type: MilestoneRewardType.tipChance,
          value: 0.01,
          featureKey: 'tips',
        ),
        const MilestoneReward(
          level: 15,
          type: MilestoneRewardType.featureUnlock,
          featureKey: 'auto_collect_bonus',
        ),
        const MilestoneReward(
          level: 20,
          type: MilestoneRewardType.offlineEfficiency,
          value: 0.03,
        ),
        MilestoneReward(
          level: 25,
          type: MilestoneRewardType.chest,
          quantity: 1,
          collectionKey: completionCollectionKey,
        ),
      ];
    case UpgradeId.oven:
      return [
        const MilestoneReward(
          level: 5,
          type: MilestoneRewardType.globalBonusPercent,
          value: 0.03,
        ),
        const MilestoneReward(
          level: 10,
          type: MilestoneRewardType.turboChargeSpeed,
          value: 0.03,
        ),
        const MilestoneReward(
          level: 15,
          type: MilestoneRewardType.passiveBonusPercent,
          value: 0.04,
        ),
        const MilestoneReward(
          level: 20,
          type: MilestoneRewardType.tapBonusPercent,
          value: 0.04,
        ),
        MilestoneReward(
          level: 25,
          type: MilestoneRewardType.chest,
          quantity: 1,
          collectionKey: completionCollectionKey,
        ),
      ];
    case UpgradeId.menu:
      return [
        const MilestoneReward(
          level: 5,
          type: MilestoneRewardType.menuBonusPercent,
          value: 0.04,
        ),
        const MilestoneReward(
          level: 10,
          type: MilestoneRewardType.tipValuePercent,
          value: 0.05,
          featureKey: 'tips',
        ),
        const MilestoneReward(
          level: 15,
          type: MilestoneRewardType.specialOrderChance,
          value: 0.01,
          featureKey: 'special_orders',
        ),
        const MilestoneReward(
          level: 20,
          type: MilestoneRewardType.goldenDonerRewardPercent,
          value: 0.05,
          featureKey: 'golden_doner',
        ),
        MilestoneReward(
          level: 25,
          type: MilestoneRewardType.chest,
          quantity: 1,
          collectionKey: completionCollectionKey,
        ),
      ];
    case UpgradeId.turbo:
      return [
        const MilestoneReward(
          level: 5,
          type: MilestoneRewardType.turboBonusPercent,
          value: 0.05,
        ),
        const MilestoneReward(
          level: 10,
          type: MilestoneRewardType.turboDuration,
          value: 1,
        ),
        const MilestoneReward(
          level: 15,
          type: MilestoneRewardType.turboChargeSpeed,
          value: 0.05,
        ),
        const MilestoneReward(
          level: 20,
          type: MilestoneRewardType.turboCooldownReduction,
          value: 0.03,
        ),
        MilestoneReward(
          level: 25,
          type: MilestoneRewardType.chest,
          quantity: 1,
          collectionKey: completionCollectionKey,
        ),
      ];
    case UpgradeId.offline:
      return [
        const MilestoneReward(
          level: 5,
          type: MilestoneRewardType.offlineEfficiency,
          value: 0.03,
        ),
        const MilestoneReward(
          level: 10,
          type: MilestoneRewardType.offlineMaxDuration,
          value: 900,
        ),
        const MilestoneReward(
          level: 15,
          type: MilestoneRewardType.featureUnlock,
          featureKey: 'offline_minimum_claim',
        ),
        const MilestoneReward(
          level: 20,
          type: MilestoneRewardType.offlineAdRewardPercent,
          value: 0.05,
        ),
        MilestoneReward(
          level: 25,
          type: MilestoneRewardType.chest,
          quantity: 1,
          collectionKey: completionCollectionKey,
        ),
      ];
  }
}

List<UpgradeDefinition> defaultUpgradeDefinitions() {
  return upgrade_tracks
      .defaultUpgradeTracks()
      .map(UpgradeDefinition.fromTrack)
      .toList(growable: false);
}

UpgradeEffectKind _effectKindFor(UpgradeEffectType effectType) {
  return switch (effectType) {
    UpgradeEffectType.tapMultiplier ||
    UpgradeEffectType.globalIncomeMultiplier ||
    UpgradeEffectType.menuMultiplier ||
    UpgradeEffectType.turboMultiplier => UpgradeEffectKind.multiplier,
    UpgradeEffectType.passiveIncome => UpgradeEffectKind.passiveIncome,
    UpgradeEffectType.offlineEfficiency => UpgradeEffectKind.efficiency,
  };
}

UpgradeTrackType _trackTypeFor(UpgradeId id) {
  return switch (id) {
    UpgradeId.knife => UpgradeTrackType.knife,
    UpgradeId.oven => UpgradeTrackType.oven,
    UpgradeId.staff => UpgradeTrackType.staff,
    UpgradeId.menu => UpgradeTrackType.menu,
    UpgradeId.turbo => UpgradeTrackType.turbo,
    UpgradeId.offline => UpgradeTrackType.offline,
  };
}

UpgradeEffectType _effectTypeFor(UpgradeId id) {
  return switch (id) {
    UpgradeId.knife => UpgradeEffectType.tapMultiplier,
    UpgradeId.oven => UpgradeEffectType.globalIncomeMultiplier,
    UpgradeId.menu => UpgradeEffectType.menuMultiplier,
    UpgradeId.staff => UpgradeEffectType.passiveIncome,
    UpgradeId.turbo => UpgradeEffectType.turboMultiplier,
    UpgradeId.offline => UpgradeEffectType.offlineEfficiency,
  };
}

class _UpgradeTrackPosition {
  const _UpgradeTrackPosition({
    required this.itemIndex,
    required this.itemLevel,
  });

  final int itemIndex;
  final int itemLevel;
}
