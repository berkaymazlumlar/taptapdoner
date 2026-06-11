import 'package:taptapdoner/domain/progression/faz5_models.dart';

enum QuestStatus { locked, active, completed, claimed }

enum StarterQuestGoalType {
  tapCount,
  totalUpgradesPurchased,
  rustyKnifeLevel,
  lifetimeCash,
  knifeLevel,
  criticalCutCount,
  staffPurchased,
  passiveIncomeActiveSeconds,
  maxCombo,
  turboUsedCount,
  goldenDonerCollected,
  knifeItemIndex,
  shopLevel,
  openPrestigeScreenOnce,
}

class QuestProgress {
  const QuestProgress({
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

  QuestProgress copyWith({
    QuestStatus? status,
    double? currentValue,
    double? targetValue,
    bool? rewardClaimed,
  }) {
    return QuestProgress(
      questId: questId,
      status: status ?? this.status,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questId': questId,
      'status': status.name,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'rewardClaimed': rewardClaimed,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is QuestProgress &&
        questId == other.questId &&
        status == other.status &&
        currentValue == other.currentValue &&
        targetValue == other.targetValue &&
        rewardClaimed == other.rewardClaimed;
  }

  @override
  int get hashCode =>
      Object.hash(questId, status, currentValue, targetValue, rewardClaimed);

  factory QuestProgress.fromJson(
    Map<String, dynamic> json, {
    required QuestProgress fallback,
  }) {
    return QuestProgress(
      questId: _stringValue(json['questId'], fallback: fallback.questId),
      status: _questStatusValue(json['status'], fallback: fallback.status),
      currentValue: _doubleValue(
        json['currentValue'],
        fallback: fallback.currentValue,
      ),
      targetValue: _doubleValue(
        json['targetValue'],
        fallback: fallback.targetValue,
      ),
      rewardClaimed: _boolValue(
        json['rewardClaimed'],
        fallback: fallback.rewardClaimed,
      ),
    );
  }
}

class StarterQuestReward {
  const StarterQuestReward({
    this.cash = 0,
    this.chests = 0,
    this.chestType = ChestType.small,
    this.featureKey,
    this.passiveBoostDuration = Duration.zero,
    this.comboMultiplierBonus = 0,
    this.turboChargeSpeedPercent = 0,
    this.globalBonusPercent = 0,
    this.shopLevel = 0,
  }) : assert(cash >= 0, 'cash cannot be negative.'),
       assert(chests >= 0, 'chests cannot be negative.'),
       assert(shopLevel >= 0, 'shopLevel cannot be negative.');

  final int cash;
  final int chests;
  final ChestType chestType;
  final String? featureKey;
  final Duration passiveBoostDuration;
  final double comboMultiplierBonus;
  final double turboChargeSpeedPercent;
  final double globalBonusPercent;
  final int shopLevel;
}

class StarterQuestDefinition {
  const StarterQuestDefinition({
    required this.id,
    required this.goalType,
    required this.targetValue,
    required this.reward,
  }) : assert(targetValue > 0, 'targetValue must be positive.');

  final String id;
  final StarterQuestGoalType goalType;
  final double targetValue;
  final StarterQuestReward reward;

  QuestProgress initialProgress({required bool active}) {
    return QuestProgress(
      questId: id,
      status: active ? QuestStatus.active : QuestStatus.locked,
      currentValue: 0,
      targetValue: targetValue,
      rewardClaimed: false,
    );
  }
}

abstract final class StarterQuestCatalog {
  static const definitions = <StarterQuestDefinition>[
    StarterQuestDefinition(
      id: 'starter_tap_10',
      goalType: StarterQuestGoalType.tapCount,
      targetValue: 10,
      reward: StarterQuestReward(cash: 50),
    ),
    StarterQuestDefinition(
      id: 'starter_first_upgrade',
      goalType: StarterQuestGoalType.totalUpgradesPurchased,
      targetValue: 1,
      reward: StarterQuestReward(cash: 25),
    ),
    StarterQuestDefinition(
      id: 'starter_rusty_knife_5',
      goalType: StarterQuestGoalType.rustyKnifeLevel,
      targetValue: 5,
      reward: StarterQuestReward(cash: 100),
    ),
    StarterQuestDefinition(
      id: 'starter_lifetime_500',
      goalType: StarterQuestGoalType.lifetimeCash,
      targetValue: 500,
      reward: StarterQuestReward(chests: 1),
    ),
    StarterQuestDefinition(
      id: 'starter_rusty_knife_10',
      goalType: StarterQuestGoalType.knifeLevel,
      targetValue: 10,
      reward: StarterQuestReward(featureKey: 'critical_cut'),
    ),
    StarterQuestDefinition(
      id: 'starter_critical_3',
      goalType: StarterQuestGoalType.criticalCutCount,
      targetValue: 3,
      reward: StarterQuestReward(cash: 150),
    ),
    StarterQuestDefinition(
      id: 'starter_first_staff',
      goalType: StarterQuestGoalType.staffPurchased,
      targetValue: 1,
      reward: StarterQuestReward(
        chests: 1,
        passiveBoostDuration: Duration(seconds: 60),
      ),
    ),
    StarterQuestDefinition(
      id: 'starter_passive_60',
      goalType: StarterQuestGoalType.passiveIncomeActiveSeconds,
      targetValue: 60,
      reward: StarterQuestReward(cash: 250),
    ),
    StarterQuestDefinition(
      id: 'starter_combo_15',
      goalType: StarterQuestGoalType.maxCombo,
      targetValue: 15,
      reward: StarterQuestReward(comboMultiplierBonus: 0.05),
    ),
    StarterQuestDefinition(
      id: 'starter_turbo_use',
      goalType: StarterQuestGoalType.turboUsedCount,
      targetValue: 1,
      reward: StarterQuestReward(turboChargeSpeedPercent: 1),
    ),
    StarterQuestDefinition(
      id: 'starter_golden_1',
      goalType: StarterQuestGoalType.goldenDonerCollected,
      targetValue: 1,
      reward: StarterQuestReward(chests: 1),
    ),
    StarterQuestDefinition(
      id: 'starter_knife_item_1',
      goalType: StarterQuestGoalType.knifeItemIndex,
      targetValue: 1,
      reward: StarterQuestReward(chests: 1, chestType: ChestType.master),
    ),
    StarterQuestDefinition(
      id: 'starter_shop_prepare',
      goalType: StarterQuestGoalType.lifetimeCash,
      targetValue: 10000,
      reward: StarterQuestReward(featureKey: 'shop_progression', shopLevel: 1),
    ),
    StarterQuestDefinition(
      id: 'starter_shop_level_2',
      goalType: StarterQuestGoalType.shopLevel,
      targetValue: 2,
      reward: StarterQuestReward(globalBonusPercent: 0.05),
    ),
    StarterQuestDefinition(
      id: 'starter_open_prestige',
      goalType: StarterQuestGoalType.openPrestigeScreenOnce,
      targetValue: 1,
      reward: StarterQuestReward(cash: 500),
    ),
  ];

  static final byId = Map<String, StarterQuestDefinition>.unmodifiable({
    for (final definition in definitions) definition.id: definition,
  });

  static Map<String, QuestProgress> initialProgress() {
    return Map<String, QuestProgress>.unmodifiable({
      for (var index = 0; index < definitions.length; index += 1)
        definitions[index].id: definitions[index].initialProgress(
          active: index == 0,
        ),
    });
  }
}

QuestStatus _questStatusValue(Object? value, {required QuestStatus fallback}) {
  if (value is String) {
    final normalized = value.toLowerCase();
    for (final status in QuestStatus.values) {
      if (status.name == normalized) {
        return status;
      }
    }
  }
  return fallback;
}

String _stringValue(Object? value, {required String fallback}) {
  return value is String && value.isNotEmpty ? value : fallback;
}

double _doubleValue(Object? value, {required double fallback}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool _boolValue(Object? value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return fallback;
}
