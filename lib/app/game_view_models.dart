import 'package:flutter/foundation.dart';
import 'package:taptapdoner/domain/goals/goal_models.dart';
import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/progression/prestige_shop_catalog.dart';
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
class ActivePlaySnapshot {
  const ActivePlaySnapshot({
    required this.comboUnlocked,
    required this.currentCombo,
    required this.maxCombo,
    required this.comboMultiplier,
    required this.comboRemaining,
    required this.criticalUnlocked,
    required this.criticalChance,
    required this.criticalMultiplier,
    required this.goldenDonerUnlocked,
    required this.goldenDonerActive,
    required this.goldenDonerRemaining,
    required this.goldenDonerHits,
    required this.goldenDonerRequiredHits,
    required this.goldenDonerRewardPreview,
  });

  final bool comboUnlocked;
  final int currentCombo;
  final int maxCombo;
  final double comboMultiplier;
  final Duration comboRemaining;
  final bool criticalUnlocked;
  final double criticalChance;
  final double criticalMultiplier;
  final bool goldenDonerUnlocked;
  final bool goldenDonerActive;
  final Duration goldenDonerRemaining;
  final int goldenDonerHits;
  final int goldenDonerRequiredHits;
  final int goldenDonerRewardPreview;

  bool get hasCombo => comboUnlocked && currentCombo > 0;

  double get goldenDonerProgress {
    if (goldenDonerRequiredHits <= 0) {
      return 0;
    }
    return (goldenDonerHits / goldenDonerRequiredHits).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is ActivePlaySnapshot &&
        comboUnlocked == other.comboUnlocked &&
        currentCombo == other.currentCombo &&
        maxCombo == other.maxCombo &&
        comboMultiplier == other.comboMultiplier &&
        comboRemaining == other.comboRemaining &&
        criticalUnlocked == other.criticalUnlocked &&
        criticalChance == other.criticalChance &&
        criticalMultiplier == other.criticalMultiplier &&
        goldenDonerUnlocked == other.goldenDonerUnlocked &&
        goldenDonerActive == other.goldenDonerActive &&
        goldenDonerRemaining == other.goldenDonerRemaining &&
        goldenDonerHits == other.goldenDonerHits &&
        goldenDonerRequiredHits == other.goldenDonerRequiredHits &&
        goldenDonerRewardPreview == other.goldenDonerRewardPreview;
  }

  @override
  int get hashCode => Object.hash(
    comboUnlocked,
    currentCombo,
    maxCombo,
    comboMultiplier,
    comboRemaining,
    criticalUnlocked,
    criticalChance,
    criticalMultiplier,
    goldenDonerUnlocked,
    goldenDonerActive,
    goldenDonerRemaining,
    goldenDonerHits,
    goldenDonerRequiredHits,
    goldenDonerRewardPreview,
  );
}

@immutable
class CustomerOrderSnapshot {
  const CustomerOrderSnapshot({
    required this.reputationLevel,
    required this.reputationInCurrentLevel,
    required this.reputationRequiredForNextLevel,
    required this.totalReputation,
    required this.completedOrderCount,
    required this.failedOrderCount,
    required this.unlockedCustomerTypeCount,
    required this.nextSpawnRemaining,
    this.activeOrder,
  });

  final int reputationLevel;
  final int reputationInCurrentLevel;
  final int reputationRequiredForNextLevel;
  final int totalReputation;
  final int completedOrderCount;
  final int failedOrderCount;
  final int unlockedCustomerTypeCount;
  final Duration nextSpawnRemaining;
  final ActiveCustomerOrderSnapshot? activeOrder;

  double get reputationProgress {
    if (reputationRequiredForNextLevel <= 0) {
      return 0;
    }
    return (reputationInCurrentLevel / reputationRequiredForNextLevel)
        .clamp(0, 1)
        .toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is CustomerOrderSnapshot &&
        reputationLevel == other.reputationLevel &&
        reputationInCurrentLevel == other.reputationInCurrentLevel &&
        reputationRequiredForNextLevel ==
            other.reputationRequiredForNextLevel &&
        totalReputation == other.totalReputation &&
        completedOrderCount == other.completedOrderCount &&
        failedOrderCount == other.failedOrderCount &&
        unlockedCustomerTypeCount == other.unlockedCustomerTypeCount &&
        nextSpawnRemaining == other.nextSpawnRemaining &&
        activeOrder == other.activeOrder;
  }

