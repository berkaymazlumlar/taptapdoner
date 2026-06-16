import 'dart:math' as math;

import 'package:taptapdoner/domain/branches/branch_models.dart';
import 'package:taptapdoner/domain/customers/customer_order_models.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/goals/goal_models.dart';
import 'package:taptapdoner/domain/progression/achievement_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/progression/shop_progression_catalog.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

class UpgradeState {
  const UpgradeState({
    required this.id,
    this.itemIndex = 0,
    required this.level,
  }) : assert(itemIndex >= 0, 'itemIndex cannot be negative.'),
       assert(level >= 1, 'level must be at least 1.');

  factory UpgradeState.fromTotalLevel({
    required UpgradeDefinition definition,
    required int totalLevel,
  }) {
    final normalizedLevel = definition.normalizedLevel(totalLevel);
    return UpgradeState(
      id: definition.id,
      itemIndex: definition.itemIndexForLevel(normalizedLevel),
      level: definition.itemLevelForTotalLevel(normalizedLevel),
    );
  }

  final UpgradeId id;

  /// Current item index in the static upgrade tier chain.
  final int itemIndex;

  /// Current level of the active item.
  final int level;

  bool get purchased => itemIndex > 0 || level > 1;

  UpgradeState copyWith({int? itemIndex, int? level, bool? purchased}) {
    final nextItemIndex =
        itemIndex ?? (purchased == false ? 0 : this.itemIndex);
    final nextLevel =
        level ??
        (purchased == null
            ? this.level
            : (purchased ? (this.purchased ? this.level : 2) : 1));
    return UpgradeState(
      id: id,
      itemIndex: nextItemIndex < 0 ? 0 : nextItemIndex,
      level: nextLevel < 1 ? 1 : nextLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id.key, 'itemIndex': itemIndex, 'level': level};
  }
}

class PrestigeState {
  const PrestigeState({
    int? totalPrestigePoints,
    int? reputation,
    required this.runCashEarned,
    int? unspentPrestigePoints,
    this.prestigeCount = 0,
    this.purchasedPrestigeUpgrades = const <String, int>{},
  }) : totalPrestigePoints = totalPrestigePoints ?? reputation ?? 0,
       unspentPrestigePoints =
           unspentPrestigePoints ?? totalPrestigePoints ?? reputation ?? 0;

  final int totalPrestigePoints;
  final int runCashEarned;
  final int unspentPrestigePoints;
  final int prestigeCount;
  final Map<String, int> purchasedPrestigeUpgrades;

  int get reputation => totalPrestigePoints;

  int prestigeUpgradeLevel(String upgradeId) {
    return math.max(0, purchasedPrestigeUpgrades[upgradeId] ?? 0);
  }

  PrestigeState copyWith({
    int? totalPrestigePoints,
    int? reputation,
    int? runCashEarned,
    int? unspentPrestigePoints,
    int? prestigeCount,
    Map<String, int>? purchasedPrestigeUpgrades,
  }) {
    return PrestigeState(
      totalPrestigePoints:
          totalPrestigePoints ?? reputation ?? this.totalPrestigePoints,
      runCashEarned: runCashEarned ?? this.runCashEarned,
      unspentPrestigePoints: math.max(
        0,
        unspentPrestigePoints ?? this.unspentPrestigePoints,
      ),
      prestigeCount: math.max(0, prestigeCount ?? this.prestigeCount),
      purchasedPrestigeUpgrades: Map<String, int>.unmodifiable(
        purchasedPrestigeUpgrades ?? this.purchasedPrestigeUpgrades,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reputation': reputation,
      'totalPrestigePoints': totalPrestigePoints,
      'unspentPrestigePoints': unspentPrestigePoints,
      'prestigeCount': prestigeCount,
      'runCashEarned': runCashEarned,
      'purchasedPrestigeUpgrades': purchasedPrestigeUpgrades,
    };
  }

  factory PrestigeState.fromJson(Map<String, dynamic>? json) {
    final total = math.max(
      0,
      _intValue(
        json?['totalPrestigePoints'],
        fallback: _intValue(json?['reputation']),
      ),
    );
    final rawUnspent = json?.containsKey('unspentPrestigePoints') == true
        ? _intValue(json?['unspentPrestigePoints'])
        : total;
    return PrestigeState(
      totalPrestigePoints: total,
      unspentPrestigePoints: math.min(total, math.max(0, rawUnspent)),
      prestigeCount: math.max(0, _intValue(json?['prestigeCount'])),
      runCashEarned: math.max(0, _intValue(json?['runCashEarned'])),
      purchasedPrestigeUpgrades: _intMap(json?['purchasedPrestigeUpgrades']),
    );
  }
}

class ShopProgressionState {
  const ShopProgressionState({
    this.currentShopLevel = 1,
    this.highestShopLevel = 1,
    this.unlockedShopIds = const <String>{'street_stand'},
    this.claimedShopLevelRewards = const <String>{},
  }) : assert(currentShopLevel >= 1, 'currentShopLevel must be at least 1.'),
       assert(highestShopLevel >= 1, 'highestShopLevel must be at least 1.');

  final int currentShopLevel;
  final int highestShopLevel;
  final Set<String> unlockedShopIds;
  final Set<String> claimedShopLevelRewards;

  ShopProgressionState copyWith({
    int? currentShopLevel,
    int? highestShopLevel,
    Set<String>? unlockedShopIds,
    Set<String>? claimedShopLevelRewards,
  }) {
    final current = math.max(1, currentShopLevel ?? this.currentShopLevel);
    return ShopProgressionState(
      currentShopLevel: current,
      highestShopLevel: math.max(
        current,
        math.max(1, highestShopLevel ?? this.highestShopLevel),
      ),
      unlockedShopIds: unlockedShopIds ?? this.unlockedShopIds,
      claimedShopLevelRewards:
          claimedShopLevelRewards ?? this.claimedShopLevelRewards,
    );
  }

  ShopProgressionState unlockThroughLevel(int level) {
    final clampedLevel = math.max(1, level);
    final unlocked = Set<String>.from(unlockedShopIds);
    for (final definition in ShopProgressionCatalog.levels) {
      if (definition.level <= clampedLevel) {
        unlocked.add(definition.id);
      }
    }
    return copyWith(
      currentShopLevel: clampedLevel,
      highestShopLevel: math.max(highestShopLevel, clampedLevel),
      unlockedShopIds: Set<String>.unmodifiable(unlocked),
    );
  }

