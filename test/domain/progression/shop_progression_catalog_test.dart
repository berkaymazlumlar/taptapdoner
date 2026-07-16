import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/progression/shop_progression_catalog.dart';
import 'package:taptapdoner/domain/state/game_state.dart';

void main() {
  final config = EconomyConfig.standard();

  test('shop levels are unique and contiguous', () {
    final levelNumbers = ShopProgressionCatalog.levels
        .map((definition) => definition.level)
        .toList(growable: false);
    final ids = ShopProgressionCatalog.levels
        .map((definition) => definition.id)
        .toSet();

    expect(
      levelNumbers,
      List<int>.generate(levelNumbers.length, (index) => index + 1),
    );
    expect(ids, hasLength(ShopProgressionCatalog.levels.length));
  });

  test('every item unlock requirement references a real upgrade item', () {
    for (final shop in ShopProgressionCatalog.levels) {
      for (final requirement in shop.requirements.where(
        (item) => item.type == ShopLevelRequirementType.upgradeItemUnlocked,
      )) {
        final itemKeys = config
            .upgrade(requirement.upgradeId!)
            .items
            .map((item) => item.key);

        expect(
          itemKeys,
          contains(requirement.itemKey),
          reason:
              'Shop Lv. ${shop.level} references missing '
              '${requirement.upgradeId!.name}/${requirement.itemKey}.',
        );
      }
    }
  });

  test('a later eligible level cannot bypass an unmet earlier level', () {
    final initial = GameState.initial(config, nowUtc: DateTime.utc(2026));
    final lateGameWithoutUpgrades = initial.copyWith(
      cash: 1_000_000_000_000,
      lifetimeCash: 1_000_000_000_000,
      prestige: initial.prestige.copyWith(
        prestigeCount: 4,
        runCashEarned: 1_000_000_000_000,
      ),
    );

    expect(
      ShopProgressionCatalog.eligibleLevel(lateGameWithoutUpgrades, config),
      1,
    );
  });

  test('out-of-range saved levels resolve to the nearest catalog level', () {
    expect(ShopProgressionCatalog.byLevel(0).level, 1);
    expect(
      ShopProgressionCatalog.byLevel(999).level,
      ShopProgressionCatalog.levels.last.level,
    );
  });
}
