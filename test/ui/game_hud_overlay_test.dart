import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/overlays/game_hud_overlay.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets('game hud shell keeps outer edges transparent and tinted', (
    tester,
  ) async {
    final controller = GameController(
      config: config,
      saveRepository: _MemorySaveRepository(),
      adService: const NoopRewardedAdService(),
      clock: () => nowUtc,
    )..hydrate(GameState.initial(config, nowUtc: nowUtc));

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: AppStrings.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: GameHudOverlay(
                controller: controller,
                onOpenGoals: () {},
                onOpenSettings: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NAKİT'), findsOneWidget);

    final shellFinder = find.byKey(const ValueKey('game-hud-shell-decoration'));
    final shell = tester.widget<DecoratedBox>(shellFinder);
    final shellRect = tester.getRect(shellFinder);
    final decoration = shell.decoration as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;

    expect(shellRect.left, closeTo(0, 0.5));
    expect(shellRect.right, closeTo(390, 0.5));
    expect(gradient.colors.every((color) => color.a < 1), isTrue);
  });
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
