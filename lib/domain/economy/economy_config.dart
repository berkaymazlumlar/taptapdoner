import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

class EconomyConfig {
  EconomyConfig({
    required this.baseTapValue,
    required this.offlineCap,
    required this.prestigeThreshold,
    required this.prestigeBonusPerPoint,
    required this.upgrades,
    this.comboBaseExpireDuration = const Duration(seconds: 1),
    this.comboMaxExpireDuration = const Duration(seconds: 1),
    this.comboActivationThreshold = 10,
    this.comboMaxMultiplier = 5,
    this.criticalBaseChance = 0.03,
    this.criticalMaxChance = 0.40,
    this.criticalBaseMultiplier = 3,
    this.criticalMaxMultiplier = 10,
    this.comboCriticalMultiplierCap = 20,
  });

  factory EconomyConfig.standard() {
    return EconomyConfig(
      baseTapValue: 1,
      offlineCap: const Duration(hours: 24),
      prestigeThreshold: 1000000,
      prestigeBonusPerPoint: 0.05,
      upgrades: defaultUpgradeDefinitions(),
    );
  }

  final int baseTapValue;
  final Duration offlineCap;
  final int prestigeThreshold;
  final double prestigeBonusPerPoint;
  final List<UpgradeDefinition> upgrades;
  final Duration comboBaseExpireDuration;
  final Duration comboMaxExpireDuration;
  final int comboActivationThreshold;
  final double comboMaxMultiplier;
  final double criticalBaseChance;
  final double criticalMaxChance;
  final double criticalBaseMultiplier;
  final double criticalMaxMultiplier;
  final double comboCriticalMultiplierCap;
  UpgradeDefinition upgrade(UpgradeId id) {
    return upgrades.firstWhere((definition) => definition.id == id);
  }
}
