import 'dart:math' as math;

import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

class StarterQuestEngine {
  const StarterQuestEngine(this.config);

  final EconomyConfig config;

  GameState refresh(GameState state) {
    var nextState = _syncDerivedStats(state);
    final nextProgress = _evaluateProgress(nextState);
    if (_sameProgress(nextState.quests, nextProgress) &&
        identical(nextState, state)) {
      return state;
    }
    return nextState.copyWith(quests: nextProgress);
  }

  GameState claimActiveReward(GameState state, {required DateTime nowUtc}) {
    var nextState = refresh(state);
    final definition = _claimableDefinition(nextState);
    if (definition == null) {
      return state;
    }

    nextState = _applyReward(nextState, definition.reward, nowUtc: nowUtc);
    final nextProgress = Map<String, QuestProgress>.from(nextState.quests);
    final progress = nextProgress[definition.id]!;
    nextProgress[definition.id] = progress.copyWith(
      status: QuestStatus.claimed,
      currentValue: math.max(progress.currentValue, progress.targetValue),
      rewardClaimed: true,
    );
    return refresh(nextState.copyWith(quests: nextProgress));
  }

  QuestProgress? activeQuest(GameState state) {
    final refreshed = refresh(state);
    for (final definition in StarterQuestCatalog.definitions) {
      final progress = refreshed.quests[definition.id];
      if (progress == null) {
        continue;
      }
      if (progress.status == QuestStatus.active ||
          progress.status == QuestStatus.completed) {
        return progress;
      }
    }
    return null;
  }

  Map<String, QuestProgress> _evaluateProgress(GameState state) {
    final progress = _mergedProgress(state.quests);
    var previousClaimed = true;

    for (final definition in StarterQuestCatalog.definitions) {
      final existing = progress[definition.id]!;
      if (!previousClaimed) {
        progress[definition.id] = existing.copyWith(
          status: QuestStatus.locked,
          currentValue: 0,
          targetValue: definition.targetValue,
          rewardClaimed: false,
        );
        continue;
      }

      if (existing.status == QuestStatus.claimed || existing.rewardClaimed) {
        progress[definition.id] = existing.copyWith(
          status: QuestStatus.claimed,
          currentValue: math.max(existing.currentValue, definition.targetValue),
          targetValue: definition.targetValue,
          rewardClaimed: true,
        );
        previousClaimed = true;
        continue;
      }

      final currentValue = _currentValueFor(state, definition);
      progress[definition.id] = existing.copyWith(
        status: currentValue >= definition.targetValue
            ? QuestStatus.completed
            : QuestStatus.active,
        currentValue: currentValue,
        targetValue: definition.targetValue,
        rewardClaimed: false,
      );
      previousClaimed = false;
    }

    return Map<String, QuestProgress>.unmodifiable(progress);
  }

  Map<String, QuestProgress> _mergedProgress(
    Map<String, QuestProgress> existing,
  ) {
    final initial = StarterQuestCatalog.initialProgress();
    final progress = <String, QuestProgress>{};
    for (final definition in StarterQuestCatalog.definitions) {
      final fallback = initial[definition.id]!;
      final candidate = existing[definition.id];
      progress[definition.id] = candidate == null
          ? fallback
          : QuestProgress(
              questId: definition.id,
              status: candidate.status,
              currentValue: candidate.currentValue,
              targetValue: definition.targetValue,
              rewardClaimed: candidate.rewardClaimed,
            );
    }
    return progress;
  }

  StarterQuestDefinition? _claimableDefinition(GameState state) {
    for (final definition in StarterQuestCatalog.definitions) {
      final progress = state.quests[definition.id];
      if (progress?.status == QuestStatus.completed &&
          progress?.rewardClaimed == false) {
        return definition;
      }
    }
    return null;
  }

  double _currentValueFor(GameState state, StarterQuestDefinition definition) {
    return switch (definition.goalType) {
      StarterQuestGoalType.tapCount => state.stats.tapCount.toDouble(),
      StarterQuestGoalType.totalUpgradesPurchased =>
        math
            .max(
              state.stats.totalUpgradesPurchased,
              _totalUpgradePurchasesFromState(state),
            )
            .toDouble(),
      StarterQuestGoalType.rustyKnifeLevel => _rustyKnifeLevel(state),
      StarterQuestGoalType.lifetimeCash => state.lifetimeCash.toDouble(),
      StarterQuestGoalType.knifeLevel => _knifeLevel(state),
      StarterQuestGoalType.criticalCutCount =>
        state.stats.criticalCutCount.toDouble(),
      StarterQuestGoalType.staffPurchased =>
        _totalUpgradeLevel(state, UpgradeId.staff) >= 1 ? 1.0 : 0.0,
      StarterQuestGoalType.passiveIncomeActiveSeconds =>
        state.stats.passiveIncomeActiveSeconds,
      StarterQuestGoalType.maxCombo => state.stats.maxCombo.toDouble(),
      StarterQuestGoalType.turboUsedCount =>
        state.stats.turboUsedCount.toDouble(),
      StarterQuestGoalType.goldenDonerCollected =>
        state.stats.goldenDonerCollected.toDouble(),
      StarterQuestGoalType.knifeItemIndex =>
        state.upgrade(UpgradeId.knife).itemIndex.toDouble(),
      StarterQuestGoalType.shopLevel => _shopLevel(state).toDouble(),
      StarterQuestGoalType.openPrestigeScreenOnce =>
        state.stats.openPrestigeScreenOnce ? 1.0 : 0.0,
    };
  }