  ShopProgressionState resetCurrentRun() {
    return copyWith(currentShopLevel: 1);
  }

  Map<String, dynamic> toJson() {
    return {
      'currentShopLevel': currentShopLevel,
      'highestShopLevel': highestShopLevel,
      'unlockedShopIds': _sortedStrings(unlockedShopIds),
      'claimedShopLevelRewards': _sortedStrings(claimedShopLevelRewards),
    };
  }

  factory ShopProgressionState.fromJson(Map<String, dynamic>? json) {
    final current = math.max(
      1,
      _intValue(json?['currentShopLevel'], fallback: 1),
    );
    final highest = math.max(
      current,
      _intValue(json?['highestShopLevel'], fallback: current),
    );
    final unlocked = _stringSet(json?['unlockedShopIds']);
    return ShopProgressionState(
      currentShopLevel: current,
      highestShopLevel: highest,
      unlockedShopIds: unlocked.isEmpty
          ? const <String>{'street_stand'}
          : unlocked,
      claimedShopLevelRewards: _stringSet(json?['claimedShopLevelRewards']),
    );
  }
}

class TimedEffectState {
  const TimedEffectState({this.endsAtUtc, this.cooldownEndsAtUtc});

  final DateTime? endsAtUtc;
  final DateTime? cooldownEndsAtUtc;

  TimedEffectState copyWith({
    DateTime? endsAtUtc,
    DateTime? cooldownEndsAtUtc,
    bool clearEndsAtUtc = false,
    bool clearCooldownEndsAtUtc = false,
  }) {
    return TimedEffectState(
      endsAtUtc: clearEndsAtUtc ? null : (endsAtUtc ?? this.endsAtUtc),
      cooldownEndsAtUtc: clearCooldownEndsAtUtc
          ? null
          : (cooldownEndsAtUtc ?? this.cooldownEndsAtUtc),
    );
  }

  bool isActiveAt(DateTime nowUtc) {
    return endsAtUtc?.isAfter(nowUtc) ?? false;
  }

  bool isCoolingDownAt(DateTime nowUtc) {
    return cooldownEndsAtUtc?.isAfter(nowUtc) ?? false;
  }

  Duration remainingActive(DateTime nowUtc) {
    if (!isActiveAt(nowUtc)) {
      return Duration.zero;
    }
    return endsAtUtc!.difference(nowUtc);
  }

  Duration remainingCooldown(DateTime nowUtc) {
    if (!isCoolingDownAt(nowUtc)) {
      return Duration.zero;
    }
    return cooldownEndsAtUtc!.difference(nowUtc);
  }

  Map<String, dynamic> toJson() {
    return {
      'endsAtUtc': endsAtUtc?.toIso8601String(),
      'cooldownEndsAtUtc': cooldownEndsAtUtc?.toIso8601String(),
    };
  }

  factory TimedEffectState.fromJson(Map<String, dynamic>? json) {
    return TimedEffectState(
      endsAtUtc: _dateTimeValue(json?['endsAtUtc']),
      cooldownEndsAtUtc: _dateTimeValue(json?['cooldownEndsAtUtc']),
    );
  }
}

class GoldenDonerState {
  const GoldenDonerState({
    this.activeUntilUtc,
    this.nextSpawnAtUtc,
    this.lastSpawnAtUtc,
    this.requiredHits = 0,
    this.currentHits = 0,
    this.rewardPreview = 0,
  }) : assert(requiredHits >= 0, 'requiredHits cannot be negative.'),
       assert(currentHits >= 0, 'currentHits cannot be negative.'),
       assert(rewardPreview >= 0, 'rewardPreview cannot be negative.');

  final DateTime? activeUntilUtc;
  final DateTime? nextSpawnAtUtc;
  final DateTime? lastSpawnAtUtc;
  final int requiredHits;
  final int currentHits;
  final int rewardPreview;

  bool isActiveAt(DateTime nowUtc) {
    return activeUntilUtc?.isAfter(nowUtc) == true &&
        requiredHits > 0 &&
        currentHits < requiredHits;
  }

  Duration remainingActive(DateTime nowUtc) {
    if (!isActiveAt(nowUtc)) {
      return Duration.zero;
    }
    return activeUntilUtc!.difference(nowUtc);
  }

  GoldenDonerState copyWith({
    DateTime? activeUntilUtc,
    DateTime? nextSpawnAtUtc,
    DateTime? lastSpawnAtUtc,
    int? requiredHits,
    int? currentHits,
    int? rewardPreview,
    bool clearActiveUntilUtc = false,
    bool clearNextSpawnAtUtc = false,
    bool clearLastSpawnAtUtc = false,
  }) {
    return GoldenDonerState(
      activeUntilUtc: clearActiveUntilUtc
          ? null
          : (activeUntilUtc ?? this.activeUntilUtc),
      nextSpawnAtUtc: clearNextSpawnAtUtc
          ? null
          : (nextSpawnAtUtc ?? this.nextSpawnAtUtc),
      lastSpawnAtUtc: clearLastSpawnAtUtc
          ? null
          : (lastSpawnAtUtc ?? this.lastSpawnAtUtc),
      requiredHits: math.max(0, requiredHits ?? this.requiredHits),
      currentHits: math.max(0, currentHits ?? this.currentHits),
      rewardPreview: math.max(0, rewardPreview ?? this.rewardPreview),
    );
  }

  GoldenDonerState clearActive() {
    return copyWith(
      clearActiveUntilUtc: true,
      requiredHits: 0,
      currentHits: 0,
      rewardPreview: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeUntilUtc': activeUntilUtc?.toIso8601String(),
      'nextSpawnAtUtc': nextSpawnAtUtc?.toIso8601String(),
      'lastSpawnAtUtc': lastSpawnAtUtc?.toIso8601String(),
      'requiredHits': requiredHits,
      'currentHits': currentHits,
      'rewardPreview': rewardPreview,
    };
  }