  @override
  int get hashCode => Object.hash(
    reputationLevel,
    reputationInCurrentLevel,
    reputationRequiredForNextLevel,
    totalReputation,
    completedOrderCount,
    failedOrderCount,
    unlockedCustomerTypeCount,
    nextSpawnRemaining,
    activeOrder,
  );
}

@immutable
class ActiveCustomerOrderSnapshot {
  const ActiveCustomerOrderSnapshot({
    required this.id,
    required this.customerTypeId,
    required this.customerName,
    required this.title,
    required this.description,
    required this.currentValue,
    required this.targetValue,
    required this.remaining,
    required this.rewardLabel,
  });

  final String id;
  final String customerTypeId;
  final String customerName;
  final String title;
  final String description;
  final double currentValue;
  final double targetValue;
  final Duration remaining;
  final String rewardLabel;

  double get progress {
    if (targetValue <= 0) {
      return 0;
    }
    return (currentValue / targetValue).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveCustomerOrderSnapshot &&
        id == other.id &&
        customerTypeId == other.customerTypeId &&
        customerName == other.customerName &&
        title == other.title &&
        description == other.description &&
        currentValue == other.currentValue &&
        targetValue == other.targetValue &&
        remaining == other.remaining &&
        rewardLabel == other.rewardLabel;
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerTypeId,
    customerName,
    title,
    description,
    currentValue,
    targetValue,
    remaining,
    rewardLabel,
  );
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
class GoalBoardSnapshot {
  const GoalBoardSnapshot({
    required this.dailyGoals,
    required this.weeklyGoals,
    required this.prestigeRunGoals,
    required this.eventGoals,
  });

  final List<GoalProgressSnapshot> dailyGoals;
  final List<GoalProgressSnapshot> weeklyGoals;
  final List<GoalProgressSnapshot> prestigeRunGoals;
  final List<GoalProgressSnapshot> eventGoals;

  Iterable<GoalProgressSnapshot> get allGoals sync* {
    yield* dailyGoals;
    yield* weeklyGoals;
    yield* prestigeRunGoals;
    yield* eventGoals;
  }

  int get claimableCount {
    return allGoals.where((goal) => goal.canClaim).length;
  }

  int get completedDailyCount {
    return dailyGoals.where((goal) => goal.completed).length;
  }

  int get completedWeeklyCount {
    return weeklyGoals.where((goal) => goal.completed).length;
  }

  @override
  bool operator ==(Object other) {
    return other is GoalBoardSnapshot &&
        listEquals(dailyGoals, other.dailyGoals) &&
        listEquals(weeklyGoals, other.weeklyGoals) &&
        listEquals(prestigeRunGoals, other.prestigeRunGoals) &&
        listEquals(eventGoals, other.eventGoals);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(dailyGoals),
    Object.hashAll(weeklyGoals),
    Object.hashAll(prestigeRunGoals),
    Object.hashAll(eventGoals),
  );
}

@immutable
class GoalProgressSnapshot {
  const GoalProgressSnapshot({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.currentValue,
    required this.targetValue,
    required this.status,
    required this.rewardClaimed,
    required this.rewardLabel,
    required this.expiresAtMillis,
  });

  final String id;
  final String title;
  final String description;
  final GoalCategory category;
  final double currentValue;
  final double targetValue;
  final GoalStatus status;
  final bool rewardClaimed;
  final String rewardLabel;
  final int? expiresAtMillis;

  bool get completed => status == GoalStatus.completed || rewardClaimed;

  bool get canClaim => status == GoalStatus.completed && !rewardClaimed;

