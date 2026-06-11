import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
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
      'goals page chest buttons fit compact width in ${locale.languageCode}',
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
          child: GoalsPage(controller: controller),
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

  testWidgets('goals sections can collapse and expand', (tester) async {
    const tallSize = Size(320, 1600);
    final controller = _controller(config, nowUtc: nowUtc, localeCode: 'en');

    await _pumpGoalsPage(
      tester,
      size: tallSize,
      locale: const Locale('en'),
      child: GoalsPage(controller: controller),
    );

    expect(find.text('First Cut'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('goals-section-toggle-achievements')),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Cut'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('goals-section-toggle-achievements')),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Cut'), findsOneWidget);
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
}) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
  )..hydrate(GameState.initial(config, nowUtc: nowUtc, localeCode: localeCode));
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
