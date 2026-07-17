import 'dart:math' as math;

import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';

class Collection2ApplyResult {
  const Collection2ApplyResult({
    required this.state,
    this.unlockedCount = 0,
    this.levelUpCount = 0,
    this.overflowReputation = 0,
    this.prestigePoints = 0,
    this.claimedSetBonusCount = 0,
  });

  final Collection2State state;
  final int unlockedCount;
  final int levelUpCount;
  final int overflowReputation;
  final int prestigePoints;
  final int claimedSetBonusCount;
}

class _UpgradeableApplyResult {
  const _UpgradeableApplyResult({
    required this.shards,
    required this.levels,
    required this.unlockedCount,
    required this.levelUpCount,
    required this.overflowShards,
  });

  final Map<String, int> shards;
  final Map<String, int> levels;
  final int unlockedCount;
  final int levelUpCount;
  final int overflowShards;
}

class _UnlockableApplyResult {
  const _UnlockableApplyResult({
    required this.shards,
    required this.unlockedIds,
    required this.equippedIds,
    required this.unlockedCount,
    required this.overflowShards,
  });

  final Map<String, int> shards;
  final Set<String> unlockedIds;
  final Set<String> equippedIds;
  final int unlockedCount;
  final int overflowShards;
}

abstract final class Collection2Catalog {
  static const prestigeShardsPerPoint = 10;

  static const customerCards = <CustomerCard>[
    CustomerCard(
      id: 'customer_student_regular',
      name: 'Student Regular',
      rarity: Rarity.common,
      requiredShards: 10,
      maxLevel: 5,
      bonusType: CustomerCardBonusType.menuMultiplier,
      bonusValuePerLevel: 0.01,
      assetKey: 'placeholder_customer_student_regular',
    ),
    CustomerCard(
      id: 'customer_night_worker',
      name: 'Night Shift Worker',
      rarity: Rarity.common,
      requiredShards: 10,
      maxLevel: 5,
      bonusType: CustomerCardBonusType.menuMultiplier,
      bonusValuePerLevel: 0.015,
      assetKey: 'placeholder_customer_night_worker',
    ),
    CustomerCard(
      id: 'customer_taxi_driver',
      name: 'Taxi Driver',
      rarity: Rarity.rare,
      requiredShards: 20,
      maxLevel: 5,
      bonusType: CustomerCardBonusType.tipValue,
      bonusValuePerLevel: 0.02,
      assetKey: 'placeholder_customer_taxi_driver',
    ),
    CustomerCard(
      id: 'customer_food_blogger',
      name: 'Food Blogger',
      rarity: Rarity.rare,
      requiredShards: 20,
      maxLevel: 5,
      bonusType: CustomerCardBonusType.customerReward,
      bonusValuePerLevel: 0.02,
      assetKey: 'placeholder_customer_food_blogger',
    ),
    CustomerCard(
      id: 'customer_gourmet_critic',
      name: 'Gourmet Critic',
      rarity: Rarity.epic,
      requiredShards: 35,
      maxLevel: 5,
      bonusType: CustomerCardBonusType.globalIncome,
      bonusValuePerLevel: 0.01,
      assetKey: 'placeholder_customer_gourmet_critic',
    ),
    CustomerCard(
      id: 'customer_cosmic_traveler',
      name: 'Cosmic Traveler',
      rarity: Rarity.mythic,
      requiredShards: 100,
      maxLevel: 5,
      bonusType: CustomerCardBonusType.globalIncome,
      bonusValuePerLevel: 0.02,
      assetKey: 'placeholder_customer_cosmic_traveler',
    ),
  ];

