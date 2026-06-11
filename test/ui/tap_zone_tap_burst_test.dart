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
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets('tap burst amount uses display font styling', (tester) async {
    final controller = _controller(config, nowUtc);
    final game = TapTapDonerGame(controller: controller);

    await tester.pumpWidget(
      _SizedHost(
        size: const Size(390, 844),
        child: TapZoneOverlay(controller: controller, game: game),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(_tapZoneCenter(tester));
    await tester.pump();

    final fillText = tester.widget<Text>(
      find.byKey(const ValueKey('tap-zone-cash-splash-fill')),
    );

    expect(fillText.style?.fontFamily, DonerTypography.displayFontFamily);
    expect(fillText.style?.fontWeight, FontWeight.w900);

    await tester.pumpAndSettle(const Duration(milliseconds: 700));
  });

  testWidgets('critical tap burst pops in with lighter highlight', (
    tester,
  ) async {
    final controller = _controller(
      config,
      nowUtc,
      random: _FixedRandom(0),
      state: GameState.initial(config, nowUtc: nowUtc).copyWith(
        milestones: const MilestoneState(unlockedFeatureKeys: {'critical_cut'}),
      ),
    );
    final game = TapTapDonerGame(controller: controller);

    await tester.pumpWidget(
      _SizedHost(
        size: const Size(390, 844),
        child: TapZoneOverlay(controller: controller, game: game),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(_tapZoneCenter(tester));
    await tester.pump();

    final initialEntry = tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('tap-zone-cash-splash-critical-entry')),
    );
    final initialFillText = tester.widget<Text>(
      find.byKey(const ValueKey('tap-zone-cash-splash-fill')),
    );

    expect(initialEntry.scale, closeTo(0.58, 0.001));
    expect(initialFillText.style?.color, const Color(0xFFFFF6DD));

    await tester.pump();

    final risingEntry = tester.widget<AnimatedScale>(
      find.byKey(const ValueKey('tap-zone-cash-splash-critical-entry')),
    );

    expect(risingEntry.scale, 1);

    await tester.pumpAndSettle(const Duration(milliseconds: 700));
  });
}

Offset _tapZoneCenter(WidgetTester tester) {
  return tester.getCenter(find.byKey(const ValueKey('tap-zone-target')));
}

GameController _controller(
  EconomyConfig config,
  DateTime nowUtc, {
  math.Random? random,
  GameState? state,
}) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
    random: random,
  )..hydrate(state ?? GameState.initial(config, nowUtc: nowUtc));
}

class _FixedRandom implements math.Random {
  _FixedRandom(this.value);

  final double value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;
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
