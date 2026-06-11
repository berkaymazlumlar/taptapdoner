import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

class EconomyConfig {
  EconomyConfig({
    required this.baseTapValue,
    required this.rushIncomeMultiplier,
    required this.rushDuration,
    required this.rushCooldown,
    required this.offlineCap,
    required this.prestigeThreshold,
    required this.prestigeBonusPerPoint,
    required this.upgrades,
    this.comboBaseExpireDuration = const Duration(seconds: 2),
    this.comboMaxExpireDuration = const Duration(seconds: 5),
    this.comboMaxMultiplier = 5,
    this.criticalBaseChance = 0.03,
    this.criticalMaxChance = 0.40,
    this.criticalBaseMultiplier = 3,
    this.criticalMaxMultiplier = 10,
    this.comboCriticalMultiplierCap = 20,
    this.goldenDonerMinSpawnInterval = const Duration(seconds: 90),
    this.goldenDonerMaxSpawnInterval = const Duration(seconds: 240),
    this.goldenDonerActiveDuration = const Duration(seconds: 6),
    this.goldenDonerRequiredHits = 10,
  });

  factory EconomyConfig.standard() {
    return EconomyConfig(
      baseTapValue: 1,
      rushIncomeMultiplier: 3,
      rushDuration: const Duration(seconds: 15),
      rushCooldown: const Duration(seconds: 120),
      offlineCap: const Duration(hours: 24),
      prestigeThreshold: 1000000,
      prestigeBonusPerPoint: 0.05,
      upgrades: defaultUpgradeDefinitions(),
    );
  }

  final int baseTapValue;
  final double rushIncomeMultiplier;
  final Duration rushDuration;
  final Duration rushCooldown;
  final Duration offlineCap;
  final int prestigeThreshold;
  final double prestigeBonusPerPoint;
  final List<UpgradeDefinition> upgrades;
  final Duration comboBaseExpireDuration;
  final Duration comboMaxExpireDuration;
  final double comboMaxMultiplier;
  final double criticalBaseChance;
  final double criticalMaxChance;
  final double criticalBaseMultiplier;
  final double criticalMaxMultiplier;
  final double comboCriticalMultiplierCap;
  final Duration goldenDonerMinSpawnInterval;
  final Duration goldenDonerMaxSpawnInterval;
  final Duration goldenDonerActiveDuration;
  final int goldenDonerRequiredHits;

  UpgradeDefinition upgrade(UpgradeId id) {
    return upgrades.firstWhere((definition) => definition.id == id);
  }
}