  double get progress {
    if (targetValue <= 0) {
      return 0;
    }
    return (currentValue / targetValue).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is GoalProgressSnapshot &&
        id == other.id &&
        title == other.title &&
        description == other.description &&
        category == other.category &&
        currentValue == other.currentValue &&
        targetValue == other.targetValue &&
        status == other.status &&
        rewardClaimed == other.rewardClaimed &&
        rewardLabel == other.rewardLabel &&
        expiresAtMillis == other.expiresAtMillis;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    category,
    currentValue,
    targetValue,
    status,
    rewardClaimed,
    rewardLabel,
    expiresAtMillis,
  );
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
  const ShopSnapshot({
    required this.hud,
    required this.upgrades,
    required this.progression,
  });

  final GameHudSnapshot hud;
  final Map<UpgradeId, ShopUpgradeSnapshot> upgrades;
  final ShopProgressionSnapshot progression;

  @override
  bool operator ==(Object other) {
    return other is ShopSnapshot &&
        hud == other.hud &&
        mapEquals(upgrades, other.upgrades) &&
        progression == other.progression;
  }

  @override
  int get hashCode => Object.hash(
    hud,
    Object.hashAll(
      upgrades.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    progression,
  );
}

@immutable
class ShopRequirementSnapshot {
  const ShopRequirementSnapshot({required this.label, required this.completed});

  final String label;
  final bool completed;

  @override
  bool operator ==(Object other) {
    return other is ShopRequirementSnapshot &&
        label == other.label &&
        completed == other.completed;
  }

  @override
  int get hashCode => Object.hash(label, completed);
}

@immutable
class ShopProgressionSnapshot {
  const ShopProgressionSnapshot({
    required this.currentLevel,
    required this.currentName,
    required this.highestLevel,
    required this.incomeMultiplier,
    required this.nextLevel,
    required this.nextName,
    required this.nextIncomeMultiplier,
    required this.requirements,
  });

  final int currentLevel;
  final String currentName;
  final int highestLevel;
  final double incomeMultiplier;
  final int? nextLevel;
  final String? nextName;
  final double? nextIncomeMultiplier;
  final List<ShopRequirementSnapshot> requirements;

  int get completedRequirements {
    return requirements.where((requirement) => requirement.completed).length;
  }

  @override
  bool operator ==(Object other) {
    return other is ShopProgressionSnapshot &&
        currentLevel == other.currentLevel &&
        currentName == other.currentName &&
        highestLevel == other.highestLevel &&
        incomeMultiplier == other.incomeMultiplier &&
        nextLevel == other.nextLevel &&
        nextName == other.nextName &&
        nextIncomeMultiplier == other.nextIncomeMultiplier &&
        listEquals(requirements, other.requirements);
  }

  @override
  int get hashCode => Object.hash(
    currentLevel,
    currentName,
    highestLevel,
    incomeMultiplier,
    nextLevel,
    nextName,
    nextIncomeMultiplier,
    Object.hashAll(requirements),
  );
}

@immutable
class ShopLevelUpSnapshot {
  const ShopLevelUpSnapshot({
    required this.previousLevelName,
    required this.currentLevelName,
    required this.unlockLabel,
    required this.incomeMultiplier,
  });

  final String previousLevelName;
  final String currentLevelName;
  final String unlockLabel;
  final double incomeMultiplier;
}

@immutable
class BranchBoardSnapshot {
  const BranchBoardSnapshot({
    required this.systemVisible,
    required this.incomeActive,
    required this.branchIncomePerSecond,
    required this.totalBranchIncomeEarned,
    required this.unlockedBranchCount,
    required this.totalBranchCount,
    required this.totalBranchLevel,
    required this.regions,
    required this.branches,
  });

  final bool systemVisible;
  final bool incomeActive;
  final double branchIncomePerSecond;
  final double totalBranchIncomeEarned;
  final int unlockedBranchCount;
  final int totalBranchCount;
  final int totalBranchLevel;
  final List<BranchRegionSnapshot> regions;
  final List<BranchProgressSnapshot> branches;

