import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/l10n/locale_case.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/overlays/offline_reward_overlay.dart';
import 'package:taptapdoner/ui/overlays/prestige_overlay.dart';
import 'package:taptapdoner/ui/overlays/settings_overlay.dart';
import 'package:taptapdoner/ui/overlays/shop_overlay.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);
  const size = Size(320, 640);
  final locales = <String>['en', 'tr'];

  for (final localeCode in locales) {
    final locale = Locale(localeCode);
    final strings = AppStrings(locale);

    testWidgets('shop modal fits compact width in $localeCode', (tester) async {
      final controller = _controller(
        config,
        nowUtc: nowUtc,
        localeCode: localeCode,
      );
      await _pumpModal(
        tester,
        size: size,
        locale: locale,
        child: ShopOverlay(controller: controller, onClose: () {}),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(strings.shopTitle), findsWidgets);
      await _expectPanelFits(tester, 'shop-modal-panel', size);
    });

    testWidgets('shop modal builds lower rows in $localeCode', (tester) async {
      const tallSize = Size(320, 6000);
      final controller = _controller(
        config,
        nowUtc: nowUtc,
        localeCode: localeCode,
      );
      await _pumpModal(
        tester,
        size: tallSize,
        locale: locale,
        child: ShopOverlay(controller: controller, onClose: () {}),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('shop-station-card-donerSpit')),
        findsNothing,
      );
      expect(
        find.byKey(
          ValueKey('shop-upgrade-card-${controller.upgrades.last.id.key}'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(strings.upgradeName(controller.upgrades.last.id)),
        findsWidgets,
      );
      await _expectPanelFits(tester, 'shop-modal-panel', tallSize);
    });

    testWidgets('prestige modal fits compact width in $localeCode', (
      tester,
    ) async {
      await _pumpModal(
        tester,
        size: size,
        locale: locale,
        child: PrestigeOverlay(
          controller: _controller(
            config,
            nowUtc: nowUtc,
            localeCode: localeCode,
          ),
          onClose: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(strings.prestigeTitle), findsWidgets);
      await _expectPanelFits(tester, 'prestige-modal-panel', size);
    });

    testWidgets('settings page fits compact width in $localeCode', (
      tester,
    ) async {
      await _pumpModal(
        tester,
        size: size,
        locale: locale,
        child: SettingsOverlay(
          controller: _controller(
            config,
            nowUtc: nowUtc,
            localeCode: localeCode,
          ),
          onClose: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(strings.settingsTitle), findsWidgets);
      expect(find.text(strings.englishLabel), findsWidgets);
      expect(find.text(strings.turkishLabel), findsWidgets);
      await _expectPanelFits(tester, 'settings-page-root', size);
    });

    testWidgets('offline reward popup fits compact width in $localeCode', (
      tester,
    ) async {
      final controller = _controller(
        config,
        nowUtc: nowUtc,
        localeCode: localeCode,
        adService: const _AvailableRewardedAdService(),
      );
      await _pumpModal(
        tester,
        size: size,
        locale: locale,
        child: OfflineRewardOverlay(controller: controller),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text(localeUpperCase(strings.offlineTitle, strings.locale)),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey('offline-reward-stat-row')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('offline-reward-double-amount-badge')),
        findsOneWidget,
      );
      await _expectPanelFits(tester, 'offline-reward-popup-panel', size);
      await _expectPanelCentered(tester, 'offline-reward-popup-panel', size);
    });

    testWidgets('offline reward popup shows ad preview copy in $localeCode', (
      tester,
    ) async {
      final controller = _controller(
        config,
        nowUtc: nowUtc,
        localeCode: localeCode,
      );
      await _pumpModal(
        tester,
        size: size,
        locale: locale,
        child: OfflineRewardOverlay(controller: controller),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text(localeUpperCase(strings.offlineTitle, strings.locale)),
        findsWidgets,
      );
      expect(
        find.text(
          localeUpperCase(strings.offlineAdPreviewLabel, strings.locale),
        ),
        findsWidgets,
      );
      await _expectPanelFits(tester, 'offline-reward-popup-panel', size);
      await _expectPanelCentered(tester, 'offline-reward-popup-panel', size);
    });
  }
}

Future<void> _pumpModal(
  WidgetTester tester, {
  required Size size,
  required Locale locale,
  required Widget child,
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
      builder: (context, _) {
        return MaterialApp(
          locale: locale,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: AppStrings.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(size: size, padding: EdgeInsets.zero),
            child: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectPanelFits(
  WidgetTester tester,
  String key,
  Size size,
) async {
  final rect = tester.getRect(find.byKey(ValueKey(key)));
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(size.width + 0.5));
  expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
}

Future<void> _expectPanelCentered(
  WidgetTester tester,
  String key,
  Size size,
) async {
  final rect = tester.getRect(find.byKey(ValueKey(key)));
  expect(rect.center.dx, closeTo(size.width / 2, 1));
  expect(rect.center.dy, closeTo(size.height / 2, 1));
}

GameController _controller(
  EconomyConfig config, {
  required DateTime nowUtc,
  required String localeCode,
  RewardedAdService adService = const NoopRewardedAdService(),
}) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: adService,
    clock: () => nowUtc,
  )..hydrate(
    GameState.initial(
      config,
      nowUtc: nowUtc,
      localeCode: localeCode,
    ).copyWith(pendingOfflineCash: 2500),
  );
}

class _AvailableRewardedAdService implements RewardedAdService {
  const _AvailableRewardedAdService();

  @override
  bool get isAvailable => true;

  @override
  Future<RewardOutcome> showOfflineRewardDouble() async {
    return RewardOutcome.declined;
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
