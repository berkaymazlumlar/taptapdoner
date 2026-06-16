import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/overlays/combo_badge.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets('combo multiplier grows and turns gold at the top tier', (
    tester,
  ) async {
    final controller = _controller(
      config,
      nowUtc,
      state: _comboState(config, nowUtc, currentCombo: 10, maxCombo: 10),
    );

    await tester.pumpWidget(
      _SizedHost(
        size: const Size(390, 844),
        child: _ComboBadgeHost(controller: controller),
      ),
    );
    await tester.pump();

    final lowMultiplier = tester.widget<Text>(
      find.byKey(const ValueKey('tap-zone-combo-badge-multiplier')),
    );
    final lowLabel = tester.widget<Text>(
      find.byKey(const ValueKey('tap-zone-combo-badge-label')),
    );

    expect(
      tester.widget(find.byKey(const ValueKey('tap-zone-combo-badge'))),
      isA<SizedBox>(),
    );
    expect(lowLabel.data, 'FAST COMBO');
    expect(lowMultiplier.style?.fontFamily, DonerTypography.displayFontFamily);
    expect(lowMultiplier.style?.color, isNot(DonerColors.goldBright));
    expect(lowMultiplier.style?.shadows, isNull);
    expect(lowLabel.style?.shadows, isNull);
    expect(find.byType(ImageFiltered), findsWidgets);
    expect(
      lowMultiplier.style!.fontSize!,
      greaterThan(lowLabel.style!.fontSize!),
    );

    await tester.pump(const Duration(milliseconds: 180));
    final animatedLowMultiplier = tester.widget<Text>(
      find.byKey(const ValueKey('tap-zone-combo-badge-multiplier')),
    );
    expect(
      animatedLowMultiplier.style?.color,
      isNot(lowMultiplier.style?.color),
    );

    controller.hydrate(
      _comboState(config, nowUtc, currentCombo: 100, maxCombo: 100),
    );
    await tester.pump();

    final highMultiplier = tester.widget<Text>(
      find.byKey(const ValueKey('tap-zone-combo-badge-multiplier')),
    );
    final highLabel = tester.widget<Text>(
      find.byKey(const ValueKey('tap-zone-combo-badge-label')),
    );

    expect(highLabel.data, 'LEGENDARY COMBO');
    expect(highMultiplier.style?.color, isNot(lowMultiplier.style?.color));
    expect(
      highMultiplier.style!.fontSize!,
      greaterThan(lowMultiplier.style!.fontSize!),
    );
  });

  testWidgets('combo badge pulses when multiplier increases', (tester) async {
    final controller = _controller(
      config,
      nowUtc,
      state: _comboState(config, nowUtc, currentCombo: 10, maxCombo: 10),
    );

    await tester.pumpWidget(
      _SizedHost(
        size: const Size(390, 844),
        child: _ComboBadgeHost(controller: controller),
      ),
    );
    await tester.pump();

    expect(_comboScale(tester), closeTo(1.0, 0.001));

    controller.hydrate(
      _comboState(config, nowUtc, currentCombo: 20, maxCombo: 20),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));

    expect(_comboScale(tester), greaterThan(1.02));

    await tester.pump(const Duration(milliseconds: 360));
    expect(_comboScale(tester), closeTo(1.0, 0.001));
  });

  testWidgets('combo badge idly jitters while it is visible', (tester) async {
    final controller = _controller(
      config,
      nowUtc,
      state: _comboState(config, nowUtc, currentCombo: 20, maxCombo: 20),
    );

    await tester.pumpWidget(
      _SizedHost(
        size: const Size(390, 844),
        child: _ComboBadgeHost(controller: controller),
      ),
    );
    await tester.pump();

    final firstOffset = _comboIdleOffset(tester);
    await tester.pump(const Duration(milliseconds: 120));
    final nextOffset = _comboIdleOffset(tester);

    expect((nextOffset - firstOffset).distance, greaterThan(0.1));
  });
}

double _comboScale(WidgetTester tester) {
  final badge = tester.widget<Transform>(
    find.byKey(const ValueKey('tap-zone-combo-badge-scale')),
  );
  return badge.transform.getMaxScaleOnAxis();
}

Offset _comboIdleOffset(WidgetTester tester) {
  final badge = tester.widget<Transform>(
    find.byKey(const ValueKey('tap-zone-combo-badge-idle')),
  );
  final translation = badge.transform.getTranslation();
  return Offset(translation.x, translation.y);
}

GameState _comboState(
  EconomyConfig config,
  DateTime nowUtc, {
  required int currentCombo,
  required int maxCombo,
}) {
  return GameState.initial(config, nowUtc: nowUtc).copyWith(
    milestones: const MilestoneState(unlockedFeatureKeys: {'combo'}),
    stats: GameStatsState(
      currentCombo: currentCombo,
      maxCombo: maxCombo,
      lastTapAtUtc: nowUtc,
    ),
  );
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

class _ComboBadgeHost extends StatelessWidget {
  const _ComboBadgeHost({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<ActivePlaySnapshot>(
        valueListenable: controller.activePlaySnapshotListenable,
        builder: (context, snapshot, _) {
          return ComboBadge(snapshot: snapshot, scale: 1);
        },
      ),
    );
  }
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
