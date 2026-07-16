import 'dart:math' as math;

import 'package:taptapdoner/domain/progression/faz5_models.dart';

enum GoalCategory { starter, daily, weekly, prestigeRun, event, lifetime }

enum GoalObjectiveType {
  tapCount,
  earnMoney,
  buyUpgrades,
  completeCustomerOrders,
  completeSpecificCustomerType,
  openChests,
  triggerCritical,
  reachCombo,
  gainReputation,
  levelUpShop,
  completeMilestones,
  doPrestige,
  unlockCollectionItem,
  completeEvent,
  unlockBranches,
  upgradeBranchLevels,
  reachTotalBranchLevel,
  reachBranchMilestones,
  completeBranchRegions,
  assignBranchManager,
}

enum GoalRewardType {
  money,
  reputation,
  chest,
  temporaryBoost,
  recipeShard,
  staffCardShard,
  decorShard,
  knifeSkinShard,
  prestigePoint,
  prestigeShard,
}

enum GoalStatus { active, completed, expired }

class GoalReward {
  const GoalReward({
    required this.type,
    this.amount = 0,
    this.chestType,
    this.durationSeconds,
    this.itemId,
  }) : assert(amount >= 0, 'amount cannot be negative.');

  final GoalRewardType type;
  final double amount;
  final ChestType? chestType;
  final int? durationSeconds;
  final String? itemId;

  Map<String, dynamic> toJson() {
    return {
      'type': goalRewardTypeKey(type),
      'amount': amount,
      'chestType': chestType == null ? null : chestTypeKey(chestType!),
      'durationSeconds': durationSeconds,
      'itemId': itemId,
    };
  }

  factory GoalReward.fromJson(Map<String, dynamic>? json) {
    return GoalReward(
      type: goalRewardTypeFromKey(_stringValue(json?['type'])),
      amount: _nonNegativeDouble(json?['amount']),
      chestType: chestTypeFromKey(_stringValue(json?['chestType'])),
      durationSeconds: _nullableIntValue(json?['durationSeconds']),
      itemId: _nullableStringValue(json?['itemId']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GoalReward &&
        type == other.type &&
        amount == other.amount &&
        chestType == other.chestType &&
        durationSeconds == other.durationSeconds &&
        itemId == other.itemId;
  }

  @override
  int get hashCode =>
      Object.hash(type, amount, chestType, durationSeconds, itemId);
}

class GoalDefinition {
  const GoalDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.objectiveType,
    required this.targetValue,
    required this.rewards,
    this.weight = 1,
    this.minShopLevel = 1,
    this.minReputationLevel = 1,
    this.minPrestigeCount = 0,
    this.requiredFeatureKeys = const <String>{},
  }) : assert(targetValue > 0, 'targetValue must be positive.'),
       assert(weight > 0, 'weight must be positive.'),
       assert(minShopLevel >= 1, 'minShopLevel must be at least 1.'),
       assert(
         minReputationLevel >= 1,
         'minReputationLevel must be at least 1.',
       ),
       assert(minPrestigeCount >= 0, 'minPrestigeCount cannot be negative.');

  final String id;
  final String title;
  final String description;
  final GoalCategory category;
  final GoalObjectiveType objectiveType;
  final double targetValue;
  final List<GoalReward> rewards;
  final int weight;
  final int minShopLevel;
  final int minReputationLevel;
  final int minPrestigeCount;
  final Set<String> requiredFeatureKeys;
}

class GoalProgress {
  const GoalProgress({
    required this.goalId,
    this.currentValue = 0,
    required this.targetValue,
    this.status = GoalStatus.active,
    this.rewardClaimed = false,
    required this.generatedAtMillis,
    this.expiresAtMillis,
  }) : assert(currentValue >= 0, 'currentValue cannot be negative.'),
       assert(targetValue > 0, 'targetValue must be positive.'),
       assert(generatedAtMillis >= 0, 'generatedAtMillis cannot be negative.');

  final String goalId;
  final double currentValue;
  final double targetValue;
  final GoalStatus status;
  final bool rewardClaimed;
  final int generatedAtMillis;
  final int? expiresAtMillis;

  bool isExpiredAt(DateTime nowUtc) {
    final expiresAt = expiresAtMillis;
    return expiresAt != null && nowUtc.millisecondsSinceEpoch >= expiresAt;
  }

  bool canClaimAt(DateTime nowUtc) {
    return status == GoalStatus.completed &&
        !rewardClaimed &&
        !isExpiredAt(nowUtc);
  }

