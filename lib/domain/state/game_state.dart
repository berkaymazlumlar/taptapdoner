import 'dart:math' as math;

import 'package:taptapdoner/domain/economy/economy_config.dart';
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
  const PrestigeState({required this.reputation, required this.runCashEarned});

  final int reputation;
  final int runCashEarned;

  PrestigeState copyWith({int? reputation, int? runCashEarned}) {
    return PrestigeState(
      reputation: reputation ?? this.reputation,
      runCashEarned: runCashEarned ?? this.runCashEarned,
    );
  }

  Map<String, dynamic> toJson() {
    return {'reputation': reputation, 'runCashEarned': runCashEarned};
  }

  factory PrestigeState.fromJson(Map<String, dynamic>? json) {
    return PrestigeState(
      reputation: math.max(0, _intValue(json?['reputation'])),
      runCashEarned: math.max(0, _intValue(json?['runCashEarned'])),
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

class GameState {
  const GameState({
    required this.schemaVersion,
    required this.cash,
    required this.lifetimeCash,
    required this.pendingOfflineCash,
    required this.upgrades,
    required this.prestige,
    required this.rush,
    required this.lastActiveAtUtc,
    required this.lastSavedAtUtc,
    required this.localeCode,
  });

  static const currentSchemaVersion = 5;

  final int schemaVersion;
  final int cash;
  final int lifetimeCash;
  final int pendingOfflineCash;
  final Map<UpgradeId, UpgradeState> upgrades;
  final PrestigeState prestige;
  final TimedEffectState rush;
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
      prestige: const PrestigeState(reputation: 0, runCashEarned: 0),
      rush: const TimedEffectState(),
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
    PrestigeState? prestige,
    TimedEffectState? rush,
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
      prestige: prestige ?? this.prestige,
      rush: rush ?? this.rush,
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
      'prestige': prestige.toJson(),
      'rush': rush.toJson(),
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
      prestige: PrestigeState.fromJson(_stringKeyMap(json['prestige'])),
      rush: TimedEffectState.fromJson(_stringKeyMap(json['rush'])),
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
