import 'dart:math' as math;

import 'package:taptapdoner/domain/progression/faz5_models.dart';

enum OrderObjectiveType {
  tapCount,
  earnMoney,
  reachCombo,
  triggerCritical,
  waitPassiveSeconds,
  buyUpgrade,
  openChest,
}

enum OrderRewardType {
  money,
  reputation,
  tip,
  chest,
  temporaryBoost,
  recipeShard,
  staffCardShard,
  decorShard,
  knifeSkinShard,
}

enum OrderRarity { common, rare, epic, legendary }

class OrderReward {
  const OrderReward({
    required this.type,
    required this.amount,
    this.chestType,
    this.durationSeconds,
    this.itemId,
  }) : assert(amount >= 0, 'amount cannot be negative.');

  final OrderRewardType type;
  final double amount;
  final ChestType? chestType;
  final int? durationSeconds;
  final String? itemId;

  OrderReward copyWith({
    OrderRewardType? type,
    double? amount,
    ChestType? chestType,
    int? durationSeconds,
    String? itemId,
  }) {
    return OrderReward(
      type: type ?? this.type,
      amount: math.max(0, amount ?? this.amount),
      chestType: chestType ?? this.chestType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      itemId: itemId ?? this.itemId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': orderRewardTypeKey(type),
      'amount': amount,
      'chestType': chestType == null ? null : chestTypeKey(chestType!),
      'durationSeconds': durationSeconds,
      'itemId': itemId,
    };
  }

  factory OrderReward.fromJson(Map<String, dynamic>? json) {
    return OrderReward(
      type: orderRewardTypeFromKey(_stringValue(json?['type'])),
      amount: _nonNegativeDouble(json?['amount']),
      chestType: chestTypeFromKey(_stringValue(json?['chestType'])),
      durationSeconds: _nullableIntValue(json?['durationSeconds']),
      itemId: _nullableStringValue(json?['itemId']),
    );
  }
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.customerTypeId,
    required this.customerName,
    required this.title,
    required this.description,
    required this.objectiveType,
    required this.targetValue,
    this.currentValue = 0,
    required this.durationSeconds,
    required this.remainingSeconds,
    required this.rewards,
    required this.rarity,
    required this.minShopLevel,
    this.minReputationLevel = 1,
    this.minPrestigeCount = 0,
    this.rewardClaimed = false,
  }) : assert(targetValue > 0, 'targetValue must be positive.'),
       assert(durationSeconds > 0, 'durationSeconds must be positive.'),
       assert(remainingSeconds >= 0, 'remainingSeconds cannot be negative.');

  final String id;
  final String customerTypeId;
  final String customerName;
  final String title;
  final String description;
  final OrderObjectiveType objectiveType;
  final double targetValue;
  final double currentValue;
  final int durationSeconds;
  final double remainingSeconds;
  final List<OrderReward> rewards;
  final OrderRarity rarity;
  final int minShopLevel;
  final int minReputationLevel;
  final int minPrestigeCount;
  final bool rewardClaimed;

  bool get isComplete => currentValue >= targetValue;

  double get progress {
    return targetValue <= 0
        ? 0
        : (currentValue / targetValue).clamp(0, 1).toDouble();
  }

  CustomerOrder copyWith({
    String? id,
    String? customerTypeId,
    String? customerName,
    String? title,
    String? description,
    OrderObjectiveType? objectiveType,
    double? targetValue,
    double? currentValue,
    int? durationSeconds,
    double? remainingSeconds,
    List<OrderReward>? rewards,
    OrderRarity? rarity,
    int? minShopLevel,
    int? minReputationLevel,
    int? minPrestigeCount,
    bool? rewardClaimed,
  }) {
    return CustomerOrder(
      id: id ?? this.id,
      customerTypeId: customerTypeId ?? this.customerTypeId,
      customerName: customerName ?? this.customerName,
      title: title ?? this.title,
      description: description ?? this.description,
      objectiveType: objectiveType ?? this.objectiveType,
      targetValue: math.max(1, targetValue ?? this.targetValue),
      currentValue: math.max(0, currentValue ?? this.currentValue),
      durationSeconds: math.max(1, durationSeconds ?? this.durationSeconds),
      remainingSeconds: math.max(0, remainingSeconds ?? this.remainingSeconds),
      rewards: rewards ?? this.rewards,
      rarity: rarity ?? this.rarity,
      minShopLevel: math.max(1, minShopLevel ?? this.minShopLevel),
      minReputationLevel: math.max(
        1,
        minReputationLevel ?? this.minReputationLevel,
      ),
      minPrestigeCount: math.max(0, minPrestigeCount ?? this.minPrestigeCount),
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerTypeId': customerTypeId,
      'customerName': customerName,
      'title': title,
      'description': description,
      'objectiveType': orderObjectiveTypeKey(objectiveType),
      'targetValue': targetValue,
      'currentValue': currentValue,
      'durationSeconds': durationSeconds,
      'remainingSeconds': remainingSeconds,
      'rewards': rewards.map((reward) => reward.toJson()).toList(),
      'rarity': orderRarityKey(rarity),
      'minShopLevel': minShopLevel,
      'minReputationLevel': minReputationLevel,
      'minPrestigeCount': minPrestigeCount,
      'rewardClaimed': rewardClaimed,
    };
  }

  factory CustomerOrder.fromJson(Map<String, dynamic>? json) {
    final duration = math.max(
      1,
      _intValue(json?['durationSeconds'], fallback: 1),
    );
    return CustomerOrder(
      id: _stringValue(json?['id']),
      customerTypeId: _stringValue(
        json?['customerTypeId'],
        fallback: CustomerOrderCatalog.regularCustomer,
      ),
      customerName: _stringValue(json?['customerName'], fallback: 'Customer'),
      title: _stringValue(json?['title'], fallback: 'Customer Order'),
      description: _stringValue(json?['description'], fallback: 'Complete it.'),
      objectiveType: orderObjectiveTypeFromKey(
        _stringValue(json?['objectiveType']),
      ),
      targetValue: math.max(1, _nonNegativeDouble(json?['targetValue'])),
      currentValue: _nonNegativeDouble(json?['currentValue']),
      durationSeconds: duration,
      remainingSeconds: _nonNegativeDouble(
        json?['remainingSeconds'],
        fallback: duration.toDouble(),
      ),
      rewards: _rewardList(json?['rewards']),
      rarity: orderRarityFromKey(_stringValue(json?['rarity'])),
      minShopLevel: math.max(1, _intValue(json?['minShopLevel'], fallback: 1)),
      minReputationLevel: math.max(
        1,
        _intValue(json?['minReputationLevel'], fallback: 1),
      ),
      minPrestigeCount: math.max(0, _intValue(json?['minPrestigeCount'])),
      rewardClaimed: _boolValue(json?['rewardClaimed']),
    );
  }
}

