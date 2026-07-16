import 'dart:math' as math;

import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

enum ShopLevelRequirementType {
  runCashEarned,
  upgradeTotalLevel,
  upgradeItemUnlocked,
  prestigeCount,
}

class ShopLevelRequirement {
  const ShopLevelRequirement.runCashEarned(this.target)
    : type = ShopLevelRequirementType.runCashEarned,
      upgradeId = null,
      itemKey = null;

  const ShopLevelRequirement.upgradeTotalLevel({
    required this.upgradeId,
    required this.target,
  }) : type = ShopLevelRequirementType.upgradeTotalLevel,
       itemKey = null;

  const ShopLevelRequirement.upgradeItemUnlocked({
    required this.upgradeId,
    required this.itemKey,
  }) : type = ShopLevelRequirementType.upgradeItemUnlocked,
       target = 1;

  const ShopLevelRequirement.prestigeCount(this.target)
    : type = ShopLevelRequirementType.prestigeCount,
      upgradeId = null,
      itemKey = null;

  final ShopLevelRequirementType type;
  final UpgradeId? upgradeId;
  final String? itemKey;
  final int target;

  bool isMet(GameState state, EconomyConfig config) {
    return switch (type) {
      ShopLevelRequirementType.runCashEarned =>
        state.prestige.runCashEarned >= target,
      ShopLevelRequirementType.upgradeTotalLevel =>
        _upgradeTotalLevel(state, config, upgradeId!) >= target,
      ShopLevelRequirementType.upgradeItemUnlocked => _hasUnlockedItem(
        state,
        config,
        upgradeId!,
        itemKey!,
      ),
      ShopLevelRequirementType.prestigeCount =>
        state.prestige.prestigeCount >= target,
    };
  }

  String label() {
    return switch (type) {
      ShopLevelRequirementType.runCashEarned => 'Earn $target this run',
      ShopLevelRequirementType.upgradeTotalLevel =>
        '${upgradeId!.key} reaches Lv. $target',
      ShopLevelRequirementType.upgradeItemUnlocked =>
        '${upgradeId!.key} unlocks $itemKey',
      ShopLevelRequirementType.prestigeCount => 'Prestige $target times',
    };
  }

  int _upgradeTotalLevel(GameState state, EconomyConfig config, UpgradeId id) {
    final definition = config.upgrade(id);
    final upgrade = state.upgrade(id);
    return definition.totalLevelForPosition(
      itemIndex: upgrade.itemIndex,
      itemLevel: upgrade.level,
    );
  }

  bool _hasUnlockedItem(
    GameState state,
    EconomyConfig config,
    UpgradeId id,
    String key,
  ) {
    final definition = config.upgrade(id);
    final upgrade = state.upgrade(id);
    for (var index = 0; index <= upgrade.itemIndex; index += 1) {
      if (index < definition.items.length &&
          definition.items[index].key == key) {
        return true;
      }
    }
    return false;
  }
}

class ShopLevelDefinition {
  const ShopLevelDefinition({
    required this.level,
    required this.id,
    required this.name,
    required this.theme,
    required this.unlockLabel,
    required this.incomeBonusPercent,
    required this.requirements,
  });

  final int level;
  final String id;
  final String name;
  final String theme;
  final String unlockLabel;
  final double incomeBonusPercent;
  final List<ShopLevelRequirement> requirements;

  double get incomeMultiplier => 1 + math.max(0, incomeBonusPercent);
}

class ShopProgressionCatalog {
  const ShopProgressionCatalog._();

