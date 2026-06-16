import 'dart:math' as math;

class BranchDefinition {
  const BranchDefinition({
    required this.id,
    required this.name,
    required this.cityName,
    required this.regionId,
    required this.description,
    required this.baseUnlockCost,
    required this.baseIncomePerSecond,
    required this.incomeMultiplierPerLevel,
    required this.maxLevel,
    required this.requiredShopLevel,
    required this.requiredPrestigeCount,
    required this.requiredLifetimeCash,
    required this.assetKey,
  }) : assert(baseUnlockCost >= 0, 'baseUnlockCost cannot be negative.'),
       assert(
         baseIncomePerSecond >= 0,
         'baseIncomePerSecond cannot be negative.',
       ),
       assert(
         incomeMultiplierPerLevel >= 1,
         'incomeMultiplierPerLevel must be at least 1.',
       ),
       assert(maxLevel > 0, 'maxLevel must be positive.'),
       assert(requiredShopLevel >= 1, 'requiredShopLevel must be at least 1.'),
       assert(
         requiredPrestigeCount >= 0,
         'requiredPrestigeCount cannot be negative.',
       ),
       assert(
         requiredLifetimeCash >= 0,
         'requiredLifetimeCash cannot be negative.',
       );

  final String id;
  final String name;
  final String cityName;
  final String regionId;
  final String description;
  final double baseUnlockCost;
  final double baseIncomePerSecond;
  final double incomeMultiplierPerLevel;
  final int maxLevel;
  final int requiredShopLevel;
  final int requiredPrestigeCount;
  final double requiredLifetimeCash;
  final String assetKey;
}

class BranchRegionDefinition {
  const BranchRegionDefinition({
    required this.id,
    required this.name,
    required this.order,
    required this.requiredRegionId,
    required this.assetKey,
  });

  final String id;
  final String name;
  final int order;
  final String? requiredRegionId;
  final String assetKey;
}

class BranchProgress {
  const BranchProgress({
    required this.branchId,
    this.isUnlocked = false,
    this.level = 0,
    this.assignedManagerId,
  }) : assert(level >= 0, 'level cannot be negative.');

  final String branchId;
  final bool isUnlocked;
  final int level;
  final String? assignedManagerId;

