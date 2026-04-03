import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/pages/shop_page.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets('shop page renders the warm bottom-sheet layout', (tester) async {
    final controller = _controller(config, nowUtc);

    await _pumpShopPage(
      tester,
      controller: controller,
      size: const Size(390, 844),
      onOpenKitchen: () {},
      onOpenPrestige: () {},
    );

    expect(find.byKey(const ValueKey('shop-sheet-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('shop-sheet-title')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('shop-station-card-donerSpit')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shop page stays stable on a narrow portrait viewport', (
    tester,
  ) async {
    final controller = _controller(config, nowUtc);

    await _pumpShopPage(
      tester,
      controller: controller,
      size: const Size(320, 640),
      onOpenKitchen: () {},
      onOpenPrestige: () {},
    );

    expect(find.byKey(const ValueKey('shop-sheet-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('shop-sheet-title')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('close button triggers the provided callback', (tester) async {
    final controller = _controller(config, nowUtc);
    var didClose = false;

    await _pumpShopPage(
      tester,
      controller: controller,
      size: const Size(390, 844),
      onOpenKitchen: () => didClose = true,
      onOpenPrestige: () {},
      onBack: () => didClose = true,
    );

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pump();

    expect(didClose, isTrue);
  });
}

Future<void> _pumpShopPage(
  WidgetTester tester, {
  required GameController controller,
  required Size size,
  required VoidCallback onOpenKitchen,
  required VoidCallback onOpenPrestige,
  VoidCallback? onBack,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

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
            data: MediaQueryData(size: size, padding: EdgeInsets.zero),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return ShopPage(
                  controller: controller,
                  onOpenKitchen: onOpenKitchen,
                  onOpenPrestige: onOpenPrestige,
                  onBack: onBack,
                );
              },
            ),
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

GameController _controller(EconomyConfig config, DateTime nowUtc) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
  )..hydrate(
    GameState.initial(
      config,
      nowUtc: nowUtc,
    ).copyWith(cash: 2000, lifetimeCash: 2000),
  );
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
