import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/economy_engine.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/services/background/background_production_calculator.dart';

void main() {
  final config = EconomyConfig.standard();
  final engine = EconomyEngine(config);
  final calculator = BackgroundProductionCalculator(
    config: config,
    engine: engine,
  );
  final baseline = DateTime.utc(2026, 4, 1, 12);

  GameState buildState({required DateTime lastActiveAtUtc}) {
    return GameState.initial(
      config,
      nowUtc: baseline,
    ).copyWith(lastActiveAtUtc: lastActiveAtUtc);
  }

  test('negative elapsed is clamped to zero', () {
    final grant = calculator.calculate(
      state: buildState(
        lastActiveAtUtc: baseline.add(const Duration(hours: 1)),
      ),
      nowUtc: baseline,
    );

    expect(grant.coins, 0);
    expect(grant.effectiveElapsed, Duration.zero);
  });

  test('elapsed time is capped at 24 hours', () {
    final grant = calculator.calculate(
      state: buildState(
        lastActiveAtUtc: baseline.subtract(const Duration(days: 2)),
      ),
      nowUtc: baseline,
    );

    expect(grant.effectiveElapsed, const Duration(hours: 24));
    expect(grant.coins, 17280);
  });

  test('offline income applies offline efficiency', () {
    final grant = calculator.calculate(
      state: buildState(
        lastActiveAtUtc: baseline.subtract(const Duration(hours: 2)),
      ),
      nowUtc: baseline,
    );

    expect(grant.coins, 1440);
  });
}
