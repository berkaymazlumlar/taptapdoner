enum UpgradeId {
  tapGloves,
  sharpKnife,
  greaseMaintenance,
  brandBoard,
  rushTraining,
}

extension UpgradeIdKey on UpgradeId {
  String get key => switch (this) {
    UpgradeId.tapGloves => 'tapGloves',
    UpgradeId.sharpKnife => 'sharpKnife',
    UpgradeId.greaseMaintenance => 'greaseMaintenance',
    UpgradeId.brandBoard => 'brandBoard',
    UpgradeId.rushTraining => 'rushTraining',
  };
}

UpgradeId? upgradeIdFromKey(String key) {
  for (final value in UpgradeId.values) {
    if (value.key == key) {
      return value;
    }
  }
  return null;
}

class UpgradeDefinition {
  const UpgradeDefinition({
    required this.id,
    required this.cost,
    this.flatTapBonus = 0,
    this.tapMultiplier = 1,
    this.passiveMultiplier = 1,
    this.globalIncomeMultiplier = 1,
    this.rushDurationBonus = Duration.zero,
    this.rushCooldownReduction = Duration.zero,
  });

  final UpgradeId id;
  final int cost;
  final int flatTapBonus;
  final double tapMultiplier;
  final double passiveMultiplier;
  final double globalIncomeMultiplier;
  final Duration rushDurationBonus;
  final Duration rushCooldownReduction;
}

List<UpgradeDefinition> defaultUpgradeDefinitions() {
  return const [
    UpgradeDefinition(id: UpgradeId.tapGloves, cost: 25, flatTapBonus: 1),
    UpgradeDefinition(id: UpgradeId.sharpKnife, cost: 250, tapMultiplier: 2),
    UpgradeDefinition(
      id: UpgradeId.greaseMaintenance,
      cost: 1000,
      passiveMultiplier: 1.25,
    ),
    UpgradeDefinition(
      id: UpgradeId.brandBoard,
      cost: 5000,
      globalIncomeMultiplier: 1.5,
    ),
    UpgradeDefinition(
      id: UpgradeId.rushTraining,
      cost: 10000,
      rushDurationBonus: Duration(seconds: 5),
      rushCooldownReduction: Duration(seconds: 20),
    ),
  ];
}