  double get progress {
    return targetValue <= 0
        ? 0
        : (currentValue / targetValue).clamp(0, 1).toDouble();
  }

  GoalProgress copyWith({
    double? currentValue,
    double? targetValue,
    GoalStatus? status,
    bool? rewardClaimed,
    int? generatedAtMillis,
    int? expiresAtMillis,
    bool clearExpiresAtMillis = false,
  }) {
    return GoalProgress(
      goalId: goalId,
      currentValue: math.max(0, currentValue ?? this.currentValue),
      targetValue: math.max(1, targetValue ?? this.targetValue),
      status: status ?? this.status,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
      generatedAtMillis: math.max(
        0,
        generatedAtMillis ?? this.generatedAtMillis,
      ),
      expiresAtMillis: clearExpiresAtMillis
          ? null
          : (expiresAtMillis ?? this.expiresAtMillis),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goalId': goalId,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'status': goalStatusKey(status),
      'rewardClaimed': rewardClaimed,
      'generatedAtMillis': generatedAtMillis,
      'expiresAtMillis': expiresAtMillis,
    };
  }

  factory GoalProgress.fromJson(Map<String, dynamic>? json) {
    return GoalProgress(
      goalId: _stringValue(json?['goalId']),
      currentValue: _nonNegativeDouble(json?['currentValue']),
      targetValue: math.max(1, _nonNegativeDouble(json?['targetValue'])),
      status: goalStatusFromKey(_stringValue(json?['status'])),
      rewardClaimed: _boolValue(json?['rewardClaimed']),
      generatedAtMillis: math.max(0, _intValue(json?['generatedAtMillis'])),
      expiresAtMillis: _nullableIntValue(json?['expiresAtMillis']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GoalProgress &&
        goalId == other.goalId &&
        currentValue == other.currentValue &&
        targetValue == other.targetValue &&
        status == other.status &&
        rewardClaimed == other.rewardClaimed &&
        generatedAtMillis == other.generatedAtMillis &&
        expiresAtMillis == other.expiresAtMillis;
  }

  @override
  int get hashCode => Object.hash(
    goalId,
    currentValue,
    targetValue,
    status,
    rewardClaimed,
    generatedAtMillis,
    expiresAtMillis,
  );
}

class GoalSystemState {
  const GoalSystemState({
    this.activeDailyGoals = const <GoalProgress>[],
    this.activeWeeklyGoals = const <GoalProgress>[],
    this.activePrestigeRunGoals = const <GoalProgress>[],
    this.activeEventGoals = const <GoalProgress>[],
    this.lastDailyResetDate = '',
    this.lastWeeklyResetWeek = '',
    this.runGoalPrestigeCount = 0,
  }) : assert(runGoalPrestigeCount >= 0, 'runGoalPrestigeCount is negative.');

  factory GoalSystemState.initial({required DateTime nowUtc}) {
    return GoalSystemState(
      lastDailyResetDate: goalLocalDateKey(nowUtc),
      lastWeeklyResetWeek: goalIsoWeekKey(nowUtc),
    );
  }

  final List<GoalProgress> activeDailyGoals;
  final List<GoalProgress> activeWeeklyGoals;
  final List<GoalProgress> activePrestigeRunGoals;
  final List<GoalProgress> activeEventGoals;
  final String lastDailyResetDate;
  final String lastWeeklyResetWeek;
  final int runGoalPrestigeCount;

  Iterable<GoalProgress> get allActiveGoals sync* {
    yield* activeDailyGoals;
    yield* activeWeeklyGoals;
    yield* activePrestigeRunGoals;
    yield* activeEventGoals;
  }

  GoalProgress? progressFor(String goalId) {
    for (final progress in allActiveGoals) {
      if (progress.goalId == goalId) {
        return progress;
      }
    }
    return null;
  }

  GoalSystemState copyWith({
    List<GoalProgress>? activeDailyGoals,
    List<GoalProgress>? activeWeeklyGoals,
    List<GoalProgress>? activePrestigeRunGoals,
    List<GoalProgress>? activeEventGoals,
    String? lastDailyResetDate,
    String? lastWeeklyResetWeek,
    int? runGoalPrestigeCount,
  }) {
    return GoalSystemState(
      activeDailyGoals: activeDailyGoals ?? this.activeDailyGoals,
      activeWeeklyGoals: activeWeeklyGoals ?? this.activeWeeklyGoals,
      activePrestigeRunGoals:
          activePrestigeRunGoals ?? this.activePrestigeRunGoals,
      activeEventGoals: activeEventGoals ?? this.activeEventGoals,
      lastDailyResetDate: lastDailyResetDate ?? this.lastDailyResetDate,
      lastWeeklyResetWeek: lastWeeklyResetWeek ?? this.lastWeeklyResetWeek,
      runGoalPrestigeCount: math.max(
        0,
        runGoalPrestigeCount ?? this.runGoalPrestigeCount,
      ),
    );
  }

  GoalSystemState updateGoal(
    String goalId,
    GoalProgress Function(GoalProgress progress) update,
  ) {
    List<GoalProgress> updateList(List<GoalProgress> values) {
      var changed = false;
      final next = values
          .map((progress) {
            if (progress.goalId != goalId) {
              return progress;
            }
            final updated = update(progress);
            changed = changed || updated != progress;
            return updated;
          })
          .toList(growable: false);
      return changed ? List<GoalProgress>.unmodifiable(next) : values;
    }

    final nextDaily = updateList(activeDailyGoals);
    final nextWeekly = updateList(activeWeeklyGoals);
    final nextRun = updateList(activePrestigeRunGoals);
    final nextEvent = updateList(activeEventGoals);
    if (identical(nextDaily, activeDailyGoals) &&
        identical(nextWeekly, activeWeeklyGoals) &&
        identical(nextRun, activePrestigeRunGoals) &&
        identical(nextEvent, activeEventGoals)) {
      return this;
    }
    return copyWith(
      activeDailyGoals: nextDaily,
      activeWeeklyGoals: nextWeekly,
      activePrestigeRunGoals: nextRun,
      activeEventGoals: nextEvent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeDailyGoals': activeDailyGoals
          .map((progress) => progress.toJson())
          .toList(),
      'activeWeeklyGoals': activeWeeklyGoals
          .map((progress) => progress.toJson())
          .toList(),
      'activePrestigeRunGoals': activePrestigeRunGoals
          .map((progress) => progress.toJson())
          .toList(),
      'activeEventGoals': activeEventGoals
          .map((progress) => progress.toJson())
          .toList(),
      'lastDailyResetDate': lastDailyResetDate,
      'lastWeeklyResetWeek': lastWeeklyResetWeek,
      'runGoalPrestigeCount': runGoalPrestigeCount,
    };
  }

  factory GoalSystemState.fromJson(Map<String, dynamic>? json) {
    return GoalSystemState(
      activeDailyGoals: _goalProgressList(json?['activeDailyGoals']),
      activeWeeklyGoals: _goalProgressList(json?['activeWeeklyGoals']),
      activePrestigeRunGoals: _goalProgressList(
        json?['activePrestigeRunGoals'],
      ),
      activeEventGoals: _goalProgressList(json?['activeEventGoals']),
      lastDailyResetDate: _stringValue(json?['lastDailyResetDate']),
      lastWeeklyResetWeek: _stringValue(json?['lastWeeklyResetWeek']),
      runGoalPrestigeCount: math.max(
        0,
        _intValue(json?['runGoalPrestigeCount']),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GoalSystemState &&
        _listEquals(activeDailyGoals, other.activeDailyGoals) &&
        _listEquals(activeWeeklyGoals, other.activeWeeklyGoals) &&
        _listEquals(activePrestigeRunGoals, other.activePrestigeRunGoals) &&
        _listEquals(activeEventGoals, other.activeEventGoals) &&
        lastDailyResetDate == other.lastDailyResetDate &&
        lastWeeklyResetWeek == other.lastWeeklyResetWeek &&
        runGoalPrestigeCount == other.runGoalPrestigeCount;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(activeDailyGoals),
    Object.hashAll(activeWeeklyGoals),
    Object.hashAll(activePrestigeRunGoals),
    Object.hashAll(activeEventGoals),
    lastDailyResetDate,
    lastWeeklyResetWeek,
    runGoalPrestigeCount,
  );
}

String goalCategoryKey(GoalCategory category) {
  return switch (category) {
    GoalCategory.starter => 'starter',
    GoalCategory.daily => 'daily',
    GoalCategory.weekly => 'weekly',
    GoalCategory.prestigeRun => 'prestige_run',
    GoalCategory.event => 'event',
    GoalCategory.lifetime => 'lifetime',
  };
}

String goalObjectiveTypeKey(GoalObjectiveType type) {
  return switch (type) {
    GoalObjectiveType.tapCount => 'tap_count',
    GoalObjectiveType.earnMoney => 'earn_money',
    GoalObjectiveType.buyUpgrades => 'buy_upgrades',
    GoalObjectiveType.completeCustomerOrders => 'complete_customer_orders',
    GoalObjectiveType.completeSpecificCustomerType =>
      'complete_specific_customer_type',
    GoalObjectiveType.openChests => 'open_chests',
    GoalObjectiveType.triggerCritical => 'trigger_critical',
    GoalObjectiveType.reachCombo => 'reach_combo',
    GoalObjectiveType.gainReputation => 'gain_reputation',
    GoalObjectiveType.levelUpShop => 'level_up_shop',
    GoalObjectiveType.completeMilestones => 'complete_milestones',
    GoalObjectiveType.doPrestige => 'do_prestige',
    GoalObjectiveType.unlockCollectionItem => 'unlock_collection_item',
    GoalObjectiveType.completeEvent => 'complete_event',
    GoalObjectiveType.unlockBranches => 'unlock_branches',
    GoalObjectiveType.upgradeBranchLevels => 'upgrade_branch_levels',
    GoalObjectiveType.reachTotalBranchLevel => 'reach_total_branch_level',
    GoalObjectiveType.reachBranchMilestones => 'reach_branch_milestones',
    GoalObjectiveType.completeBranchRegions => 'complete_branch_regions',
    GoalObjectiveType.assignBranchManager => 'assign_branch_manager',
  };
}

String goalRewardTypeKey(GoalRewardType type) {
  return switch (type) {
    GoalRewardType.money => 'money',
    GoalRewardType.reputation => 'reputation',
    GoalRewardType.chest => 'chest',
    GoalRewardType.temporaryBoost => 'temporary_boost',
    GoalRewardType.recipeShard => 'recipe_shard',
    GoalRewardType.staffCardShard => 'staff_card_shard',
    GoalRewardType.decorShard => 'decor_shard',
    GoalRewardType.knifeSkinShard => 'knife_skin_shard',
    GoalRewardType.prestigePoint => 'prestige_point',
    GoalRewardType.prestigeShard => 'prestige_shard',
  };
}

GoalRewardType goalRewardTypeFromKey(String key) {
  return switch (key) {
    'reputation' => GoalRewardType.reputation,
    'chest' => GoalRewardType.chest,
    'temporary_boost' => GoalRewardType.temporaryBoost,
    'recipe_shard' => GoalRewardType.recipeShard,
    'staff_card_shard' => GoalRewardType.staffCardShard,
    'decor_shard' => GoalRewardType.decorShard,
    'knife_skin_shard' => GoalRewardType.knifeSkinShard,
    'prestige_point' => GoalRewardType.prestigePoint,
    'prestige_shard' => GoalRewardType.prestigeShard,
    _ => GoalRewardType.money,
  };
}

String goalStatusKey(GoalStatus status) {
  return switch (status) {
    GoalStatus.active => 'active',
    GoalStatus.completed => 'completed',
    GoalStatus.expired => 'expired',
  };
}

GoalStatus goalStatusFromKey(String key) {
  return switch (key) {
    'completed' => GoalStatus.completed,
    'expired' => GoalStatus.expired,
    _ => GoalStatus.active,
  };
}

String goalLocalDateKey(DateTime nowUtc) {
  final local = nowUtc.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String goalIsoWeekKey(DateTime nowUtc) {
  final local = DateTime(
    nowUtc.toLocal().year,
    nowUtc.toLocal().month,
    nowUtc.toLocal().day,
  );
  final thursday = local.add(Duration(days: 4 - local.weekday));
  final firstThursday = DateTime(thursday.year, 1, 4);
  final firstIsoThursday = firstThursday.add(
    Duration(days: 4 - firstThursday.weekday),
  );
  final week =
      1 + thursday.difference(firstIsoThursday).inDays ~/ DateTime.daysPerWeek;
  return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
}

List<GoalProgress> _goalProgressList(Object? value) {
  if (value is! List) {
    return const <GoalProgress>[];
  }
  final parsed = value
      .map(_stringKeyMap)
      .whereType<Map<String, dynamic>>()
      .map(GoalProgress.fromJson)
      .where((progress) => progress.goalId.isNotEmpty)
      .toList(growable: false);
  return List<GoalProgress>.unmodifiable(parsed);
}

Map<String, dynamic>? _stringKeyMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
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

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
