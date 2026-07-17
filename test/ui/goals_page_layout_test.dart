import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/pages/goals_page.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);
  final locales = <Locale>[const Locale('en'), const Locale('tr')];
  const size = Size(320, 640);

  for (final locale in locales) {
    testWidgets(
      'chest page buttons fit compact width in ${locale.languageCode}',
      (tester) async {
        final controller = _controller(
          config,
          nowUtc: nowUtc,
          localeCode: locale.languageCode,
        );

        await _pumpGoalsPage(
          tester,
          size: size,
          locale: locale,
          child: ChestPage(controller: controller),
        );

        expect(tester.takeException(), isNull);

        for (final chestKey in const [
          'goals-open-small-chest',
          'goals-open-master-chest',
          'goals-open-gold-chest',
        ]) {
          final rect = tester.getRect(find.byKey(ValueKey(chestKey)));
          expect(rect.width, greaterThanOrEqualTo(88));
          expect(rect.height, greaterThanOrEqualTo(40));
          expect(rect.right, lessThanOrEqualTo(size.width));
        }
      },
    );
  }

  testWidgets('goals page stays achievements-only without expansion', (
    tester,
  ) async {
    const tallSize = Size(320, 1600);
    final controller = _controller(config, nowUtc: nowUtc, localeCode: 'en');

    await _pumpGoalsPage(
      tester,
      size: tallSize,
      locale: const Locale('en'),
      child: GoalsPage(controller: controller),
    );

    expect(find.text('First Cut'), findsOneWidget);
    expect(find.text('Daily Goals'), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('chest details expose weighted rewards and staff goal sources', (
    tester,
  ) async {
    const discoverySize = Size(320, 3000);
    final controller = _controller(config, nowUtc: nowUtc, localeCode: 'en');

    await _pumpGoalsPage(
      tester,
      size: discoverySize,
      locale: const Locale('en'),
      child: ChestPage(controller: controller),
    );

    final detailsButton = find.byKey(
      const ValueKey('goals-chest-details-staff'),
    );
    await tester.tap(detailsButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('goals-chest-contents-staff')),
      findsOneWidget,
    );
    expect(find.text('Apprentice Ali • 5 master cards'), findsOneWidget);
    expect(find.text('%22'), findsOneWidget);
    expect(
      find.text(
        'Source: Daily 50 reputation, daily 3 branch levels, weekly 50 customers, and weekly branch milestone goals.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('master cards show chest sources derived from drop tables', (
    tester,
  ) async {
    const discoverySize = Size(320, 3000);
    final controller = _controller(config, nowUtc: nowUtc, localeCode: 'en');

    await _pumpGoalsPage(
      tester,
      size: discoverySize,
      locale: const Locale('en'),
      child: CollectionPage(controller: controller),
    );

    final staffTab = find.text('Masters');
    await tester.tap(staffTab);
    await tester.pumpAndSettle();

    final apprenticeSource = find.byKey(
      const ValueKey('staff-drop-sources-staff_apprentice'),
    );
    expect(apprenticeSource, findsOneWidget);
    final sourceText = tester.widget<Text>(apprenticeSource).data!;
    expect(sourceText, contains('Small Chest (%9.6)'));
    expect(sourceText, contains('Chef Chest (%22)'));
  });

  test('chest reward snapshots localize Turkish item names', () async {
    final controller = _controller(
      config,
      nowUtc: nowUtc,
      localeCode: 'tr',
      random: const _FixedRandom(0),
      chestInventory: const ChestInventoryState(counts: {ChestType.staff: 1}),
    );

    final reward = await controller.openChest(ChestType.staff);

    expect(reward?.label, 'Çırak Ali x5');
  });

  testWidgets('opening a chest swaps the row for a roulette bar', (
    tester,
  ) async {
    const tallSize = Size(320, 1600);
    final controller = _controller(
      config,
      nowUtc: nowUtc,
      localeCode: 'en',
      random: const _FixedRandom(0),
      chestInventory: const ChestInventoryState(counts: {ChestType.small: 1}),
    );

    await _pumpGoalsPage(
      tester,
      size: tallSize,
      locale: const Locale('en'),
      child: ChestPage(controller: controller),
    );

    final idleHeight = tester
        .getRect(find.byKey(const ValueKey('goals-chest-idle-small')))
        .height;
    expect(idleHeight, closeTo(58, 0.1));

    await tester.tap(find.byKey(const ValueKey('goals-open-small-chest')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('goals-chest-roulette-small')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('goals-open-small-chest')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey('goals-chest-roulette-small')),
      findsOneWidget,
    );
    final rouletteHeight = tester
        .getRect(find.byKey(const ValueKey('goals-chest-roulette-small')))
        .height;
    expect(rouletteHeight, closeTo(idleHeight, 0.1));
    expect(find.byKey(const ValueKey('goals-open-small-chest')), findsNothing);
    expect(
      find.byKey(const ValueKey('goals-chest-roulette-result-small')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 5500));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('goals-chest-roulette-result-small')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('goals-chest-roulette-small')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey('goals-chest-roulette-small')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('chest-reward-reveal')), findsNothing);
    expect(find.textContaining('Small Chest:'), findsNothing);
  });
}

Future<void> _pumpGoalsPage(
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
            data: MediaQueryData(
              size: size,
              padding: EdgeInsets.zero,
              textScaler: const TextScaler.linear(1.2),
            ),
            child: Scaffold(body: child),
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

GameController _controller(
  EconomyConfig config, {
  required DateTime nowUtc,
  required String localeCode,
  math.Random? random,
  ChestInventoryState chestInventory = const ChestInventoryState(),
}) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
    random: random,
  )..hydrate(
    GameState.initial(
      config,
      nowUtc: nowUtc,
      localeCode: localeCode,
    ).copyWith(chestInventory: chestInventory),
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

class _FixedRandom implements math.Random {
  const _FixedRandom(this.value);

  final double value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => (value * max).floor().clamp(0, max - 1);
}
