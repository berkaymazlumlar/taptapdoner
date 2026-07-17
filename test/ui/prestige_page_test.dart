import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/pages/prestige_page.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets('prestige sheet renders the collapsed info layout', (
    tester,
  ) async {
    final controller = _controller(
      config,
      nowUtc,
      state: GameState.initial(config, nowUtc: nowUtc).copyWith(
        prestige: const PrestigeState(reputation: 2, runCashEarned: 1_250_000),
      ),
    );

    await _pumpPage(tester, controller);

    expect(find.byKey(const ValueKey('prestige-sheet-handle')), findsOneWidget);
    expect(find.byKey(const ValueKey('prestige-sheet-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('prestige-summary-card')), findsOneWidget);
    expect(find.text('Prestige'), findsOneWidget);
    expect(find.text('RESET THIS RUN AND COLLECT REPUTATION'), findsOneWidget);
    expect(find.text('POINTS TO GAIN'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    expect(find.text('Earned'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('After'), findsOneWidget);
    expect(find.text('x1.14'), findsOneWidget);
    expect(find.text('x1.17'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('prestige-shop-shortcut-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prestige-checklist-toggle-What Resets')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prestige-checklist-toggle-What Stays')),
      findsOneWidget,
    );
    expect(find.text('What Resets'), findsOneWidget);
    expect(
      find.text(
        'Current money, all upgrade progress, current shop level, temporary boosts, and combo state',
      ),
      findsNothing,
    );
    expect(find.text('Unspent'), findsOneWidget);
    expect(find.text('What Stays'), findsOneWidget);
    expect(find.text('Prestige multiplier'), findsNothing);
    final actionButton = find.byKey(const ValueKey('prestige-action-button'));
    expect(actionButton, findsOneWidget);
    expect(tester.getRect(actionButton).bottom, lessThanOrEqualTo(844));
    expect(find.byKey(const ValueKey('prestige-close-button')), findsOneWidget);
    expect(find.text('PRESTIGE'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('prestige action applies the reset and notifies completion', (
    tester,
  ) async {
    final controller = _controller(
      config,
      nowUtc,
      state: GameState.initial(config, nowUtc: nowUtc).copyWith(
        prestige: const PrestigeState(reputation: 2, runCashEarned: 1_250_000),
      ),
    );
    var applied = false;

    await _pumpPage(
      tester,
      controller,
      onPrestigeApplied: () async {
        applied = true;
      },
    );

    await tester.tap(find.byKey(const ValueKey('prestige-action-button')));
    await tester.pumpAndSettle();

    expect(applied, isTrue);
    expect(controller.state.prestige.reputation, 3);
    expect(controller.state.prestige.runCashEarned, 0);
    expect(controller.availablePrestigePoints, 0);
  });

  testWidgets('points to gain reflects the logarithmic reward curve', (
    tester,
  ) async {
    final controller = _controller(
      config,
      nowUtc,
      state: GameState.initial(config, nowUtc: nowUtc).copyWith(
        prestige: const PrestigeState(runCashEarned: 1_522_756_000_000),
      ),
    );

    await _pumpPage(tester, controller);

    expect(find.text('+13'), findsOneWidget);
    expect(find.text('+1234'), findsNothing);
  });

  testWidgets('prestige info tiles expand on demand', (tester) async {
    final controller = _controller(
      config,
      nowUtc,
      state: GameState.initial(config, nowUtc: nowUtc).copyWith(
        prestige: const PrestigeState(reputation: 2, runCashEarned: 1_250_000),
      ),
    );

    await _pumpPage(
      tester,
      controller,
      presentation: PrestigePagePresentation.tab,
    );

    const resetText =
        'Current money, all upgrade progress, current shop level, temporary boosts, and combo state';
    expect(find.text(resetText), findsNothing);

    final resetToggle = find.byKey(
      const ValueKey('prestige-checklist-toggle-What Resets'),
    );
    await tester.ensureVisible(resetToggle);
    await tester.tap(resetToggle);
    await tester.pumpAndSettle();

    expect(find.text(resetText), findsOneWidget);
  });

  testWidgets('prestige shop opens as a separate page and purchases upgrades', (
    tester,
  ) async {
    final controller = _controller(
      config,
      nowUtc,
      state: GameState.initial(config, nowUtc: nowUtc).copyWith(
        prestige: const PrestigeState(
          totalPrestigePoints: 2,
          unspentPrestigePoints: 2,
          runCashEarned: 1_250_000,
        ),
      ),
    );

    await _pumpPage(tester, controller);

    await tester.tap(
      find.byKey(const ValueKey('prestige-shop-shortcut-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('prestige-shop-page-root')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prestige-shop-page-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('prestige-shop-upgrade-master_hand')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('prestige-shop-buy-button-master_hand')),
    );
    await tester.pumpAndSettle();

    expect(controller.state.prestige.prestigeUpgradeLevel('master_hand'), 1);
    expect(controller.state.prestige.unspentPrestigePoints, 1);

    await tester.tap(
      find.byKey(const ValueKey('prestige-shop-page-close-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('prestige-shop-page-root')), findsNothing);
  });

  testWidgets('prestige tab keeps the action inside the summary card', (
    tester,
  ) async {
    final controller = _controller(
      config,
      nowUtc,
      state: GameState.initial(config, nowUtc: nowUtc).copyWith(
        prestige: const PrestigeState(reputation: 2, runCashEarned: 1_250_000),
      ),
    );

    await _pumpPage(
      tester,
      controller,
      presentation: PrestigePagePresentation.tab,
    );

    final actionButton = find.byKey(const ValueKey('prestige-action-button'));
    final summaryCard = find.byKey(const ValueKey('prestige-summary-card'));
    final resetCard = find.byKey(const ValueKey('prestige-resets-card'));
    final staysCard = find.byKey(const ValueKey('prestige-stays-card'));
    final cardStack = find.byKey(const ValueKey('prestige-card-stack'));

    expect(find.byKey(const ValueKey('prestige-sheet-handle')), findsNothing);
    expect(find.byKey(const ValueKey('prestige-close-button')), findsNothing);
    expect(actionButton, findsOneWidget);
    expect(summaryCard, findsOneWidget);
    expect(resetCard, findsOneWidget);
    expect(staysCard, findsOneWidget);
    expect(cardStack, findsOneWidget);

    final actionRect = tester.getRect(actionButton);
    final summaryRect = tester.getRect(summaryCard);
    expect(summaryRect.contains(actionRect.center), isTrue);

    final stackRect = tester.getRect(cardStack);
    final resetRect = tester.getRect(resetCard);
    final staysRect = tester.getRect(staysCard);
    expect(summaryRect.top, greaterThanOrEqualTo(stackRect.top));
    expect(resetRect.top, greaterThan(summaryRect.bottom));
    expect(staysRect.top, greaterThan(resetRect.bottom));
    expect(stackRect.bottom, greaterThan(staysRect.bottom));
  });

  testWidgets('close button uses the provided callback', (tester) async {
    final controller = _controller(
      config,
      nowUtc,
      state: GameState.initial(config, nowUtc: nowUtc).copyWith(
        prestige: const PrestigeState(reputation: 1, runCashEarned: 500_000),
      ),
    );
    var backPressed = false;

    await _pumpPage(
      tester,
      controller,
      onBack: () {
        backPressed = true;
      },
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('prestige-close-button')),
    );
    await tester.tap(find.byKey(const ValueKey('prestige-close-button')));
    await tester.pump();

    expect(backPressed, isTrue);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  GameController controller, {
  VoidCallback? onBack,
  Future<void> Function()? onPrestigeApplied,
  PrestigePagePresentation presentation = PrestigePagePresentation.sheet,
}) async {
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
  await tester.binding.setSurfaceSize(const Size(390, 844));

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
            data: const MediaQueryData(size: Size(390, 844)),
            child: PrestigePage(
              controller: controller,
              onBack: onBack,
              onPrestigeApplied: onPrestigeApplied,
              presentation: presentation,
            ),
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

GameController _controller(
  EconomyConfig config,
  DateTime nowUtc, {
  required GameState state,
}) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
  )..hydrate(state);
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
