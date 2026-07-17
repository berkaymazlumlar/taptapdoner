import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/progression/collection2_catalog.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/l10n/app_strings.dart';

void main() {
  group('Turkish localization', () {
    final strings = AppStrings.forLanguageCode('tr');

    test('uses Turkish characters for core upgrade names', () {
      expect(strings.shopLevelLabel, 'Dükkân Seviyesi');
      expect(strings.shopLevelName('street_stand'), 'Sokak Tezgâhı');
      expect(
        strings.upgradeItemName(UpgradeId.knife, 'rusty_knife'),
        'Paslı Bıçak',
      );
      expect(
        strings.upgradeItemName(UpgradeId.knife, 'sharp_knife'),
        'Keskin Bıçak',
      );
      expect(
        strings.upgradeItemName(UpgradeId.oven, 'small_oven'),
        'Küçük Fırın',
      );
      expect(strings.upgradeItemName(UpgradeId.staff, 'apprentice'), 'Çırak');
    });

    test('localizes every shop progression level', () {
      const ids = <String>[
        'street_stand',
        'small_buffet',
        'neighborhood_doner',
        'busy_street_doner',
        'mall_doner',
        'luxury_restaurant',
        'doner_chain',
        'city_brand',
        'national_chain',
        'global_doner_empire',
        'galactic_doner_center',
        'infinite_doner_universe',
      ];

      for (final id in ids) {
        expect(strings.shopLevelName(id), isNot('shop.$id.name'));
        expect(strings.shopUnlockLabel(id), isNot('shop.$id.unlock'));
      }
    });

    test('localizes every collection item that can drop from chests', () {
      final items = <String, String>{
        for (final item in Collection2Catalog.customerCards) item.id: item.name,
        for (final item in Collection2Catalog.masterCards) item.id: item.name,
        for (final item in Collection2Catalog.decorItems) item.id: item.name,
        for (final item in Collection2Catalog.momentCards) item.id: item.name,
      };

      for (final item in items.entries) {
        expect(
          strings.collection2ItemName(item.key, fallback: item.value),
          isNot(item.value),
          reason: 'Missing Turkish collection name for ${item.key}',
        );
      }

      expect(
        strings.collection2ItemName(
          'staff_apprentice',
          fallback: 'Apprentice Card',
        ),
        'Çırak Ali',
      );
    });
  });
}
