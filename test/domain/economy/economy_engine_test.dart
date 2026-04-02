import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/economy_engine.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/stations/station_catalog.dart';
import 'package:taptapdoner/domain/stations/upgrade_catalog.dart';

void main() {
  final config = EconomyConfig.standard();
  final engine = EconomyEngine(config);
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  test('tap upgrades increase tap income', () {
    var state = GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 500);

    expect(engine.tapValue(state, nowUtc: nowUtc), 1);

    state = engine.buyUpgrade(state, UpgradeId.tapGloves).state;
    state = engine.buyUpgrade(state, UpgradeId.sharpKnife).state;

    expect(engine.tapValue(state, nowUtc: nowUtc), 4);
  });

  test('station purchase spends cash and increases income', () {
    var state = GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 100);

    final purchase = engine.buyStationLevel(state, StationId.donerSpit);
    expect(purchase.success, isTrue);

    final updated = purchase.state;
    expect(updated.station(StationId.donerSpit).level, 1);
    expect(updated.cash, 90);
    expect(engine.passiveIncomePerSecond(updated), greaterThan(0));
    expect(
      engine.stationCost(
        config.station(StationId.donerSpit),
        updated.station(StationId.donerSpit),
      ),
      greaterThan(10),
    );
  });

  test('rush multiplies passive income while active', () {
    final boostedState = GameState.initial(config, nowUtc: nowUtc).copyWith(
      stations: {
        for (final definition in config.stations)
          definition.id: StationState(
            id: definition.id,
            level: definition.id == StationId.donerSpit ? 2 : 0,
          ),
      },
      rush: TimedEffectState(
        endsAtUtc: nowUtc.add(const Duration(seconds: 10)),
        cooldownEndsAtUtc: nowUtc.add(const Duration(seconds: 80)),
      ),
    );

    final passive = engine.passiveIncomePerSecond(
      boostedState.copyWith(rush: const TimedEffectState()),
      nowUtc: nowUtc,
    );
    final rushed = engine.passiveIncomePerSecond(boostedState, nowUtc: nowUtc);

    expect(rushed, passive * config.rushIncomeMultiplier);
  });

  test('rush training only extends duration when purchased', () {
    var state = GameState.initial(config, nowUtc: nowUtc);

    final baseRush = engine.startRush(state, nowUtc: nowUtc);
    expect(baseRush.rush.endsAtUtc, nowUtc.add(const Duration(seconds: 15)));

    state = state.copyWith(
      upgrades: {
        for (final definition in config.upgrades)
          definition.id: UpgradeState(
            id: definition.id,
            purchased: definition.id == UpgradeId.rushTraining,
          ),
      },
    );

    final trainedRush = engine.startRush(state, nowUtc: nowUtc);
    expect(trainedRush.rush.endsAtUtc, nowUtc.add(const Duration(seconds: 20)));
  });
}
