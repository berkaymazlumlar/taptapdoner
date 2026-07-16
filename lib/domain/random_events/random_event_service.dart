import 'dart:math' as math;

import 'package:taptapdoner/domain/random_events/random_event_models.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

class RandomEventService {
  const RandomEventService({
    this.firstEventDelay = const Duration(minutes: 5),
    this.eventInterval = const Duration(minutes: 30),
  });

  final Duration firstEventDelay;
  final Duration eventInterval;

  RandomEventDefinition? pickRandomEvent({
    required List<RandomEventDefinition> allEvents,
    required GameState state,
    required DateTime nowUtc,
    required math.Random random,
  }) {
    final eventState = state.randomEvents;
    if (eventState.activeEventId != null) {
      return null;
    }

    final lastShownAt = eventState.lastEventShownAtUtc;
    if (lastShownAt == null) {
      if (nowUtc.difference(state.lastActiveAtUtc) < firstEventDelay) {
        return null;
      }
    } else if (nowUtc.difference(lastShownAt) < eventInterval) {
      return null;
    }

    var eligible = allEvents
        .where((event) {
          if (!_isUnlockConditionMet(event.unlockCondition, state)) {
            return false;
          }
          if (eventState.recentEventIds.contains(event.id)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    if (eligible.isEmpty) {
      eligible = allEvents
          .where((event) => _isUnlockConditionMet(event.unlockCondition, state))
          .toList(growable: false);
    }

    if (eligible.isEmpty) {
      return null;
    }

    return _weightedPick(eligible, eventState, nowUtc, random);
  }

  RandomEventOutcome resolveOutcome(
    RandomEventChoice choice,
    math.Random random,
  ) {
    if (choice.outcomes.isEmpty) {
      return RandomEventOutcome(
        key: '${choice.key}_no_effect',
        probability: 1,
        effect: const RandomEventEffect(
          type: RandomEventEffectType.noEffect,
          value: 0,
        ),
        resultText: choice.outcomeLogic,
      );
    }

    final total = choice.outcomes.fold<double>(
      0,
      (sum, outcome) => sum + math.max(0, outcome.probability),
    );
    if (total <= 0) {
      return choice.outcomes.first;
    }
    var roll = random.nextDouble() * total;
    for (final outcome in choice.outcomes) {
      roll -= math.max(0, outcome.probability);
      if (roll <= 0) {
        return outcome;
      }
    }
    return choice.outcomes.last;
  }

  RandomEventDefinition? _weightedPick(
    List<RandomEventDefinition> eligible,
    RandomEventRuntimeState state,
    DateTime nowUtc,
    math.Random random,
  ) {
    final weights = <RandomEventDefinition, double>{};
    var total = 0.0;
    for (final event in eligible) {
      var weight = event.weight.toDouble();
      final groupCooldown = state.groupCooldowns[event.cooldownGroup];
      if (groupCooldown != null && groupCooldown.isAfter(nowUtc)) {
        weight *= 0.35;
      }
      if (state.lastEventType == event.type) {
        weight *= 0.50;
      }
      if (weight <= 0) {
        continue;
      }
      weights[event] = weight;
      total += weight;
    }
    if (weights.isEmpty || total <= 0) {
      return eligible.first;
    }
    var roll = random.nextDouble() * total;
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll <= 0) {
        return entry.key;
      }
    }
    return weights.keys.last;
  }

  bool _isUnlockConditionMet(String condition, GameState state) {
    switch (condition) {
      case 'default':
        return true;
      case 'staff unlocked':
        return state.upgrade(UpgradeId.staff).purchased;
      case 'menu unlocked':
        return state.upgrade(UpgradeId.menu).purchased;
      case 'oven unlocked':
        return state.upgrade(UpgradeId.oven).purchased;
      case 'knife item tier >= 2':
        return state.upgrade(UpgradeId.knife).itemIndex >= 1;
    }

    if (condition.startsWith('prestige >=')) {
      final value = int.tryParse(condition.split('>=').last.trim()) ?? 0;
      return state.prestige.prestigeCount >= value;
    }
    if (condition.startsWith('reputation >=')) {
      final value = int.tryParse(condition.split('>=').last.trim()) ?? 0;
      return state.customerReputation.currentLevel >= value;
    }
    return true;
  }
}
