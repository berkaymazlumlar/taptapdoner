import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';

void main() {
  final config = EconomyConfig.standard();

  test('checkpoint then reconcile grants offline production once', () async {
    var nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller = GameController(
      config: config,
      saveRepository: _RecordingSaveRepository(),
      adService: const NoopRewardedAdService(),
      clock: () => nowUtc,
    )..hydrate(GameState.initial(config, nowUtc: nowUtc));

    expect(controller.state.lastActiveAtUtc, nowUtc);
    await controller.checkpointLifecycle();
    expect(controller.state.lastActiveAtUtc, nowUtc);

    nowUtc = nowUtc.add(const Duration(hours: 1));
    await controller.reconcileBackground();

    expect(controller.state.pendingOfflineCash, 720);
    expect(controller.state.lastActiveAtUtc, nowUtc);

    await controller.reconcileBackground();
    expect(controller.state.pendingOfflineCash, 720);
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

    await controller.startRush();
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

  test(
    'buying an upgrade saves updated track progress before returning',
    () async {
      final repository = _RecordingSaveRepository();
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller = GameController(
        config: config,
        saveRepository: repository,
        adService: const NoopRewardedAdService(),
        clock: () => nowUtc,
      )..hydrate(GameState.initial(config, nowUtc: nowUtc).copyWith(cash: 100));

      final bought = await controller.buyUpgrade(config.upgrades.first.id);

      expect(bought, isTrue);
      expect(repository.savedState, isNotNull);
      expect(repository.savedState!.cash, lessThan(100));
      expect(
        repository.savedState!.upgrade(config.upgrades.first.id).itemIndex,
        0,
      );
      expect(repository.savedState!.upgrade(config.upgrades.first.id).level, 2);
    },
  );

  test(
    'starter quest chain completes, claims once, and unlocks next quest',
    () async {
      final repository = _RecordingSaveRepository();
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller = GameController(
        config: config,
        saveRepository: repository,
        adService: const NoopRewardedAdService(),
        clock: () => nowUtc,
      )..hydrate(GameState.initial(config, nowUtc: nowUtc));

      expect(
        controller.questSnapshotListenable.value?.questId,
        'starter_tap_10',
      );

      for (var i = 0; i < 10; i += 1) {
        await controller.tap();
      }

      expect(controller.questSnapshotListenable.value?.canClaim, isTrue);
      final claimedFirst = await controller.claimActiveQuestReward();

      expect(claimedFirst, isTrue);
      expect(controller.state.cash, 60);
      expect(
        controller.questSnapshotListenable.value?.questId,
        'starter_first_upgrade',
      );
      expect(controller.questSnapshotListenable.value?.canClaim, isFalse);

      final duplicateClaim = await controller.claimActiveQuestReward();
      expect(duplicateClaim, isFalse);
      expect(controller.state.cash, 60);

      final bought = await controller.buyUpgrade(UpgradeId.knife);
      expect(bought, isTrue);
      expect(controller.questSnapshotListenable.value?.canClaim, isTrue);

      await controller.claimActiveQuestReward();
      expect(controller.state.cash, 65);
      expect(
        controller.questSnapshotListenable.value?.questId,
        'starter_rusty_knife_5',
      );
      expect(
        repository.savedState?.quests['starter_tap_10']?.rewardClaimed,
        isTrue,
      );
    },
  );

  test(
    'achievement progress completes and reward can be claimed once',
    () async {
      final repository = _RecordingSaveRepository();
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller = GameController(
        config: config,
        saveRepository: repository,
        adService: const NoopRewardedAdService(),
        clock: () => nowUtc,
      )..hydrate(GameState.initial(config, nowUtc: nowUtc));

      for (var i = 0; i < 10; i += 1) {
        await controller.tap();
      }

      final progress = controller.state.achievements['tap_10'];
      expect(progress?.isCompleted, isTrue);
      expect(progress?.isRewardClaimed, isFalse);
      expect(
        controller
            .progressionSnapshotListenable
            .value
            .latestClaimableAchievement
            ?.id,
        'tap_10',
      );

      final claimed = await controller.claimAchievementReward('tap_10');
      final duplicate = await controller.claimAchievementReward('tap_10');

      expect(claimed, isTrue);
      expect(duplicate, isFalse);
      expect(controller.state.cash, 60);
      expect(controller.state.achievements['tap_10']?.isRewardClaimed, isTrue);
      expect(
        repository.savedState?.achievements['tap_10']?.isRewardClaimed,
        isTrue,
      );
    },
  );

  test(
    'opening a chest consumes inventory and applies the rolled reward',
    () async {
      final nowUtc = DateTime.utc(2026, 4, 1, 12);
      final controller =
          GameController(
            config: config,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
            random: _FixedRandom(0.1),
          )..hydrate(
            GameState.initial(config, nowUtc: nowUtc).copyWith(
              chestInventory: const ChestInventoryState(
                counts: {ChestType.small: 1},
              ),
            ),
          );

      final reward = await controller.openChest(ChestType.small);

      expect(reward, isNotNull);
      expect(reward!.rewardType, ChestRewardType.money);
      expect(controller.state.chestInventory.count(ChestType.small), 0);
      expect(controller.state.stats.chestsOpened, 1);
      expect(controller.state.cash, greaterThan(0));
      expect(controller.state.achievements['chest_1']?.isCompleted, isTrue);
    },
  );

  test('combo increases tap income and expires after its window', () async {
    var nowUtc = DateTime.utc(2026, 4, 1, 12);
    final comboConfig = _activePlayConfig(baseTapValue: 10);
    final controller =
        GameController(
          config: comboConfig,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(comboConfig, nowUtc: nowUtc).copyWith(
            milestones: const MilestoneState(unlockedFeatureKeys: {'combo'}),
          ),
        );

    final first = await controller.tap();
    TapOutcome fifth = first;
    for (var index = 0; index < 4; index += 1) {
      fifth = await controller.tap();
    }

    expect(first.combo, 1);
    expect(fifth.combo, 5);
    expect(fifth.comboMultiplier, closeTo(1.10, 0.0001));
    expect(fifth.coins, greaterThan(first.coins));
    expect(controller.activePlaySnapshotListenable.value.currentCombo, 5);

    nowUtc = nowUtc.add(const Duration(seconds: 3));
    controller.tick(const Duration(seconds: 3));

    expect(controller.activePlaySnapshotListenable.value.currentCombo, 0);
  });

  test('critical cut randomly multiplies an unlocked tap', () async {
    final criticalConfig = _activePlayConfig(
      baseTapValue: 10,
      criticalBaseChance: 1,
      criticalMaxChance: 1,
    );
    final nowUtc = DateTime.utc(2026, 4, 1, 12);
    final controller =
        GameController(
          config: criticalConfig,
          saveRepository: _RecordingSaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(criticalConfig, nowUtc: nowUtc).copyWith(
            milestones: const MilestoneState(
              unlockedFeatureKeys: {'critical_cut'},
            ),
          ),
        );

    final outcome = await controller.tap();

    expect(outcome.isCritical, isTrue);
    expect(outcome.criticalMultiplier, closeTo(3, 0.0001));
    expect(outcome.coins, 30);
    expect(controller.state.stats.criticalCutCount, 1);
  });

  test(
    'golden doner spawns while active and pays only when completed',
    () async {
      var nowUtc = DateTime.utc(2026, 4, 1, 12);
      final goldenConfig = _activePlayConfig(
        baseTapValue: 10,
        goldenDonerMinSpawnInterval: const Duration(seconds: 1),
        goldenDonerMaxSpawnInterval: const Duration(seconds: 1),
        goldenDonerActiveDuration: const Duration(seconds: 5),
        goldenDonerRequiredHits: 2,
      );
      final controller =
          GameController(
            config: goldenConfig,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(goldenConfig, nowUtc: nowUtc).copyWith(
              milestones: const MilestoneState(
                unlockedFeatureKeys: {'golden_doner'},
              ),
            ),
          );

      nowUtc = nowUtc.add(const Duration(seconds: 1));
      controller.tick(const Duration(seconds: 1));

      expect(
        controller.activePlaySnapshotListenable.value.goldenDonerActive,
        isTrue,
      );
      expect(controller.state.goldenDoner.requiredHits, 2);

      final firstHit = await controller.tap();
      final secondHit = await controller.tap();

      expect(firstHit.goldenDonerHit, isTrue);
      expect(firstHit.goldenDonerCompleted, isFalse);
      expect(secondHit.goldenDonerCompleted, isTrue);
      expect(secondHit.goldenDonerReward, greaterThanOrEqualTo(500));
      expect(controller.state.stats.goldenDonerCollected, 1);
      expect(controller.state.goldenDoner.isActiveAt(nowUtc), isFalse);
      expect(
        controller.state.cash,
        greaterThanOrEqualTo(secondHit.goldenDonerReward),
      );
    },
  );

  test(
    'expired golden doner gives no reward after background checkpoint',
    () async {
      var nowUtc = DateTime.utc(2026, 4, 1, 12);
      final goldenConfig = _activePlayConfig(
        goldenDonerMinSpawnInterval: const Duration(seconds: 1),
        goldenDonerMaxSpawnInterval: const Duration(seconds: 1),
        goldenDonerActiveDuration: const Duration(seconds: 2),
        goldenDonerRequiredHits: 2,
      );
      final controller =
          GameController(
            config: goldenConfig,
            saveRepository: _RecordingSaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(goldenConfig, nowUtc: nowUtc).copyWith(
              milestones: const MilestoneState(
                unlockedFeatureKeys: {'golden_doner'},
              ),
            ),
          );

      nowUtc = nowUtc.add(const Duration(seconds: 1));
      controller.tick(const Duration(seconds: 1));
      expect(controller.state.goldenDoner.isActiveAt(nowUtc), isTrue);

      nowUtc = nowUtc.add(const Duration(seconds: 5));
      await controller.checkpointLifecycle();

      expect(controller.state.goldenDoner.isActiveAt(nowUtc), isFalse);
      expect(controller.state.stats.goldenDonerCollected, 0);
    },
  );
}

EconomyConfig _activePlayConfig({
  int baseTapValue = 1,
  double criticalBaseChance = 0.03,
  double criticalMaxChance = 0.40,
  Duration goldenDonerMinSpawnInterval = const Duration(seconds: 90),
  Duration goldenDonerMaxSpawnInterval = const Duration(seconds: 240),
  Duration goldenDonerActiveDuration = const Duration(seconds: 6),
  int goldenDonerRequiredHits = 10,
}) {
  final config = EconomyConfig.standard();
  return EconomyConfig(
    baseTapValue: baseTapValue,
    rushIncomeMultiplier: config.rushIncomeMultiplier,
    rushDuration: config.rushDuration,
    rushCooldown: config.rushCooldown,
    offlineCap: config.offlineCap,
    prestigeThreshold: config.prestigeThreshold,
    prestigeBonusPerPoint: config.prestigeBonusPerPoint,
    upgrades: config.upgrades,
    criticalBaseChance: criticalBaseChance,
    criticalMaxChance: criticalMaxChance,
    goldenDonerMinSpawnInterval: goldenDonerMinSpawnInterval,
    goldenDonerMaxSpawnInterval: goldenDonerMaxSpawnInterval,
    goldenDonerActiveDuration: goldenDonerActiveDuration,
    goldenDonerRequiredHits: goldenDonerRequiredHits,
  );
}

class _RecordingSaveRepository implements SaveRepository {
  GameState? _state;

  GameState? get savedState => _state;

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

class _FixedRandom implements math.Random {
  const _FixedRandom(this.value);

  final double value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => (value * max).floor().clamp(0, max - 1);
}