  static const masterCards = <MasterCard>[
    MasterCard(
      id: 'staff_apprentice',
      name: 'Apprentice Ali',
      rarity: Rarity.common,
      requiredCards: 10,
      maxLevel: 5,
      bonusType: StaffCardBonusType.passiveIncome,
      bonusValuePerLevel: 0.01,
      assetKey: 'placeholder_staff_apprentice',
    ),
    MasterCard(
      id: 'staff_journeyman',
      name: 'Journeyman Zeynep',
      rarity: Rarity.common,
      requiredCards: 10,
      maxLevel: 5,
      bonusType: StaffCardBonusType.passiveIncome,
      bonusValuePerLevel: 0.015,
      assetKey: 'placeholder_staff_journeyman',
    ),
    MasterCard(
      id: 'staff_cashier',
      name: 'Cashier Ece',
      rarity: Rarity.rare,
      requiredCards: 20,
      maxLevel: 5,
      bonusType: StaffCardBonusType.tipChance,
      bonusValuePerLevel: 0.005,
      assetKey: 'placeholder_staff_cashier',
    ),
    MasterCard(
      id: 'staff_sauce_master',
      name: 'Sauce Master Leyla',
      rarity: Rarity.rare,
      requiredCards: 20,
      maxLevel: 5,
      bonusType: StaffCardBonusType.customerReward,
      bonusValuePerLevel: 0.02,
      assetKey: 'placeholder_staff_sauce_master',
    ),
    MasterCard(
      id: 'staff_doner_master',
      name: 'Doner Master Kemal',
      rarity: Rarity.epic,
      requiredCards: 35,
      maxLevel: 5,
      bonusType: StaffCardBonusType.customerOrderDuration,
      bonusValuePerLevel: 0.02,
      assetKey: 'placeholder_staff_doner_master',
    ),
    MasterCard(
      id: 'staff_courier',
      name: 'Courier Mert',
      rarity: Rarity.epic,
      requiredCards: 35,
      maxLevel: 5,
      bonusType: StaffCardBonusType.offlineIncome,
      bonusValuePerLevel: 0.02,
      assetKey: 'placeholder_staff_courier',
    ),
    MasterCard(
      id: 'staff_robot_master',
      name: 'Robot Master RX-01',
      rarity: Rarity.legendary,
      requiredCards: 50,
      maxLevel: 5,
      bonusType: StaffCardBonusType.autoTapPower,
      bonusValuePerLevel: 0.03,
      assetKey: 'placeholder_staff_robot_master',
    ),
    MasterCard(
      id: 'staff_influencer_chef',
      name: 'Influencer Chef Duru',
      rarity: Rarity.mythic,
      requiredCards: 100,
      maxLevel: 5,
      bonusType: StaffCardBonusType.reputationGain,
      bonusValuePerLevel: 0.03,
      assetKey: 'placeholder_staff_influencer_chef',
    ),
  ];

  static const decorItems = <DecorItem>[
    DecorItem(
      id: 'decor_new_sign',
      name: 'New Sign',
      rarity: Rarity.common,
      requiredShards: 10,
      bonusType: DecorBonusType.customerSpawnSpeed,
      bonusValue: 0.01,
      assetKey: 'placeholder_decor_new_sign',
    ),
    DecorItem(
      id: 'decor_spice_shelf',
      name: 'Spice Shelf',
      rarity: Rarity.common,
      requiredShards: 10,
      bonusType: DecorBonusType.shopMultiplier,
      bonusValue: 0.01,
      assetKey: 'placeholder_decor_spice_shelf',
    ),
    DecorItem(
      id: 'decor_red_neon',
      name: 'Red Neon',
      rarity: Rarity.rare,
      requiredShards: 20,
      bonusType: DecorBonusType.reputationGain,
      bonusValue: 0.02,
      assetKey: 'placeholder_decor_red_neon',
    ),
    DecorItem(
      id: 'decor_modern_menu_board',
      name: 'Modern Menu Board',
      rarity: Rarity.rare,
      requiredShards: 20,
      bonusType: DecorBonusType.tipValue,
      bonusValue: 0.02,
      assetKey: 'placeholder_decor_modern_menu_board',
    ),
    DecorItem(
      id: 'decor_gold_counter',
      name: 'Gold Counter',
      rarity: Rarity.epic,
      requiredShards: 35,
      bonusType: DecorBonusType.globalIncome,
      bonusValue: 0.02,
      assetKey: 'placeholder_decor_gold_counter',
    ),
    DecorItem(
      id: 'decor_vip_table',
      name: 'VIP Table',
      rarity: Rarity.epic,
      requiredShards: 35,
      bonusType: DecorBonusType.customerSpawnSpeed,
      bonusValue: 0.01,
      assetKey: 'placeholder_decor_vip_table',
    ),
    DecorItem(
      id: 'decor_mall_stand',
      name: 'Mall Stand',
      rarity: Rarity.legendary,
      requiredShards: 50,
      bonusType: DecorBonusType.chestReward,
      bonusValue: 0.03,
      assetKey: 'placeholder_decor_mall_stand',
    ),
    DecorItem(
      id: 'decor_galactic_sign',
      name: 'Galactic Sign',
      rarity: Rarity.legendary,
      requiredShards: 50,
      bonusType: DecorBonusType.shopMultiplier,
      bonusValue: 0.03,
      assetKey: 'placeholder_decor_galactic_sign',
    ),
    DecorItem(
      id: 'decor_infinite_doner_statue',
      name: 'Infinite Doner Statue',
      rarity: Rarity.mythic,
      requiredShards: 100,
      bonusType: DecorBonusType.globalIncome,
      bonusValue: 0.05,
      assetKey: 'placeholder_decor_infinite_doner_statue',
    ),
  ];

