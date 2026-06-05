import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/overlays/tap_zone_overlay.dart';
import 'package:taptapdoner/ui/theme/ui_asset_paths.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets('tap zone spawns a falling slice without blocking taps', (
    tester,
  ) async {
    final controller = _controller(config, nowUtc);
    final game = TapTapDonerGame(controller: controller);

    await tester.pumpWidget(
      _SizedHost(
        size: const Size(390, 844),
        child: TapZoneOverlay(controller: controller, game: game),
      ),
    );
    await tester.pumpAndSettle();

    final squareRect = tester.getRect(
      find.byKey(const ValueKey('tap-zone-square')),
    );
    final targetRect = tester.getRect(
      find.byKey(const ValueKey('tap-zone-target')),
    );
    final calloutRect = tester.getRect(
      find.byKey(const ValueKey('tap-zone-callout')),
    );

    expect(squareRect.width, closeTo(squareRect.height, 0.5));
    expect(squareRect.width, closeTo(256, 0.5));
    expect(targetRect.width, greaterThan(squareRect.width));
    expect(targetRect.height, greaterThan(squareRect.height));
    expect(targetRect.top, lessThan(squareRect.top));
    expect(targetRect.bottom, greaterThan(squareRect.bottom));
    expect(calloutRect.center.dx, closeTo(squareRect.center.dx, 14));
    expect(calloutRect.center.dy, closeTo(squareRect.center.dy, 14));
    final calloutImage = tester.widget<Image>(
      find.byKey(const ValueKey('tap-zone-callout')),
    );
    expect(calloutImage.image, isA<ResizeImage>());
    expect(
      (calloutImage.image as ResizeImage).imageProvider,
      const AssetImage(UiAssetPaths.tapDoner),
    );

    final initialCash = controller.state.cash;
    final topTapPosition = Offset(targetRect.center.dx, targetRect.top + 12);
    await tester.tapAt(topTapPosition);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));

    expect(controller.state.cash, greaterThan(initialCash));
    expect(find.byKey(const ValueKey('tap-zone-cash-splash')), findsOneWidget);
    expect(find.textContaining('₵'), findsWidgets);
    final firstCashSplashRect = tester.getRect(
      find.byKey(const ValueKey('tap-zone-cash-splash-0')),
    );
    expect(firstCashSplashRect.center.dx, greaterThan(topTapPosition.dx));
    expect(firstCashSplashRect.top, lessThanOrEqualTo(topTapPosition.dy));
    expect(
      find.byKey(const ValueKey('tap-zone-falling-slice-0')),
      findsOneWidget,
    );

    final cashAfterFirstTap = controller.state.cash;
    final bottomTapPosition = Offset(
      targetRect.center.dx,
      targetRect.bottom - 12,
    );
    await tester.tapAt(bottomTapPosition);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));

    expect(controller.state.cash, greaterThan(cashAfterFirstTap));
    final secondCashSplashRect = tester.getRect(
      find.byKey(const ValueKey('tap-zone-cash-splash-1')),
    );
    expect(secondCashSplashRect.center.dx, greaterThan(bottomTapPosition.dx));
    expect(secondCashSplashRect.top, lessThanOrEqualTo(bottomTapPosition.dy));
    expect(
      find.byKey(const ValueKey('tap-zone-falling-slice-1')),
      findsOneWidget,
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tap-zone-falling-slice-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('tap-zone-falling-slice-1')),
      findsNothing,
    );
  });

  testWidgets('tap zone cuts on contact even when the pointer moves', (
    tester,
  ) async {
    final controller = _controller(config, nowUtc);
    final game = TapTapDonerGame(controller: controller);

    await tester.pumpWidget(
      _SizedHost(
        size: const Size(390, 844),
        child: TapZoneOverlay(controller: controller, game: game),
      ),
    );
    await tester.pumpAndSettle();

    final targetRect = tester.getRect(
      find.byKey(const ValueKey('tap-zone-target')),
    );
    final initialCash = controller.state.cash;

    final gesture = await tester.startGesture(targetRect.center);
    await tester.pump();
    await gesture.moveBy(const Offset(36, 18));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 130));

    expect(controller.state.cash, greaterThan(initialCash));
    expect(
      find.byKey(const ValueKey('tap-zone-falling-slice-0')),
      findsOneWidget,
    );

    await tester.pumpAndSettle();
  });
}

GameController _controller(EconomyConfig config, DateTime nowUtc) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
  )..hydrate(
    GameState.initial(config, nowUtc: nowUtc).copyWith(pendingOfflineCash: 250),
  );
}

class _SizedHost extends StatelessWidget {
  const _SizedHost({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: AppStrings.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(size: size, padding: EdgeInsets.zero),
        child: Scaffold(
          body: SizedBox(width: size.width, height: size.height, child: child),
        ),
      ),
    );
  }
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
