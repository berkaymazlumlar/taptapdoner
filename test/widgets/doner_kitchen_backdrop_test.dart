import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('doner kitchen backdrop stays static without passive income', () async {
    final game = TapTapDonerGame(
      controller: _controller(config: _zeroPassiveConfig()),
    );
    game.onGameResize(Vector2(360, 640));
    await game.onLoad();

    expect(game.backdrop.debugHasBackdropImage, isTrue);
    expect(game.controller.passiveIncomePerSecond, 0);
    final first = await _renderBackdropBytes(game);
    game.update(1);
    final second = await _renderBackdropBytes(game);

    expect(first, isNotEmpty);
    expect(first, equals(second));
    expect(game.backdrop.debugActiveMoneyDropCount, 0);
    expect(game.backdrop.debugSpawnRateFor(0), 0);
  });

  test('money rain scales with passive income', () async {
    final lowGame = TapTapDonerGame(
      controller: _controller(upgradeLevels: const {UpgradeId.staff: 2}),
    );
    final highGame = TapTapDonerGame(
      controller: _controller(upgradeLevels: const {UpgradeId.staff: 20}),
    );

    lowGame.onGameResize(Vector2(360, 640));
    highGame.onGameResize(Vector2(360, 640));
    await lowGame.onLoad();
    await highGame.onLoad();

    final lowIncome = lowGame.controller.passiveIncomePerSecond;
    final highIncome = highGame.controller.passiveIncomePerSecond;
    expect(highIncome, greaterThan(lowIncome));
    expect(
      highGame.backdrop.debugSpawnRateFor(highIncome),
      greaterThan(lowGame.backdrop.debugSpawnRateFor(lowIncome)),
    );

    lowGame.update(2);
    highGame.update(2);

    expect(lowGame.backdrop.debugActiveMoneyDropCount, greaterThan(0));
    expect(
      highGame.backdrop.debugActiveMoneyDropCount,
      greaterThan(lowGame.backdrop.debugActiveMoneyDropCount),
    );
  });
}

Future<Uint8List> _renderBackdropBytes(TapTapDonerGame game) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  game.backdrop.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(360, 640);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  expect(bytes, isNotNull);
  return bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
}

GameController _controller({
  EconomyConfig? config,
  Map<UpgradeId, int> upgradeLevels = const {},
}) {
  final nowUtc = DateTime.utc(2026, 4, 1, 12);
  final effectiveConfig = config ?? EconomyConfig.standard();
  return GameController(
    config: effectiveConfig,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
  )..hydrate(
    GameState.initial(effectiveConfig, nowUtc: nowUtc).copyWith(
      upgrades: {
        for (final definition in effectiveConfig.upgrades)
          definition.id: UpgradeState.fromTotalLevel(
            definition: definition,
            totalLevel: upgradeLevels[definition.id] ?? 0,
          ),
      },
    ),
  );
}

EconomyConfig _zeroPassiveConfig() {
  final config = EconomyConfig.standard();
  return EconomyConfig(
    baseTapValue: config.baseTapValue,
    rushIncomeMultiplier: config.rushIncomeMultiplier,
    rushDuration: config.rushDuration,
    rushCooldown: config.rushCooldown,
    offlineCap: config.offlineCap,
    prestigeThreshold: config.prestigeThreshold,
    prestigeBonusPerPoint: config.prestigeBonusPerPoint,
    upgrades: [
      for (final upgrade in config.upgrades)
        if (upgrade.id == UpgradeId.staff)
          const UpgradeDefinition(
            id: UpgradeId.staff,
            effectKind: UpgradeEffectKind.passiveIncome,
            baseCost: 1,
            costGrowth: 1,
            baselineEffect: 0,
            items: [
              UpgradeItemDefinition(
                key: 'zero_staff',
                tier: 1,
                effectAtLevel1: 0,
                effectPerLevel: 0,
                baseCost: 1,
                costMultiplier: 1,
              ),
            ],
          )
        else
          upgrade,
    ],
  );
}

class _MemorySaveRepository implements SaveRepository {
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