  static const momentCards = <MomentCard>[
    MomentCard(
      id: 'moment_first_shift',
      name: 'The First Shift',
      rarity: Rarity.common,
      requiredShards: 10,
      bonusType: MomentCardBonusType.tapIncome,
      bonusValue: 0.01,
      assetKey: 'placeholder_moment_first_shift',
    ),
    MomentCard(
      id: 'moment_neon_rush',
      name: 'Neon Rush',
      rarity: Rarity.epic,
      requiredShards: 35,
      bonusType: MomentCardBonusType.tapIncome,
      bonusValue: 0.03,
      assetKey: 'placeholder_moment_neon_rush',
    ),
    MomentCard(
      id: 'moment_golden_service',
      name: 'The Golden Service',
      rarity: Rarity.legendary,
      requiredShards: 50,
      bonusType: MomentCardBonusType.globalIncome,
      bonusValue: 0.04,
      assetKey: 'placeholder_moment_golden_service',
    ),
    MomentCard(
      id: 'moment_cosmic_opening',
      name: 'Cosmic Grand Opening',
      rarity: Rarity.mythic,
      requiredShards: 100,
      bonusType: MomentCardBonusType.reputationGain,
      bonusValue: 0.05,
      assetKey: 'placeholder_moment_cosmic_opening',
    ),
  ];

  static const setBonuses = <CollectionSetBonus>[
    CollectionSetBonus(
      id: 'street_set',
      name: 'Street Set',
      customerCardId: 'customer_student_regular',
      masterCardId: 'staff_apprentice',
      decorId: 'decor_new_sign',
      momentCardId: 'moment_first_shift',
      bonusType: CollectionSetBonusType.tapIncome,
      bonusValue: 0.05,
    ),
    CollectionSetBonus(
      id: 'master_set',
      name: 'Master Set',
      customerCardId: 'customer_gourmet_critic',
      masterCardId: 'staff_doner_master',
      decorId: 'decor_modern_menu_board',
      momentCardId: 'moment_neon_rush',
      bonusType: CollectionSetBonusType.passiveIncome,
      bonusValue: 0.10,
    ),
  ];

  static final customerCardById = Map<String, CustomerCard>.unmodifiable({
    for (final item in customerCards) item.id: item,
  });

  static final masterCardById = Map<String, MasterCard>.unmodifiable({
    for (final item in masterCards) item.id: item,
  });

  static final decorById = Map<String, DecorItem>.unmodifiable({
    for (final item in decorItems) item.id: item,
  });