  static const levels = <ShopLevelDefinition>[
    ShopLevelDefinition(
      level: 1,
      id: 'street_stand',
      name: 'Street Stand',
      theme: 'Starter counter',
      unlockLabel: 'Tap + Knife',
      incomeBonusPercent: 0,
      requirements: [],
    ),
    ShopLevelDefinition(
      level: 2,
      id: 'small_buffet',
      name: 'Small Buffet',
      theme: 'First expansion',
      unlockLabel: 'Staff',
      incomeBonusPercent: 0.05,
      requirements: [
        ShopLevelRequirement.runCashEarned(10000),
        ShopLevelRequirement.upgradeTotalLevel(
          upgradeId: UpgradeId.knife,
          target: 20,
        ),
        ShopLevelRequirement.upgradeTotalLevel(
          upgradeId: UpgradeId.staff,
          target: 1,
        ),
      ],
    ),
    ShopLevelDefinition(
      level: 3,
      id: 'neighborhood_doner',
      name: 'Neighborhood Doner',
      theme: 'Local favorite',
      unlockLabel: 'Menu focus',
      incomeBonusPercent: 0.10,
      requirements: [
        ShopLevelRequirement.runCashEarned(250000),
        ShopLevelRequirement.upgradeItemUnlocked(
          upgradeId: UpgradeId.knife,
          itemKey: 'sharp_knife',
        ),
        ShopLevelRequirement.upgradeTotalLevel(
          upgradeId: UpgradeId.staff,
          target: 15,
        ),
        ShopLevelRequirement.upgradeTotalLevel(
          upgradeId: UpgradeId.menu,
          target: 1,
        ),
      ],
    ),
    ShopLevelDefinition(
      level: 4,
      id: 'busy_street_doner',
      name: 'Busy Street Doner',
      theme: 'Heavy customer flow',
      unlockLabel: 'Income boost',
      incomeBonusPercent: 0.15,
      requirements: [
        ShopLevelRequirement.runCashEarned(5000000),
        ShopLevelRequirement.upgradeItemUnlocked(
          upgradeId: UpgradeId.knife,
          itemKey: 'double_knife',
        ),
        ShopLevelRequirement.upgradeItemUnlocked(
          upgradeId: UpgradeId.staff,
          itemKey: 'journeyman',
        ),
        ShopLevelRequirement.upgradeTotalLevel(
          upgradeId: UpgradeId.oven,
          target: 20,
        ),
      ],
    ),
    ShopLevelDefinition(
      level: 5,
      id: 'mall_doner',
      name: 'Mall Doner',
      theme: 'Modern service',
      unlockLabel: 'Prestige target',
      incomeBonusPercent: 0.20,
      requirements: [
        ShopLevelRequirement.runCashEarned(100000000),
        ShopLevelRequirement.upgradeItemUnlocked(
          upgradeId: UpgradeId.knife,
          itemKey: 'electric_knife',
        ),
        ShopLevelRequirement.upgradeTotalLevel(
          upgradeId: UpgradeId.staff,
          target: 40,
        ),
        ShopLevelRequirement.upgradeTotalLevel(
          upgradeId: UpgradeId.menu,
          target: 35,
        ),
      ],
    ),
    ShopLevelDefinition(
      level: 6,
      id: 'luxury_restaurant',
      name: 'Luxury Restaurant',
      theme: 'Premium dining',
      unlockLabel: 'Cosmetic hint',
      incomeBonusPercent: 0.30,
      requirements: [
        ShopLevelRequirement.runCashEarned(1000000000),
        ShopLevelRequirement.upgradeItemUnlocked(
          upgradeId: UpgradeId.oven,
          itemKey: 'large_oven',
        ),
        ShopLevelRequirement.prestigeCount(1),
      ],
    ),
    ShopLevelDefinition(
      level: 7,
      id: 'doner_chain',
      name: 'Doner Chain',
      theme: 'Branch planning',
      unlockLabel: 'Branch hint',
      incomeBonusPercent: 0.45,
      requirements: [
        ShopLevelRequirement.runCashEarned(10000000000),
        ShopLevelRequirement.upgradeItemUnlocked(
          upgradeId: UpgradeId.staff,
          itemKey: 'doner_master',
        ),
        ShopLevelRequirement.prestigeCount(2),
      ],
    ),
    ShopLevelDefinition(
      level: 8,
      id: 'city_brand',
      name: 'City Brand',
      theme: 'Large brand',
      unlockLabel: 'Advanced prestige',
      incomeBonusPercent: 0.65,
      requirements: [
        ShopLevelRequirement.runCashEarned(100000000000),
        ShopLevelRequirement.upgradeItemUnlocked(
          upgradeId: UpgradeId.menu,
          itemKey: 'gourmet_doner',
        ),
        ShopLevelRequirement.prestigeCount(3),
      ],
    ),
    ShopLevelDefinition(
      level: 9,
      id: 'national_chain',
      name: 'National Chain',
      theme: 'Late game',
      unlockLabel: 'Prestige shop expands',
      incomeBonusPercent: 0.90,
      requirements: [
        ShopLevelRequirement.runCashEarned(1000000000000),
        ShopLevelRequirement.prestigeCount(4),
      ],
    ),
    ShopLevelDefinition(
      level: 10,
      id: 'global_empire',
      name: 'Global Doner Empire',
      theme: 'Endgame brand',
      unlockLabel: 'Global collection',
      incomeBonusPercent: 1.25,
      requirements: [
        ShopLevelRequirement.runCashEarned(10000000000000),
        ShopLevelRequirement.prestigeCount(5),
      ],
    ),
    ShopLevelDefinition(
      level: 11,
      id: 'galactic_center',
      name: 'Galactic Doner Center',
      theme: 'Sci-fi',
      unlockLabel: 'Cosmic items',
      incomeBonusPercent: 1.75,
      requirements: [
        ShopLevelRequirement.runCashEarned(100000000000000),
        ShopLevelRequirement.prestigeCount(7),
      ],
    ),
    ShopLevelDefinition(
      level: 12,
      id: 'infinite_universe',
      name: 'Infinite Doner Universe',
      theme: 'Soft cap',
      unlockLabel: 'Endgame loop',
      incomeBonusPercent: 2.50,
      requirements: [
        ShopLevelRequirement.runCashEarned(1000000000000000),
        ShopLevelRequirement.prestigeCount(10),
      ],
    ),
  ];

  static ShopLevelDefinition byLevel(int level) {
    var result = levels.first;
    for (final definition in levels) {
      if (definition.level > level) {
        break;
      }
      result = definition;
    }
    return result;
  }

  static ShopLevelDefinition? nextAfter(int level) {
    for (final definition in levels) {
      if (definition.level > level) {
        return definition;
      }
    }
    return null;
  }

  static int eligibleLevel(GameState state, EconomyConfig config) {
    var eligible = 1;
    for (final definition in levels.skip(1)) {
      final requirementsMet = definition.requirements.every(
        (requirement) => requirement.isMet(state, config),
      );
      if (!requirementsMet) {
        break;
      }
      eligible = math.max(eligible, definition.level);
    }
    return eligible;
  }
}