class CustomerSystemState {
  const CustomerSystemState({
    this.activeOrder,
    this.completedOrderIds = const <String>{},
    this.failedOrderCount = 0,
    this.completedOrderCount = 0,
    this.completedByType = const <String, int>{},
    this.lastSpawnTimeMillis = 0,
    this.nextSpawnTimeMillis = 0,
    this.spawnRemainingSeconds = 240,
    this.unlockedCustomerTypeIds = const <String>{
      CustomerOrderCatalog.regularCustomer,
    },
  }) : assert(failedOrderCount >= 0, 'failedOrderCount cannot be negative.'),
       assert(
         completedOrderCount >= 0,
         'completedOrderCount cannot be negative.',
       ),
       assert(
         spawnRemainingSeconds >= 0,
         'spawnRemainingSeconds cannot be negative.',
       );

  factory CustomerSystemState.initial({required DateTime nowUtc}) {
    const firstSpawnSeconds = 240.0;
    return CustomerSystemState(
      nextSpawnTimeMillis: nowUtc
          .add(Duration(seconds: firstSpawnSeconds.round()))
          .millisecondsSinceEpoch,
      spawnRemainingSeconds: firstSpawnSeconds,
    );
  }

  final CustomerOrder? activeOrder;
  final Set<String> completedOrderIds;
  final int failedOrderCount;
  final int completedOrderCount;
  final Map<String, int> completedByType;
  final int lastSpawnTimeMillis;
  final int nextSpawnTimeMillis;
  final double spawnRemainingSeconds;
  final Set<String> unlockedCustomerTypeIds;

