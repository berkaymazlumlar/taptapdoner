import 'dart:math' as math;

import 'package:taptapdoner/domain/progression/faz5_models.dart';

enum Collection2ItemKind { recipe, staff, decor, knifeSkin, setBonus }

enum RecipeBonusType {
  menuMultiplier,
  tipValue,
  customerReward,
  goldenDonerReward,
  globalIncome,
}

enum StaffCardBonusType {
  passiveIncome,
  tipChance,
  customerOrderDuration,
  customerReward,
  offlineIncome,
  autoTapPower,
  reputationGain,
}

enum DecorBonusType {
  globalIncome,
  customerSpawnSpeed,
  tipValue,
  reputationGain,
  chestReward,
  shopMultiplier,
}

enum KnifeSkinBonusType { tapIncome, globalIncome, reputationGain }

enum CollectionSetBonusType { tapIncome, passiveIncome, globalIncome }

class RecipeCollectible {
  const RecipeCollectible({
    required this.id,
    required this.name,
    required this.rarity,
    required this.requiredShards,
    required this.maxLevel,
    required this.bonusType,
    required this.bonusValuePerLevel,
    required this.assetKey,
  }) : assert(requiredShards > 0, 'requiredShards must be positive.'),
       assert(maxLevel > 0, 'maxLevel must be positive.');

  final String id;
  final String name;
  final Rarity rarity;
  final int requiredShards;
  final int maxLevel;
  final RecipeBonusType bonusType;
  final double bonusValuePerLevel;
  final String assetKey;
}

class StaffCard {
  const StaffCard({
    required this.id,
    required this.name,
    required this.rarity,
    required this.requiredCards,
    required this.maxLevel,
    required this.bonusType,
    required this.bonusValuePerLevel,
    required this.assetKey,
  }) : assert(requiredCards > 0, 'requiredCards must be positive.'),
       assert(maxLevel > 0, 'maxLevel must be positive.');

  final String id;
  final String name;
  final Rarity rarity;
  final int requiredCards;
  final int maxLevel;
  final StaffCardBonusType bonusType;
  final double bonusValuePerLevel;
  final String assetKey;
}

class DecorItem {
  const DecorItem({
    required this.id,
    required this.name,
    required this.rarity,
    required this.requiredShards,
    required this.bonusType,
    required this.bonusValue,
    required this.assetKey,
  }) : assert(requiredShards > 0, 'requiredShards must be positive.');

  final String id;
  final String name;
  final Rarity rarity;
  final int requiredShards;
  final DecorBonusType bonusType;
  final double bonusValue;
  final String assetKey;
}

class KnifeSkin {
  const KnifeSkin({
    required this.id,
    required this.name,
    required this.rarity,
    required this.requiredShards,
    required this.bonusType,
    required this.bonusValue,
    required this.assetKey,
  }) : assert(requiredShards > 0, 'requiredShards must be positive.');

  final String id;
  final String name;
  final Rarity rarity;
  final int requiredShards;
  final KnifeSkinBonusType bonusType;
  final double bonusValue;
  final String assetKey;
}

class CollectionSetBonus {
  const CollectionSetBonus({
    required this.id,
    required this.name,
    required this.recipeId,
    required this.staffCardId,
    required this.decorId,
    required this.knifeSkinId,
    required this.bonusType,
    required this.bonusValue,
  });

  final String id;
  final String name;
  final String recipeId;
  final String staffCardId;
  final String decorId;
  final String knifeSkinId;
  final CollectionSetBonusType bonusType;
  final double bonusValue;
}

class Collection2BonusTotals {
  const Collection2BonusTotals({
    this.tapBonusPercent = 0,
    this.passiveBonusPercent = 0,
    this.globalBonusPercent = 0,
    this.menuBonusPercent = 0,
    this.tipValueBonusPercent = 0,
    this.tipChanceBonusPercent = 0,
    this.customerRewardBonusPercent = 0,
    this.customerSpawnSpeedPercent = 0,
    this.customerOrderDurationBonusPercent = 0,
    this.offlineIncomeBonusPercent = 0,
    this.reputationGainBonusPercent = 0,
    this.chestRewardBonusPercent = 0,
    this.shopBonusPercent = 0,
    this.goldenDonerRewardBonusPercent = 0,
  });

  final double tapBonusPercent;
  final double passiveBonusPercent;
  final double globalBonusPercent;
  final double menuBonusPercent;
  final double tipValueBonusPercent;
  final double tipChanceBonusPercent;
  final double customerRewardBonusPercent;
  final double customerSpawnSpeedPercent;
  final double customerOrderDurationBonusPercent;
  final double offlineIncomeBonusPercent;
  final double reputationGainBonusPercent;
  final double chestRewardBonusPercent;
  final double shopBonusPercent;
  final double goldenDonerRewardBonusPercent;

