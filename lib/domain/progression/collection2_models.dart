import 'dart:math' as math;

import 'package:taptapdoner/domain/progression/faz5_models.dart';

enum Collection2ItemKind { customer, master, decor, moment, setBonus }

enum CustomerCardBonusType {
  menuMultiplier,
  tipValue,
  customerReward,
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

enum MomentCardBonusType { tapIncome, globalIncome, reputationGain }

enum CollectionSetBonusType { tapIncome, passiveIncome, globalIncome }

class CustomerCard {
  const CustomerCard({
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
  final CustomerCardBonusType bonusType;
  final double bonusValuePerLevel;
  final String assetKey;
}

class MasterCard {
  const MasterCard({
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

class MomentCard {
  const MomentCard({
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
  final MomentCardBonusType bonusType;
  final double bonusValue;
  final String assetKey;
}

class CollectionSetBonus {
  const CollectionSetBonus({
    required this.id,
    required this.name,
    required this.customerCardId,
    required this.masterCardId,
    required this.decorId,
    required this.momentCardId,
    required this.bonusType,
    required this.bonusValue,
  });

  final String id;
  final String name;
  final String customerCardId;
  final String masterCardId;
  final String decorId;
  final String momentCardId;
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

  double get reputationGainMultiplier =>
      1 + math.max(0, reputationGainBonusPercent);

  double get chestRewardMultiplier => 1 + math.max(0, chestRewardBonusPercent);
}

class Collection2State {
  const Collection2State({
    this.customerCardShards = const <String, int>{},
    this.customerCardLevels = const <String, int>{},
    this.masterCards = const <String, int>{},
    this.masterCardLevels = const <String, int>{},
    this.decorShards = const <String, int>{},
    this.unlockedDecorIds = const <String>{},
    this.equippedDecorIds = const <String>{},
    this.momentCardShards = const <String, int>{},
    this.unlockedMomentCardIds = const <String>{},
    this.claimedSetBonuses = const <String>{},
    this.prestigeShards = 0,
  });

  final Map<String, int> customerCardShards;
  final Map<String, int> customerCardLevels;
  final Map<String, int> masterCards;
  final Map<String, int> masterCardLevels;
  final Map<String, int> decorShards;
  final Set<String> unlockedDecorIds;
  final Set<String> equippedDecorIds;
  final Map<String, int> momentCardShards;
  final Set<String> unlockedMomentCardIds;
  final Set<String> claimedSetBonuses;
  final int prestigeShards;

  int customerCardCount(String id) => math.max(0, customerCardShards[id] ?? 0);

  int customerCardLevel(String id) => math.max(0, customerCardLevels[id] ?? 0);

  int masterCardCount(String id) => math.max(0, masterCards[id] ?? 0);

  int masterCardLevel(String id) => math.max(0, masterCardLevels[id] ?? 0);

  int decorShardCount(String id) => math.max(0, decorShards[id] ?? 0);

  int momentCardCount(String id) => math.max(0, momentCardShards[id] ?? 0);

  bool isCustomerCardUnlocked(String id) => customerCardLevel(id) > 0;

  bool isMasterCardUnlocked(String id) => masterCardLevel(id) > 0;

  bool isDecorUnlocked(String id) => unlockedDecorIds.contains(id);

  bool isMomentCardUnlocked(String id) => unlockedMomentCardIds.contains(id);

  int get unlockedContentCount {
    return customerCardLevels.values.where((level) => level > 0).length +
        masterCardLevels.values.where((level) => level > 0).length +
        unlockedDecorIds.length +
        unlockedMomentCardIds.length +
        claimedSetBonuses.length;
  }

  Collection2State copyWith({
    Map<String, int>? customerCardShards,
    Map<String, int>? customerCardLevels,
    Map<String, int>? masterCards,
    Map<String, int>? masterCardLevels,
    Map<String, int>? decorShards,
    Set<String>? unlockedDecorIds,
    Set<String>? equippedDecorIds,
    Map<String, int>? momentCardShards,
    Set<String>? unlockedMomentCardIds,
    Set<String>? claimedSetBonuses,
    int? prestigeShards,
  }) {
    return Collection2State(
      customerCardShards: customerCardShards ?? this.customerCardShards,
      customerCardLevels: customerCardLevels ?? this.customerCardLevels,
      masterCards: masterCards ?? this.masterCards,
      masterCardLevels: masterCardLevels ?? this.masterCardLevels,
      decorShards: decorShards ?? this.decorShards,
      unlockedDecorIds: unlockedDecorIds ?? this.unlockedDecorIds,
      equippedDecorIds: equippedDecorIds ?? this.equippedDecorIds,
      momentCardShards: momentCardShards ?? this.momentCardShards,
      unlockedMomentCardIds:
          unlockedMomentCardIds ?? this.unlockedMomentCardIds,
      claimedSetBonuses: claimedSetBonuses ?? this.claimedSetBonuses,
      prestigeShards: math.max(0, prestigeShards ?? this.prestigeShards),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerCardShards': customerCardShards,
      'customerCardLevels': customerCardLevels,
      'masterCards': masterCards,
      'masterCardLevels': masterCardLevels,
      'decorShards': decorShards,
      'unlockedDecorIds': _sortedStrings(unlockedDecorIds),
      'equippedDecorIds': _sortedStrings(equippedDecorIds),
      'momentCardShards': momentCardShards,
      'unlockedMomentCardIds': _sortedStrings(unlockedMomentCardIds),
      'claimedSetBonuses': _sortedStrings(claimedSetBonuses),
      'prestigeShards': prestigeShards,
    };
  }

  factory Collection2State.fromJson(Map<String, dynamic>? json) {
    final customerShards = _intMap(
      json?['customerCardShards'] ?? json?['recipeShards'],
    );
    final customerLevels = _intMap(
      json?['customerCardLevels'] ?? json?['recipeLevels'],
    );
    final momentShards = _intMap(
      json?['momentCardShards'] ?? json?['knifeSkinShards'],
    );
    final unlockedMoments = _stringSet(
      json?['unlockedMomentCardIds'] ?? json?['unlockedKnifeSkinIds'],
    );
    return Collection2State(
      customerCardShards: _migrateCardMap(customerShards, _legacyCustomerIds),
      customerCardLevels: _migrateCardMap(customerLevels, _legacyCustomerIds),
      masterCards: _intMap(json?['masterCards'] ?? json?['staffCards']),
      masterCardLevels: _intMap(
        json?['masterCardLevels'] ?? json?['staffCardLevels'],
      ),
      decorShards: _intMap(json?['decorShards']),
      unlockedDecorIds: _stringSet(json?['unlockedDecorIds']),
      equippedDecorIds: _stringSet(json?['equippedDecorIds']),
      momentCardShards: _migrateCardMap(momentShards, _legacyMomentIds),
      unlockedMomentCardIds: _migrateCardSet(unlockedMoments, _legacyMomentIds),
      claimedSetBonuses: _stringSet(json?['claimedSetBonuses']),
      prestigeShards: math.max(0, _intValue(json?['prestigeShards'])),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Collection2State &&
        _mapEquals(customerCardShards, other.customerCardShards) &&
        _mapEquals(customerCardLevels, other.customerCardLevels) &&
        _mapEquals(masterCards, other.masterCards) &&
        _mapEquals(masterCardLevels, other.masterCardLevels) &&
        _mapEquals(decorShards, other.decorShards) &&
        _setEquals(unlockedDecorIds, other.unlockedDecorIds) &&
        _setEquals(equippedDecorIds, other.equippedDecorIds) &&
        _mapEquals(momentCardShards, other.momentCardShards) &&
        _setEquals(unlockedMomentCardIds, other.unlockedMomentCardIds) &&
        _setEquals(claimedSetBonuses, other.claimedSetBonuses) &&
        prestigeShards == other.prestigeShards;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(customerCardShards.entries),
    Object.hashAll(customerCardLevels.entries),
    Object.hashAll(masterCards.entries),
    Object.hashAll(masterCardLevels.entries),
    Object.hashAll(decorShards.entries),
    Object.hashAll(unlockedDecorIds),
    Object.hashAll(equippedDecorIds),
    Object.hashAll(momentCardShards.entries),
    Object.hashAll(unlockedMomentCardIds),
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

const _legacyCustomerIds = <String, String>{
  'recipe_chicken_doner': 'customer_student_regular',
  'recipe_beef_doner': 'customer_night_worker',
  'recipe_hatay_style': 'customer_taxi_driver',
  'recipe_sauced_doner': 'customer_food_blogger',
  'recipe_gourmet_doner': 'customer_gourmet_critic',
  'recipe_cosmic_doner': 'customer_cosmic_traveler',
};

const _legacyMomentIds = <String, String>{
  'knife_skin_rusty': 'moment_first_shift',
  'knife_skin_electric': 'moment_neon_rush',
  'knife_skin_gold': 'moment_golden_service',
  'knife_skin_cosmic': 'moment_cosmic_opening',
};

Map<String, int> _migrateCardMap(
  Map<String, int> source,
  Map<String, String> legacyIds,
) {
  if (source.isEmpty) {
    return source;
  }
  final migrated = <String, int>{};
  for (final entry in source.entries) {
    final id = legacyIds[entry.key] ?? entry.key;
    migrated[id] = math.max(migrated[id] ?? 0, entry.value);
  }
  return Map<String, int>.unmodifiable(migrated);
}

Set<String> _migrateCardSet(Set<String> source, Map<String, String> legacyIds) {
  return Set<String>.unmodifiable(source.map((id) => legacyIds[id] ?? id));
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
