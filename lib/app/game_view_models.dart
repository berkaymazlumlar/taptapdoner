import 'package:flutter/foundation.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

@immutable
class GameHudSnapshot {
  const GameHudSnapshot({
    required this.cash,
    required this.passiveIncomePerSecond,
    required this.reputation,
    required this.tapValue,
  });

  final int cash;
  final double passiveIncomePerSecond;
  final int reputation;
  final int tapValue;

  @override
  bool operator ==(Object other) {
    return other is GameHudSnapshot &&
        cash == other.cash &&
        passiveIncomePerSecond == other.passiveIncomePerSecond &&
        reputation == other.reputation &&
        tapValue == other.tapValue;
  }

  @override
  int get hashCode =>
      Object.hash(cash, passiveIncomePerSecond, reputation, tapValue);
}

@immutable
class RushSnapshot {
  const RushSnapshot({
    required this.isActive,
    required this.canStart,
    required this.remaining,
    required this.cooldownRemaining,
  });

  final bool isActive;
  final bool canStart;
  final Duration remaining;
  final Duration cooldownRemaining;

  @override
  bool operator ==(Object other) {
    return other is RushSnapshot &&
        isActive == other.isActive &&
        canStart == other.canStart &&
        remaining == other.remaining &&
        cooldownRemaining == other.cooldownRemaining;
  }

  @override
  int get hashCode =>
      Object.hash(isActive, canStart, remaining, cooldownRemaining);
}

@immutable
class QuestSnapshot {
  const QuestSnapshot({
    required this.questId,
    required this.status,
    required this.currentValue,
    required this.targetValue,
    required this.rewardClaimed,
  });

  final String questId;
  final QuestStatus status;
  final double currentValue;
  final double targetValue;
  final bool rewardClaimed;

  bool get canClaim =>
      status == QuestStatus.completed && rewardClaimed == false;

  double get progress {
    if (targetValue <= 0) {
      return 0;
    }
    return (currentValue / targetValue).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is QuestSnapshot &&
        questId == other.questId &&
        status == other.status &&
        currentValue == other.currentValue &&
        targetValue == other.targetValue &&
        rewardClaimed == other.rewardClaimed;
  }

  @override
  int get hashCode =>
      Object.hash(questId, status, currentValue, targetValue, rewardClaimed);
}

@immutable
class ShopUpgradeSnapshot {
  const ShopUpgradeSnapshot({
    required this.totalLevel,
    required this.itemLevel,
    required this.maxItemLevel,
    required this.maxLevel,
    required this.currentItemTier,
    required this.currentItemKey,
    required this.currentEffect,
    required this.nextEffect,
    required this.maxed,
    required this.unlocksNextItem,
    required this.cost,
    required this.canAfford,
    this.nextItemKey,
    this.nextItemEffect,
    this.nextMilestoneItemKey,
    this.nextMilestoneLevel,
    this.nextMilestoneReward,
  });

  final int totalLevel;
  final int itemLevel;
  final int maxItemLevel;
  final int maxLevel;
  final int currentItemTier;
  final String currentItemKey;
  final String? nextItemKey;
  final double? nextItemEffect;
  final String? nextMilestoneItemKey;
  final int? nextMilestoneLevel;
  final MilestoneReward? nextMilestoneReward;
  final double currentEffect;
  final double nextEffect;
  final bool maxed;
  final bool unlocksNextItem;
  final int cost;
  final bool canAfford;

  bool get purchased => totalLevel > 0;

  @override
  bool operator ==(Object other) {
    return other is ShopUpgradeSnapshot &&
        totalLevel == other.totalLevel &&
        itemLevel == other.itemLevel &&
        maxItemLevel == other.maxItemLevel &&
        maxLevel == other.maxLevel &&
        currentItemTier == other.currentItemTier &&
        currentItemKey == other.currentItemKey &&
        nextItemKey == other.nextItemKey &&
        nextItemEffect == other.nextItemEffect &&
        nextMilestoneItemKey == other.nextMilestoneItemKey &&
        nextMilestoneLevel == other.nextMilestoneLevel &&
        nextMilestoneReward == other.nextMilestoneReward &&
        currentEffect == other.currentEffect &&
        nextEffect == other.nextEffect &&
        maxed == other.maxed &&
        unlocksNextItem == other.unlocksNextItem &&
        cost == other.cost &&
        canAfford == other.canAfford;
  }

  @override
  int get hashCode => Object.hash(
    totalLevel,
    itemLevel,
    maxItemLevel,
    maxLevel,
    currentItemTier,
    currentItemKey,
    nextItemKey,
    nextItemEffect,
    nextMilestoneItemKey,
    nextMilestoneLevel,
    nextMilestoneReward,
    currentEffect,
    nextEffect,
    maxed,
    unlocksNextItem,
    cost,
    canAfford,
  );
}

@immutable
class ShopSnapshot {
  const ShopSnapshot({required this.hud, required this.upgrades});

  final GameHudSnapshot hud;
  final Map<UpgradeId, ShopUpgradeSnapshot> upgrades;

  @override
  bool operator ==(Object other) {
    return other is ShopSnapshot &&
        hud == other.hud &&
        mapEquals(upgrades, other.upgrades);
  }

  @override
  int get hashCode => Object.hash(
    hud,
    Object.hashAll(
      upgrades.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}

@immutable
class PrestigeSnapshot {
  const PrestigeSnapshot({
    required this.availablePoints,
    required this.reputation,
    required this.runCashEarned,
    required this.threshold,
    required this.currentMultiplier,
    required this.newMultiplier,
    required this.resetItems,
    required this.keptItems,
  });

  final int availablePoints;
  final int reputation;
  final int runCashEarned;
  final int threshold;
  final double currentMultiplier;
  final double newMultiplier;
  final List<String> resetItems;
  final List<String> keptItems;

  int get currentTotalEarned => runCashEarned;
  int get pointsToGain => availablePoints;

  @override
  bool operator ==(Object other) {
    return other is PrestigeSnapshot &&
        availablePoints == other.availablePoints &&
        reputation == other.reputation &&
        runCashEarned == other.runCashEarned &&
        threshold == other.threshold &&
        currentMultiplier == other.currentMultiplier &&
        newMultiplier == other.newMultiplier &&
        listEquals(resetItems, other.resetItems) &&
        listEquals(keptItems, other.keptItems);
  }

  @override
  int get hashCode => Object.hash(
    availablePoints,
    reputation,
    runCashEarned,
    threshold,
    currentMultiplier,
    newMultiplier,
    Object.hashAll(resetItems),
    Object.hashAll(keptItems),
  );
}