  CustomerSystemState copyWith({
    CustomerOrder? activeOrder,
    bool clearActiveOrder = false,
    Set<String>? completedOrderIds,
    int? failedOrderCount,
    int? completedOrderCount,
    Map<String, int>? completedByType,
    int? lastSpawnTimeMillis,
    int? nextSpawnTimeMillis,
    double? spawnRemainingSeconds,
    Set<String>? unlockedCustomerTypeIds,
  }) {
    return CustomerSystemState(
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      completedOrderIds: completedOrderIds ?? this.completedOrderIds,
      failedOrderCount: math.max(0, failedOrderCount ?? this.failedOrderCount),
      completedOrderCount: math.max(
        0,
        completedOrderCount ?? this.completedOrderCount,
      ),
      completedByType: completedByType ?? this.completedByType,
      lastSpawnTimeMillis: math.max(
        0,
        lastSpawnTimeMillis ?? this.lastSpawnTimeMillis,
      ),
      nextSpawnTimeMillis: math.max(
        0,
        nextSpawnTimeMillis ?? this.nextSpawnTimeMillis,
      ),
      spawnRemainingSeconds: math.max(
        0,
        spawnRemainingSeconds ?? this.spawnRemainingSeconds,
      ),
      unlockedCustomerTypeIds:
          unlockedCustomerTypeIds ?? this.unlockedCustomerTypeIds,
    );
  }

  CustomerSystemState resetForPrestige(DateTime nowUtc) {
    const resetSpawnSeconds = 240.0;
    return copyWith(
      clearActiveOrder: true,
      nextSpawnTimeMillis: nowUtc
          .add(Duration(seconds: resetSpawnSeconds.round()))
          .millisecondsSinceEpoch,
      spawnRemainingSeconds: resetSpawnSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeOrder': activeOrder?.toJson(),
      'completedOrderIds': _sortedStrings(completedOrderIds),
      'failedOrderCount': failedOrderCount,
      'completedOrderCount': completedOrderCount,
      'completedByType': completedByType,
      'lastSpawnTimeMillis': lastSpawnTimeMillis,
      'nextSpawnTimeMillis': nextSpawnTimeMillis,
      'spawnRemainingSeconds': spawnRemainingSeconds,
      'unlockedCustomerTypes': _sortedStrings(unlockedCustomerTypeIds),
    };
  }

  factory CustomerSystemState.fromJson(Map<String, dynamic>? json) {
    final activeJson = _stringKeyMap(json?['activeOrder']);
    final completedByType = _intMap(json?['completedByType']);
    final unlocked = _stringSet(json?['unlockedCustomerTypes']);
    return CustomerSystemState(
      activeOrder: activeJson == null
          ? null
          : CustomerOrder.fromJson(activeJson),
      completedOrderIds: _stringSet(json?['completedOrderIds']),
      failedOrderCount: math.max(0, _intValue(json?['failedOrderCount'])),
      completedOrderCount: math.max(0, _intValue(json?['completedOrderCount'])),
      completedByType: completedByType,
      lastSpawnTimeMillis: math.max(0, _intValue(json?['lastSpawnTimeMillis'])),
      nextSpawnTimeMillis: math.max(0, _intValue(json?['nextSpawnTimeMillis'])),
      spawnRemainingSeconds: _nonNegativeDouble(
        json?['spawnRemainingSeconds'],
        fallback: 240,
      ),
      unlockedCustomerTypeIds: unlocked.isEmpty
          ? const <String>{CustomerOrderCatalog.regularCustomer}
          : unlocked,
    );
  }
}

class CustomerReputationState {
  const CustomerReputationState({
    this.totalReputation = 0,
    this.currentLevel = 1,
    this.reputationInCurrentLevel = 0,
  }) : assert(totalReputation >= 0, 'totalReputation cannot be negative.'),
       assert(currentLevel >= 1, 'currentLevel must be at least 1.'),
       assert(
         reputationInCurrentLevel >= 0,
         'reputationInCurrentLevel cannot be negative.',
       );