  double get reputationGainMultiplier =>
      1 + math.max(0, reputationGainBonusPercent);

  double get chestRewardMultiplier => 1 + math.max(0, chestRewardBonusPercent);
}

class Collection2State {
  const Collection2State({
    this.recipeShards = const <String, int>{},
    this.recipeLevels = const <String, int>{},
    this.staffCards = const <String, int>{},
    this.staffCardLevels = const <String, int>{},
    this.decorShards = const <String, int>{},
    this.unlockedDecorIds = const <String>{},
    this.equippedDecorIds = const <String>{},
    this.knifeSkinShards = const <String, int>{},
    this.unlockedKnifeSkinIds = const <String>{},
    this.equippedKnifeSkinId,
    this.claimedSetBonuses = const <String>{},
    this.prestigeShards = 0,
  });

  final Map<String, int> recipeShards;
  final Map<String, int> recipeLevels;
  final Map<String, int> staffCards;
  final Map<String, int> staffCardLevels;
  final Map<String, int> decorShards;
  final Set<String> unlockedDecorIds;
  final Set<String> equippedDecorIds;
  final Map<String, int> knifeSkinShards;
  final Set<String> unlockedKnifeSkinIds;
  final String? equippedKnifeSkinId;
  final Set<String> claimedSetBonuses;
  final int prestigeShards;

  int recipeShardCount(String id) => math.max(0, recipeShards[id] ?? 0);

  int recipeLevel(String id) => math.max(0, recipeLevels[id] ?? 0);

  int staffCardCount(String id) => math.max(0, staffCards[id] ?? 0);

  int staffCardLevel(String id) => math.max(0, staffCardLevels[id] ?? 0);

  int decorShardCount(String id) => math.max(0, decorShards[id] ?? 0);

  int knifeSkinShardCount(String id) => math.max(0, knifeSkinShards[id] ?? 0);

  bool isRecipeUnlocked(String id) => recipeLevel(id) > 0;

  bool isStaffCardUnlocked(String id) => staffCardLevel(id) > 0;

  bool isDecorUnlocked(String id) => unlockedDecorIds.contains(id);

  bool isKnifeSkinUnlocked(String id) => unlockedKnifeSkinIds.contains(id);

  int get unlockedContentCount {
    return recipeLevels.values.where((level) => level > 0).length +
        staffCardLevels.values.where((level) => level > 0).length +
        unlockedDecorIds.length +
        unlockedKnifeSkinIds.length +
        claimedSetBonuses.length;
  }

  Collection2State copyWith({
    Map<String, int>? recipeShards,
    Map<String, int>? recipeLevels,
    Map<String, int>? staffCards,
    Map<String, int>? staffCardLevels,
    Map<String, int>? decorShards,
    Set<String>? unlockedDecorIds,
    Set<String>? equippedDecorIds,
    Map<String, int>? knifeSkinShards,
    Set<String>? unlockedKnifeSkinIds,
    String? equippedKnifeSkinId,
    bool clearEquippedKnifeSkinId = false,
    Set<String>? claimedSetBonuses,
    int? prestigeShards,
  }) {
    return Collection2State(
      recipeShards: recipeShards ?? this.recipeShards,
      recipeLevels: recipeLevels ?? this.recipeLevels,
      staffCards: staffCards ?? this.staffCards,
      staffCardLevels: staffCardLevels ?? this.staffCardLevels,
      decorShards: decorShards ?? this.decorShards,
      unlockedDecorIds: unlockedDecorIds ?? this.unlockedDecorIds,
      equippedDecorIds: equippedDecorIds ?? this.equippedDecorIds,
      knifeSkinShards: knifeSkinShards ?? this.knifeSkinShards,
      unlockedKnifeSkinIds: unlockedKnifeSkinIds ?? this.unlockedKnifeSkinIds,
      equippedKnifeSkinId: clearEquippedKnifeSkinId
          ? null
          : (equippedKnifeSkinId ?? this.equippedKnifeSkinId),
      claimedSetBonuses: claimedSetBonuses ?? this.claimedSetBonuses,
      prestigeShards: math.max(0, prestigeShards ?? this.prestigeShards),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipeShards': recipeShards,
      'recipeLevels': recipeLevels,
      'staffCards': staffCards,
      'staffCardLevels': staffCardLevels,
      'decorShards': decorShards,
      'unlockedDecorIds': _sortedStrings(unlockedDecorIds),
      'equippedDecorIds': _sortedStrings(equippedDecorIds),
      'knifeSkinShards': knifeSkinShards,
      'unlockedKnifeSkinIds': _sortedStrings(unlockedKnifeSkinIds),
      'equippedKnifeSkinId': equippedKnifeSkinId,
      'claimedSetBonuses': _sortedStrings(claimedSetBonuses),
      'prestigeShards': prestigeShards,
    };
  }