  factory GoldenDonerState.fromJson(Map<String, dynamic>? json) {
    return GoldenDonerState(
      activeUntilUtc: _dateTimeValue(json?['activeUntilUtc']),
      nextSpawnAtUtc: _dateTimeValue(json?['nextSpawnAtUtc']),
      lastSpawnAtUtc: _dateTimeValue(json?['lastSpawnAtUtc']),
      requiredHits: math.max(0, _intValue(json?['requiredHits'])),
      currentHits: math.max(0, _intValue(json?['currentHits'])),
      rewardPreview: math.max(0, _intValue(json?['rewardPreview'])),
    );
  }
}

class GameStatsState {
  const GameStatsState({
    this.tapCount = 0,
    this.totalUpgradesPurchased = 0,
    this.criticalCutCount = 0,
    this.passiveIncomeActiveSeconds = 0,
    this.maxCombo = 0,
    this.currentCombo = 0,
    this.turboUsedCount = 0,
    this.goldenDonerCollected = 0,
    this.chestsOpened = 0,
    this.shopLevel = 1,
    this.openPrestigeScreenOnce = false,
    this.lastTapAtUtc,
  }) : assert(tapCount >= 0, 'tapCount cannot be negative.'),
       assert(
         totalUpgradesPurchased >= 0,
         'totalUpgradesPurchased cannot be negative.',
       ),
       assert(criticalCutCount >= 0, 'criticalCutCount cannot be negative.'),
       assert(
         passiveIncomeActiveSeconds >= 0,
         'passiveIncomeActiveSeconds cannot be negative.',
       ),
       assert(maxCombo >= 0, 'maxCombo cannot be negative.'),
       assert(currentCombo >= 0, 'currentCombo cannot be negative.'),
       assert(turboUsedCount >= 0, 'turboUsedCount cannot be negative.'),
       assert(
         goldenDonerCollected >= 0,
         'goldenDonerCollected cannot be negative.',
       ),
       assert(chestsOpened >= 0, 'chestsOpened cannot be negative.'),
       assert(shopLevel >= 1, 'shopLevel must be at least 1.');

  final int tapCount;
  final int totalUpgradesPurchased;
  final int criticalCutCount;
  final double passiveIncomeActiveSeconds;
  final int maxCombo;
  final int currentCombo;
  final int turboUsedCount;
  final int goldenDonerCollected;
  final int chestsOpened;
  final int shopLevel;
  final bool openPrestigeScreenOnce;
  final DateTime? lastTapAtUtc;

  GameStatsState copyWith({
    int? tapCount,
    int? totalUpgradesPurchased,
    int? criticalCutCount,
    double? passiveIncomeActiveSeconds,
    int? maxCombo,
    int? currentCombo,
    int? turboUsedCount,
    int? goldenDonerCollected,
    int? chestsOpened,
    int? shopLevel,
    bool? openPrestigeScreenOnce,
    DateTime? lastTapAtUtc,
    bool clearLastTapAtUtc = false,
  }) {
    return GameStatsState(
      tapCount: math.max(0, tapCount ?? this.tapCount),
      totalUpgradesPurchased: math.max(
        0,
        totalUpgradesPurchased ?? this.totalUpgradesPurchased,
      ),
      criticalCutCount: math.max(0, criticalCutCount ?? this.criticalCutCount),
      passiveIncomeActiveSeconds: math.max(
        0,
        passiveIncomeActiveSeconds ?? this.passiveIncomeActiveSeconds,
      ),
      maxCombo: math.max(0, maxCombo ?? this.maxCombo),
      currentCombo: math.max(0, currentCombo ?? this.currentCombo),
      turboUsedCount: math.max(0, turboUsedCount ?? this.turboUsedCount),
      goldenDonerCollected: math.max(
        0,
        goldenDonerCollected ?? this.goldenDonerCollected,
      ),
      chestsOpened: math.max(0, chestsOpened ?? this.chestsOpened),
      shopLevel: math.max(1, shopLevel ?? this.shopLevel),
      openPrestigeScreenOnce:
          openPrestigeScreenOnce ?? this.openPrestigeScreenOnce,
      lastTapAtUtc: clearLastTapAtUtc
          ? null
          : (lastTapAtUtc ?? this.lastTapAtUtc),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tapCount': tapCount,
      'totalUpgradesPurchased': totalUpgradesPurchased,
      'criticalCutCount': criticalCutCount,
      'passiveIncomeActiveSeconds': passiveIncomeActiveSeconds,
      'maxCombo': maxCombo,
      'currentCombo': currentCombo,
      'turboUsedCount': turboUsedCount,
      'goldenDonerCollected': goldenDonerCollected,
      'chestsOpened': chestsOpened,
      'shopLevel': shopLevel,
      'openPrestigeScreenOnce': openPrestigeScreenOnce,
      'lastTapAtUtc': lastTapAtUtc?.toIso8601String(),
    };
  }

  factory GameStatsState.fromJson(Map<String, dynamic>? json) {
    return GameStatsState(
      tapCount: math.max(0, _intValue(json?['tapCount'])),
      totalUpgradesPurchased: math.max(
        0,
        _intValue(json?['totalUpgradesPurchased']),
      ),
      criticalCutCount: math.max(0, _intValue(json?['criticalCutCount'])),
      passiveIncomeActiveSeconds: _nonNegativeDouble(
        json?['passiveIncomeActiveSeconds'],
      ),
      maxCombo: math.max(0, _intValue(json?['maxCombo'])),
      currentCombo: math.max(0, _intValue(json?['currentCombo'])),
      turboUsedCount: math.max(0, _intValue(json?['turboUsedCount'])),
      goldenDonerCollected: math.max(
        0,
        _intValue(json?['goldenDonerCollected']),
      ),
      chestsOpened: math.max(0, _intValue(json?['chestsOpened'])),
      shopLevel: math.max(1, _intValue(json?['shopLevel'], fallback: 1)),
      openPrestigeScreenOnce: _boolValue(json?['openPrestigeScreenOnce']),
      lastTapAtUtc: _dateTimeValue(json?['lastTapAtUtc']),
    );
  }
}

class MilestoneState {
  const MilestoneState({
    this.claimedMilestoneKeys = const <String>{},
    this.unlockedFeatureKeys = const <String>{},
    this.collectionKeys = const <String>{},
    this.tapBonusPercent = 0,
    this.passiveBonusPercent = 0,
    this.globalBonusPercent = 0,
    this.menuBonusPercent = 0,
    this.criticalChance = 0,
    this.criticalMultiplierBonus = 0,
    this.comboDurationSeconds = 0,
    this.comboMultiplierBonus = 0,
    this.turboBonusPercent = 0,
    this.turboChargeSpeedPercent = 0,
    this.turboDurationSeconds = 0,
    this.turboCooldownReductionPercent = 0,
    this.offlineEfficiencyBonus = 0,
    this.offlineMaxDurationSeconds = 0,
    this.offlineAdRewardPercent = 0,
    this.goldenDonerChance = 0,
    this.goldenDonerRewardPercent = 0,
    this.tipChance = 0,
    this.tipValuePercent = 0,
    this.specialOrderChance = 0,
    this.chests = 0,
    this.cosmeticTokens = 0,
  });