  factory CustomerReputationState.fromTotal(int totalReputation) {
    var remaining = math.max(0, totalReputation);
    var level = 1;
    while (remaining >= requiredReputationForLevel(level)) {
      remaining -= requiredReputationForLevel(level);
      level += 1;
    }
    return CustomerReputationState(
      totalReputation: math.max(0, totalReputation),
      currentLevel: level,
      reputationInCurrentLevel: remaining,
    );
  }

  final int totalReputation;
  final int currentLevel;
  final int reputationInCurrentLevel;

  int get requiredForNextLevel => requiredReputationForLevel(currentLevel);

  CustomerReputationState add(int amount) {
    if (amount <= 0) {
      return this;
    }
    return CustomerReputationState.fromTotal(totalReputation + amount);
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReputation': totalReputation,
      'currentLevel': currentLevel,
      'reputationInCurrentLevel': reputationInCurrentLevel,
    };
  }

  factory CustomerReputationState.fromJson(Map<String, dynamic>? json) {
    return CustomerReputationState.fromTotal(
      math.max(0, _intValue(json?['totalReputation'])),
    );
  }

  static int requiredReputationForLevel(int level) {
    return math.max(1, (50 * math.pow(math.max(1, level), 1.5)).floor());
  }
}

int requiredReputationForLevel(int level) {
  return CustomerReputationState.requiredReputationForLevel(level);
}

class CustomerTypeDefinition {
  const CustomerTypeDefinition({
    required this.id,
    required this.nameEn,
    required this.nameTr,
    required this.behavior,
    required this.primaryReward,
    required this.minReputationLevel,
    this.minShopLevel = 1,
    this.minPrestigeCount = 0,
  });

  final String id;
  final String nameEn;
  final String nameTr;
  final String behavior;
  final String primaryReward;
  final int minReputationLevel;
  final int minShopLevel;
  final int minPrestigeCount;

  String nameForLocale(String localeCode) {
    return localeCode == 'tr' ? nameTr : nameEn;
  }
}

class OrderRewardSpec {
  const OrderRewardSpec({
    required this.type,
    this.amount = 0,
    this.passiveIncomeSeconds = 0,
    this.chestType,
    this.durationSeconds,
    this.itemId,
  });

  final OrderRewardType type;
  final double amount;
  final double passiveIncomeSeconds;
  final ChestType? chestType;
  final int? durationSeconds;
  final String? itemId;

  OrderReward toReward({
    required double passiveIncomePerSecond,
    required num tapValue,
    required int reputationLevel,
    required double milestoneTipValuePercent,
    required double collectionCustomerRewardPercent,
    required double collectionTipValuePercent,
    required double collectionTipChancePercent,
    required double collectionReputationGainPercent,
  }) {
    var rewardAmount = amount;
    if (passiveIncomeSeconds > 0) {
      rewardAmount = math.max(
        tapValue * passiveIncomeSeconds / 2,
        passiveIncomePerSecond * passiveIncomeSeconds,
      );
    }
    if (type == OrderRewardType.money || type == OrderRewardType.tip) {
      final rewardBonus = 1 + math.max(0, reputationLevel - 1) * 0.01;
      final tipBonus = type == OrderRewardType.tip
          ? 1 +
                math.max(0, reputationLevel - 1) * 0.02 +
                math.max(0, milestoneTipValuePercent) +
                math.max(0, collectionTipValuePercent) +
                math.max(0, collectionTipChancePercent)
          : 1.0;
      rewardAmount = math
          .max(
            1,
            rewardAmount *
                rewardBonus *
                tipBonus *
                (1 + math.max(0, collectionCustomerRewardPercent)),
          )
          .roundToDouble();
    }
    if (type == OrderRewardType.reputation) {
      rewardAmount = math
          .max(
            1,
            rewardAmount * (1 + math.max(0, collectionReputationGainPercent)),
          )
          .roundToDouble();
    }
    return OrderReward(
      type: type,
      amount: rewardAmount,
      chestType: chestType,
      durationSeconds: durationSeconds,
      itemId: itemId,
    );
  }
}