  GameState _syncDerivedStats(GameState state) {
    final derivedShopLevel = _derivedShopLevel(state);
    if (derivedShopLevel <= state.stats.shopLevel) {
      return state;
    }
    return state.copyWith(
      stats: state.stats.copyWith(shopLevel: derivedShopLevel),
    );
  }

  int _derivedShopLevel(GameState state) {
    final knifeReady = _totalUpgradeLevel(state, UpgradeId.knife) >= 20;
    final staffReady = _totalUpgradeLevel(state, UpgradeId.staff) >= 5;
    if (state.lifetimeCash >= 10000 && knifeReady && staffReady) {
      return 2;
    }
    return 1;
  }

  int _shopLevel(GameState state) {
    return math.max(state.stats.shopLevel, _derivedShopLevel(state));
  }

  double _rustyKnifeLevel(GameState state) {
    final knife = state.upgrade(UpgradeId.knife);
    if (knife.itemIndex > 0) {
      return StarterQuestCatalog.byId['starter_rusty_knife_5']!.targetValue;
    }
    return knife.level.toDouble();
  }

  double _knifeLevel(GameState state) {
    final knife = state.upgrade(UpgradeId.knife);
    if (knife.itemIndex > 0) {
      return StarterQuestCatalog.byId['starter_rusty_knife_10']!.targetValue;
    }
    return knife.level.toDouble();
  }

  int _totalUpgradePurchasesFromState(GameState state) {
    var total = 0;
    for (final definition in config.upgrades) {
      total += _totalUpgradeLevel(state, definition.id);
    }
    return total;
  }

  int _totalUpgradeLevel(GameState state, UpgradeId id) {
    final definition = config.upgrade(id);
    final upgrade = state.upgrade(id);
    return definition.totalLevelForPosition(
      itemIndex: upgrade.itemIndex,
      itemLevel: upgrade.level,
    );
  }

  GameState _applyReward(
    GameState state,
    StarterQuestReward reward, {
    required DateTime nowUtc,
  }) {
    var nextState = state;
    if (reward.cash > 0) {
      nextState = _addCoins(nextState, reward.cash);
    }
    if (reward.chests > 0 ||
        reward.featureKey != null ||
        reward.comboMultiplierBonus > 0 ||
        reward.turboChargeSpeedPercent > 0 ||
        reward.globalBonusPercent > 0) {
      final nextFeatures = Set<String>.from(
        nextState.milestones.unlockedFeatureKeys,
      );
      final featureKey = reward.featureKey;
      if (featureKey != null && featureKey.isNotEmpty) {
        nextFeatures.add(featureKey);
      }
      nextState = nextState.copyWith(
        milestones: nextState.milestones.copyWith(
          unlockedFeatureKeys: nextFeatures,
          chests: nextState.milestones.chests + reward.chests,
          comboMultiplierBonus:
              nextState.milestones.comboMultiplierBonus +
              reward.comboMultiplierBonus,
          turboChargeSpeedPercent:
              nextState.milestones.turboChargeSpeedPercent +
              reward.turboChargeSpeedPercent,
          globalBonusPercent:
              nextState.milestones.globalBonusPercent +
              reward.globalBonusPercent,
        ),
      );
    }
    if (reward.passiveBoostDuration > Duration.zero) {
      nextState = nextState.copyWith(
        passiveBoost: TimedEffectState(
          endsAtUtc: nowUtc.add(reward.passiveBoostDuration),
        ),
      );
    }
    if (reward.shopLevel > 0) {
      nextState = nextState.copyWith(
        stats: nextState.stats.copyWith(
          shopLevel: math.max(nextState.stats.shopLevel, reward.shopLevel),
        ),
      );
    }
    return nextState;
  }

  GameState _addCoins(GameState state, int coins) {
    if (coins <= 0) {
      return state;
    }
    return state.copyWith(
      cash: state.cash + coins,
      lifetimeCash: state.lifetimeCash + coins,
      prestige: state.prestige.copyWith(
        runCashEarned: state.prestige.runCashEarned + coins,
      ),
    );
  }

  bool _sameProgress(
    Map<String, QuestProgress> previous,
    Map<String, QuestProgress> next,
  ) {
    if (previous.length != next.length) {
      return false;
    }
    for (final entry in next.entries) {
      final other = previous[entry.key];
      if (other == null ||
          other.questId != entry.value.questId ||
          other.status != entry.value.status ||
          other.currentValue != entry.value.currentValue ||
          other.targetValue != entry.value.targetValue ||
          other.rewardClaimed != entry.value.rewardClaimed) {
        return false;
      }
    }
    return true;
  }
}