  @override
  bool operator ==(Object other) {
    return other is BranchBoardSnapshot &&
        systemVisible == other.systemVisible &&
        incomeActive == other.incomeActive &&
        branchIncomePerSecond == other.branchIncomePerSecond &&
        totalBranchIncomeEarned == other.totalBranchIncomeEarned &&
        unlockedBranchCount == other.unlockedBranchCount &&
        totalBranchCount == other.totalBranchCount &&
        totalBranchLevel == other.totalBranchLevel &&
        listEquals(regions, other.regions) &&
        listEquals(branches, other.branches);
  }

  @override
  int get hashCode => Object.hash(
    systemVisible,
    incomeActive,
    branchIncomePerSecond,
    totalBranchIncomeEarned,
    unlockedBranchCount,
    totalBranchCount,
    totalBranchLevel,
    Object.hashAll(regions),
    Object.hashAll(branches),
  );
}

@immutable
class BranchRegionSnapshot {
  const BranchRegionSnapshot({
    required this.id,
    required this.name,
    required this.unlocked,
    required this.completed,
    required this.unlockedBranchCount,
    required this.totalBranchCount,
    required this.assetKey,
  });

  final String id;
  final String name;
  final bool unlocked;
  final bool completed;
  final int unlockedBranchCount;
  final int totalBranchCount;
  final String assetKey;

  @override
  bool operator ==(Object other) {
    return other is BranchRegionSnapshot &&
        id == other.id &&
        name == other.name &&
        unlocked == other.unlocked &&
        completed == other.completed &&
        unlockedBranchCount == other.unlockedBranchCount &&
        totalBranchCount == other.totalBranchCount &&
        assetKey == other.assetKey;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    unlocked,
    completed,
    unlockedBranchCount,
    totalBranchCount,
    assetKey,
  );
}

@immutable
class BranchProgressSnapshot {
  const BranchProgressSnapshot({
    required this.id,
    required this.name,
    required this.cityName,
    required this.regionId,
    required this.regionName,
    required this.description,
    required this.assetKey,
    required this.unlocked,
    required this.level,
    required this.maxLevel,
    required this.unlockCost,
    required this.levelUpCost,
    required this.canUnlock,
    required this.canLevelUp,
    required this.incomePerSecond,
    required this.nextIncomePerSecond,
    required this.requirements,
    required this.reachedMilestoneCount,
    required this.totalMilestoneCount,
    required this.managerSlotUnlocked,
    required this.canAssignManager,
    this.assignedManagerId,
    this.assignedManagerName,
    this.suggestedManagerId,
    this.suggestedManagerName,
  });

  final String id;
  final String name;
  final String cityName;
  final String regionId;
  final String regionName;
  final String description;
  final String assetKey;
  final bool unlocked;
  final int level;
  final int maxLevel;
  final int unlockCost;
  final int levelUpCost;
  final bool canUnlock;
  final bool canLevelUp;
  final double incomePerSecond;
  final double nextIncomePerSecond;
  final List<BranchRequirementSnapshot> requirements;
  final int reachedMilestoneCount;
  final int totalMilestoneCount;
  final bool managerSlotUnlocked;
  final bool canAssignManager;
  final String? assignedManagerId;
  final String? assignedManagerName;
  final String? suggestedManagerId;
  final String? suggestedManagerName;

  bool get maxed => unlocked && level >= maxLevel;

