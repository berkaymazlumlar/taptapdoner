import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum RandomEventType {
  reward,
  risk,
  challenge,
  maintenance,
  social,
  funny,
  investment,
  staff,
  knife,
  menu,
  crowd,
  order,
  festival,
  rival,
}

enum RandomEventRarity { common, rare, epic, legendary }

enum RandomEventEffectType {
  instantMoney,
  moneyCost,
  tapBoost,
  tapPenalty,
  passiveBoost,
  passivePenalty,
  globalBoost,
  globalPenalty,
  menuBoost,
  menuPenalty,
  upgradeDiscount,
  upgradeCostPenalty,
  reputationGain,
  reputationBoost,
  reputationPenalty,
  permanentBonus,
  challengeStart,
  noEffect,
}

enum RandomEventModifierType {
  tapIncome,
  passiveIncome,
  globalIncome,
  menuMultiplier,
  upgradeCost,
  reputationGain,
}

@immutable
class RandomEventEffect {
  const RandomEventEffect({
    required this.type,
    required this.value,
    this.duration,
    this.target,
  });

  final RandomEventEffectType type;
  final double value;
  final Duration? duration;
  final String? target;
}

@immutable
class RandomEventOutcome {
  const RandomEventOutcome({
    required this.key,
    required this.probability,
    required this.effect,
    required this.resultText,
  });

  final String key;
  final double probability;
  final RandomEventEffect effect;
  final String resultText;
}

@immutable
class RandomEventChoice {
  const RandomEventChoice({
    required this.key,
    required this.label,
    required this.outcomeLogic,
    this.requiresRewardedAd = false,
    this.outcomes = const <RandomEventOutcome>[],
  });

  final String key;
  final String label;
  final String outcomeLogic;
  final bool requiresRewardedAd;
  final List<RandomEventOutcome> outcomes;
}

@immutable
class RandomEventDefinition {
  const RandomEventDefinition({
    required this.id,
    required this.title,
    required this.type,
    required this.rarity,
    required this.weight,
    required this.unlockCondition,
    required this.eventText,
    required this.rewardSummary,
    required this.riskSummary,
    required this.cooldownGroup,
    required this.effectTags,
    required this.choices,
  });

  final String id;
  final String title;
  final RandomEventType type;
  final RandomEventRarity rarity;
  final int weight;
  final String unlockCondition;
  final String eventText;
  final String rewardSummary;
  final String riskSummary;
  final String cooldownGroup;
  final List<String> effectTags;
  final List<RandomEventChoice> choices;

  RandomEventChoice? choiceByKey(String key) {
    for (final choice in choices) {
      if (choice.key == key) {
        return choice;
      }
    }
    return null;
  }
}

@immutable
class TimedModifierState {
  const TimedModifierState({
    required this.id,
    required this.sourceEventId,
    required this.type,
    required this.value,
    required this.expiresAtUtc,
  });

  final String id;
  final String sourceEventId;
  final RandomEventModifierType type;
  final double value;
  final DateTime expiresAtUtc;

  bool isActiveAt(DateTime nowUtc) => expiresAtUtc.isAfter(nowUtc);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceEventId': sourceEventId,
      'type': type.name,
      'value': value,
      'expiresAtUtc': expiresAtUtc.toIso8601String(),
    };
  }

  factory TimedModifierState.fromJson(Map<String, dynamic>? json) {
    final typeName = _stringValue(json?['type']);
    final type = RandomEventModifierType.values.firstWhere(
      (candidate) => candidate.name == typeName,
      orElse: () => RandomEventModifierType.globalIncome,
    );
    return TimedModifierState(
      id: _stringValue(json?['id']),
      sourceEventId: _stringValue(json?['sourceEventId']),
      type: type,
      value: _doubleValue(json?['value'], fallback: 1),
      expiresAtUtc: _dateTimeValue(json?['expiresAtUtc']) ?? DateTime(1970),
    );
  }
}

@immutable
class RandomEventHistoryEntry {
  const RandomEventHistoryEntry({
    required this.eventId,
    required this.shownAtUtc,
    this.choiceKey,
    this.outcomeKey,
  });

