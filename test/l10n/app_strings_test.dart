import 'package:flutter_test/flutter_test.dart';
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
  });
}
