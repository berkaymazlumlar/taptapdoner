import 'dart:math' as math;

import 'package:taptapdoner/domain/economy/number_units.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';

enum PrestigeShopEffectType {
  tapBonus,
  passiveBonus,
  globalBonus,
  startingCash,
  offlineCap,
  criticalChance,
  comboDuration,
  prestigeChest,
}

class PrestigeShopUpgradeDefinition {
  const PrestigeShopUpgradeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.effectType,
    required this.effectPerLevel,
    required this.maxLevel,
    required this.baseCost,
  });

  final String id;
  final String name;
  final String description;
  final PrestigeShopEffectType effectType;
  final double effectPerLevel;
  final int maxLevel;
  final int baseCost;

  int costForLevel(int currentLevel) {
    if (currentLevel >= maxLevel) {
      return 0;
    }
    return math.max(1, baseCost + math.pow(currentLevel + 1, 1.7).floor());
  }

  String effectLabel(int nextLevel, {String localeCode = 'en'}) {
    final clamped = math.max(0, math.min(nextLevel, maxLevel));
    final total = effectPerLevel * clamped;
    return switch (effectType) {
      PrestigeShopEffectType.tapBonus => 'Tap +${(total * 100).round()}%',
      PrestigeShopEffectType.passiveBonus =>
        'Passive +${(total * 100).round()}%',
      PrestigeShopEffectType.globalBonus => 'Global +${(total * 100).round()}%',
      PrestigeShopEffectType.startingCash =>
        'Start +${formatNumberWithUnitNames(total, locale: localeCode)} cash',
      PrestigeShopEffectType.offlineCap =>
        'Offline +${(total / 60).round()} min',
      PrestigeShopEffectType.criticalChance =>
        'Critical +${(total * 100).round()}%',
      PrestigeShopEffectType.comboDuration =>
        'Combo +${total.toStringAsFixed(1)}s',
      PrestigeShopEffectType.prestigeChest => 'Prestige chest Lv. $clamped',
    };
  }
}

class PrestigeShopCatalog {
  const PrestigeShopCatalog._();

  static const masterHand = 'master_hand';
  static const loyalApprentices = 'loyal_apprentices';
  static const hotOven = 'hot_oven';
  static const fastStart = 'fast_start';
  static const bigRegister = 'big_register';
  static const criticalMastery = 'critical_mastery';
  static const comboMaster = 'combo_master';
  static const masterChest = 'master_chest';

  static const upgrades = <PrestigeShopUpgradeDefinition>[
    PrestigeShopUpgradeDefinition(
      id: masterHand,
      name: 'Master Hand',
      description: 'Permanent tap income training.',
      effectType: PrestigeShopEffectType.tapBonus,
      effectPerLevel: 0.05,
      maxLevel: 20,
      baseCost: 0,
    ),
    PrestigeShopUpgradeDefinition(
      id: loyalApprentices,
      name: 'Loyal Apprentices',
      description: 'Permanent staff production training.',
      effectType: PrestigeShopEffectType.passiveBonus,
      effectPerLevel: 0.05,
      maxLevel: 20,
      baseCost: 0,
    ),
    PrestigeShopUpgradeDefinition(
      id: hotOven,
      name: 'Hot Oven',
      description: 'Permanent global income heat.',
      effectType: PrestigeShopEffectType.globalBonus,
      effectPerLevel: 0.03,
      maxLevel: 20,
      baseCost: 0,
    ),
    PrestigeShopUpgradeDefinition(
      id: fastStart,
      name: 'Fast Start',
      description: 'Begin each prestige run with cash.',
      effectType: PrestigeShopEffectType.startingCash,
      effectPerLevel: 100,
      maxLevel: 20,
      baseCost: 0,
    ),
    PrestigeShopUpgradeDefinition(
      id: bigRegister,
      name: 'Big Register',
      description: 'Extend maximum offline duration.',
      effectType: PrestigeShopEffectType.offlineCap,
      effectPerLevel: 1800,
      maxLevel: 12,
      baseCost: 1,
    ),
    PrestigeShopUpgradeDefinition(
      id: criticalMastery,
      name: 'Critical Mastery',
      description: 'Increase critical cut chance.',
      effectType: PrestigeShopEffectType.criticalChance,
      effectPerLevel: 0.01,
      maxLevel: 15,
      baseCost: 1,
    ),
    PrestigeShopUpgradeDefinition(
      id: comboMaster,
      name: 'Combo Master',
      description: 'Keep combo alive for longer.',
      effectType: PrestigeShopEffectType.comboDuration,
      effectPerLevel: 0.10,
      maxLevel: 20,
      baseCost: 1,
    ),
    PrestigeShopUpgradeDefinition(
      id: masterChest,
      name: 'Master Chest',
      description: 'Earn a chest after every prestige.',
      effectType: PrestigeShopEffectType.prestigeChest,
      effectPerLevel: 1,
      maxLevel: 5,
      baseCost: 2,
    ),
  ];

  static PrestigeShopUpgradeDefinition? byId(String id) {
    for (final upgrade in upgrades) {
      if (upgrade.id == id) {
        return upgrade;
      }
    }
    return null;
  }

  static ChestType? prestigeChestForLevel(int level) {
    if (level >= 5) {
      return ChestType.prestige;
    }
    if (level >= 3) {
      return ChestType.master;
    }
    if (level >= 1) {
      return ChestType.small;
    }
    return null;
  }
}
