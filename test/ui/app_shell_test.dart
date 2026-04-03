import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/game/tap_tap_doner_game.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/overlays/game_shell_overlay.dart';
import 'package:taptapdoner/ui/pages/prestige_page.dart';
import 'package:taptapdoner/ui/pages/shop_page.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets('home bottom nav opens Shop as a bottom sheet', (tester) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForSheets(tester, controller);
    await tester.tap(find.byKey(const ValueKey('bottom-nav-shop-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('shop-sheet-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('prestige-sheet-root')), findsNothing);
  });

  testWidgets('home bottom nav opens Prestige as a bottom sheet', (
    tester,
  ) async {
    final controller = _controllerForApp(config, nowUtc);

    await _pumpAppForSheets(tester, controller);
    await tester.tap(find.byKey(const ValueKey('bottom-nav-prestige-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('prestige-sheet-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('shop-sheet-root')), findsNothing);
  });
}

Future<void> _pumpAppForSheets(
  WidgetTester tester,
  GameController controller,
) async {
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
            child: Builder(
              builder: (context) {
                final game = TapTapDonerGame(controller: controller);
                return Scaffold(
                  body: GameShellOverlay(
                    controller: controller,
                    game: game,
                    onOpenShop: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (sheetContext) => KeyedSubtree(
                          key: const ValueKey('shop-sheet-root'),
                          child: ShopPage(
                            controller: controller,
                            onOpenKitchen: () =>
                                Navigator.of(sheetContext).maybePop(),
                            onOpenPrestige: () =>
                                Navigator.of(sheetContext).maybePop(),
                            onBack: () => Navigator.of(sheetContext).maybePop(),
                          ),
                        ),
                      );
                    },
                    onOpenPrestige: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (sheetContext) => KeyedSubtree(
                          key: const ValueKey('prestige-sheet-root'),
                          child: PrestigePage(
                            controller: controller,
                            onOpenKitchen: () =>
                                Navigator.of(sheetContext).maybePop(),
                            onOpenShop: () =>
                                Navigator.of(sheetContext).maybePop(),
                            onBack: () => Navigator.of(sheetContext).maybePop(),
                            onPrestigeApplied: () async {
                              await Navigator.of(sheetContext).maybePop();
                            },
                          ),
                        ),
                      );
                    },
                    onOpenSettings: () {},
                  ),
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

GameController _controllerForApp(EconomyConfig config, DateTime nowUtc) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
  )..hydrate(GameState.initial(config, nowUtc: nowUtc));
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
