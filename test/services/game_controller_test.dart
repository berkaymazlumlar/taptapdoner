import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/stations/station_catalog.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';

void main() {
  final config = EconomyConfig.standard();

  test('checkpoint then reconcile grants offline production once', () async {
    var nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller =
        GameController(
          config: config,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            stations: {
              for (final definition in config.stations)
                definition.id: StationState(
                  id: definition.id,
                  level: definition.id == StationId.donerSpit ? 1 : 0,
                ),
            },
          ),
        );

    expect(controller.state.lastActiveAtUtc, nowUtc);
    await controller.checkpointLifecycle();
    expect(controller.state.lastActiveAtUtc, nowUtc);

    nowUtc = nowUtc.add(const Duration(hours: 1));
    await controller.reconcileBackground();

    expect(controller.state.pendingOfflineCash, 3600);
    expect(controller.state.lastActiveAtUtc, nowUtc);

    await controller.reconcileBackground();
    expect(controller.state.pendingOfflineCash, 3600);
  });

  test('save operations are serialized so newer checkpoints win', () async {
    var nowUtc = DateTime.utc(2026, 4, 1, 12);
    final repository = _DelayedSaveRepository();
    final controller = GameController(
      config: config,
      saveRepository: repository,
      adService: const NoopRewardedAdService(),
      clock: () => nowUtc,
    )..hydrate(GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 100));

    await controller.buyStation(StationId.donerSpit);
    nowUtc = nowUtc.add(const Duration(minutes: 10));
    await controller.checkpointLifecycle();

    expect(repository.savedStates, hasLength(2));
    expect(
      repository.savedStates.last.lastActiveAtUtc,
      DateTime.utc(2026, 4, 1, 12),
    );
    expect(
      repository.savedStates.last.lastSavedAtUtc,
      DateTime.utc(2026, 4, 1, 12, 10),
    );
  });
}

class _RecordingSaveRepository implements SaveRepository {
  GameState? _state;

  @override
  Future<void> clear() async {
    _state = null;
  }

  @override
  Future<GameState?> load(EconomyConfig config) async => _state;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }
}

class _DelayedSaveRepository implements SaveRepository {
  final List<GameState> savedStates = [];
  int _saveCount = 0;

  @override
  Future<void> clear() async {
    savedStates.clear();
  }

  @override
  Future<GameState?> load(EconomyConfig config) async => null;

  @override
  Future<void> save(GameState state) async {
    _saveCount += 1;
    final delay = _saveCount == 1
        ? const Duration(milliseconds: 40)
        : Duration.zero;
    await Future<void>.delayed(delay);
    savedStates.add(state);
  }
}
