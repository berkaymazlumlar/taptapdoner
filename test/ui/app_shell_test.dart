import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/random_events/random_event_models.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/overlays/game_shell_overlay.dart';
import 'package:taptapdoner/ui/widgets/stitch_bottom_sheet_primitives.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets('home bottom nav switches to Shop without a bottom sheet', (
    tester,
  ) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);
    await tester.tap(find.byKey(const ValueKey('bottom-nav-shop-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('shop-tab-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('tap-zone-root')), findsNothing);
    expect(_findGameWidget(), findsNothing);
    expect(find.byKey(const ValueKey('shop-sheet-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('shop-sheet-root')), findsNothing);
    expect(find.byKey(const ValueKey('shop-sheet-close-button')), findsNothing);
    expect(find.byType(StitchSheetHandle), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const ValueKey('bottom-nav-shell')), findsOneWidget);
  });

  testWidgets('kitchen game is preserved while another tab is active', (
    tester,
  ) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);
    final initialGame = tester
        .widget<GameWidget<TapTapDonerGame>>(_findGameWidget())
        .game!;

    await tester.tap(find.byKey(const ValueKey('bottom-nav-shop-button')));
    await tester.pumpAndSettle();

    expect(_findGameWidget(), findsNothing);
    expect(
      tester
          .widget<GameWidget<TapTapDonerGame>>(
            _findGameWidget(skipOffstage: false),
          )
          .game,
      same(initialGame),
    );
    expect(initialGame.paused, isTrue);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-kitchen-button')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<GameWidget<TapTapDonerGame>>(_findGameWidget()).game,
      same(initialGame),
    );
    expect(initialGame.paused, isFalse);
  });

  testWidgets('quest popup shows starter and daily goals together', (
    tester,
  ) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);

    expect(find.byKey(const ValueKey('shell-quest-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('starter-quest-card')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shell-quest-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('starter-quest-card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('daily-goals-popup-section')),
      findsOneWidget,
    );
    expect(find.text('DAILY GOALS'), findsOneWidget);
    expect(find.text('Cut 10 Doners'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('starter-quest-progress-bar')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('shell-quest-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('starter-quest-card')), findsNothing);
  });

  testWidgets('quest button shows a colored dot when a quest is complete', (
    tester,
  ) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);

    for (var index = 0; index < 10; index += 1) {
      await controller.tap();
    }
    await tester.pump();

    final badgeFinder = find.byKey(const ValueKey('shell-quest-button-badge'));
    expect(badgeFinder, findsOneWidget);
    expect(
      find.descendant(of: badgeFinder, matching: find.text('1')),
      findsNothing,
    );
  });

  testWidgets('kitchen groups a single active temporary income boost', (
    tester,
  ) async {
    final state = GameState.initial(config, nowUtc: nowUtc).copyWith(
      passiveBoost: TimedEffectState(
        endsAtUtc: nowUtc.add(const Duration(seconds: 120)),
      ),
    );
    final controller = _controllerForApp(config, nowUtc, state: state);

    await _pumpAppForTabs(tester, controller);

    expect(find.byKey(const ValueKey('active-effects-panel')), findsOneWidget);
    expect(find.text('Avantajlar (1)'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('active-effects-positive-toggle')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('active-income-boost-badge')),
      findsOneWidget,
    );
    expect(find.text('x2 Income'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('active-income-boost-timer')),
      findsOneWidget,
    );
    expect(find.text('2m 00s'), findsOneWidget);
  });

  testWidgets('kitchen shows active positive and negative event effects', (
    tester,
  ) async {
    final state = GameState.initial(config, nowUtc: nowUtc).copyWith(
      randomEvents: RandomEventRuntimeState(
        activeModifiers: [
          TimedModifierState(
            id: 'debug_tap_boost',
            sourceEventId: 'EVT_006',
            type: RandomEventModifierType.tapIncome,
            value: 3,
            expiresAtUtc: nowUtc.add(const Duration(seconds: 60)),
          ),
          TimedModifierState(
            id: 'debug_passive_penalty',
            sourceEventId: 'EVT_003',
            type: RandomEventModifierType.passiveIncome,
            value: 0.8,
            expiresAtUtc: nowUtc.add(const Duration(seconds: 120)),
          ),
        ],
      ),
    );
    final controller = _controllerForApp(config, nowUtc, state: state);

    await _pumpAppForTabs(tester, controller);

    expect(find.byKey(const ValueKey('active-effects-panel')), findsOneWidget);
    expect(find.text('Avantajlar (1)'), findsOneWidget);
    expect(find.text('Dezavantajlar (1)'), findsOneWidget);

    final effectsRect = tester.getRect(
      find.byKey(const ValueKey('active-effects-panel')),
    );
    final debugButtonRect = tester.getRect(
      find.byKey(const ValueKey('debug-random-event-button')),
    );
    final bottomNavRect = tester.getRect(
      find.byKey(const ValueKey('bottom-nav-shell')),
    );
    final effectsLeftInset = effectsRect.left - bottomNavRect.left;

    expect(effectsLeftInset, lessThanOrEqualTo(12));
    expect(
      bottomNavRect.top - effectsRect.bottom,
      closeTo(effectsLeftInset, 1),
    );
    expect(bottomNavRect.right - debugButtonRect.right, closeTo(12, 1));
    expect(bottomNavRect.top - debugButtonRect.bottom, closeTo(12, 1));

    await tester.tap(
      find.byKey(const ValueKey('active-effects-positive-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tap x3'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('active-effects-negative-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Passive -20%'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('active-effect-timer-debug_tap_boost')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('active-effect-timer-debug_passive_penalty')),
      findsOneWidget,
    );
  });

  testWidgets('combo quest shows unlock copy behind the info button', (
    tester,
  ) async {
    final state = _stateWithActiveQuest(
      config,
      nowUtc,
      questId: 'starter_combo_15',
    );
    final controller = _controllerForApp(config, nowUtc, state: state);

    await _pumpAppForTabs(tester, controller);
    await tester.tap(find.byKey(const ValueKey('shell-quest-button')));
    await tester.pumpAndSettle();

    expect(find.text('Reach 15 Combo'), findsOneWidget);
    expect(find.textContaining('Rusty Knife Lv. 15'), findsNothing);
    expect(
      find.byKey(const ValueKey('starter-quest-info-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('starter-quest-info-button')));
    await tester.pump();

    expect(find.text('Combo unlocks at Rusty Knife Lv. 15.'), findsOneWidget);
  });

  testWidgets('home header opens the achievements-only page', (tester) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);
    final goalsRect = tester.getRect(
      find.byKey(const ValueKey('hud-goals-button')),
    );
    final settingsRect = tester.getRect(
      find.byKey(const ValueKey('hud-settings-button')),
    );
    expect(goalsRect.right, lessThan(settingsRect.left));

    await tester.tap(find.byKey(const ValueKey('hud-goals-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('goals-tab-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('goals-page-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('tap-zone-root')), findsNothing);
    expect(_findGameWidget(), findsNothing);
    expect(find.text('First Cut'), findsOneWidget);
    expect(find.text('Daily Goals'), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.byKey(const ValueKey('bottom-nav-shell')), findsOneWidget);
  });

  testWidgets('kitchen has no second daily goals shortcut', (tester) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);

    expect(
      find.byKey(const ValueKey('shell-daily-goals-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('hud-goals-button')), findsOneWidget);
  });

  testWidgets('home chest shortcut opens the separate chest page', (
    tester,
  ) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);
    final questRect = tester.getRect(
      find.byKey(const ValueKey('shell-quest-button')),
    );
    final chestRect = tester.getRect(
      find.byKey(const ValueKey('shell-chest-button')),
    );
    expect(chestRect.top, greaterThan(questRect.bottom));

    await tester.tap(find.byKey(const ValueKey('shell-chest-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chests-tab-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('chest-page-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('goals-page-root')), findsNothing);
    expect(
      find.byKey(const ValueKey('goals-section-toggle-chests')),
      findsNothing,
    );
  });

  testWidgets('bottom nav opens the separate collection page', (tester) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);
    expect(find.byKey(const ValueKey('bottom-nav-goals-button')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('bottom-nav-collection-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('collection-tab-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('collection-page-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('goals-page-root')), findsNothing);
    expect(
      find.byKey(const ValueKey('goals-section-toggle-collection')),
      findsNothing,
    );
    expect(find.text('Recipes'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
  });

  testWidgets('achievement popup claims the reward and dismisses itself', (
    tester,
  ) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);
    for (var index = 0; index < 10; index += 1) {
      await controller.tap();
    }
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('achievement-popup-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('achievement-popup-claim-tap_10')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('achievement-popup-card')))
          .width,
      greaterThan(330),
    );

    await tester.tap(
      find.byKey(const ValueKey('achievement-popup-claim-tap_10')),
    );
    await tester.pumpAndSettle();

    expect(controller.state.achievements['tap_10']?.isRewardClaimed, isTrue);
    expect(find.byKey(const ValueKey('achievement-popup-card')), findsNothing);
  });

  testWidgets('achievement popup auto-claims and dismisses itself', (
    tester,
  ) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);
    for (var index = 0; index < 10; index += 1) {
      await controller.tap();
    }
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('achievement-popup-card')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(controller.state.achievements['tap_10']?.isRewardClaimed, isTrue);
    expect(find.byKey(const ValueKey('achievement-popup-card')), findsNothing);
  });

  testWidgets('home bottom nav switches to Prestige without a bottom sheet', (
    tester,
  ) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForTabs(tester, controller);
    await tester.tap(find.byKey(const ValueKey('bottom-nav-prestige-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('prestige-tab-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('tap-zone-root')), findsNothing);
    expect(_findGameWidget(), findsNothing);
    expect(
      find.byKey(const ValueKey('prestige-sheet-surface')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('prestige-sheet-root')), findsNothing);
    expect(find.byKey(const ValueKey('prestige-sheet-handle')), findsNothing);
    expect(find.byKey(const ValueKey('prestige-close-button')), findsNothing);
    expect(find.byType(StitchSheetHandle), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(const ValueKey('bottom-nav-shell')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-kitchen-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tap-zone-root')), findsOneWidget);
    expect(_findGameWidget(), findsOneWidget);
    expect(find.byKey(const ValueKey('prestige-tab-root')), findsNothing);
  });

  testWidgets(
    'pending offline reward is not rendered as a full page in shell',
    (tester) async {
      final state = GameState.initial(
        config,
        nowUtc: nowUtc,
      ).copyWith(pendingOfflineCash: 2500);
      final controller = _controllerForApp(config, nowUtc, state: state);

      await _pumpAppForTabs(tester, controller);

      expect(
        find.byKey(const ValueKey('offline-reward-page-root')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('offline-reward-popup-panel')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('tap-zone-root')), findsOneWidget);
      expect(find.byKey(const ValueKey('bottom-nav-shell')), findsOneWidget);
    },
  );
}

Future<void> _pumpAppForTabs(
  WidgetTester tester,
  GameController controller, {
  Size size = const Size(390, 844),
}) async {
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
  await tester.binding.setSurfaceSize(size);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 884),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: AppStrings.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Builder(
              builder: (context) {
                return Scaffold(body: GameShellOverlay(controller: controller));
              },
            ),
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

GameController _controllerForApp(
  EconomyConfig config,
  DateTime nowUtc, {
  GameState? state,
}) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
  )..hydrate(state ?? GameState.initial(config, nowUtc: nowUtc));
}

GameState _stateWithActiveQuest(
  EconomyConfig config,
  DateTime nowUtc, {
  required String questId,
}) {
  final progress = Map<String, QuestProgress>.from(
    StarterQuestCatalog.initialProgress(),
  );
  var reachedTarget = false;
  for (final definition in StarterQuestCatalog.definitions) {
    if (definition.id == questId) {
      progress[definition.id] = definition
          .initialProgress(active: true)
          .copyWith(status: QuestStatus.active);
      reachedTarget = true;
      continue;
    }
    progress[definition.id] = definition
        .initialProgress(active: reachedTarget == false)
        .copyWith(
          status: reachedTarget ? QuestStatus.locked : QuestStatus.claimed,
          currentValue: reachedTarget ? 0 : definition.targetValue,
          rewardClaimed: reachedTarget == false,
        );
  }
  return GameState.initial(config, nowUtc: nowUtc).copyWith(quests: progress);
}

class _MemorySaveRepository implements SaveRepository {
  GameState? _state;

  @override
  Future<void> clear() async {
    _state = null;
  }

  @override
  Future<GameState?> load(EconomyConfig config) async => _state;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }
}

Finder _findGameWidget({bool skipOffstage = true}) {
  return find.byWidgetPredicate(
    (widget) => widget is GameWidget<TapTapDonerGame>,
    description: 'GameWidget<TapTapDonerGame>',
    skipOffstage: skipOffstage,
  );
}
