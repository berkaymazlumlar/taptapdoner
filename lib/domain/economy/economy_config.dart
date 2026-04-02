import 'package:taptapdoner/domain/stations/station_catalog.dart';
import 'package:taptapdoner/domain/stations/upgrade_catalog.dart';

class EconomyConfig {
  EconomyConfig({
    required this.baseTapValue,
    required this.rushIncomeMultiplier,
    required this.rushDuration,
    required this.rushCooldown,
    required this.offlineCap,
    required this.prestigeThreshold,
    required this.prestigeBonusPerPoint,
    required this.stations,
    required this.upgrades,
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
      stations: defaultStationDefinitions(),
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
  final List<StationDefinition> stations;
  final List<UpgradeDefinition> upgrades;

  StationDefinition station(StationId id) {
    return stations.firstWhere((definition) => definition.id == id);
  }

  UpgradeDefinition upgrade(UpgradeId id) {
    return upgrades.firstWhere((definition) => definition.id == id);
  }
}