  final Set<String> claimedMilestoneKeys;
  final Set<String> unlockedFeatureKeys;
  final Set<String> collectionKeys;
  final double tapBonusPercent;
  final double passiveBonusPercent;
  final double globalBonusPercent;
  final double menuBonusPercent;
  final double criticalChance;
  final double criticalMultiplierBonus;
  final double comboDurationSeconds;
  final double comboMultiplierBonus;
  final double turboBonusPercent;
  final double turboChargeSpeedPercent;
  final double turboDurationSeconds;
  final double turboCooldownReductionPercent;
  final double offlineEfficiencyBonus;
  final double offlineMaxDurationSeconds;
  final double offlineAdRewardPercent;
  final double goldenDonerChance;
  final double goldenDonerRewardPercent;
  final double tipChance;
  final double tipValuePercent;
  final double specialOrderChance;
  final int chests;
  final int cosmeticTokens;

  bool hasClaimed(String key) => claimedMilestoneKeys.contains(key);

  bool hasFeature(String key) => unlockedFeatureKeys.contains(key);

  MilestoneState copyWith({
    Set<String>? claimedMilestoneKeys,
    Set<String>? unlockedFeatureKeys,
    Set<String>? collectionKeys,
    double? tapBonusPercent,
    double? passiveBonusPercent,
    double? globalBonusPercent,
    double? menuBonusPercent,
    double? criticalChance,
    double? criticalMultiplierBonus,
    double? comboDurationSeconds,
    double? comboMultiplierBonus,
    double? turboBonusPercent,
    double? turboChargeSpeedPercent,
    double? turboDurationSeconds,
    double? turboCooldownReductionPercent,
    double? offlineEfficiencyBonus,
    double? offlineMaxDurationSeconds,
    double? offlineAdRewardPercent,
    double? goldenDonerChance,
    double? goldenDonerRewardPercent,
    double? tipChance,
    double? tipValuePercent,
    double? specialOrderChance,
    int? chests,
    int? cosmeticTokens,
  }) {
    return MilestoneState(
      claimedMilestoneKeys: claimedMilestoneKeys ?? this.claimedMilestoneKeys,
      unlockedFeatureKeys: unlockedFeatureKeys ?? this.unlockedFeatureKeys,
      collectionKeys: collectionKeys ?? this.collectionKeys,
      tapBonusPercent: tapBonusPercent ?? this.tapBonusPercent,
      passiveBonusPercent: passiveBonusPercent ?? this.passiveBonusPercent,
      globalBonusPercent: globalBonusPercent ?? this.globalBonusPercent,
      menuBonusPercent: menuBonusPercent ?? this.menuBonusPercent,
      criticalChance: criticalChance ?? this.criticalChance,
      criticalMultiplierBonus:
          criticalMultiplierBonus ?? this.criticalMultiplierBonus,
      comboDurationSeconds: comboDurationSeconds ?? this.comboDurationSeconds,
      comboMultiplierBonus: comboMultiplierBonus ?? this.comboMultiplierBonus,
      turboBonusPercent: turboBonusPercent ?? this.turboBonusPercent,
      turboChargeSpeedPercent:
          turboChargeSpeedPercent ?? this.turboChargeSpeedPercent,
      turboDurationSeconds: turboDurationSeconds ?? this.turboDurationSeconds,
      turboCooldownReductionPercent:
          turboCooldownReductionPercent ?? this.turboCooldownReductionPercent,
      offlineEfficiencyBonus:
          offlineEfficiencyBonus ?? this.offlineEfficiencyBonus,
      offlineMaxDurationSeconds:
          offlineMaxDurationSeconds ?? this.offlineMaxDurationSeconds,
      offlineAdRewardPercent:
          offlineAdRewardPercent ?? this.offlineAdRewardPercent,
      goldenDonerChance: goldenDonerChance ?? this.goldenDonerChance,
      goldenDonerRewardPercent:
          goldenDonerRewardPercent ?? this.goldenDonerRewardPercent,
      tipChance: tipChance ?? this.tipChance,
      tipValuePercent: tipValuePercent ?? this.tipValuePercent,
      specialOrderChance: specialOrderChance ?? this.specialOrderChance,
      chests: math.max(0, chests ?? this.chests),
      cosmeticTokens: math.max(0, cosmeticTokens ?? this.cosmeticTokens),
    );
  }