  static final momentCardById = Map<String, MomentCard>.unmodifiable({
    for (final item in momentCards) item.id: item,
  });

  static final setBonusById = Map<String, CollectionSetBonus>.unmodifiable({
    for (final item in setBonuses) item.id: item,
  });

  static Collection2ApplyResult applyChestReward({
    required Collection2State state,
    required ChestRewardType rewardType,
    required int amount,
    required Rarity rarity,
    String? itemId,
    math.Random? random,
  }) {
    return switch (rewardType) {
      ChestRewardType.recipeShard => addRecipeShards(
        state,
        itemId ?? pickCustomerCardId(rarity: rarity, random: random),
        amount,
      ),
      ChestRewardType.staffCardShard => addStaffCards(
        state,
        itemId ?? pickMasterCardId(rarity: rarity, random: random),
        amount,
      ),
      ChestRewardType.decorShard => addDecorShards(
        state,
        itemId ?? pickDecorId(rarity: rarity, random: random),
        amount,
      ),
      ChestRewardType.knifeSkinShard => addKnifeSkinShards(
        state,
        itemId ?? pickMomentCardId(rarity: rarity, random: random),
        amount,
      ),
      ChestRewardType.prestigeShard => addPrestigeShards(state, amount),
      _ => Collection2ApplyResult(state: state),
    };
  }

  static Collection2ApplyResult addRecipeShards(
    Collection2State state,
    String itemId,
    int amount,
  ) {
    final definition = customerCardById[itemId];
    if (definition == null || amount <= 0) {
      return Collection2ApplyResult(state: state);
    }
    final result = _applyUpgradeable(
      shards: state.customerCardShards,
      levels: state.customerCardLevels,
      itemId: itemId,
      amount: amount,
      requiredShards: definition.requiredShards,
      maxLevel: definition.maxLevel,
    );
    final nextState = state.copyWith(
      customerCardShards: result.shards,
      customerCardLevels: result.levels,
    );
    return _withSetRefresh(
      nextState,
      unlockedCount: result.unlockedCount,
      levelUpCount: result.levelUpCount,
      overflowReputation: _overflowReputation(
        definition.rarity,
        result.overflowShards,
      ),
    );
  }

  static Collection2ApplyResult addStaffCards(
    Collection2State state,
    String itemId,
    int amount,
  ) {
    final definition = masterCardById[itemId];
    if (definition == null || amount <= 0) {
      return Collection2ApplyResult(state: state);
    }
    final result = _applyUpgradeable(
      shards: state.masterCards,
      levels: state.masterCardLevels,
      itemId: itemId,
      amount: amount,
      requiredShards: definition.requiredCards,
      maxLevel: definition.maxLevel,
    );
    final nextState = state.copyWith(
      masterCards: result.shards,
      masterCardLevels: result.levels,
    );
    return _withSetRefresh(
      nextState,
      unlockedCount: result.unlockedCount,
      levelUpCount: result.levelUpCount,
      overflowReputation: _overflowReputation(
        definition.rarity,
        result.overflowShards,
      ),
    );
  }

  static Collection2ApplyResult addDecorShards(
    Collection2State state,
    String itemId,
    int amount,
  ) {
    final definition = decorById[itemId];
    if (definition == null || amount <= 0) {
      return Collection2ApplyResult(state: state);
    }
    final result = _applyUnlockable(
      shards: state.decorShards,
      unlockedIds: state.unlockedDecorIds,
      equippedIds: state.equippedDecorIds,
      itemId: itemId,
      amount: amount,
      requiredShards: definition.requiredShards,
    );
    final nextState = state.copyWith(
      decorShards: result.shards,
      unlockedDecorIds: result.unlockedIds,
      equippedDecorIds: result.equippedIds,
    );
    return _withSetRefresh(
      nextState,
      unlockedCount: result.unlockedCount,
      overflowReputation: _overflowReputation(
        definition.rarity,
        result.overflowShards,
      ),
    );
  }

