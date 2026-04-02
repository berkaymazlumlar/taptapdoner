import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/tap_tap_doner_app.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/overlays/action_dock_overlay.dart';
import 'package:taptapdoner/ui/overlays/game_hud_overlay.dart';
import 'package:taptapdoner/ui/overlays/game_shell_overlay.dart';
import 'package:taptapdoner/ui/overlays/offline_reward_overlay.dart';
import 'package:taptapdoner/ui/overlays/settings_overlay.dart';
import 'package:taptapdoner/ui/overlays/tap_zone_overlay.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets('settings overlay switches locale to Turkish', (tester) async {
    final controller =
        GameController(
          config: config,
          saveRepository: _MemorySaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(
            config,
            nowUtc: nowUtc,
          ).copyWith(pendingOfflineCash: 250),
        );

    await tester.pumpWidget(
      _TestApp(
        controller: controller,
        child: SettingsOverlay(controller: controller, onClose: () {}),
      ),
    );
    await tester.pump();

    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Turkish'));
    await tester.pump();

    expect(find.text('Ayarlar'), findsOneWidget);
  });

  testWidgets('pending offline reward opens modal with fallback copy', (
    tester,
  ) async {
    final controller =
        GameController(
          config: config,
          saveRepository: _MemorySaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(
            config,
            nowUtc: nowUtc,
          ).copyWith(pendingOfflineCash: 250),
        );

    await tester.pumpWidget(
      _TestApp(
        controller: controller,
        child: OfflineRewardOverlay(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('While you were away'), findsOneWidget);
    expect(find.text('Reward ad is not available yet.'), findsOneWidget);
  });

  testWidgets(
    'shell lays out top, middle, and bottom sections on narrow portrait',
    (tester) async {
      const size = Size(320, 640);
      await _pumpShellLayout(tester, size: size);
      await _expectVerticalStack(tester);
    },
  );

  testWidgets(
    'shell lays out top, middle, and bottom sections on standard portrait',
    (tester) async {
      const size = Size(390, 844);
      await _pumpShellLayout(tester, size: size);
      await _expectVerticalStack(tester);
    },
  );

  testWidgets('shell respects non-zero safe-area insets on portrait', (
    tester,
  ) async {
    const size = Size(390, 844);
    const padding = EdgeInsets.fromLTRB(16, 30, 16, 24);

    await _pumpShellLayout(tester, size: size, padding: padding);
    await _expectVerticalStack(tester);
    await _expectPanelsWithinInsets(tester, size: size, padding: padding);
  });

  testWidgets(
    'launch with pending offline reward does not add an unknown overlay',
    (tester) async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          return null;
        }
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final controller =
          GameController(
            config: config,
            saveRepository: _MemorySaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(
              config,
              nowUtc: nowUtc,
            ).copyWith(pendingOfflineCash: 250),
          );

      await tester.pumpWidget(TapTapDonerApp(controller: controller));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('no-op controller notifications do not disturb the shell', (
    tester,
  ) async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        return null;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final controller = GameController(
      config: config,
      saveRepository: _MemorySaveRepository(),
      adService: const NoopRewardedAdService(),
      clock: () => nowUtc,
    )..hydrate(GameState.initial(config, nowUtc: nowUtc));
    var notificationCount = 0;
    controller.addListener(() {
      notificationCount += 1;
    });

    await tester.pumpWidget(TapTapDonerApp(controller: controller));
    await tester.pump(const Duration(seconds: 1));

    await controller.setLocaleCode('en');

    expect(notificationCount, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.controller, required this.child});

  final GameController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          locale: Locale(controller.state.localeCode),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: AppStrings.localizationsDelegates,
          home: Scaffold(body: child),
        );
      },
    );
  }
}

Future<void> _pumpShellLayout(
  WidgetTester tester, {
  required Size size,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
  await tester.binding.setSurfaceSize(size);

  final controller = GameController(
    config: EconomyConfig.standard(),
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => DateTime.utc(2026, 4, 1, 12),
  )..hydrate(GameState.initial(EconomyConfig.standard()));
  final game = TapTapDonerGame(controller: controller);

  await tester.pumpWidget(
    MaterialApp(
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: AppStrings.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(size: size, padding: padding),
        child: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: GameShellOverlay(
              controller: controller,
              game: game,
              onOpenShop: () {},
              onOpenPrestige: () {},
              onOpenSettings: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _expectVerticalStack(WidgetTester tester) async {
  final hudRect = tester.getRect(find.byType(GameHudOverlay));
  final tapRect = tester.getRect(find.byType(TapZoneOverlay));
  final dockRect = tester.getRect(find.byType(ActionDockOverlay));
  final navRect = tester.getRect(
    find.byKey(const ValueKey('bottom-nav-shell')),
  );
  final rushRect = tester.getRect(
    find.byKey(const ValueKey('shell-rush-button')),
  );
  final shellRect = tester.getRect(find.byType(GameShellOverlay));

  expect(shellRect.width, greaterThan(0));
  expect(shellRect.height, greaterThan(0));
  expect(hudRect.bottom, lessThanOrEqualTo(tapRect.top));
  expect(tapRect.bottom, lessThanOrEqualTo(dockRect.top));
  expect(dockRect.bottom, lessThanOrEqualTo(navRect.top));
  expect(dockRect.top - tapRect.bottom, lessThanOrEqualTo(0.5));
  expect(tapRect.height, greaterThanOrEqualTo(hudRect.height));
  expect(tapRect.height, greaterThanOrEqualTo(dockRect.height));
  expect(shellRect.height, greaterThanOrEqualTo(tapRect.height));
  expect(rushRect.center.dx, greaterThan(shellRect.center.dx));
  expect(rushRect.center.dy, lessThan(dockRect.top));
  expect(hudRect.height, lessThan(shellRect.height * 0.45));
  expect(dockRect.height, lessThan(shellRect.height * 0.45));
  expect(navRect.height, lessThan(shellRect.height * 0.2));
  expect(find.byKey(const ValueKey('game-hud-panel')), findsOneWidget);
  expect(find.byKey(const ValueKey('action-dock-panel')), findsOneWidget);
  expect(find.byKey(const ValueKey('action-dock-rush-pill')), findsOneWidget);
  expect(find.byKey(const ValueKey('shell-rush-button')), findsOneWidget);
  expect(find.byKey(const ValueKey('bottom-nav-shell')), findsOneWidget);
  expect(
    find.byKey(const ValueKey('bottom-nav-kitchen-button')),
    findsOneWidget,
  );
  expect(find.textContaining('₵'), findsWidgets);
  expect(find.byKey(const ValueKey('shell-backdrop-layer')), findsNothing);
}

Future<void> _expectPanelsWithinInsets(
  WidgetTester tester, {
  required Size size,
  required EdgeInsets padding,
}) async {
  final hudRect = tester.getRect(find.byKey(const ValueKey('game-hud-panel')));
  final dockRect = tester.getRect(
    find.byKey(const ValueKey('action-dock-panel')),
  );
  final navRect = tester.getRect(
    find.byKey(const ValueKey('bottom-nav-shell')),
  );

  expect(hudRect.top, greaterThanOrEqualTo(padding.top));
  expect(
    dockRect.bottom,
    lessThanOrEqualTo(size.height - padding.bottom + 0.5),
  );
  expect(navRect.bottom, lessThanOrEqualTo(size.height - padding.bottom + 0.5));
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