  BranchProgress copyWith({
    bool? isUnlocked,
    int? level,
    String? assignedManagerId,
    bool clearAssignedManagerId = false,
  }) {
    final unlocked = isUnlocked ?? this.isUnlocked;
    final nextLevel = math.max(0, level ?? this.level);
    return BranchProgress(
      branchId: branchId,
      isUnlocked: unlocked,
      level: unlocked ? math.max(1, nextLevel) : 0,
      assignedManagerId: clearAssignedManagerId
          ? null
          : (assignedManagerId ?? this.assignedManagerId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'isUnlocked': isUnlocked,
      'level': level,
      'assignedManagerId': assignedManagerId,
    };
  }

  factory BranchProgress.fromJson(Map<String, dynamic>? json) {
    final branchId = _stringValue(json?['branchId']);
    final unlocked = _boolValue(json?['isUnlocked']);
    return BranchProgress(
      branchId: branchId,
      isUnlocked: unlocked,
      level: unlocked ? math.max(1, _intValue(json?['level'], fallback: 1)) : 0,
      assignedManagerId: _nullableString(json?['assignedManagerId']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BranchProgress &&
        branchId == other.branchId &&
        isUnlocked == other.isUnlocked &&
        level == other.level &&
        assignedManagerId == other.assignedManagerId;
  }

  @override
  int get hashCode =>
      Object.hash(branchId, isUnlocked, level, assignedManagerId);
}

class BranchSystemState {
  const BranchSystemState({
    this.branchProgress = const <String, BranchProgress>{},
    this.unlockedRegionIds = const <String>{'local'},
    this.claimedBranchMilestones = const <String>{},
    this.totalBranchIncomeEarned = 0,
  }) : assert(
         totalBranchIncomeEarned >= 0,
         'totalBranchIncomeEarned cannot be negative.',
       );

  final Map<String, BranchProgress> branchProgress;
  final Set<String> unlockedRegionIds;
  final Set<String> claimedBranchMilestones;
  final double totalBranchIncomeEarned;

  BranchProgress progressFor(String branchId) {
    return branchProgress[branchId] ?? BranchProgress(branchId: branchId);
  }

  bool isUnlocked(String branchId) => progressFor(branchId).isUnlocked;

  int levelFor(String branchId) => progressFor(branchId).level;

  int get unlockedBranchCount {
    return branchProgress.values
        .where((progress) => progress.isUnlocked)
        .length;
  }

  int get totalBranchLevel {
    return branchProgress.values.fold<int>(
      0,
      (total, progress) => total + (progress.isUnlocked ? progress.level : 0),
    );
  }

  BranchSystemState copyWith({
    Map<String, BranchProgress>? branchProgress,
    Set<String>? unlockedRegionIds,
    Set<String>? claimedBranchMilestones,
    double? totalBranchIncomeEarned,
  }) {
    return BranchSystemState(
      branchProgress: Map<String, BranchProgress>.unmodifiable(
        branchProgress ?? this.branchProgress,
      ),
      unlockedRegionIds: Set<String>.unmodifiable(
        unlockedRegionIds ?? this.unlockedRegionIds,
      ),
      claimedBranchMilestones: Set<String>.unmodifiable(
        claimedBranchMilestones ?? this.claimedBranchMilestones,
      ),
      totalBranchIncomeEarned: math.max(
        0,
        totalBranchIncomeEarned ?? this.totalBranchIncomeEarned,
      ),
    );
  }

  BranchSystemState updateProgress(BranchProgress progress) {
    if (progress.branchId.isEmpty) {
      return this;
    }
    final next = Map<String, BranchProgress>.from(branchProgress)
      ..[progress.branchId] = progress;
    return copyWith(branchProgress: next);
  }

  BranchSystemState addIncome(double amount) {
    if (amount <= 0) {
      return this;
    }
    return copyWith(totalBranchIncomeEarned: totalBranchIncomeEarned + amount);
  }

  Map<String, dynamic> toJson() {
    final progress = branchProgress.values.toList(growable: false)
      ..sort((left, right) => left.branchId.compareTo(right.branchId));
    return {
      'branchProgress': progress.map((entry) => entry.toJson()).toList(),
      'unlockedRegionIds': _sortedStrings(unlockedRegionIds),
      'claimedBranchMilestones': _sortedStrings(claimedBranchMilestones),
      'totalBranchIncomeEarned': totalBranchIncomeEarned,
    };
  }

  factory BranchSystemState.fromJson(Map<String, dynamic>? json) {
    return BranchSystemState(
      branchProgress: _progressMap(json?['branchProgress']),
      unlockedRegionIds: _stringSet(
        json?['unlockedRegionIds'],
        fallback: const <String>{'local'},
      ),
      claimedBranchMilestones: _stringSet(json?['claimedBranchMilestones']),
      totalBranchIncomeEarned: _nonNegativeDouble(
        json?['totalBranchIncomeEarned'],
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BranchSystemState &&
        _mapEquals(branchProgress, other.branchProgress) &&
        _setEquals(unlockedRegionIds, other.unlockedRegionIds) &&
        _setEquals(claimedBranchMilestones, other.claimedBranchMilestones) &&
        totalBranchIncomeEarned == other.totalBranchIncomeEarned;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(
      branchProgress.entries.map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
    Object.hashAll(unlockedRegionIds),
    Object.hashAll(claimedBranchMilestones),
    totalBranchIncomeEarned,
  );
}

Map<String, BranchProgress> _progressMap(Object? value) {
  if (value is! List) {
    return const <String, BranchProgress>{};
  }
  final parsed = <String, BranchProgress>{};
  for (final entry in value) {
    final map = _stringKeyMap(entry);
    if (map == null) {
      continue;
    }
    final progress = BranchProgress.fromJson(map);
    if (progress.branchId.isEmpty) {
      continue;
    }
    parsed[progress.branchId] = progress;
  }
  return Map<String, BranchProgress>.unmodifiable(parsed);
}

Map<String, dynamic>? _stringKeyMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

Set<String> _stringSet(Object? value, {Set<String> fallback = const {}}) {
  if (value is! Iterable) {
    return Set<String>.unmodifiable(fallback);
  }
  final parsed = value
      .whereType<String>()
      .where((entry) => entry.isNotEmpty)
      .toSet();
  if (parsed.isEmpty && fallback.isNotEmpty) {
    return Set<String>.unmodifiable(fallback);
  }
  return Set<String>.unmodifiable(parsed);
}

List<String> _sortedStrings(Set<String> values) {
  return values.toList(growable: false)..sort();
}

String _stringValue(Object? value, {String fallback = ''}) {
  return value is String ? value : fallback;
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