class CustomerOrderTemplate {
  const CustomerOrderTemplate({
    required this.id,
    required this.customerTypeId,
    required this.titleEn,
    required this.titleTr,
    required this.descriptionEn,
    required this.descriptionTr,
    required this.objectiveType,
    required this.targetValue,
    required this.durationSeconds,
    required this.rewards,
    required this.rarity,
    required this.weight,
    this.minShopLevel = 1,
    this.minReputationLevel = 1,
    this.minPrestigeCount = 0,
    this.requiredFeatureKeys = const <String>{},
  }) : assert(targetValue > 0, 'targetValue must be positive.'),
       assert(durationSeconds > 0, 'durationSeconds must be positive.'),
       assert(weight > 0, 'weight must be positive.');

  final String id;
  final String customerTypeId;
  final String titleEn;
  final String titleTr;
  final String descriptionEn;
  final String descriptionTr;
  final OrderObjectiveType objectiveType;
  final double targetValue;
  final int durationSeconds;
  final List<OrderRewardSpec> rewards;
  final OrderRarity rarity;
  final double weight;
  final int minShopLevel;
  final int minReputationLevel;
  final int minPrestigeCount;
  final Set<String> requiredFeatureKeys;

  CustomerOrder createOrder({
    required String instanceId,
    required String localeCode,
    required double passiveIncomePerSecond,
    required num tapValue,
    required int reputationLevel,
    required double milestoneTipValuePercent,
    required double collectionCustomerRewardPercent,
    required double collectionTipValuePercent,
    required double collectionTipChancePercent,
    required double collectionReputationGainPercent,
    required double collectionOrderDurationBonusPercent,
  }) {
    final adjustedDurationSeconds = math.max(
      1,
      (durationSeconds * (1 + math.max(0, collectionOrderDurationBonusPercent)))
          .round(),
    );
    final type = CustomerOrderCatalog.customerTypeById(customerTypeId);
    return CustomerOrder(
      id: instanceId,
      customerTypeId: customerTypeId,
      customerName: type.nameForLocale(localeCode),
      title: localeCode == 'tr' ? titleTr : titleEn,
      description: localeCode == 'tr' ? descriptionTr : descriptionEn,
      objectiveType: objectiveType,
      targetValue: targetValue,
      durationSeconds: adjustedDurationSeconds,
      remainingSeconds: adjustedDurationSeconds.toDouble(),
      rewards: rewards
          .map(
            (reward) => reward.toReward(
              passiveIncomePerSecond: passiveIncomePerSecond,
              tapValue: tapValue,
              reputationLevel: reputationLevel,
              milestoneTipValuePercent: milestoneTipValuePercent,
              collectionCustomerRewardPercent: collectionCustomerRewardPercent,
              collectionTipValuePercent: collectionTipValuePercent,
              collectionTipChancePercent: collectionTipChancePercent,
              collectionReputationGainPercent: collectionReputationGainPercent,
            ),
          )
          .toList(growable: false),
      rarity: rarity,
      minShopLevel: minShopLevel,
      minReputationLevel: minReputationLevel,
      minPrestigeCount: minPrestigeCount,
    );
  }
}

abstract final class CustomerOrderCatalog {
  static const regularCustomer = 'regular_customer';
  static const hurryCustomer = 'hurry_customer';
  static const generousCustomer = 'generous_customer';
  static const comboCustomer = 'combo_customer';
  static const criticalCustomer = 'critical_customer';
  static const vipCustomer = 'vip_customer';
  static const influencerCustomer = 'influencer_customer';
  static const nightCustomer = 'night_customer';
  static const touristCustomer = 'tourist_customer';