  static Collection2ApplyResult addKnifeSkinShards(
    Collection2State state,
    String itemId,
    int amount,
  ) {
    final definition = momentCardById[itemId];
    if (definition == null || amount <= 0) {
      return Collection2ApplyResult(state: state);
    }
    final result = _applyUnlockable(
      shards: state.momentCardShards,
      unlockedIds: state.unlockedMomentCardIds,
      equippedIds: const <String>{},
      itemId: itemId,
      amount: amount,
      requiredShards: definition.requiredShards,
    );
    final nextState = state.copyWith(
      momentCardShards: result.shards,
      unlockedMomentCardIds: result.unlockedIds,
    );
    return _withSetRefresh(
      nextState,
      unlockedCount: result.unlockedCount,
      overflowReputation: _overflowReputation(
        definition.rarity,
        result.overflowShards,
      ),
    );
  }

  static Collection2ApplyResult addPrestigeShards(
    Collection2State state,
    int amount,
  ) {
    if (amount <= 0) {
      return Collection2ApplyResult(state: state);
    }
    final total = state.prestigeShards + amount;
    return Collection2ApplyResult(
      state: state.copyWith(prestigeShards: total % prestigeShardsPerPoint),
      prestigePoints: total ~/ prestigeShardsPerPoint,
    );
  }

  static Collection2ApplyResult refreshSetBonuses(Collection2State state) {
    return _withSetRefresh(state);
  }

  static bool isSetComplete(Collection2State state, CollectionSetBonus set) {
    return state.isCustomerCardUnlocked(set.customerCardId) &&
        state.isMasterCardUnlocked(set.masterCardId) &&
        state.isDecorUnlocked(set.decorId) &&
        state.isMomentCardUnlocked(set.momentCardId);
  }

  static Collection2BonusTotals bonusTotalsFor(Collection2State state) {
    var tap = 0.0;
    var passive = 0.0;
    var global = 0.0;
    var menu = 0.0;
    var tipValue = 0.0;
    var tipChance = 0.0;
    var customerReward = 0.0;
    var customerSpawn = 0.0;
    var customerDuration = 0.0;
    var offline = 0.0;
    var reputation = 0.0;
    var chestReward = 0.0;
    var shop = 0.0;

    for (final definition in customerCards) {
      final level = state.customerCardLevel(definition.id);
      if (level <= 0) {
        continue;
      }
      final amount = definition.bonusValuePerLevel * level;
      switch (definition.bonusType) {
        case CustomerCardBonusType.menuMultiplier:
          menu += amount;
        case CustomerCardBonusType.tipValue:
          tipValue += amount;
        case CustomerCardBonusType.customerReward:
          customerReward += amount;
        case CustomerCardBonusType.globalIncome:
          global += amount;
      }
    }

    for (final definition in masterCards) {
      final level = state.masterCardLevel(definition.id);
      if (level <= 0) {
        continue;
      }
      final amount = definition.bonusValuePerLevel * level;
      switch (definition.bonusType) {
        case StaffCardBonusType.passiveIncome:
          passive += amount;
        case StaffCardBonusType.tipChance:
          tipChance += amount;
        case StaffCardBonusType.customerOrderDuration:
          customerDuration += amount;
        case StaffCardBonusType.customerReward:
          customerReward += amount;
        case StaffCardBonusType.offlineIncome:
          offline += amount;
        case StaffCardBonusType.autoTapPower:
          tap += amount;
        case StaffCardBonusType.reputationGain:
          reputation += amount;
      }
    }

    for (final definition in decorItems) {
      if (!state.isDecorUnlocked(definition.id)) {
        continue;
      }
      switch (definition.bonusType) {
        case DecorBonusType.globalIncome:
          global += definition.bonusValue;
        case DecorBonusType.customerSpawnSpeed:
          customerSpawn += definition.bonusValue;
        case DecorBonusType.tipValue:
          tipValue += definition.bonusValue;
        case DecorBonusType.reputationGain:
          reputation += definition.bonusValue;
        case DecorBonusType.chestReward:
          chestReward += definition.bonusValue;
        case DecorBonusType.shopMultiplier:
          shop += definition.bonusValue;
      }
    }

    for (final definition in momentCards) {
      if (!state.isMomentCardUnlocked(definition.id)) {
        continue;
      }
      switch (definition.bonusType) {
        case MomentCardBonusType.tapIncome:
          tap += definition.bonusValue;
        case MomentCardBonusType.globalIncome:
          global += definition.bonusValue;
        case MomentCardBonusType.reputationGain:
          reputation += definition.bonusValue;
      }
    }

    for (final setId in state.claimedSetBonuses) {
      final set = setBonusById[setId];
      if (set == null) {
        continue;
      }
      switch (set.bonusType) {
        case CollectionSetBonusType.tapIncome:
          tap += set.bonusValue;
        case CollectionSetBonusType.passiveIncome:
          passive += set.bonusValue;
        case CollectionSetBonusType.globalIncome:
          global += set.bonusValue;
      }
    }

    return Collection2BonusTotals(
      tapBonusPercent: tap,
      passiveBonusPercent: passive,
      globalBonusPercent: global,
      menuBonusPercent: menu,
      tipValueBonusPercent: tipValue,
      tipChanceBonusPercent: tipChance,
      customerRewardBonusPercent: customerReward,
      customerSpawnSpeedPercent: customerSpawn,
      customerOrderDurationBonusPercent: customerDuration,
      offlineIncomeBonusPercent: offline,
      reputationGainBonusPercent: reputation,
      chestRewardBonusPercent: chestReward,
      shopBonusPercent: shop,
    );
  }

