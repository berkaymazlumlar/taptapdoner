import 'dart:math' as math;

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

const _maxSliceTravelAngleTangent = 0.5773502692; // tan(30deg)
const _tapBurstSpawnRightFactor = 0.23;
const _tapBurstMinLeftPaddingFactor = 0.28;
const _sliceSpawnDownFactor = 0.18;

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
    expect(
      find.byKey(const ValueKey('tap-zone-falling-slice-0')),
      findsOneWidget,
    );
    _expectSliceStartsBelowTap(tester, 0, topTapPosition, targetRect);
    await tester.pump(const Duration(milliseconds: 130));

    expect(controller.state.cash, greaterThan(initialCash));
    expect(find.byKey(const ValueKey('tap-zone-cash-splash')), findsOneWidget);
    expect(find.textContaining('₵'), findsWidgets);
    final firstCashSplashRect = tester.getRect(
      find.byKey(const ValueKey('tap-zone-cash-splash-0')),
    );
    expect(
      firstCashSplashRect.left,
      closeTo(
        topTapPosition.dx + (squareRect.width * _tapBurstSpawnRightFactor),
        1.0,
      ),
    );
    expect(firstCashSplashRect.center.dx, greaterThan(topTapPosition.dx));
    expect(
      firstCashSplashRect.top,
      greaterThanOrEqualTo(topTapPosition.dy - 4),
    );
    expect(firstCashSplashRect.top, lessThan(topTapPosition.dy + 48));
    await tester.pump(const Duration(milliseconds: 120));
    _expectDownwardSliceWithinAngle(tester, 0);

    final cashAfterFirstTap = controller.state.cash;
    final bottomTapPosition = Offset(
      targetRect.center.dx,
      targetRect.bottom - 12,
    );
    await tester.tapAt(bottomTapPosition);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('tap-zone-falling-slice-1')),
      findsOneWidget,
    );
    _expectSliceStartsBelowTap(tester, 1, bottomTapPosition, targetRect);
    await tester.pump(const Duration(milliseconds: 130));

    expect(controller.state.cash, greaterThan(cashAfterFirstTap));
    final secondCashSplashRect = tester.getRect(
      find.byKey(const ValueKey('tap-zone-cash-splash-1')),
    );
    expect(
      secondCashSplashRect.left,
      closeTo(
        bottomTapPosition.dx + (squareRect.width * _tapBurstSpawnRightFactor),
        1.0,
      ),
    );
    expect(secondCashSplashRect.center.dx, greaterThan(bottomTapPosition.dx));
    expect(
      secondCashSplashRect.top,
      greaterThanOrEqualTo(bottomTapPosition.dy - 4),
    );
    expect(secondCashSplashRect.top, lessThan(bottomTapPosition.dy + 48));
    await tester.pump(const Duration(milliseconds: 120));
    _expectDownwardSliceWithinAngle(tester, 1);

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

  testWidgets('tap zone ignores simultaneous multi-touch inputs', (
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

    final firstGesture = await tester.startGesture(
      targetRect.center,
      pointer: 1,
    );
    final secondGesture = await tester.startGesture(
      targetRect.center.translate(18, 0),
      pointer: 2,
    );
    await tester.pump();

    expect(controller.state.stats.tapCount, 1);
    expect(
      find.byKey(const ValueKey('tap-zone-falling-slice-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('tap-zone-falling-slice-1')),
      findsNothing,
    );

    await firstGesture.up();
    await secondGesture.up();
    await tester.pump(const Duration(milliseconds: 130));

    final thirdGesture = await tester.startGesture(
      targetRect.center,
      pointer: 3,
    );
    await tester.pump();
    await thirdGesture.up();
    await tester.pump(const Duration(milliseconds: 130));

    expect(controller.state.stats.tapCount, 2);

    await tester.pumpAndSettle();
  });

  testWidgets('tap burst keeps left padding near the tap zone edge', (
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
    final squareSize = tester
        .getSize(find.byKey(const ValueKey('tap-zone-square')))
        .width;
    final leftTapPosition = Offset(targetRect.left + 4, targetRect.center.dy);

    await tester.tapAt(leftTapPosition);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));

    final cashSplashRect = tester.getRect(
      find.byKey(const ValueKey('tap-zone-cash-splash-0')),
    );
    expect(
      cashSplashRect.left,
      greaterThanOrEqualTo(
        targetRect.left + (squareSize * _tapBurstMinLeftPaddingFactor) - 1,
      ),
    );

    await tester.pumpAndSettle();
  });

  testWidgets('tap zone keeps slice movement stable during rapid taps', (
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
    final tapPositions = [
      targetRect.center,
      targetRect.center.translate(-24, 18),
      targetRect.center.translate(22, -16),
      targetRect.center.translate(14, 28),
    ];

    for (var index = 0; index < 28; index += 1) {
      await tester.tapAt(tapPositions[index % tapPositions.length]);
    }

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));

    final sliceTransforms = _activeSliceTransforms(tester);
    expect(sliceTransforms, hasLength(14));
    for (final transform in sliceTransforms) {
      _expectDownwardTransformWithinAngle(transform);
    }

    await tester.pumpAndSettle();
  });
}

void _expectSliceStartsBelowTap(
  WidgetTester tester,
  int sliceId,
  Offset tapPosition,
  Rect targetRect,
) {
  final sliceRect = tester.getRect(
    find.byKey(ValueKey('tap-zone-falling-slice-$sliceId')),
  );
  final squareSize = tester
      .getSize(find.byKey(const ValueKey('tap-zone-square')))
      .width;
  final expectedOffset = math.min(
    squareSize * _sliceSpawnDownFactor,
    targetRect.bottom - tapPosition.dy,
  );

  expect(sliceRect.center.dy, closeTo(tapPosition.dy + expectedOffset, 1.0));
  expect(sliceRect.center.dy, greaterThan(tapPosition.dy));
}

void _expectDownwardSliceWithinAngle(WidgetTester tester, int sliceId) {
  final sliceTransform = tester.widget<Transform>(
    find.byKey(ValueKey('tap-zone-falling-slice-$sliceId')),
  );
  _expectDownwardTransformWithinAngle(sliceTransform);
}

List<Transform> _activeSliceTransforms(WidgetTester tester) {
  final sliceKeyPattern = RegExp(r'^tap-zone-falling-slice-\d+$');
  return tester
      .widgetList<Transform>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Transform &&
              widget.key is ValueKey<String> &&
              sliceKeyPattern.hasMatch((widget.key! as ValueKey<String>).value),
        ),
      )
      .toList(growable: false);
}

void _expectDownwardTransformWithinAngle(Transform sliceTransform) {
  final translation = sliceTransform.transform.getTranslation();

  expect(translation.y, greaterThan(0));
  expect(
    translation.x.abs(),
    lessThanOrEqualTo((translation.y * _maxSliceTravelAngleTangent) + 0.001),
  );
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
