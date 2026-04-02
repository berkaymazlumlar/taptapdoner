enum StationId { donerSpit, prepStation, drinkFridge, cashDesk, courierScooter }

extension StationIdKey on StationId {
  String get key => switch (this) {
    StationId.donerSpit => 'donerSpit',
    StationId.prepStation => 'prepStation',
    StationId.drinkFridge => 'drinkFridge',
    StationId.cashDesk => 'cashDesk',
    StationId.courierScooter => 'courierScooter',
  };
}

StationId? stationIdFromKey(String key) {
  for (final value in StationId.values) {
    if (value.key == key) {
      return value;
    }
  }
  return null;
}

class StationDefinition {
  const StationDefinition({
    required this.id,
    required this.unlockAtLifetimeCash,
    required this.baseCost,
    required this.costGrowth,
    required this.baseIncomePerSecond,
  });

  final StationId id;
  final int unlockAtLifetimeCash;
  final int baseCost;
  final double costGrowth;
  final double baseIncomePerSecond;
}

List<StationDefinition> defaultStationDefinitions() {
  return const [
    StationDefinition(
      id: StationId.donerSpit,
      unlockAtLifetimeCash: 0,
      baseCost: 10,
      costGrowth: 1.15,
      baseIncomePerSecond: 1,
    ),
    StationDefinition(
      id: StationId.prepStation,
      unlockAtLifetimeCash: 100,
      baseCost: 60,
      costGrowth: 1.16,
      baseIncomePerSecond: 5,
    ),
    StationDefinition(
      id: StationId.drinkFridge,
      unlockAtLifetimeCash: 1000,
      baseCost: 400,
      costGrowth: 1.17,
      baseIncomePerSecond: 25,
    ),
    StationDefinition(
      id: StationId.cashDesk,
      unlockAtLifetimeCash: 10000,
      baseCost: 2500,
      costGrowth: 1.18,
      baseIncomePerSecond: 120,
    ),
    StationDefinition(
      id: StationId.courierScooter,
      unlockAtLifetimeCash: 50000,
      baseCost: 15000,
      costGrowth: 1.2,
      baseIncomePerSecond: 600,
    ),
  ];
}