  static String pickCustomerCardId({Rarity? rarity, math.Random? random}) {
    return _pickByRarity(customerCards, rarity, random).id;
  }

  static String pickMasterCardId({Rarity? rarity, math.Random? random}) {
    return _pickByRarity(masterCards, rarity, random).id;
  }

  static String pickDecorId({Rarity? rarity, math.Random? random}) {
    return _pickByRarity(decorItems, rarity, random).id;
  }

  static String pickMomentCardId({Rarity? rarity, math.Random? random}) {
    return _pickByRarity(momentCards, rarity, random).id;
  }

  static _UpgradeableApplyResult _applyUpgradeable({
    required Map<String, int> shards,
    required Map<String, int> levels,
    required String itemId,
    required int amount,
    required int requiredShards,
    required int maxLevel,
  }) {
    final nextShards = Map<String, int>.from(shards);
    final nextLevels = Map<String, int>.from(levels);
    final currentLevel = math.max(0, levels[itemId] ?? 0);
    if (currentLevel >= maxLevel) {
      nextShards[itemId] = 0;
      return _UpgradeableApplyResult(
        shards: Map<String, int>.unmodifiable(nextShards),
        levels: Map<String, int>.unmodifiable(nextLevels),
        unlockedCount: 0,
        levelUpCount: 0,
        overflowShards: amount,
      );
    }

    var totalShards = math.max(0, shards[itemId] ?? 0) + amount;
    var nextLevel = currentLevel;
    var unlockedCount = 0;
    var levelUpCount = 0;

    while (nextLevel < maxLevel && totalShards >= requiredShards) {
      totalShards -= requiredShards;
      nextLevel += 1;
      if (nextLevel == 1 && currentLevel == 0) {
        unlockedCount += 1;
      } else {
        levelUpCount += 1;
      }
    }

    var overflowShards = 0;
    if (nextLevel >= maxLevel && totalShards > 0) {
      overflowShards = totalShards;
      totalShards = 0;
    }
    nextShards[itemId] = totalShards;
    nextLevels[itemId] = nextLevel;
    return _UpgradeableApplyResult(
      shards: Map<String, int>.unmodifiable(nextShards),
      levels: Map<String, int>.unmodifiable(nextLevels),
      unlockedCount: unlockedCount,
      levelUpCount: levelUpCount,
      overflowShards: overflowShards,
    );
  }

