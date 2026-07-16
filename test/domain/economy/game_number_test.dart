import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/game_number.dart';
import 'package:taptapdoner/domain/state/game_state.dart';

void main() {
  test('normalizes and calculates beyond the double exponent range', () {
    final first = GameNumber.fromParts(9, 500);
    final second = GameNumber.fromParts(5, 500);
    final result = first + second;

    expect(result.mantissa, closeTo(1.4, 1e-12));
    expect(result.exponent, 501);
    expect(result.toDouble(), double.infinity);
  });

  test('very small additions do not corrupt a large balance', () {
    final balance = GameNumber.fromParts(4.2, 1000);

    expect(balance + 1, balance);
    expect(balance - 1, balance);
  });

  test('game state saves huge currency without converting through double', () {
    final config = EconomyConfig.standard();
    final huge = GameNumber.fromParts(7.25, 1200);
    final state = GameState.initial(config).copyWith(
      cash: huge,
      lifetimeCash: huge,
      pendingOfflineCash: GameNumber.fromParts(3, 900),
      prestige: PrestigeState(reputation: 2, runCashEarned: huge),
    );

    final restored = GameState.fromJson(state.toJson(), config);

    expect(restored.cash, huge);
    expect(restored.lifetimeCash, huge);
    expect(restored.pendingOfflineCash, GameNumber.fromParts(3, 900));
    expect(restored.prestige.runCashEarned, huge);
  });

  test('legacy numeric save values remain readable', () {
    final config = EconomyConfig.standard();
    final json = GameState.initial(config).toJson()
      ..['cash'] = 1234
      ..['lifetimeCash'] = 5678;

    final restored = GameState.fromJson(json, config);

    expect(restored.cash, 1234);
    expect(restored.lifetimeCash, 5678);
  });
}