  double get levelProgress {
    if (!unlocked || maxLevel <= 0) {
      return 0;
    }
    return (level / maxLevel).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is BranchProgressSnapshot &&
        id == other.id &&
        name == other.name &&
        cityName == other.cityName &&
        regionId == other.regionId &&
        regionName == other.regionName &&
        description == other.description &&
        assetKey == other.assetKey &&
        unlocked == other.unlocked &&
        level == other.level &&
        maxLevel == other.maxLevel &&
        unlockCost == other.unlockCost &&
        levelUpCost == other.levelUpCost &&
        canUnlock == other.canUnlock &&
        canLevelUp == other.canLevelUp &&
        incomePerSecond == other.incomePerSecond &&
        nextIncomePerSecond == other.nextIncomePerSecond &&
        listEquals(requirements, other.requirements) &&
        reachedMilestoneCount == other.reachedMilestoneCount &&
        totalMilestoneCount == other.totalMilestoneCount &&
        managerSlotUnlocked == other.managerSlotUnlocked &&
        canAssignManager == other.canAssignManager &&
        assignedManagerId == other.assignedManagerId &&
        assignedManagerName == other.assignedManagerName &&
        suggestedManagerId == other.suggestedManagerId &&
        suggestedManagerName == other.suggestedManagerName;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    cityName,
    regionId,
    regionName,
    description,
    assetKey,
    unlocked,
    level,
    maxLevel,
    unlockCost,
    levelUpCost,
    canUnlock,
    canLevelUp,
    incomePerSecond,
    nextIncomePerSecond,
    Object.hashAll(requirements),
    reachedMilestoneCount,
    totalMilestoneCount,
    managerSlotUnlocked,
    canAssignManager,
    assignedManagerId,
    assignedManagerName,
    suggestedManagerId,
    suggestedManagerName,
  ]);
}

@immutable
class BranchRequirementSnapshot {
  const BranchRequirementSnapshot({
    required this.label,
    required this.completed,
  });

  final String label;
  final bool completed;

  @override
  bool operator ==(Object other) {
    return other is BranchRequirementSnapshot &&
        label == other.label &&
        completed == other.completed;
  }

  @override
  int get hashCode => Object.hash(label, completed);
}

@immutable
class PrestigeSnapshot {
  const PrestigeSnapshot({
    required this.availablePoints,
    required this.reputation,
    required this.unspentPoints,
    required this.prestigeCount,
    required this.runCashEarned,
    required this.threshold,
    required this.currentMultiplier,
    required this.newMultiplier,
    required this.shopUpgrades,
    required this.resetItems,
    required this.keptItems,
  });

  final int availablePoints;
  final int reputation;
  final int unspentPoints;
  final int prestigeCount;
  final int runCashEarned;
  final int threshold;
  final double currentMultiplier;
  final double newMultiplier;
  final List<PrestigeShopUpgradeSnapshot> shopUpgrades;
  final List<String> resetItems;
  final List<String> keptItems;

  int get currentTotalEarned => runCashEarned;
  int get pointsToGain => availablePoints;

  @override
  bool operator ==(Object other) {
    return other is PrestigeSnapshot &&
        availablePoints == other.availablePoints &&
        reputation == other.reputation &&
        unspentPoints == other.unspentPoints &&
        prestigeCount == other.prestigeCount &&
        runCashEarned == other.runCashEarned &&
        threshold == other.threshold &&
        currentMultiplier == other.currentMultiplier &&
        newMultiplier == other.newMultiplier &&
        listEquals(shopUpgrades, other.shopUpgrades) &&
        listEquals(resetItems, other.resetItems) &&
        listEquals(keptItems, other.keptItems);
  }

  @override
  int get hashCode => Object.hash(
    availablePoints,
    reputation,
    unspentPoints,
    prestigeCount,
    runCashEarned,
    threshold,
    currentMultiplier,
    newMultiplier,
    Object.hashAll(shopUpgrades),
    Object.hashAll(resetItems),
    Object.hashAll(keptItems),
  );
}

@immutable
class PrestigeShopUpgradeSnapshot {
  const PrestigeShopUpgradeSnapshot({
    required this.id,
    required this.name,
    required this.description,
    required this.effectType,
    required this.level,
    required this.maxLevel,
    required this.cost,
    required this.canAfford,
    required this.maxed,
    required this.currentEffectLabel,
    required this.nextEffectLabel,
  });

  final String id;
  final String name;
  final String description;
  final PrestigeShopEffectType effectType;
  final int level;
  final int maxLevel;
  final int cost;
  final bool canAfford;
  final bool maxed;
  final String currentEffectLabel;
  final String nextEffectLabel;

