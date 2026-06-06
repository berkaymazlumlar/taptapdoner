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
    final offlineCap = engine.offlineCap(state);
    final effectiveElapsed = positiveElapsed > offlineCap
        ? offlineCap
        : positiveElapsed;
    if (effectiveElapsed == Duration.zero) {
      return ProductionGrant(
        coins: 0,
        rawElapsed: rawElapsed,
        effectiveElapsed: Duration.zero,
        rushElapsed: Duration.zero,
      );
    }

    return ProductionGrant(
      coins: engine.offlineIncome(state, effectiveElapsed),
      rawElapsed: rawElapsed,
      effectiveElapsed: effectiveElapsed,
      rushElapsed: Duration.zero,
    );
  }
}
