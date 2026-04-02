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

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets('rush aura grows when rush mode starts', (tester) async {
    final controller = _controller(config, nowUtc);
    final game = TapTapDonerGame(controller: controller);

    await tester.pumpWidget(
      _SizedHost(
        size: const Size(390, 844),
        child: TapZoneOverlay(controller: controller, game: game),
      ),
    );
    await tester.pumpAndSettle();

    expect(_auraScale(tester), closeTo(1.0, 0.001));

    await controller.startRush();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(_auraScale(tester), greaterThan(1.05));
  });
}

double _auraScale(WidgetTester tester) {
  final aura = tester.widget<Transform>(
    find.byKey(const ValueKey('tap-zone-flame-aura')),
  );
  return aura.transform.getMaxScaleOnAxis();
}

GameController _controller(EconomyConfig config, DateTime nowUtc) {
  return GameController(
    config: config,
    saveRepository: _MemorySaveRepository(),
    adService: const NoopRewardedAdService(),
    clock: () => nowUtc,
  )..hydrate(GameState.initial(config, nowUtc: nowUtc));
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