  static _UnlockableApplyResult _applyUnlockable({
    required Map<String, int> shards,
    required Set<String> unlockedIds,
    required Set<String> equippedIds,
    required String itemId,
    required int amount,
    required int requiredShards,
  }) {
    final nextShards = Map<String, int>.from(shards);
    final nextUnlocked = Set<String>.from(unlockedIds);
    final nextEquipped = Set<String>.from(equippedIds);
    if (nextUnlocked.contains(itemId)) {
      nextShards[itemId] = 0;
      return _UnlockableApplyResult(
        shards: Map<String, int>.unmodifiable(nextShards),
        unlockedIds: Set<String>.unmodifiable(nextUnlocked),
        equippedIds: Set<String>.unmodifiable(nextEquipped),
        unlockedCount: 0,
        overflowShards: amount,
      );
    }

    final totalShards = math.max(0, shards[itemId] ?? 0) + amount;
    if (totalShards < requiredShards) {
      nextShards[itemId] = totalShards;
      return _UnlockableApplyResult(
        shards: Map<String, int>.unmodifiable(nextShards),
        unlockedIds: Set<String>.unmodifiable(nextUnlocked),
        equippedIds: Set<String>.unmodifiable(nextEquipped),
        unlockedCount: 0,
        overflowShards: 0,
      );
    }

    nextShards[itemId] = 0;
    nextUnlocked.add(itemId);
    if (nextEquipped.isEmpty) {
      nextEquipped.add(itemId);
    }
    return _UnlockableApplyResult(
      shards: Map<String, int>.unmodifiable(nextShards),
      unlockedIds: Set<String>.unmodifiable(nextUnlocked),
      equippedIds: Set<String>.unmodifiable(nextEquipped),
      unlockedCount: 1,
      overflowShards: math.max(0, totalShards - requiredShards),
    );
  }

  static Collection2ApplyResult _withSetRefresh(
    Collection2State state, {
    int unlockedCount = 0,
    int levelUpCount = 0,
    int overflowReputation = 0,
    int prestigePoints = 0,
  }) {
    final claimed = Set<String>.from(state.claimedSetBonuses);
    var claimedSetBonusCount = 0;
    for (final set in setBonuses) {
      if (claimed.contains(set.id) || !isSetComplete(state, set)) {
        continue;
      }
      claimed.add(set.id);
      claimedSetBonusCount += 1;
    }
    final nextState = claimedSetBonusCount == 0
        ? state
        : state.copyWith(claimedSetBonuses: Set<String>.unmodifiable(claimed));
    return Collection2ApplyResult(
      state: nextState,
      unlockedCount: unlockedCount,
      levelUpCount: levelUpCount,
      overflowReputation: overflowReputation,
      prestigePoints: prestigePoints,
      claimedSetBonusCount: claimedSetBonusCount,
    );
  }

  static int _overflowReputation(Rarity rarity, int overflowShards) {
    if (overflowShards <= 0) {
      return 0;
    }
    final value = switch (rarity) {
      Rarity.common => 1,
      Rarity.rare => 2,
      Rarity.epic => 4,
      Rarity.legendary => 8,
      Rarity.mythic => 15,
    };
    return overflowShards * value;
  }

  static T _pickByRarity<T>(
    List<T> items,
    Rarity? rarity,
    math.Random? random,
  ) {
    Rarity itemRarity(T item) {
      return switch (item) {
        CustomerCard(:final rarity) => rarity,
        MasterCard(:final rarity) => rarity,
        DecorItem(:final rarity) => rarity,
        MomentCard(:final rarity) => rarity,
        _ => Rarity.common,
      };
    }

    final eligible = rarity == null
        ? items
        : items.where((item) => itemRarity(item) == rarity).toList();
    final pool = eligible.isEmpty ? items : eligible;
    if (pool.length == 1) {
      return pool.first;
    }
    final index = (random ?? math.Random()).nextInt(pool.length);
    return pool[index];
  }
}