  final String eventId;
  final DateTime shownAtUtc;
  final String? choiceKey;
  final String? outcomeKey;

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'shownAtUtc': shownAtUtc.toIso8601String(),
      'choiceKey': choiceKey,
      'outcomeKey': outcomeKey,
    };
  }

  factory RandomEventHistoryEntry.fromJson(Map<String, dynamic>? json) {
    return RandomEventHistoryEntry(
      eventId: _stringValue(json?['eventId']),
      shownAtUtc: _dateTimeValue(json?['shownAtUtc']) ?? DateTime(1970),
      choiceKey: _nullableStringValue(json?['choiceKey']),
      outcomeKey: _nullableStringValue(json?['outcomeKey']),
    );
  }
}

@immutable
class RandomEventRuntimeState {
  const RandomEventRuntimeState({
    this.lastEventShownAtUtc,
    this.recentEventIds = const <String>[],
    this.activeEventId,
    this.lastEventType,
    this.groupCooldowns = const <String, DateTime>{},
    this.activeModifiers = const <TimedModifierState>[],
    this.history = const <RandomEventHistoryEntry>[],
  });

  final DateTime? lastEventShownAtUtc;
  final List<String> recentEventIds;
  final String? activeEventId;
  final RandomEventType? lastEventType;
  final Map<String, DateTime> groupCooldowns;
  final List<TimedModifierState> activeModifiers;
  final List<RandomEventHistoryEntry> history;

  RandomEventRuntimeState copyWith({
    DateTime? lastEventShownAtUtc,
    List<String>? recentEventIds,
    String? activeEventId,
    RandomEventType? lastEventType,
    Map<String, DateTime>? groupCooldowns,
    List<TimedModifierState>? activeModifiers,
    List<RandomEventHistoryEntry>? history,
    bool clearActiveEventId = false,
  }) {
    return RandomEventRuntimeState(
      lastEventShownAtUtc: lastEventShownAtUtc ?? this.lastEventShownAtUtc,
      recentEventIds: List<String>.unmodifiable(
        recentEventIds ?? this.recentEventIds,
      ),
      activeEventId: clearActiveEventId
          ? null
          : (activeEventId ?? this.activeEventId),
      lastEventType: lastEventType ?? this.lastEventType,
      groupCooldowns: Map<String, DateTime>.unmodifiable(
        groupCooldowns ?? this.groupCooldowns,
      ),
      activeModifiers: List<TimedModifierState>.unmodifiable(
        activeModifiers ?? this.activeModifiers,
      ),
      history: List<RandomEventHistoryEntry>.unmodifiable(
        history ?? this.history,
      ),
    );
  }

  RandomEventRuntimeState markShown(
    RandomEventDefinition event,
    DateTime nowUtc,
  ) {
    final recent = <String>[
      event.id,
      ...recentEventIds,
    ].take(5).toList(growable: false);
    final cooldowns = Map<String, DateTime>.from(groupCooldowns);
    cooldowns[event.cooldownGroup] = nowUtc.add(const Duration(hours: 1));
    final nextHistory = <RandomEventHistoryEntry>[
      RandomEventHistoryEntry(eventId: event.id, shownAtUtc: nowUtc),
      ...history,
    ].take(20).toList(growable: false);
    return copyWith(
      lastEventShownAtUtc: nowUtc,
      recentEventIds: recent,
      activeEventId: event.id,
      lastEventType: event.type,
      groupCooldowns: cooldowns,
      history: nextHistory,
    );
  }

  RandomEventRuntimeState resolveActive({
    required String eventId,
    required String choiceKey,
    required String outcomeKey,
    required List<TimedModifierState> modifiers,
    required DateTime nowUtc,
    bool clearActiveEventId = true,
  }) {
    final nextHistory = history.isEmpty
        ? <RandomEventHistoryEntry>[
            RandomEventHistoryEntry(
              eventId: eventId,
              shownAtUtc: nowUtc,
              choiceKey: choiceKey,
              outcomeKey: outcomeKey,
            ),
          ]
        : <RandomEventHistoryEntry>[
            RandomEventHistoryEntry(
              eventId: history.first.eventId,
              shownAtUtc: history.first.shownAtUtc,
              choiceKey: choiceKey,
              outcomeKey: outcomeKey,
            ),
            ...history.skip(1),
          ];
    return copyWith(
      clearActiveEventId: clearActiveEventId,
      activeModifiers: modifiers,
      history: nextHistory.take(20).toList(growable: false),
    );
  }