  static const customerTypes = <CustomerTypeDefinition>[
    CustomerTypeDefinition(
      id: regularCustomer,
      nameEn: 'Regular Customer',
      nameTr: 'Normal Müşteri',
      behavior: 'Simple short order',
      primaryReward: 'Money',
      minReputationLevel: 1,
    ),
    CustomerTypeDefinition(
      id: hurryCustomer,
      nameEn: 'Hurry Customer',
      nameTr: 'Aceleci Müşteri',
      behavior: 'Short tap target',
      primaryReward: 'Tip',
      minReputationLevel: 2,
    ),
    CustomerTypeDefinition(
      id: generousCustomer,
      nameEn: 'Generous Customer',
      nameTr: 'Cömert Müşteri',
      behavior: 'Higher tip reward',
      primaryReward: 'Tip + reputation',
      minReputationLevel: 2,
    ),
    CustomerTypeDefinition(
      id: comboCustomer,
      nameEn: 'Combo Fan',
      nameTr: 'Kombo Seven Müşteri',
      behavior: 'Requests combo target',
      primaryReward: 'Money + boost',
      minReputationLevel: 3,
    ),
    CustomerTypeDefinition(
      id: criticalCustomer,
      nameEn: 'Critical Fan',
      nameTr: 'Kritik Seven Müşteri',
      behavior: 'Requests critical cuts',
      primaryReward: 'Money + reputation',
      minReputationLevel: 4,
    ),
    CustomerTypeDefinition(
      id: vipCustomer,
      nameEn: 'VIP Customer',
      nameTr: 'VIP Müşteri',
      behavior: 'Hard order with large reward',
      primaryReward: 'Chest + reputation',
      minReputationLevel: 5,
      minShopLevel: 2,
    ),
    CustomerTypeDefinition(
      id: nightCustomer,
      nameEn: 'Night Customer',
      nameTr: 'Gece Müşterisi',
      behavior: 'Active passive-income order',
      primaryReward: 'Offline-style bonus',
      minReputationLevel: 6,
      minShopLevel: 2,
    ),
    CustomerTypeDefinition(
      id: touristCustomer,
      nameEn: 'Tourist Customer',
      nameTr: 'Turist Müşteri',
      behavior: 'Menu and recipe linked order',
      primaryReward: 'Recipe chance',
      minReputationLevel: 8,
      minShopLevel: 3,
    ),
    CustomerTypeDefinition(
      id: influencerCustomer,
      nameEn: 'Influencer Customer',
      nameTr: 'Fenomen Müşteri',
      behavior: 'Reputation-heavy order',
      primaryReward: 'Reputation',
      minReputationLevel: 10,
      minShopLevel: 3,
    ),
  ];

