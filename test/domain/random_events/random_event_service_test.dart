import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/random_events/random_event_catalog.dart';
import 'package:taptapdoner/domain/random_events/random_event_models.dart';
import 'package:taptapdoner/domain/random_events/random_event_service.dart';
import 'package:taptapdoner/domain/state/game_state.dart';

void main() {
  test('catalog contains the full random event sheet', () {
    expect(RandomEventCatalog.events, hasLength(79));
    expect(RandomEventCatalog.byId.keys, containsAll(['EVT_001', 'EVT_080']));
    expect(RandomEventCatalog.byId, isNot(contains('EVT_010')));
    expect(
      RandomEventCatalog.events.any(
        (event) =>
            event.effectTags.any((tag) => tag.contains('turbo')) ||
            event.rewardSummary.toLowerCase().contains('turbo') ||
            event.riskSummary.toLowerCase().contains('turbo') ||
            event.eventText.toLowerCase().contains('turbo'),
      ),
      isFalse,
    );
    expect(
      RandomEventCatalog.events.where(
        (event) => event.choices.any((choice) => choice.requiresRewardedAd),
      ),
      hasLength(3),
    );
  });

  test('catalog does not emit unsupported effect types', () {
    final unsupported = {
      RandomEventEffectType.permanentBonus,
      RandomEventEffectType.challengeStart,
    };
    final unsupportedOutcomes = [
      for (final event in RandomEventCatalog.events)
        for (final choice in event.choices)
          for (final outcome in choice.outcomes)
            if (unsupported.contains(outcome.effect.type))
              '${event.id}:${choice.key}:${outcome.key}:${outcome.effect.type.name}',
    ];

    expect(unsupportedOutcomes, isEmpty);
  });

  test(
    'picker waits for first event delay and then selects an eligible event',
    () {
      final config = EconomyConfig.standard();
      final startedAt = DateTime.utc(2026, 7, 12, 10);
      final state = GameState.initial(config, nowUtc: startedAt);
      const service = RandomEventService();

      final tooEarly = service.pickRandomEvent(
        allEvents: RandomEventCatalog.events,
        state: state,
        nowUtc: startedAt.add(const Duration(minutes: 4, seconds: 59)),
        random: math.Random(1),
      );
      expect(tooEarly, isNull);

      final picked = service.pickRandomEvent(
        allEvents: RandomEventCatalog.events,
        state: state,
        nowUtc: startedAt.add(const Duration(minutes: 5)),
        random: math.Random(1),
      );
      expect(picked, isNotNull);
      expect(picked!.unlockCondition, 'default');
    },
  );

  test('runtime state persists active event and temporary modifiers', () {
    final now = DateTime.utc(2026, 7, 12, 10);
    final event = RandomEventCatalog.byId['EVT_001']!;
    final modifier = TimedModifierState(
      id: 'event-test-modifier',
      sourceEventId: event.id,
      type: RandomEventModifierType.globalIncome,
      value: 2,
      expiresAtUtc: now.add(const Duration(minutes: 10)),
    );
    final state = RandomEventRuntimeState(
      lastEventShownAtUtc: now,
      recentEventIds: [event.id],
      activeEventId: event.id,
      lastEventType: event.type,
      groupCooldowns: {event.cooldownGroup: now.add(const Duration(hours: 1))},
      activeModifiers: [modifier],
    );

    final restored = RandomEventRuntimeState.fromJson(state.toJson());

    expect(restored.activeEventId, event.id);
    expect(restored.recentEventIds, [event.id]);
    expect(restored.lastEventType, event.type);
    expect(restored.activeModifiers.single.value, 2);
    expect(
      randomEventModifierProduct(
        restored,
        RandomEventModifierType.globalIncome,
        nowUtc: now,
      ),
      2,
    );
  });
}
