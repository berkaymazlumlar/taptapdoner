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

  testWidgets('prestige sheet renders the stitched hierarchy', (tester) async {
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
    expect(find.text('REPUTATION READY'), findsOneWidget);
    expect(find.text('Permanent Boost'), findsOneWidget);
    expect(find.text('What Resets'), findsOneWidget);
    expect(find.text('What Stays'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('prestige-action-button')),
      findsOneWidget,
    );
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

    await tester.ensureVisible(
      find.byKey(const ValueKey('prestige-action-button')),
    );
    await tester.tap(find.byKey(const ValueKey('prestige-action-button')));
    await tester.pumpAndSettle();

    expect(applied, isTrue);
    expect(controller.state.prestige.reputation, 3);
    expect(controller.state.prestige.runCashEarned, 0);
    expect(controller.availablePrestigePoints, 0);
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