  static const templates = <CustomerOrderTemplate>[
    CustomerOrderTemplate(
      id: 'regular_cut_15',
      customerTypeId: regularCustomer,
      titleEn: 'Simple Doner Order',
      titleTr: 'Basit Döner Siparişi',
      descriptionEn: 'Cut 15 doners.',
      descriptionTr: '15 döner kes.',
      objectiveType: OrderObjectiveType.tapCount,
      targetValue: 15,
      durationSeconds: 20,
      rarity: OrderRarity.common,
      weight: 8,
      rewards: [
        OrderRewardSpec(type: OrderRewardType.money, passiveIncomeSeconds: 30),
        OrderRewardSpec(type: OrderRewardType.reputation, amount: 1),
      ],
    ),
    CustomerOrderTemplate(
      id: 'hurry_cut_25',
      customerTypeId: hurryCustomer,
      titleEn: 'Quick Order',
      titleTr: 'Acele Sipariş',
      descriptionEn: 'Cut 25 doners in 10 seconds.',
      descriptionTr: '10 saniye içinde 25 döner kes.',
      objectiveType: OrderObjectiveType.tapCount,
      targetValue: 25,
      durationSeconds: 10,
      minReputationLevel: 2,
      rarity: OrderRarity.rare,
      weight: 4,
      rewards: [
        OrderRewardSpec(type: OrderRewardType.tip, passiveIncomeSeconds: 60),
        OrderRewardSpec(type: OrderRewardType.reputation, amount: 3),
      ],
    ),
    CustomerOrderTemplate(
      id: 'generous_cash_150',
      customerTypeId: generousCustomer,
      titleEn: 'Full Tray Order',
      titleTr: 'Dolu Tepsi Siparişi',
      descriptionEn: 'Earn cash for this customer.',
      descriptionTr: 'Bu müşteri için para kazan.',
      objectiveType: OrderObjectiveType.earnMoney,
      targetValue: 150,
      durationSeconds: 25,
      minReputationLevel: 2,
      rarity: OrderRarity.rare,
      weight: 3,
      rewards: [
        OrderRewardSpec(type: OrderRewardType.tip, passiveIncomeSeconds: 75),
        OrderRewardSpec(type: OrderRewardType.reputation, amount: 3),
      ],
    ),
    CustomerOrderTemplate(
      id: 'combo_reach_20',
      customerTypeId: comboCustomer,
      titleEn: 'Serial Cuts',
      titleTr: 'Seri Kesim İstiyor',
      descriptionEn: 'Reach a 20 combo.',
      descriptionTr: "20 combo'ya ulas.",
      objectiveType: OrderObjectiveType.reachCombo,
      targetValue: 20,
      durationSeconds: 20,
      minReputationLevel: 3,
      requiredFeatureKeys: {'combo'},
      rarity: OrderRarity.rare,
      weight: 2.6,
      rewards: [
        OrderRewardSpec(type: OrderRewardType.money, passiveIncomeSeconds: 90),
        OrderRewardSpec(type: OrderRewardType.reputation, amount: 5),
        OrderRewardSpec(
          type: OrderRewardType.temporaryBoost,
          amount: 2,
          durationSeconds: 30,
        ),
      ],
    ),
    CustomerOrderTemplate(
      id: 'critical_cut_2',
      customerTypeId: criticalCustomer,
      titleEn: 'Flashy Cuts',
      titleTr: 'Gösterişli Kesim',
      descriptionEn: 'Make 2 critical cuts.',
      descriptionTr: '2 kritik kesim yap.',
      objectiveType: OrderObjectiveType.triggerCritical,
      targetValue: 2,
      durationSeconds: 30,
      minReputationLevel: 4,
      requiredFeatureKeys: {'critical_cut'},
      rarity: OrderRarity.epic,
      weight: 1.8,
      rewards: [
        OrderRewardSpec(type: OrderRewardType.money, passiveIncomeSeconds: 120),
        OrderRewardSpec(type: OrderRewardType.reputation, amount: 6),
      ],
    ),
    CustomerOrderTemplate(
      id: 'vip_cut_50',
      customerTypeId: vipCustomer,
      titleEn: 'VIP Order',
      titleTr: 'VIP Sipariş',
      descriptionEn: 'Cut 50 doners in 30 seconds.',
      descriptionTr: '30 saniye içinde 50 döner kes.',
      objectiveType: OrderObjectiveType.tapCount,
      targetValue: 50,
      durationSeconds: 30,
      minShopLevel: 2,
      minReputationLevel: 5,
      rarity: OrderRarity.epic,
      weight: 0.55,
      rewards: [
        OrderRewardSpec(
          type: OrderRewardType.chest,
          amount: 1,
          chestType: ChestType.master,
        ),
        OrderRewardSpec(type: OrderRewardType.reputation, amount: 15),
      ],
    ),
    CustomerOrderTemplate(
      id: 'night_wait_45',
      customerTypeId: nightCustomer,
      titleEn: 'Late Counter',
      titleTr: 'Gece Tezgâhı',
      descriptionEn: 'Keep passive income running for 45 seconds.',
      descriptionTr: '45 saniye aktif pasif gelir kazan.',
      objectiveType: OrderObjectiveType.waitPassiveSeconds,
      targetValue: 45,
      durationSeconds: 70,
      minShopLevel: 2,
      minReputationLevel: 6,
      rarity: OrderRarity.rare,
      weight: 1.4,
      rewards: [
        OrderRewardSpec(type: OrderRewardType.money, passiveIncomeSeconds: 150),
        OrderRewardSpec(type: OrderRewardType.reputation, amount: 4),
      ],
    ),
    CustomerOrderTemplate(
      id: 'influencer_cut_40',
      customerTypeId: influencerCustomer,
      titleEn: 'Viral Plate',
      titleTr: 'Viral Tabak',
      descriptionEn: 'Cut 40 doners before the clip ends.',
      descriptionTr: 'Video bitmeden 40 döner kes.',
      objectiveType: OrderObjectiveType.tapCount,
      targetValue: 40,
      durationSeconds: 25,
      minShopLevel: 3,
      minReputationLevel: 10,
      rarity: OrderRarity.legendary,
      weight: 0.45,
      rewards: [
        OrderRewardSpec(type: OrderRewardType.tip, passiveIncomeSeconds: 160),
        OrderRewardSpec(type: OrderRewardType.reputation, amount: 12),
      ],
    ),
  ];