  @override
  bool operator ==(Object other) {
    return other is PrestigeShopUpgradeSnapshot &&
        id == other.id &&
        name == other.name &&
        description == other.description &&
        effectType == other.effectType &&
        level == other.level &&
        maxLevel == other.maxLevel &&
        cost == other.cost &&
        canAfford == other.canAfford &&
        maxed == other.maxed &&
        currentEffectLabel == other.currentEffectLabel &&
        nextEffectLabel == other.nextEffectLabel;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    effectType,
    level,
    maxLevel,
    cost,
    canAfford,
    maxed,
    currentEffectLabel,
    nextEffectLabel,
  );
}

@immutable
class AchievementProgressSnapshot {
  const AchievementProgressSnapshot({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.currentValue,
    required this.targetValue,
    required this.completed,
    required this.rewardClaimed,
    required this.rewardLabel,
  });

  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final double currentValue;
  final double targetValue;
  final bool completed;
  final bool rewardClaimed;
  final String rewardLabel;

  bool get canClaim => completed && !rewardClaimed;

  double get progress {
    if (targetValue <= 0) {
      return 0;
    }
    return (currentValue / targetValue).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is AchievementProgressSnapshot &&
        id == other.id &&
        title == other.title &&
        description == other.description &&
        category == other.category &&
        currentValue == other.currentValue &&
        targetValue == other.targetValue &&
        completed == other.completed &&
        rewardClaimed == other.rewardClaimed &&
        rewardLabel == other.rewardLabel;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    category,
    currentValue,
    targetValue,
    completed,
    rewardClaimed,
    rewardLabel,
  );
}

@immutable
class CollectionItemSnapshot {
  const CollectionItemSnapshot({
    required this.id,
    required this.category,
    required this.name,
    required this.rarity,
    required this.unlocked,
    required this.bonusLabel,
  });

  final String id;
  final CollectionCategory category;
  final String name;
  final Rarity rarity;
  final bool unlocked;
  final String bonusLabel;

  @override
  bool operator ==(Object other) {
    return other is CollectionItemSnapshot &&
        id == other.id &&
        category == other.category &&
        name == other.name &&
        rarity == other.rarity &&
        unlocked == other.unlocked &&
        bonusLabel == other.bonusLabel;
  }

  @override
  int get hashCode =>
      Object.hash(id, category, name, rarity, unlocked, bonusLabel);
}

@immutable
class Collection2ItemSnapshot {
  const Collection2ItemSnapshot({
    required this.id,
    required this.kind,
    required this.name,
    required this.rarity,
    required this.currentShards,
    required this.requiredShards,
    required this.level,
    required this.maxLevel,
    required this.unlocked,
    required this.equipped,
    required this.bonusLabel,
    required this.assetKey,
  });

  final String id;
  final Collection2ItemKind kind;
  final String name;
  final Rarity rarity;
  final int currentShards;
  final int requiredShards;
  final int level;
  final int maxLevel;
  final bool unlocked;
  final bool equipped;
  final String bonusLabel;
  final String assetKey;

  double get progress {
    if (unlocked && maxLevel <= 1) {
      return 1;
    }
    if (requiredShards <= 0) {
      return 0;
    }
    return (currentShards / requiredShards).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return other is Collection2ItemSnapshot &&
        id == other.id &&
        kind == other.kind &&
        name == other.name &&
        rarity == other.rarity &&
        currentShards == other.currentShards &&
        requiredShards == other.requiredShards &&
        level == other.level &&
        maxLevel == other.maxLevel &&
        unlocked == other.unlocked &&
        equipped == other.equipped &&
        bonusLabel == other.bonusLabel &&
        assetKey == other.assetKey;
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    rarity,
    currentShards,
    requiredShards,
    level,
    maxLevel,
    unlocked,
    equipped,
    bonusLabel,
    assetKey,
  );
}

@immutable
class CollectionSetSnapshot {
  const CollectionSetSnapshot({
    required this.id,
    required this.name,
    required this.completed,
    required this.claimed,
    required this.bonusLabel,
    required this.requirementLabel,
  });

  final String id;
  final String name;
  final bool completed;
  final bool claimed;
  final String bonusLabel;
  final String requirementLabel;

