import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/economy_engine.dart';
import 'package:taptapdoner/domain/state/game_state.dart';

class BackgroundProductionCalculator {
  BackgroundProductionCalculator({required this.config, required this.engine});

  final EconomyConfig config;
  final EconomyEngine engine;

  ProductionGrant calculate({
    required GameState state,
    required DateTime nowUtc,
  }) {
    final rawElapsed = nowUtc.difference(state.lastActiveAtUtc);
    final positiveElapsed = rawElapsed.isNegative ? Duration.zero : rawElapsed;
    final effectiveElapsed = positiveElapsed > config.offlineCap
        ? config.offlineCap
        : positiveElapsed;
    if (effectiveElapsed == Duration.zero) {
      return ProductionGrant(
        coins: 0,
        rawElapsed: rawElapsed,
        effectiveElapsed: Duration.zero,
        rushElapsed: Duration.zero,
      );
    }

    final passiveIncomePerSecond = engine.passiveIncomePerSecond(
      state,
      includeRush: false,
    );
    final rushElapsed = _rushOverlap(state, effectiveElapsed);
    final normalElapsed = effectiveElapsed - rushElapsed;
    final normalGain =
        passiveIncomePerSecond * normalElapsed.inMilliseconds / 1000;
    final rushGain =
        passiveIncomePerSecond *
        config.rushIncomeMultiplier *
        rushElapsed.inMilliseconds /
        1000;

    return ProductionGrant(
      coins: (normalGain + rushGain).floor(),
      rawElapsed: rawElapsed,
      effectiveElapsed: effectiveElapsed,
      rushElapsed: rushElapsed,
    );
  }

  Duration _rushOverlap(GameState state, Duration effectiveElapsed) {
    final rushEndsAtUtc = state.rush.endsAtUtc;
    if (rushEndsAtUtc == null) {
      return Duration.zero;
    }
    final cappedEnd = state.lastActiveAtUtc.add(effectiveElapsed);
    final overlapEnd = rushEndsAtUtc.isBefore(cappedEnd)
        ? rushEndsAtUtc
        : cappedEnd;
    if (!overlapEnd.isAfter(state.lastActiveAtUtc)) {
      return Duration.zero;
    }
    return overlapEnd.difference(state.lastActiveAtUtc);
  }
}