  static CustomerTypeDefinition customerTypeById(String id) {
    for (final type in customerTypes) {
      if (type.id == id) {
        return type;
      }
    }
    return customerTypes.first;
  }

  static Set<String> unlockedTypeIdsForLevel(
    int reputationLevel, {
    Set<String> existing = const <String>{},
  }) {
    final unlocked = Set<String>.from(existing)
      ..add(CustomerOrderCatalog.regularCustomer);
    for (final type in customerTypes) {
      if (type.minReputationLevel <= reputationLevel) {
        unlocked.add(type.id);
      }
    }
    return Set<String>.unmodifiable(unlocked);
  }
}

String orderObjectiveTypeKey(OrderObjectiveType type) {
  return switch (type) {
    OrderObjectiveType.tapCount => 'tap_count',
    OrderObjectiveType.earnMoney => 'earn_money',
    OrderObjectiveType.reachCombo => 'reach_combo',
    OrderObjectiveType.triggerCritical => 'trigger_critical',
    OrderObjectiveType.waitPassiveSeconds => 'wait_passive_seconds',
    OrderObjectiveType.buyUpgrade => 'buy_upgrade',
    OrderObjectiveType.openChest => 'open_chest',
  };
}

OrderObjectiveType orderObjectiveTypeFromKey(String key) {
  return switch (key) {
    'earn_money' => OrderObjectiveType.earnMoney,
    'reach_combo' => OrderObjectiveType.reachCombo,
    'trigger_critical' => OrderObjectiveType.triggerCritical,
    'wait_passive_seconds' => OrderObjectiveType.waitPassiveSeconds,
    'buy_upgrade' => OrderObjectiveType.buyUpgrade,
    'open_chest' => OrderObjectiveType.openChest,
    _ => OrderObjectiveType.tapCount,
  };
}

String orderRewardTypeKey(OrderRewardType type) {
  return switch (type) {
    OrderRewardType.money => 'money',
    OrderRewardType.reputation => 'reputation',
    OrderRewardType.tip => 'tip',
    OrderRewardType.chest => 'chest',
    OrderRewardType.temporaryBoost => 'temporary_boost',
    OrderRewardType.recipeShard => 'recipe_shard',
    OrderRewardType.staffCardShard => 'staff_card_shard',
    OrderRewardType.decorShard => 'decor_shard',
    OrderRewardType.knifeSkinShard => 'knife_skin_shard',
  };
}

OrderRewardType orderRewardTypeFromKey(String key) {
  return switch (key) {
    'reputation' => OrderRewardType.reputation,
    'tip' => OrderRewardType.tip,
    'chest' => OrderRewardType.chest,
    'temporary_boost' => OrderRewardType.temporaryBoost,
    'recipe_shard' => OrderRewardType.recipeShard,
    'staff_card_shard' => OrderRewardType.staffCardShard,
    'decor_shard' => OrderRewardType.decorShard,
    'knife_skin_shard' => OrderRewardType.knifeSkinShard,
    _ => OrderRewardType.money,
  };
}

String orderRarityKey(OrderRarity rarity) {
  return switch (rarity) {
    OrderRarity.common => 'common',
    OrderRarity.rare => 'rare',
    OrderRarity.epic => 'epic',
    OrderRarity.legendary => 'legendary',
  };
}

OrderRarity orderRarityFromKey(String key) {
  return switch (key) {
    'rare' => OrderRarity.rare,
    'epic' => OrderRarity.epic,
    'legendary' => OrderRarity.legendary,
    _ => OrderRarity.common,
  };
}

Map<String, dynamic>? _stringKeyMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<OrderReward> _rewardList(Object? value) {
  if (value is! List) {
    return const <OrderReward>[];
  }
  return value
      .map(_stringKeyMap)
      .whereType<Map<String, dynamic>>()
      .map(OrderReward.fromJson)
      .toList(growable: false);
}

String _stringValue(Object? value, {String fallback = ''}) {
  return value is String ? value : fallback;
}

String? _nullableStringValue(Object? value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  return null;
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

double _nonNegativeDouble(Object? value, {double fallback = 0}) {
  return math.max(0, _doubleValue(value, fallback: fallback));
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