  @override
  bool operator ==(Object other) {
    return other is CollectionSetSnapshot &&
        id == other.id &&
        name == other.name &&
        completed == other.completed &&
        claimed == other.claimed &&
        bonusLabel == other.bonusLabel &&
        requirementLabel == other.requirementLabel;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, completed, claimed, bonusLabel, requirementLabel);
}

@immutable
class ChestInventorySnapshot {
  const ChestInventorySnapshot({required this.counts});

  final Map<ChestType, int> counts;

  int count(ChestType type) => counts[type] ?? 0;

  int get totalCount {
    return ChestType.values.fold(0, (total, type) => total + count(type));
  }

  @override
  bool operator ==(Object other) {
    return other is ChestInventorySnapshot && mapEquals(counts, other.counts);
  }

  @override
  int get hashCode => Object.hashAll(
    counts.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

@immutable
class LastChestRewardSnapshot {
  const LastChestRewardSnapshot({
    required this.chestType,
    required this.rewardType,
    required this.amount,
    required this.label,
  });

  final ChestType chestType;
  final ChestRewardType rewardType;
  final double amount;
  final String label;

  @override
  bool operator ==(Object other) {
    return other is LastChestRewardSnapshot &&
        chestType == other.chestType &&
        rewardType == other.rewardType &&
        amount == other.amount &&
        label == other.label;
  }

  @override
  int get hashCode => Object.hash(chestType, rewardType, amount, label);
}

@immutable
class ProgressionSnapshot {
  const ProgressionSnapshot({
    required this.achievements,
    required this.collections,
    required this.recipeCollections,
    required this.staffCollections,
    required this.decorCollections,
    required this.knifeSkinCollections,
    required this.collectionSets,
    required this.chests,
    this.latestClaimableAchievement,
    this.lastChestReward,
  });

  final List<AchievementProgressSnapshot> achievements;
  final List<CollectionItemSnapshot> collections;
  final List<Collection2ItemSnapshot> recipeCollections;
  final List<Collection2ItemSnapshot> staffCollections;
  final List<Collection2ItemSnapshot> decorCollections;
  final List<Collection2ItemSnapshot> knifeSkinCollections;
  final List<CollectionSetSnapshot> collectionSets;
  final ChestInventorySnapshot chests;
  final AchievementProgressSnapshot? latestClaimableAchievement;
  final LastChestRewardSnapshot? lastChestReward;

  int get claimableAchievementCount {
    return achievements.where((achievement) => achievement.canClaim).length;
  }

  int get unlockedCollectionCount {
    return collections.where((item) => item.unlocked).length +
        recipeCollections.where((item) => item.unlocked).length +
        staffCollections.where((item) => item.unlocked).length +
        decorCollections.where((item) => item.unlocked).length +
        knifeSkinCollections.where((item) => item.unlocked).length +
        collectionSets.where((item) => item.claimed).length;
  }

  int get totalCollectionCount {
    return collections.length +
        recipeCollections.length +
        staffCollections.length +
        decorCollections.length +
        knifeSkinCollections.length +
        collectionSets.length;
  }

  @override
  bool operator ==(Object other) {
    return other is ProgressionSnapshot &&
        listEquals(achievements, other.achievements) &&
        listEquals(collections, other.collections) &&
        listEquals(recipeCollections, other.recipeCollections) &&
        listEquals(staffCollections, other.staffCollections) &&
        listEquals(decorCollections, other.decorCollections) &&
        listEquals(knifeSkinCollections, other.knifeSkinCollections) &&
        listEquals(collectionSets, other.collectionSets) &&
        chests == other.chests &&
        latestClaimableAchievement == other.latestClaimableAchievement &&
        lastChestReward == other.lastChestReward;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(achievements),
    Object.hashAll(collections),
    Object.hashAll(recipeCollections),
    Object.hashAll(staffCollections),
    Object.hashAll(decorCollections),
    Object.hashAll(knifeSkinCollections),
    Object.hashAll(collectionSets),
    chests,
    latestClaimableAchievement,
    lastChestReward,
  );
}