  factory Collection2State.fromJson(Map<String, dynamic>? json) {
    return Collection2State(
      recipeShards: _intMap(json?['recipeShards']),
      recipeLevels: _intMap(json?['recipeLevels']),
      staffCards: _intMap(json?['staffCards']),
      staffCardLevels: _intMap(json?['staffCardLevels']),
      decorShards: _intMap(json?['decorShards']),
      unlockedDecorIds: _stringSet(json?['unlockedDecorIds']),
      equippedDecorIds: _stringSet(json?['equippedDecorIds']),
      knifeSkinShards: _intMap(json?['knifeSkinShards']),
      unlockedKnifeSkinIds: _stringSet(json?['unlockedKnifeSkinIds']),
      equippedKnifeSkinId: _nullableString(json?['equippedKnifeSkinId']),
      claimedSetBonuses: _stringSet(json?['claimedSetBonuses']),
      prestigeShards: math.max(0, _intValue(json?['prestigeShards'])),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Collection2State &&
        _mapEquals(recipeShards, other.recipeShards) &&
        _mapEquals(recipeLevels, other.recipeLevels) &&
        _mapEquals(staffCards, other.staffCards) &&
        _mapEquals(staffCardLevels, other.staffCardLevels) &&
        _mapEquals(decorShards, other.decorShards) &&
        _setEquals(unlockedDecorIds, other.unlockedDecorIds) &&
        _setEquals(equippedDecorIds, other.equippedDecorIds) &&
        _mapEquals(knifeSkinShards, other.knifeSkinShards) &&
        _setEquals(unlockedKnifeSkinIds, other.unlockedKnifeSkinIds) &&
        equippedKnifeSkinId == other.equippedKnifeSkinId &&
        _setEquals(claimedSetBonuses, other.claimedSetBonuses) &&
        prestigeShards == other.prestigeShards;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(recipeShards.entries),
    Object.hashAll(recipeLevels.entries),
    Object.hashAll(staffCards.entries),
    Object.hashAll(staffCardLevels.entries),
    Object.hashAll(decorShards.entries),
    Object.hashAll(unlockedDecorIds),
    Object.hashAll(equippedDecorIds),
    Object.hashAll(knifeSkinShards.entries),
    Object.hashAll(unlockedKnifeSkinIds),
    equippedKnifeSkinId,
    Object.hashAll(claimedSetBonuses),
    prestigeShards,
  );
}

class WeightedDrop {
  const WeightedDrop({
    required this.rewardType,
    this.itemId,
    required this.amount,
    required this.weight,
    required this.rarity,
    this.durationSeconds,
  }) : assert(amount >= 0, 'amount cannot be negative.'),
       assert(weight > 0, 'weight must be positive.');

  final ChestRewardType rewardType;
  final String? itemId;
  final int amount;
  final int weight;
  final Rarity rarity;
  final int? durationSeconds;
}

class ChestDropTable {
  const ChestDropTable({required this.chestType, required this.drops});

  final ChestType chestType;
  final List<WeightedDrop> drops;

  WeightedDrop roll(math.Random random) {
    final totalWeight = drops.fold<int>(
      0,
      (total, drop) => total + math.max(0, drop.weight),
    );
    if (drops.isEmpty || totalWeight <= 0) {
      return const WeightedDrop(
        rewardType: ChestRewardType.money,
        amount: 1,
        weight: 1,
        rarity: Rarity.common,
      );
    }
    var roll = random.nextDouble() * totalWeight;
    for (final drop in drops) {
      roll -= drop.weight;
      if (roll <= 0) {
        return drop;
      }
    }
    return drops.last;
  }
}

String? _nullableString(Object? value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
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

Set<String> _stringSet(Object? value) {
  if (value is! Iterable) {
    return const <String>{};
  }
  return Set<String>.unmodifiable(
    value.whereType<String>().where((entry) => entry.isNotEmpty),
  );
}

List<String> _sortedStrings(Set<String> values) {
  return values.toList(growable: false)..sort();
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _setEquals<T>(Set<T> left, Set<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final value in left) {
    if (!right.contains(value)) {
      return false;
    }
  }
  return true;
}
