import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

abstract final class CollectionCatalog {
  static List<CollectionItem> itemsForConfig(EconomyConfig config) {
    return [
      for (final definition in config.upgrades)
        for (final item in definition.items)
          CollectionItem(
            id: collectionItemId(definition.id, item.key),
            category: _categoryForUpgrade(definition.id),
            name: item.key,
            iconKey: item.key,
            rarity: _rarityForTier(item.tier),
            unlockCondition: '${definition.id.key}:${item.key}',
            permanentBonus: _bonusFor(definition.id, item.tier),
          ),
    ];
  }

  static Map<String, CollectionItem> itemMapForConfig(EconomyConfig config) {
    return Map<String, CollectionItem>.unmodifiable({
      for (final item in itemsForConfig(config)) item.id: item,
    });
  }

  static CollectionBonusTotals bonusTotalsFor({
    required EconomyConfig config,
    required Set<String> claimedBonusItemIds,
  }) {
    final items = itemMapForConfig(config);
    var tap = 0.0;
    var passive = 0.0;
    var global = 0.0;

    for (final id in claimedBonusItemIds) {
      final bonus = items[id]?.permanentBonus;
      if (bonus == null) {
        continue;
      }
      switch (bonus.type) {
        case PermanentBonusType.tap:
          tap += bonus.percent;
        case PermanentBonusType.passive:
          passive += bonus.percent;
        case PermanentBonusType.global:
          global += bonus.percent;
      }
    }

    return CollectionBonusTotals(
      tapBonusPercent: tap,
      passiveBonusPercent: passive,
      globalBonusPercent: global,
    );
  }

  static CollectionCategory _categoryForUpgrade(UpgradeId id) {
    return switch (id) {
      UpgradeId.knife => CollectionCategory.knife,
      UpgradeId.staff => CollectionCategory.staff,
      UpgradeId.oven => CollectionCategory.oven,
      UpgradeId.menu => CollectionCategory.menu,
      UpgradeId.turbo => CollectionCategory.turbo,
      UpgradeId.offline => CollectionCategory.offline,
    };
  }

  static Rarity _rarityForTier(int tier) {
    if (tier >= 10) {
      return Rarity.mythic;
    }
    if (tier >= 7) {
      return Rarity.legendary;
    }
    if (tier >= 5) {
      return Rarity.epic;
    }
    if (tier >= 3) {
      return Rarity.rare;
    }
    return Rarity.common;
  }

  static PermanentBonus _bonusFor(UpgradeId id, int tier) {
    final percent = tier >= 5 ? 0.02 : 0.01;
    return switch (id) {
      UpgradeId.knife => PermanentBonus(
        type: PermanentBonusType.tap,
        percent: percent,
      ),
      UpgradeId.staff => PermanentBonus(
        type: PermanentBonusType.passive,
        percent: percent,
      ),
      UpgradeId.oven || UpgradeId.menu => PermanentBonus(
        type: PermanentBonusType.global,
        percent: percent,
      ),
      UpgradeId.turbo => PermanentBonus(
        type: PermanentBonusType.tap,
        percent: percent,
      ),
      UpgradeId.offline => PermanentBonus(
        type: PermanentBonusType.passive,
        percent: percent,
      ),
    };
  }
}
