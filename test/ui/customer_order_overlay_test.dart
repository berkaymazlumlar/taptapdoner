import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/customers/customer_order_models.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/overlays/customer_order_overlay.dart';

void main() {
  final config = EconomyConfig.standard();
  final nowUtc = DateTime.utc(2026, 4, 1, 12);

  testWidgets(
    'idle customer order overlay stays hidden until a customer arrives',
    (tester) async {
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
          locale: const Locale('en'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: AppStrings.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: CustomerOrderOverlay(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('customer-order-card')), findsNothing);
      expect(find.byKey(const ValueKey('customer-order-timer')), findsNothing);
      expect(find.text('Next customer'), findsNothing);
      expect(find.text('New orders show up here.'), findsNothing);
    },
  );

  testWidgets('active customer reward stays pinned to the card edge', (
    tester,
  ) async {
    final order = CustomerOrder(
      id: 'test_order',
      customerTypeId: CustomerOrderCatalog.regularCustomer,
      customerName: 'Regular Customer',
      title: 'Simple Order',
      description: 'Cut 2 doners.',
      objectiveType: OrderObjectiveType.tapCount,
      targetValue: 2,
      currentValue: 1,
      durationSeconds: 20,
      remainingSeconds: 20,
      rarity: OrderRarity.common,
      minShopLevel: 1,
      rewards: const [
        OrderReward(type: OrderRewardType.money, amount: 10),
        OrderReward(type: OrderRewardType.reputation, amount: 50),
      ],
    );
    final controller =
        GameController(
          config: config,
          saveRepository: _MemorySaveRepository(),
          adService: const NoopRewardedAdService(),
          clock: () => nowUtc,
        )..hydrate(
          GameState.initial(config, nowUtc: nowUtc).copyWith(
            customerOrders: CustomerSystemState.initial(nowUtc: nowUtc)
                .copyWith(
                  activeOrder: order,
                  lastSpawnTimeMillis: nowUtc.millisecondsSinceEpoch,
                ),
          ),
        );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: AppStrings.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: CustomerOrderOverlay(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('customer-order-card')),
    );
    final rewardRect = tester.getRect(
      find.byKey(const ValueKey('customer-order-reward')),
    );

    expect(find.textContaining('Reward:'), findsOneWidget);
    expect(rewardRect.right, closeTo(cardRect.right - 10, 12));
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
