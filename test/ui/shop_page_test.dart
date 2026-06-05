import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
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
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('shop-upgrade-card-knife')),
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

  testWidgets('shop page renders all six upgrade track cards', (tester) async {
    final controller = _controller(config, nowUtc);

    await _pumpShopPage(
      tester,
      controller: controller,
      size: const Size(390, 844),
      onOpenKitchen: () {},
      onOpenPrestige: () {},
    );

    for (final upgrade in controller.upgrades) {
      expect(
        find.byKey(ValueKey('shop-upgrade-card-${upgrade.id.key}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('normal upgrade purchase increments the current item level', (
    tester,
  ) async {
    final controller = _controller(config, nowUtc);

    await _pumpShopPage(
      tester,
      controller: controller,
      size: const Size(390, 844),
      onOpenKitchen: () {},
      onOpenPrestige: () {},
    );

    final button = find.byKey(const ValueKey('shop-upgrade-button-knife'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(controller.state.upgrade(UpgradeId.knife).itemIndex, 0);
    expect(controller.state.upgrade(UpgradeId.knife).level, 2);
  });

  testWidgets(
    'level twenty-five upgrade shows next item preview and feedback',
    (tester) async {
      final base = GameState.initial(config, nowUtc: nowUtc);
      final controller = _controller(
        config,
        nowUtc,
        state: base.copyWith(
          cash: 10000,
          lifetimeCash: 10000,
          upgrades: {
            ...base.upgrades,
            UpgradeId.knife: const UpgradeState(
              id: UpgradeId.knife,
              itemIndex: 0,
              level: 25,
            ),
          },
        ),
      );

      await _pumpShopPage(
        tester,
        controller: controller,
        size: const Size(390, 844),
        onOpenKitchen: () {},
        onOpenPrestige: () {},
      );

      expect(
        find.byKey(const ValueKey('shop-upgrade-next-item-knife')),
        findsOneWidget,
      );
      expect(find.text('Sharp Knife Lv. 1'), findsWidgets);

      final button = find.byKey(const ValueKey('shop-upgrade-button-knife'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(controller.state.upgrade(UpgradeId.knife).itemIndex, 1);
      expect(controller.state.upgrade(UpgradeId.knife).level, 1);
      expect(find.text('New Equipment Unlocked!'), findsOneWidget);
      expect(find.text('Rusty Knife -> Sharp Knife'), findsOneWidget);
    },
  );

  testWidgets('final item at level twenty-five renders max state', (
    tester,
  ) async {
    final base = GameState.initial(config, nowUtc: nowUtc);
    final knife = config.upgrade(UpgradeId.knife);
    final controller = _controller(
      config,
      nowUtc,
      state: base.copyWith(
        cash: 1000000,
        lifetimeCash: 1000000,
        upgrades: {
          ...base.upgrades,
          UpgradeId.knife: UpgradeState(
            id: UpgradeId.knife,
            itemIndex: knife.items.length - 1,
            level: UpgradeDefinition.maxItemLevel,
          ),
        },
      ),
    );

    await _pumpShopPage(
      tester,
      controller: controller,
      size: const Size(390, 844),
      onOpenKitchen: () {},
      onOpenPrestige: () {},
    );

    expect(
      find.byKey(const ValueKey('shop-upgrade-max-knife')),
      findsOneWidget,
    );
    expect(find.text('MAX'), findsOneWidget);
  });

  testWidgets('upgrade button is inactive when cash is insufficient', (
    tester,
  ) async {
    final base = GameState.initial(config, nowUtc: nowUtc);
    final controller = _controller(
      config,
      nowUtc,
      state: base.copyWith(cash: 0, lifetimeCash: 0),
    );

    await _pumpShopPage(
      tester,
      controller: controller,
      size: const Size(390, 844),
      onOpenKitchen: () {},
      onOpenPrestige: () {},
    );

    final button = find.byKey(const ValueKey('shop-upgrade-button-knife'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('NEED CASH'), findsWidgets);
    expect(controller.state.upgrade(UpgradeId.knife).level, 1);
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
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          locale: const Locale('en'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: AppStrings.localizationsDelegates,
          home: Scaffold(
            body: MediaQuery(
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
  GameState? state,
}) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
  )..hydrate(
    state ??
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