  MilestoneState claimReward({
    required String key,
    required MilestoneReward reward,
  }) {
    if (hasClaimed(key)) {
      return this;
    }

    final nextClaimed = Set<String>.from(claimedMilestoneKeys)..add(key);
    final nextFeatures = Set<String>.from(unlockedFeatureKeys);
    final nextCollections = Set<String>.from(collectionKeys);
    final featureKey = reward.featureKey;
    final collectionKey = reward.collectionKey;
    if (featureKey != null && featureKey.isNotEmpty) {
      nextFeatures.add(featureKey);
    }
    if (collectionKey != null && collectionKey.isNotEmpty) {
      nextCollections.add(collectionKey);
    }

    final quantity = reward.quantity > 0 ? reward.quantity : 1;
    switch (reward.type) {
      case MilestoneRewardType.tapBonusPercent:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          tapBonusPercent: tapBonusPercent + reward.value,
        );
      case MilestoneRewardType.passiveBonusPercent:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          passiveBonusPercent: passiveBonusPercent + reward.value,
        );
      case MilestoneRewardType.globalBonusPercent:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          globalBonusPercent: globalBonusPercent + reward.value,
        );
      case MilestoneRewardType.menuBonusPercent:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          menuBonusPercent: menuBonusPercent + reward.value,
        );
      case MilestoneRewardType.criticalChance:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          criticalChance: criticalChance + reward.value,
        );
      case MilestoneRewardType.criticalMultiplier:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          criticalMultiplierBonus: criticalMultiplierBonus + reward.value,
        );
      case MilestoneRewardType.comboDuration:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          comboDurationSeconds: comboDurationSeconds + reward.value,
        );
      case MilestoneRewardType.comboMultiplier:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          comboMultiplierBonus: comboMultiplierBonus + reward.value,
        );
      case MilestoneRewardType.turboBonusPercent:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          turboBonusPercent: turboBonusPercent + reward.value,
        );
      case MilestoneRewardType.turboChargeSpeed:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          turboChargeSpeedPercent: turboChargeSpeedPercent + reward.value,
        );
      case MilestoneRewardType.turboDuration:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          turboDurationSeconds: turboDurationSeconds + reward.value,
        );
      case MilestoneRewardType.turboCooldownReduction:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          turboCooldownReductionPercent:
              turboCooldownReductionPercent + reward.value,
        );
      case MilestoneRewardType.offlineEfficiency:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          offlineEfficiencyBonus: offlineEfficiencyBonus + reward.value,
        );
      case MilestoneRewardType.offlineMaxDuration:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          offlineMaxDurationSeconds: offlineMaxDurationSeconds + reward.value,
        );
      case MilestoneRewardType.offlineAdRewardPercent:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          offlineAdRewardPercent: offlineAdRewardPercent + reward.value,
        );
      case MilestoneRewardType.goldenDonerChance:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          goldenDonerChance: goldenDonerChance + reward.value,
        );
      case MilestoneRewardType.goldenDonerRewardPercent:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          goldenDonerRewardPercent: goldenDonerRewardPercent + reward.value,
        );
      case MilestoneRewardType.tipChance:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          tipChance: tipChance + reward.value,
        );
      case MilestoneRewardType.tipValuePercent:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          tipValuePercent: tipValuePercent + reward.value,
        );
      case MilestoneRewardType.specialOrderChance:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          specialOrderChance: specialOrderChance + reward.value,
        );
      case MilestoneRewardType.chest:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          chests: chests + quantity,
        );
      case MilestoneRewardType.cosmeticToken:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
          cosmeticTokens: cosmeticTokens + quantity,
        );
      case MilestoneRewardType.collectionUnlock:
      case MilestoneRewardType.featureUnlock:
      case MilestoneRewardType.instantMoney:
        return copyWith(
          claimedMilestoneKeys: nextClaimed,
          unlockedFeatureKeys: nextFeatures,
          collectionKeys: nextCollections,
        );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'claimedMilestones': _sortedStrings(claimedMilestoneKeys),
      'unlockedFeatures': _sortedStrings(unlockedFeatureKeys),
      'collections': _sortedStrings(collectionKeys),
      'tapBonusPercent': tapBonusPercent,
      'passiveBonusPercent': passiveBonusPercent,
      'globalBonusPercent': globalBonusPercent,
      'menuBonusPercent': menuBonusPercent,
      'criticalChance': criticalChance,
      'criticalMultiplierBonus': criticalMultiplierBonus,
      'comboDurationSeconds': comboDurationSeconds,
      'comboMultiplierBonus': comboMultiplierBonus,
      'turboBonusPercent': turboBonusPercent,
      'turboChargeSpeedPercent': turboChargeSpeedPercent,
      'turboDurationSeconds': turboDurationSeconds,
      'turboCooldownReductionPercent': turboCooldownReductionPercent,
      'offlineEfficiencyBonus': offlineEfficiencyBonus,
      'offlineMaxDurationSeconds': offlineMaxDurationSeconds,
      'offlineAdRewardPercent': offlineAdRewardPercent,
      'goldenDonerChance': goldenDonerChance,
      'goldenDonerRewardPercent': goldenDonerRewardPercent,
      'tipChance': tipChance,
      'tipValuePercent': tipValuePercent,
      'specialOrderChance': specialOrderChance,
      'chests': chests,
      'cosmeticTokens': cosmeticTokens,
    };
  }

  factory MilestoneState.fromJson(Map<String, dynamic>? json) {
    return MilestoneState(
      claimedMilestoneKeys: _stringSet(json?['claimedMilestones']),
      unlockedFeatureKeys: _stringSet(json?['unlockedFeatures']),
      collectionKeys: _stringSet(json?['collections']),
      tapBonusPercent: _nonNegativeDouble(json?['tapBonusPercent']),
      passiveBonusPercent: _nonNegativeDouble(json?['passiveBonusPercent']),
      globalBonusPercent: _nonNegativeDouble(json?['globalBonusPercent']),
      menuBonusPercent: _nonNegativeDouble(json?['menuBonusPercent']),
      criticalChance: _nonNegativeDouble(json?['criticalChance']),
      criticalMultiplierBonus: _nonNegativeDouble(
        json?['criticalMultiplierBonus'],
      ),
      comboDurationSeconds: _nonNegativeDouble(json?['comboDurationSeconds']),
      comboMultiplierBonus: _nonNegativeDouble(json?['comboMultiplierBonus']),
      turboBonusPercent: _nonNegativeDouble(json?['turboBonusPercent']),
      turboChargeSpeedPercent: _nonNegativeDouble(
        json?['turboChargeSpeedPercent'],
      ),
      turboDurationSeconds: _nonNegativeDouble(json?['turboDurationSeconds']),
      turboCooldownReductionPercent: _nonNegativeDouble(
        json?['turboCooldownReductionPercent'],
      ),
      offlineEfficiencyBonus: _nonNegativeDouble(
        json?['offlineEfficiencyBonus'],
      ),
      offlineMaxDurationSeconds: _nonNegativeDouble(
        json?['offlineMaxDurationSeconds'],
      ),
      offlineAdRewardPercent: _nonNegativeDouble(
        json?['offlineAdRewardPercent'],
      ),
      goldenDonerChance: _nonNegativeDouble(json?['goldenDonerChance']),
      goldenDonerRewardPercent: _nonNegativeDouble(
        json?['goldenDonerRewardPercent'],
      ),
      tipChance: _nonNegativeDouble(json?['tipChance']),
      tipValuePercent: _nonNegativeDouble(json?['tipValuePercent']),
      specialOrderChance: _nonNegativeDouble(json?['specialOrderChance']),
      chests: math.max(0, _intValue(json?['chests'])),
      cosmeticTokens: math.max(0, _intValue(json?['cosmeticTokens'])),
    );
  }
}

class AchievementProgress {
  const AchievementProgress({
    required this.achievementId,
    this.currentValue = 0,
    this.isCompleted = false,
    this.isRewardClaimed = false,
  });

  final String achievementId;
  final double currentValue;
  final bool isCompleted;
  final bool isRewardClaimed;

  AchievementProgress copyWith({
    double? currentValue,
    bool? isCompleted,
    bool? isRewardClaimed,
  }) {
    return AchievementProgress(
      achievementId: achievementId,
      currentValue: math.max(0, currentValue ?? this.currentValue),
      isCompleted: isCompleted ?? this.isCompleted,
      isRewardClaimed: isRewardClaimed ?? this.isRewardClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'currentValue': currentValue,
      'isCompleted': isCompleted,
      'isRewardClaimed': isRewardClaimed,
    };
  }