  RandomEventRuntimeState pruneExpired(DateTime nowUtc) {
    final liveModifiers = activeModifiers
        .where((modifier) => modifier.isActiveAt(nowUtc))
        .toList(growable: false);
    final liveCooldowns = Map<String, DateTime>.fromEntries(
      groupCooldowns.entries.where((entry) => entry.value.isAfter(nowUtc)),
    );
    if (listEquals(liveModifiers, activeModifiers) &&
        mapEquals(liveCooldowns, groupCooldowns)) {
      return this;
    }
    return copyWith(
      activeModifiers: liveModifiers,
      groupCooldowns: liveCooldowns,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastEventShownAtUtc': lastEventShownAtUtc?.toIso8601String(),
      'recentEventIds': recentEventIds,
      'activeEventId': activeEventId,
      'lastEventType': lastEventType?.name,
      'groupCooldowns': groupCooldowns.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'activeModifiers': activeModifiers
          .map((modifier) => modifier.toJson())
          .toList(growable: false),
      'history': history.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  factory RandomEventRuntimeState.fromJson(Map<String, dynamic>? json) {
    final lastTypeName = _stringValue(json?['lastEventType']);
    RandomEventType? lastType;
    for (final candidate in RandomEventType.values) {
      if (candidate.name == lastTypeName) {
        lastType = candidate;
        break;
      }
    }
    return RandomEventRuntimeState(
      lastEventShownAtUtc: _dateTimeValue(json?['lastEventShownAtUtc']),
      recentEventIds: _stringList(json?['recentEventIds']),
      activeEventId: _nullableStringValue(json?['activeEventId']),
      lastEventType: lastType,
      groupCooldowns: _dateTimeMap(json?['groupCooldowns']),
      activeModifiers: _modifierList(json?['activeModifiers']),
      history: _historyList(json?['history']),
    );
  }
}

double randomEventModifierProduct(
  RandomEventRuntimeState state,
  RandomEventModifierType type, {
  required DateTime nowUtc,
}) {
  var multiplier = 1.0;
  for (final modifier in state.activeModifiers) {
    if (modifier.type == type && modifier.isActiveAt(nowUtc)) {
      multiplier *= math.max(0, modifier.value);
    }
  }
  return multiplier;
}

String _stringValue(Object? value, {String fallback = ''}) {
  return value is String ? value : fallback;
}

String? _nullableStringValue(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return value;
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

DateTime? _dateTimeValue(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value)?.toUtc();
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) {
    return const <String>[];
  }
  return List<String>.unmodifiable(
    value.whereType<String>().where((entry) => entry.isNotEmpty),
  );
}

Map<String, DateTime> _dateTimeMap(Object? value) {
  if (value is! Map) {
    return const <String, DateTime>{};
  }
  final parsed = <String, DateTime>{};
  value.forEach((key, value) {
    final date = _dateTimeValue(value);
    if (date != null) {
      parsed[key.toString()] = date;
    }
  });
  return Map<String, DateTime>.unmodifiable(parsed);
}

List<TimedModifierState> _modifierList(Object? value) {
  if (value is! Iterable) {
    return const <TimedModifierState>[];
  }
  return List<TimedModifierState>.unmodifiable(
    value.whereType<Map>().map(
      (entry) => TimedModifierState.fromJson(_stringKeyMap(entry)),
    ),
  );
}

List<RandomEventHistoryEntry> _historyList(Object? value) {
  if (value is! Iterable) {
    return const <RandomEventHistoryEntry>[];
  }
  return List<RandomEventHistoryEntry>.unmodifiable(
    value.whereType<Map>().map(
      (entry) => RandomEventHistoryEntry.fromJson(_stringKeyMap(entry)),
    ),
  );
}

Map<String, dynamic> _stringKeyMap(Map<dynamic, dynamic> value) {
  return value.map((key, value) => MapEntry(key.toString(), value));
}
