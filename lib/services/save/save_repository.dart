import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';

abstract interface class SaveRepository {
  Future<GameState?> load(EconomyConfig config);

  Future<void> save(GameState state);

  Future<void> clear();
}