  factory AchievementProgress.fromJson(
    Map<String, dynamic> json, {
    required AchievementProgress fallback,
  }) {
    return AchievementProgress(
      achievementId: _stringValue(
        json['achievementId'],
        fallback: fallback.achievementId,
      ),
      currentValue: _nonNegativeDouble(json['currentValue']),
      isCompleted: _boolValue(json['isCompleted']),
      isRewardClaimed: _boolValue(json['isRewardClaimed']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AchievementProgress &&
        achievementId == other.achievementId &&
        currentValue == other.currentValue &&
        isCompleted == other.isCompleted &&
        isRewardClaimed == other.isRewardClaimed;
  }

  @override
  int get hashCode =>
      Object.hash(achievementId, currentValue, isCompleted, isRewardClaimed);
}

class CollectionState {
  const CollectionState({
    this.unlockedItemIds = const <String>{},
    this.claimedBonusItemIds = const <String>{},
  });

  final Set<String> unlockedItemIds;
  final Set<String> claimedBonusItemIds;

  bool isUnlocked(String itemId) => unlockedItemIds.contains(itemId);

  bool hasClaimedBonus(String itemId) => claimedBonusItemIds.contains(itemId);

  CollectionState copyWith({
    Set<String>? unlockedItemIds,
    Set<String>? claimedBonusItemIds,
  }) {
    return CollectionState(
      unlockedItemIds: unlockedItemIds ?? this.unlockedItemIds,
      claimedBonusItemIds: claimedBonusItemIds ?? this.claimedBonusItemIds,
    );
  }

  CollectionState unlock(String itemId, {bool claimBonus = true}) {
    if (itemId.isEmpty) {
      return this;
    }
    final nextUnlocked = Set<String>.from(unlockedItemIds)..add(itemId);
    final nextClaimed = Set<String>.from(claimedBonusItemIds);
    if (claimBonus) {
      nextClaimed.add(itemId);
    }
    return copyWith(
      unlockedItemIds: Set<String>.unmodifiable(nextUnlocked),
      claimedBonusItemIds: Set<String>.unmodifiable(nextClaimed),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unlockedItems': _sortedStrings(unlockedItemIds),
      'claimedBonuses': _sortedStrings(claimedBonusItemIds),
    };
  }

  factory CollectionState.fromJson(Map<String, dynamic>? json) {
    return CollectionState(
      unlockedItemIds: _stringSet(json?['unlockedItems']),
      claimedBonusItemIds: _stringSet(json?['claimedBonuses']),
    );
  }
}

class ChestInventoryState {
  const ChestInventoryState({this.counts = const <ChestType, int>{}});

  final Map<ChestType, int> counts;

  int count(ChestType type) => math.max(0, counts[type] ?? 0);

  int get totalCount {
    return ChestType.values.fold(0, (total, type) => total + count(type));
  }

  ChestInventoryState add(ChestType type, {int quantity = 1}) {
    if (quantity <= 0) {
      return this;
    }
    final next = Map<ChestType, int>.from(counts);
    next[type] = count(type) + quantity;
    return ChestInventoryState(counts: Map<ChestType, int>.unmodifiable(next));
  }

  ChestInventoryState remove(ChestType type, {int quantity = 1}) {
    if (quantity <= 0 || count(type) <= 0) {
      return this;
    }
    final next = Map<ChestType, int>.from(counts);
    next[type] = math.max(0, count(type) - quantity);
    return ChestInventoryState(counts: Map<ChestType, int>.unmodifiable(next));
  }

  Map<String, dynamic> toJson() {
    return {
      for (final type in ChestType.values)
        chestTypeKey(type): math.max(0, counts[type] ?? 0),
    };
  }

  factory ChestInventoryState.fromJson(
    Map<String, dynamic>? json, {
    int legacySmallChests = 0,
  }) {
    final counts = <ChestType, int>{};
    for (final type in ChestType.values) {
      counts[type] = math.max(0, _intValue(json?[chestTypeKey(type)]));
    }
    if (counts.values.every((value) => value == 0) && legacySmallChests > 0) {
      counts[ChestType.small] = legacySmallChests;
    }
    return ChestInventoryState(
      counts: Map<ChestType, int>.unmodifiable(counts),
    );
  }
}

class GameState {
  const GameState({
    required this.schemaVersion,
    required this.cash,
    required this.lifetimeCash,
    required this.pendingOfflineCash,
    required this.upgrades,
    required this.milestones,
    required this.prestige,
    required this.rush,
    required this.passiveBoost,
    required this.goldenDoner,
    required this.stats,
    required this.quests,
    required this.achievements,
    required this.collection,
    required this.collection2,
    required this.chestInventory,
    required this.shopProgression,
    required this.customerReputation,
    required this.customerOrders,
    required this.goals,
    required this.branches,
    required this.lastActiveAtUtc,
    required this.lastSavedAtUtc,
    required this.localeCode,
  });

  static const currentSchemaVersion = 14;

  final int schemaVersion;
  final int cash;
  final int lifetimeCash;
  final int pendingOfflineCash;
  final Map<UpgradeId, UpgradeState> upgrades;
  final MilestoneState milestones;
  final PrestigeState prestige;
  final TimedEffectState rush;
  final TimedEffectState passiveBoost;
  final GoldenDonerState goldenDoner;
  final GameStatsState stats;
  final Map<String, QuestProgress> quests;
  final Map<String, AchievementProgress> achievements;
  final CollectionState collection;
  final Collection2State collection2;
  final ChestInventoryState chestInventory;
  final ShopProgressionState shopProgression;
  final CustomerReputationState customerReputation;
  final CustomerSystemState customerOrders;
  final GoalSystemState goals;
  final BranchSystemState branches;
  final DateTime lastActiveAtUtc;
  final DateTime lastSavedAtUtc;
  final String localeCode;

  factory GameState.initial(
    EconomyConfig config, {
    DateTime? nowUtc,
    String localeCode = 'en',
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    return GameState(
      schemaVersion: currentSchemaVersion,
      cash: 0,
      lifetimeCash: 0,
      pendingOfflineCash: 0,
      upgrades: {
        for (final definition in config.upgrades)
          definition.id: UpgradeState(id: definition.id, level: 1),
      },
      milestones: const MilestoneState(),
      prestige: const PrestigeState(reputation: 0, runCashEarned: 0),
      rush: const TimedEffectState(),
      passiveBoost: const TimedEffectState(),
      goldenDoner: const GoldenDonerState(),
      stats: const GameStatsState(),
      quests: StarterQuestCatalog.initialProgress(),
      achievements: _initialAchievementProgress(),
      collection: const CollectionState(),
      collection2: const Collection2State(),
      chestInventory: const ChestInventoryState(),
      shopProgression: const ShopProgressionState(),
      customerReputation: const CustomerReputationState(),
      customerOrders: CustomerSystemState.initial(nowUtc: now),
      goals: GoalSystemState.initial(nowUtc: now),
      branches: const BranchSystemState(),
      lastActiveAtUtc: now,
      lastSavedAtUtc: now,
      localeCode: localeCode,
    );
  }

  UpgradeState upgrade(UpgradeId id) => upgrades[id]!;

  GameState copyWith({
    int? schemaVersion,
    int? cash,
    int? lifetimeCash,
    int? pendingOfflineCash,
    Map<UpgradeId, UpgradeState>? upgrades,
    MilestoneState? milestones,
    PrestigeState? prestige,
    TimedEffectState? rush,
    TimedEffectState? passiveBoost,
    GoldenDonerState? goldenDoner,
    GameStatsState? stats,
    Map<String, QuestProgress>? quests,
    Map<String, AchievementProgress>? achievements,
    CollectionState? collection,
    Collection2State? collection2,
    ChestInventoryState? chestInventory,
    ShopProgressionState? shopProgression,
    CustomerReputationState? customerReputation,
    CustomerSystemState? customerOrders,
    GoalSystemState? goals,
    BranchSystemState? branches,
    DateTime? lastActiveAtUtc,
    DateTime? lastSavedAtUtc,
    String? localeCode,
  }) {
    return GameState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      cash: cash ?? this.cash,
      lifetimeCash: lifetimeCash ?? this.lifetimeCash,
      pendingOfflineCash: pendingOfflineCash ?? this.pendingOfflineCash,
      upgrades: upgrades ?? this.upgrades,
      milestones: milestones ?? this.milestones,
      prestige: prestige ?? this.prestige,
      rush: rush ?? this.rush,
      passiveBoost: passiveBoost ?? this.passiveBoost,
      goldenDoner: goldenDoner ?? this.goldenDoner,
      stats: stats ?? this.stats,
      quests: quests ?? this.quests,
      achievements: achievements ?? this.achievements,
      collection: collection ?? this.collection,
      collection2: collection2 ?? this.collection2,
      chestInventory: chestInventory ?? this.chestInventory,
      shopProgression: shopProgression ?? this.shopProgression,
      customerReputation: customerReputation ?? this.customerReputation,
      customerOrders: customerOrders ?? this.customerOrders,
      goals: goals ?? this.goals,
      branches: branches ?? this.branches,
      lastActiveAtUtc: lastActiveAtUtc ?? this.lastActiveAtUtc,
      lastSavedAtUtc: lastSavedAtUtc ?? this.lastSavedAtUtc,
      localeCode: localeCode ?? this.localeCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'cash': cash,
      'lifetimeCash': lifetimeCash,
      'pendingOfflineCash': pendingOfflineCash,
      'upgrades': upgrades.values.map((value) => value.toJson()).toList(),
      'milestones': milestones.toJson(),
      'prestige': prestige.toJson(),
      'rush': rush.toJson(),
      'passiveBoost': passiveBoost.toJson(),
      'goldenDoner': goldenDoner.toJson(),
      'stats': stats.toJson(),
      'quests': quests.values.map((value) => value.toJson()).toList(),
      'achievements': achievements.values
          .map((value) => value.toJson())
          .toList(),
      'collection': collection.toJson(),
      'collection2': collection2.toJson(),
      'chestInventory': chestInventory.toJson(),
      'shopProgression': shopProgression.toJson(),
      'customerReputation': customerReputation.toJson(),
      'customerOrders': customerOrders.toJson(),
      'goals': goals.toJson(),
      'branches': branches.toJson(),
      'lastActiveAtUtc': lastActiveAtUtc.toIso8601String(),
      'lastSavedAtUtc': lastSavedAtUtc.toIso8601String(),
      'localeCode': localeCode,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json, EconomyConfig config) {
    final fallback = GameState.initial(
      config,
      localeCode: _stringValue(json['localeCode'], fallback: 'en'),
    );
    final schemaVersion = _intValue(
      json['schemaVersion'],
      fallback: currentSchemaVersion,
    );
    if (schemaVersion > currentSchemaVersion) {
      return fallback;
    }

    final upgradeDefinitions = {
      for (final definition in config.upgrades) definition.id: definition,
    };
    final parsedUpgrades = <UpgradeId, UpgradeState>{};
    final upgradeList = json['upgrades'];
    if (upgradeList is List) {
      for (final entry in upgradeList) {
        final map = _stringKeyMap(entry);
        if (map == null) {
          continue;
        }
        final state = _upgradeStateFromJson(map, upgradeDefinitions);
        if (state == null) {
          continue;
        }
        final definition = upgradeDefinitions[state.id];
        if (definition == null) {
          continue;
        }
        final existing = parsedUpgrades[state.id];
        parsedUpgrades[state.id] =
            existing == null ||
                definition.totalLevelForPosition(
                      itemIndex: state.itemIndex,
                      itemLevel: state.level,
                    ) >
                    definition.totalLevelForPosition(
                      itemIndex: existing.itemIndex,
                      itemLevel: existing.level,
                    )
            ? state
            : existing;
      }
    }

    final milestones = MilestoneState.fromJson(
      _stringKeyMap(json['milestones']),
    );
    final customerReputation = CustomerReputationState.fromJson(
      _stringKeyMap(json['customerReputation']),
    );
    final parsedCustomerOrders = CustomerSystemState.fromJson(
      _stringKeyMap(json['customerOrders']),
    );
    final customerOrders = parsedCustomerOrders.copyWith(
      unlockedCustomerTypeIds: CustomerOrderCatalog.unlockedTypeIdsForLevel(
        customerReputation.currentLevel,
        existing: parsedCustomerOrders.unlockedCustomerTypeIds,
      ),
    );

    return GameState(
      schemaVersion: schemaVersion,
      cash: _intValue(json['cash']),
      lifetimeCash: math.max(0, _intValue(json['lifetimeCash'])),
      pendingOfflineCash: math.max(0, _intValue(json['pendingOfflineCash'])),
      upgrades: {
        for (final definition in config.upgrades)
          definition.id: _clampedUpgradeState(
            parsedUpgrades[definition.id],
            definition,
          ),
      },
      milestones: milestones,
      prestige: PrestigeState.fromJson(_stringKeyMap(json['prestige'])),
      rush: TimedEffectState.fromJson(_stringKeyMap(json['rush'])),
      passiveBoost: TimedEffectState.fromJson(
        _stringKeyMap(json['passiveBoost']),
      ),
      goldenDoner: GoldenDonerState.fromJson(
        _stringKeyMap(json['goldenDoner']),
      ),
      stats: GameStatsState.fromJson(_stringKeyMap(json['stats'])),
      quests: _questProgressMap(json['quests']),
      achievements: _achievementProgressMap(json['achievements']),
      collection: CollectionState.fromJson(_stringKeyMap(json['collection'])),
      collection2: Collection2State.fromJson(
        _stringKeyMap(json['collection2']),
      ),
      chestInventory: ChestInventoryState.fromJson(
        _stringKeyMap(json['chestInventory']),
        legacySmallChests: milestones.chests,
      ),
      shopProgression: ShopProgressionState.fromJson(
        _stringKeyMap(json['shopProgression']),
      ),
      customerReputation: customerReputation,
      customerOrders: customerOrders,
      goals: GoalSystemState.fromJson(_stringKeyMap(json['goals'])),
      branches: BranchSystemState.fromJson(_stringKeyMap(json['branches'])),
      lastActiveAtUtc:
          _dateTimeValue(json['lastActiveAtUtc']) ?? fallback.lastActiveAtUtc,
      lastSavedAtUtc:
          _dateTimeValue(json['lastSavedAtUtc']) ?? fallback.lastSavedAtUtc,
      localeCode: _stringValue(
        json['localeCode'],
        fallback: fallback.localeCode,
      ),
    );
  }
}

UpgradeState _clampedUpgradeState(
  UpgradeState? state,
  UpgradeDefinition definition,
) {
  if (state == null) {
    return UpgradeState(id: definition.id, level: 1);
  }
  return UpgradeState.fromTotalLevel(
    definition: definition,
    totalLevel: definition.totalLevelForPosition(
      itemIndex: state.itemIndex,
      itemLevel: state.level,
    ),
  );
}

UpgradeState? _upgradeStateFromJson(
  Map<String, dynamic> json,
  Map<UpgradeId, UpgradeDefinition> definitions,
) {
  final rawId = _stringValue(json['id']);
  final id = upgradeIdFromKey(rawId);
  if (id == null) {
    return null;
  }
  final definition = definitions[id];
  if (definition == null || definition.items.isEmpty) {
    return null;
  }

  if (json.containsKey('itemIndex')) {
    final itemIndex = _clampInt(
      _intValue(json['itemIndex']),
      min: 0,
      max: definition.items.length - 1,
    );
    final level = _clampInt(
      _intValue(json['level'], fallback: 1),
      min: 1,
      max: definition.items[itemIndex].maxLevel,
    );
    return UpgradeState(id: id, itemIndex: itemIndex, level: level);
  }

  final oldLevel = _nullableIntValue(json['level']);
  if (oldLevel != null) {
    return UpgradeState(
      id: id,
      itemIndex: 0,
      level: _clampInt(oldLevel, min: 1, max: definition.items.first.maxLevel),
    );
  }

  final oldTotalLevel = legacyUpgradeLevelForKey(
    rawId,
    purchased: _boolValue(json['purchased']),
  );
  return UpgradeState.fromTotalLevel(
    definition: definition,
    totalLevel: oldTotalLevel,
  );
}

Map<String, dynamic>? _stringKeyMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

Map<String, QuestProgress> _questProgressMap(Object? value) {
  final initial = StarterQuestCatalog.initialProgress();
  if (value is! List) {
    return initial;
  }

  final parsed = Map<String, QuestProgress>.from(initial);
  for (final entry in value) {
    final map = _stringKeyMap(entry);
    if (map == null) {
      continue;
    }
    final questId = _stringValue(map['questId']);
    final fallback = initial[questId];
    if (fallback == null) {
      continue;
    }
    parsed[questId] = QuestProgress.fromJson(map, fallback: fallback);
  }
  return Map<String, QuestProgress>.unmodifiable(parsed);
}

Map<String, AchievementProgress> _initialAchievementProgress() {
  return Map<String, AchievementProgress>.unmodifiable({
    for (final achievement in AchievementCatalog.achievements)
      achievement.id: AchievementProgress(achievementId: achievement.id),
  });
}

Map<String, AchievementProgress> _achievementProgressMap(Object? value) {
  final initial = _initialAchievementProgress();
  if (value is! List) {
    return initial;
  }

  final parsed = Map<String, AchievementProgress>.from(initial);
  for (final entry in value) {
    final map = _stringKeyMap(entry);
    if (map == null) {
      continue;
    }
    final achievementId = _stringValue(map['achievementId']);
    final fallback = initial[achievementId];
    if (fallback == null) {
      continue;
    }
    parsed[achievementId] = AchievementProgress.fromJson(
      map,
      fallback: fallback,
    );
  }
  return Map<String, AchievementProgress>.unmodifiable(parsed);
}

String _stringValue(Object? value, {String fallback = ''}) {
  return value is String ? value : fallback;
}

int? _nullableIntValue(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

int _intValue(Object? value, {int fallback = 0}) {
  return _nullableIntValue(value) ?? fallback;
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

double _nonNegativeDouble(Object? value) {
  return math.max(0, _doubleValue(value));
}

bool _boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return false;
}

DateTime? _dateTimeValue(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value)?.toUtc();
}

int _clampInt(int value, {required int min, required int max}) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

Set<String> _stringSet(Object? value) {
  if (value is! Iterable) {
    return const <String>{};
  }
  return Set<String>.unmodifiable(
    value.whereType<String>().where((entry) => entry.isNotEmpty),
  );
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) {
    return const <String, int>{};
  }
  final parsed = <String, int>{};
  value.forEach((key, value) {
    final normalizedKey = key.toString();
    if (normalizedKey.isEmpty) {
      return;
    }
    parsed[normalizedKey] = math.max(0, _intValue(value));
  });
  return Map<String, int>.unmodifiable(parsed);
}

List<String> _sortedStrings(Set<String> values) {
  return values.toList(growable: false)..sort();
}
