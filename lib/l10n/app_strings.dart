import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taptapdoner/domain/economy/number_units.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

class AppStrings {
  AppStrings(this.locale);

  AppStrings.forLanguageCode(String languageCode)
    : locale = Locale(languageCode);

  final Locale locale;

  static const delegate = _AppStringsDelegate();
  static const supportedLocales = [Locale('en'), Locale('tr')];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  bool get isTurkish => locale.languageCode == 'tr';

  String get appTitle => _value('appTitle');
  String get tapPrompt => _value('tapPrompt');
  String get cashLabel => _value('cashLabel');
  String get idleIncomeLabel => _value('idleIncomeLabel');
  String get reputationLabel => _value('reputationLabel');
  String get customerQueueTitle => _value('customerQueueTitle');
  String get customerQueueHint => _value('customerQueueHint');
  String get shopTitle => _value('shopTitle');
  String get shopLevelLabel => _value('shopLevelLabel');
  String get shopLevelUpTitle => _value('shopLevelUpTitle');
  String get shopUnlockedLabel => _value('shopUnlockedLabel');
  String get shopIncomeLabel => _value('shopIncomeLabel');
  String get shopNextLabel => _value('shopNextLabel');
  String get shopMaxLevelLabel => _value('shopMaxLevelLabel');
  String get upgradesTitle => _value('upgradesTitle');
  String get buyLabel => _value('buyLabel');
  String get boughtLabel => _value('boughtLabel');
  String get levelLabel => _value('levelLabel');
  String get currentEffectLabel => _value('currentEffectLabel');
  String get nextEffectLabel => _value('nextEffectLabel');
  String get nextItemLabel => _value('nextItemLabel');
  String get maxedLabel => _value('maxedLabel');
  String get upgradeTierLabel => _value('upgradeTierLabel');
  String get upgradeNextLevelLabel => _value('upgradeNextLevelLabel');
  String get upgradeNextTierLabel => _value('upgradeNextTierLabel');
  String get upgradeNextMilestoneLabel => _value('upgradeNextMilestoneLabel');
  String get upgradeNextItemPreviewLabel =>
      _value('upgradeNextItemPreviewLabel');
  String get upgradeCostLabel => _value('upgradeCostLabel');
  String get upgradeLevelUpAction => _value('upgradeLevelUpAction');
  String get upgradeTierUpAction => _value('upgradeTierUpAction');
  String get upgradeBuyTenAction => _value('upgradeBuyTenAction');
  String get upgradeBuyMaxAction => _value('upgradeBuyMaxAction');
  String get insufficientFundsLabel => _value('insufficientFundsLabel');
  String get upgradeMaxLevelLabel => _value('upgradeMaxLevelLabel');
  String get upgradeUnlockTitle => _value('upgradeUnlockTitle');
  String get milestoneUnlockTitle => _value('milestoneUnlockTitle');
  String get upgradeNewEffectLabel => _value('upgradeNewEffectLabel');
  String get closeLabel => _value('closeLabel');
  String get prestigeTitle => _value('prestigeTitle');
  String get prestigeConfirm => _value('prestigeConfirm');
  String get settingsTitle => _value('settingsTitle');
  String get settingsSubtitle => _value('settingsSubtitle');
  String get languageTitle => _value('languageTitle');
  String get preferencesTitle => _value('preferencesTitle');
  String get soundTitle => _value('soundTitle');
  String get hapticsTitle => _value('hapticsTitle');
  String get comingSoonLabel => _value('comingSoonLabel');
  String get englishLabel => _value('englishLabel');
  String get turkishLabel => _value('turkishLabel');
  String get offlineTitle => _value('offlineTitle');
  String get offlineSummaryTitle => _value('offlineSummaryTitle');
  String get offlineBaseRewardLabel => _value('offlineBaseRewardLabel');
  String get offlineDoubleRewardLabel => _value('offlineDoubleRewardLabel');
  String get offlineDoubleOfferTitle => _value('offlineDoubleOfferTitle');
  String get offlineAdPreviewLabel => _value('offlineAdPreviewLabel');
  String get watchAdDoubleLabel => _value('watchAdDoubleLabel');
  String get claimLabel => _value('claimLabel');
  String get claimDoubleLabel => _value('claimDoubleLabel');
  String get dismissLabel => _value('dismissLabel');
  String get adUnavailable => _value('adUnavailable');
  String get shopNavLabel => _value('shopNavLabel');
  String get prestigeNavLabel => _value('prestigeNavLabel');
  String get settingsNavLabel => _value('settingsNavLabel');
  String get lockedLabel => _value('lockedLabel');
  String get unlockedLabel => _value('unlockedLabel');
  String get soundSoonLabel => _value('soundSoonLabel');
  String get hapticsSoonLabel => _value('hapticsSoonLabel');
  String get prestigeHint => _value('prestigeHint');
  String get questLabel => _value('questLabel');
  String get questProgressLabel => _value('questProgressLabel');
  String get questRewardLabel => _value('questRewardLabel');
  String get questClaimLabel => _value('questClaimLabel');
  String get questCompletedLabel => _value('questCompletedLabel');
  String get questComboUnlockInfo => _value('questComboUnlockInfo');
  String get comboLabel => _value('comboLabel');
  String get criticalCutLabel => _value('criticalCutLabel');

  String comboTierLabel(double multiplier) {
    if (multiplier >= 4.0) {
      return _value('comboTierCosmic');
    }
    if (multiplier >= 3.0) {
      return _value('comboTierLegendary');
    }
    if (multiplier >= 2.0) {
      return _value('comboTierInsane');
    }
    if (multiplier >= 1.4) {
      return _value('comboTierFlaming');
    }
    if (multiplier >= 1.1) {
      return _value('comboTierFast');
    }
    return _value('comboTierSimple');
  }

  String offlineSummary(int hours) {
    return _template('offlineSummary', {'hours': hours.toString()});
  }

  String offlineAmount(String amount) {
    return _template('offlineAmount', {'amount': amount});
  }

  String offlineDoubleOfferBody(String amount) {
    return _template('offlineDoubleOfferBody', {'amount': amount});
  }

  String prestigeAvailable(int points) {
    return _template('prestigeAvailable', {'points': points.toString()});
  }

  String customerArrivalIn(String time) {
    return _template('customerArrivalIn', {'time': time});
  }

  String customerReputationLevel(int level) {
    return _template('customerReputationLevel', {'level': level.toString()});
  }

  String customerTypesUnlocked(int count) {
    return _template('customerTypesUnlocked', {'count': count.toString()});
  }

  String upgradeItemUnlocked(String itemName) {
    return _template('upgradeItemUnlocked', {'item': itemName});
  }

  String shopRunCashRequirement(Object amount) {
    return _template('shopRunCashRequirement', {
      'amount': formatNumberWithUnitNames(amount, locale: locale.languageCode),
    });
  }

  String shopUpgradeCountRequirement(String upgradeName, int count) {
    return _template('shopUpgradeCountRequirement', {
      'upgrade': upgradeName,
      'count': count.toString(),
    });
  }

  String shopUpgradeItemRequirement(String upgradeName, String itemName) {
    return _template('shopUpgradeItemRequirement', {
      'upgrade': upgradeName,
      'item': itemName,
    });
  }

  String shopPrestigeRequirement(int count) {
    return _template('shopPrestigeRequirement', {'count': count.toString()});
  }

  String shopLevelName(String id) => _value('shop.$id.name');

  String shopUnlockLabel(String id) => _value('shop.$id.unlock');

  String upgradeItemTransition(String previousItem, String nextItem) {
    return _template('upgradeItemTransition', {
      'previous': previousItem,
      'next': nextItem,
    });
  }

  String upgradeMilestonePreview(String itemName, int level, [String? reward]) {
    final milestone = _template('upgradeMilestonePreview', {
      'item': itemName,
      'level': level.toString(),
    });
    if (reward == null || reward.isEmpty) {
      return milestone;
    }
    return '$milestone - $reward';
  }

  String milestoneRewardLabel(MilestoneReward reward) {
    final custom = _maybeValue('milestone.${reward.labelKey}');
    if (custom != null) {
      return custom;
    }

    return switch (reward.type) {
      MilestoneRewardType.tapBonusPercent => _template('milestoneTapBonus', {
        'value': _signedPercent(reward.value),
      }),
      MilestoneRewardType.passiveBonusPercent => _template(
        'milestonePassiveBonus',
        {'value': _signedPercent(reward.value)},
      ),
      MilestoneRewardType.globalBonusPercent => _template(
        'milestoneGlobalBonus',
        {'value': _signedPercent(reward.value)},
      ),
      MilestoneRewardType.menuBonusPercent => _template('milestoneMenuBonus', {
        'value': _signedPercent(reward.value),
      }),
      MilestoneRewardType.criticalChance => _template(
        'milestoneCriticalChance',
        {'value': _signedPercent(reward.value)},
      ),
      MilestoneRewardType.criticalMultiplier => _template(
        'milestoneCriticalMultiplier',
        {'value': _multiplierBonus(reward.value)},
      ),
      MilestoneRewardType.comboDuration => _template('milestoneComboDuration', {
        'value': _seconds(reward.value),
      }),
      MilestoneRewardType.comboMultiplier => _template(
        'milestoneComboMultiplier',
        {'value': _multiplierBonus(reward.value)},
      ),
      MilestoneRewardType.offlineEfficiency => _template(
        'milestoneOfflineEfficiency',
        {'value': _signedPercent(reward.value)},
      ),
      MilestoneRewardType.offlineMaxDuration => _template(
        'milestoneOfflineMaxDuration',
        {'value': _minutes(reward.value)},
      ),
      MilestoneRewardType.offlineAdRewardPercent => _template(
        'milestoneOfflineAdReward',
        {'value': _signedPercent(reward.value)},
      ),
      MilestoneRewardType.tipChance => _template('milestoneTipChance', {
        'value': _signedPercent(reward.value),
      }),
      MilestoneRewardType.tipValuePercent => _template('milestoneTipValue', {
        'value': _signedPercent(reward.value),
      }),
      MilestoneRewardType.specialOrderChance => _template(
        'milestoneSpecialOrder',
        {'value': _signedPercent(reward.value)},
      ),
      MilestoneRewardType.instantMoney => _template('milestoneInstantMoney', {
        'value': formatNumberWithUnitNames(
          reward.value,
          locale: locale.languageCode,
        ),
      }),
      MilestoneRewardType.chest => _template('milestoneChest', {
        'count': _quantity(reward.quantity),
      }),
      MilestoneRewardType.cosmeticToken => _template('milestoneCosmeticToken', {
        'count': _quantity(reward.quantity),
      }),
      MilestoneRewardType.collectionUnlock => _template(
        'milestoneCollectionUnlock',
        {'collection': _featureName(reward.collectionKey)},
      ),
      MilestoneRewardType.featureUnlock => _template('milestoneFeatureUnlock', {
        'feature': _featureName(reward.featureKey),
      }),
    };
  }

  String lockedUntil(String amount) {
    return _template('lockedUntil', {'amount': amount});
  }

  String upgradeName(UpgradeId id) => _value('upgrade.${id.key}.name');

  String upgradeDescription(UpgradeId id) =>
      _value('upgrade.${id.key}.description');

  String upgradeEffectName(UpgradeId id) =>
      _value('upgrade.${id.key}.effectName');

  String upgradeItemName(UpgradeId id, String itemKey) =>
      _value('upgrade.${id.key}.item.$itemKey');

  String questTitle(String questId) => _value('quest.$questId.title');

  String questReward(String questId) => _value('quest.$questId.reward');

  String _template(String key, Map<String, String> values) {
    var text = _value(key);
    for (final entry in values.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }

  String _value(String key) {
    final translations = isTurkish ? _tr : _en;
    return translations[key] ?? _en[key] ?? key;
  }

  String? _maybeValue(String key) {
    final translations = isTurkish ? _tr : _en;
    return translations[key] ?? _en[key];
  }

  String _signedPercent(double value) {
    final percent = _trimNumber(value * 100);
    return isTurkish ? '+%$percent' : '+$percent%';
  }

  String _multiplierBonus(double value) {
    return '+x${_trimNumber(value)}';
  }

  String _seconds(double value) {
    return isTurkish ? '+${_trimNumber(value)} sn' : '+${_trimNumber(value)}s';
  }

  String _minutes(double seconds) {
    final minutes = seconds / 60;
    return isTurkish
        ? '+${_trimNumber(minutes)} dk'
        : '+${_trimNumber(minutes)}m';
  }

  String _quantity(int quantity) {
    return (quantity > 0 ? quantity : 1).toString();
  }

  String _featureName(String? key) {
    if (key == null || key.isEmpty) {
      return _value('milestoneFeatureGeneric');
    }
    return _value('milestone.feature.$key');
  }

  String _trimNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) {
    return SynchronousFuture(AppStrings(locale));
  }

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

const Map<String, String> _en = {
  'appTitle': 'TapTap Doner',
  'tapPrompt': 'Tap to Roast',
  'cashLabel': 'Cash',
  'idleIncomeLabel': 'Idle / sec',
  'reputationLabel': 'Reputation',
  'customerQueueTitle': 'Next customer',
  'customerQueueHint': 'New orders show up here.',
  'customerArrivalIn': 'In {time}',
  'customerReputationLevel': 'Customer tier {level}',
  'customerTypesUnlocked': 'Can arrive: {count}',
  'shopTitle': 'Kitchen Shop',
  'shopLevelLabel': 'Shop Level',
  'shopLevelUpTitle': 'Shop Level Up',
  'shopUnlockedLabel': 'Unlocked',
  'shopIncomeLabel': 'Income',
  'shopNextLabel': 'Next',
  'shopMaxLevelLabel': 'Maximum shop level reached',
  'upgradesTitle': 'Upgrades',
  'buyLabel': 'Buy',
  'boughtLabel': 'Owned',
  'levelLabel': 'Lvl',
  'currentEffectLabel': 'Current',
  'nextEffectLabel': 'Next',
  'nextItemLabel': 'Next item',
  'maxedLabel': 'Maxed',
  'upgradeTierLabel': 'Tier',
  'upgradeNextLevelLabel': 'Next Level',
  'upgradeNextTierLabel': 'Next Tier',
  'upgradeNextMilestoneLabel': 'Next Milestone',
  'upgradeNextItemPreviewLabel': 'Next Item',
  'upgradeCostLabel': 'Cost',
  'upgradeLevelUpAction': 'Level Up',
  'upgradeTierUpAction': 'Upgrade Tier',
  'upgradeBuyTenAction': '10x',
  'upgradeBuyMaxAction': 'Max',
  'insufficientFundsLabel': 'Need Cash',
  'upgradeMaxLevelLabel': 'Maximum level',
  'upgradeUnlockTitle': 'New Equipment Unlocked!',
  'milestoneUnlockTitle': 'Milestone Unlocked!',
  'upgradeNewEffectLabel': 'New effect:',
  'closeLabel': 'Close',
  'prestigeTitle': 'Prestige',
  'prestigeConfirm': 'Reset this run and collect reputation',
  'prestigeAvailable': '{points} reputation ready',
  'prestigeHint':
      'Prestige keeps your reputation and resets cash, upgrades, and temporary boosts.',
  'questLabel': 'Quest',
  'questProgressLabel': 'Progress',
  'questRewardLabel': 'Reward',
  'questClaimLabel': 'Claim',
  'questCompletedLabel': 'Ready',
  'quest.starter_tap_10.title': 'Cut 10 Doners',
  'quest.starter_tap_10.reward': '+50 cash',
  'quest.starter_first_upgrade.title': 'Buy the First Upgrade',
  'quest.starter_first_upgrade.reward': '+25 cash',
  'quest.starter_tap_50.title': 'Cut 50 Doners',
  'quest.starter_tap_50.reward': '+75 cash',
  'quest.starter_rusty_knife_5.title': 'Make Rusty Knife Lv. 5',
  'quest.starter_rusty_knife_5.reward': '+100 cash',
  'quest.starter_upgrades_10.title': 'Buy 10 Upgrades',
  'quest.starter_upgrades_10.reward': '+125 cash',
  'quest.starter_tap_150.title': 'Cut 150 Doners',
  'quest.starter_tap_150.reward': '+150 cash',
  'quest.starter_lifetime_500.title': 'Collect 500 cash',
  'quest.starter_lifetime_500.reward': 'Small Chest',
  'quest.starter_upgrades_25.title': 'Buy 25 Upgrades',
  'quest.starter_upgrades_25.reward': '+200 cash',
  'quest.starter_rusty_knife_10.title': 'Make Rusty Knife Lv. 10',
  'quest.starter_rusty_knife_10.reward': 'Critical Cut unlock',
  'quest.starter_critical_3.title': 'Do 3 Critical Cuts',
  'quest.starter_critical_3.reward': '+150 cash',
  'quest.starter_lifetime_2500.title': 'Collect 2,500 cash',
  'quest.starter_lifetime_2500.reward': '+200 cash',
  'quest.starter_first_staff.title': 'Hire the First Staff',
  'quest.starter_first_staff.reward': 'Small Chest + 60s passive x2',
  'quest.starter_passive_60.title': 'Earn passive income for 1 minute',
  'quest.starter_passive_60.reward': '+250 cash',
  'quest.starter_passive_180.title': 'Earn passive income for 3 minutes',
  'quest.starter_passive_180.reward': '+300 cash',
  'quest.starter_staff_5.title': 'Hire 5 Staff',
  'quest.starter_staff_5.reward': 'Small Chest',
  'quest.starter_staff_10.title': 'Hire 10 Staff',
  'quest.starter_staff_10.reward': '+350 cash',
  'quest.starter_staff_25.title': 'Hire 25 Staff',
  'quest.starter_staff_25.reward': 'Small Chest',
  'quest.starter_combo_15.title': 'Reach 15 Combo',
  'questComboUnlockInfo': 'Combo unlocks at Rusty Knife Lv. 15.',
  'quest.starter_combo_15.reward': 'Combo bonus +5%',
  'quest.starter_lifetime_5000.title': 'Collect 5,000 cash',
  'quest.starter_lifetime_5000.reward': '+300 cash',
  'quest.starter_passive_300.title': 'Earn passive income for 5 minutes',
  'quest.starter_passive_300.reward': '+350 cash',
  'quest.starter_passive_600.title': 'Earn passive income for 10 minutes',
  'quest.starter_passive_600.reward': '+450 cash',
  'quest.starter_critical_10.title': 'Do 10 Critical Cuts',
  'quest.starter_critical_10.reward': '+350 cash',
  'quest.starter_combo_30.title': 'Reach 30 Combo',
  'quest.starter_combo_30.reward': 'Combo bonus +5%',
  'quest.starter_critical_25.title': 'Do 25 Critical Cuts',
  'quest.starter_critical_25.reward': '+500 cash',
  'quest.starter_critical_50.title': 'Do 50 Critical Cuts',
  'quest.starter_critical_50.reward': '+650 cash',
  'quest.starter_combo_50.title': 'Reach 50 Combo',
  'quest.starter_combo_50.reward': 'Combo bonus +5%',
  'quest.starter_combo_75.title': 'Reach 75 Combo',
  'quest.starter_combo_75.reward': 'Combo bonus +5%',
  'quest.starter_tap_500.title': 'Cut 500 Doners',
  'quest.starter_tap_500.reward': '+500 cash',
  'quest.starter_tap_1000.title': 'Cut 1,000 Doners',
  'quest.starter_tap_1000.reward': '+600 cash',
  'quest.starter_knife_item_1.title': 'Complete the First Knife',
  'quest.starter_knife_item_1.reward': 'Master Chest',
  'quest.starter_tap_2500.title': 'Cut 2,500 Doners',
  'quest.starter_tap_2500.reward': '+750 cash',
  'quest.starter_upgrades_50.title': 'Buy 50 Upgrades',
  'quest.starter_upgrades_50.reward': 'Small Chest',
  'quest.starter_upgrades_75.title': 'Buy 75 Upgrades',
  'quest.starter_upgrades_75.reward': '+700 cash',
  'quest.starter_upgrades_100.title': 'Buy 100 Upgrades',
  'quest.starter_upgrades_100.reward': 'Master Chest',
  'quest.starter_shop_prepare.title': 'Prepare for the Small Buffet',
  'quest.starter_shop_prepare.reward': 'Shop progression unlock',
  'quest.starter_shop_level_2.title': 'Open the Small Buffet',
  'quest.starter_shop_level_2.reward': 'Global income +5%',
  'quest.starter_lifetime_25000.title': 'Collect 25,000 cash',
  'quest.starter_lifetime_25000.reward': '+750 cash',
  'quest.starter_lifetime_50000.title': 'Collect 50,000 cash',
  'quest.starter_lifetime_50000.reward': '+900 cash',
  'quest.starter_lifetime_100000.title': 'Collect 100,000 cash',
  'quest.starter_lifetime_100000.reward': 'Master Chest',
  'quest.starter_open_prestige.title': 'View the Prestige Goal',
  'quest.starter_open_prestige.reward': '+500 cash',
  'comboLabel': 'Combo',
  'comboTierSimple': 'Basic Combo',
  'comboTierFast': 'Fast Combo',
  'comboTierFlaming': 'Flaming Combo',
  'comboTierInsane': 'Insane Combo',
  'comboTierLegendary': 'Legendary Combo',
  'comboTierCosmic': 'Cosmic Combo',
  'criticalCutLabel': 'Critical!',
  'settingsTitle': 'Settings',
  'settingsSubtitle': 'Game preferences',
  'languageTitle': 'Language',
  'preferencesTitle': 'Preferences',
  'soundTitle': 'Sound',
  'hapticsTitle': 'Haptics',
  'comingSoonLabel': 'Soon',
  'englishLabel': 'English',
  'turkishLabel': 'Turkish',
  'offlineTitle': 'While you were away',
  'offlineSummaryTitle': 'Earnings Summary',
  'offlineBaseRewardLabel': 'Base Reward',
  'offlineDoubleRewardLabel': 'Ad x2',
  'offlineDoubleOfferTitle': 'Double it with an ad',
  'offlineDoubleOfferBody':
      'Watch a reward ad to claim {amount}. Preview only for now.',
  'offlineAdPreviewLabel': 'Ad integration later',
  'watchAdDoubleLabel': 'Watch Ad x2',
  'offlineSummary': 'Production continued for up to {hours}h.',
  'offlineAmount': 'Offline earnings: {amount}',
  'upgradeItemUnlocked': '{item} unlocked',
  'shopRunCashRequirement': 'Earn {amount} this run',
  'shopUpgradeCountRequirement': 'Upgrade {upgrade} {count} times',
  'shopUpgradeItemRequirement': 'Unlock {item} in {upgrade}',
  'shopPrestigeRequirement': 'Prestige {count} times',
  'shop.street_stand.name': 'Street Stand',
  'shop.street_stand.unlock': 'Tap + Knife',
  'shop.small_buffet.name': 'Small Buffet',
  'shop.small_buffet.unlock': 'Staff',
  'shop.neighborhood_doner.name': 'Neighborhood Doner',
  'shop.neighborhood_doner.unlock': 'Oven',
  'shop.busy_street_doner.name': 'Busy Street Doner',
  'shop.busy_street_doner.unlock': 'Menu',
  'shop.mall_doner.name': 'Mall Doner',
  'shop.mall_doner.unlock': 'Offline earnings',
  'shop.luxury_restaurant.name': 'Luxury Restaurant',
  'shop.luxury_restaurant.unlock': 'Offline earnings',
  'shop.doner_chain.name': 'Doner Chain',
  'shop.doner_chain.unlock': 'Branches',
  'shop.city_brand.name': 'City Brand',
  'shop.city_brand.unlock': 'Collections',
  'shop.national_chain.name': 'National Chain',
  'shop.national_chain.unlock': 'Advanced goals',
  'shop.global_doner_empire.name': 'Global Doner Empire',
  'shop.global_doner_empire.unlock': 'Global expansion',
  'shop.galactic_doner_center.name': 'Galactic Doner Center',
  'shop.galactic_doner_center.unlock': 'Galactic upgrades',
  'shop.infinite_doner_universe.name': 'Infinite Doner Universe',
  'shop.infinite_doner_universe.unlock': 'Infinite progression',
  'upgradeItemTransition': '{previous} -> {next}',
  'upgradeMilestonePreview': '{item} Lv. {level}',
  'milestoneTapBonus': 'Tap income {value}',
  'milestonePassiveBonus': 'Passive income {value}',
  'milestoneGlobalBonus': 'Global income {value}',
  'milestoneMenuBonus': 'Menu multiplier {value}',
  'milestoneCriticalChance': 'Critical chance {value}',
  'milestoneCriticalMultiplier': 'Critical multiplier {value}',
  'milestoneComboDuration': 'Combo duration {value}',
  'milestoneComboMultiplier': 'Combo multiplier {value}',
  'milestoneOfflineEfficiency': 'Offline efficiency {value}',
  'milestoneOfflineMaxDuration': 'Offline cap {value}',
  'milestoneOfflineAdReward': 'Offline ad reward {value}',
  'milestoneTipChance': 'Tip chance {value}',
  'milestoneTipValue': 'Tip value {value}',
  'milestoneSpecialOrder': 'Special order chance {value}',
  'milestoneInstantMoney': '+{value} cash',
  'milestoneChest': 'Chest x{count}',
  'milestoneCosmeticToken': 'Cosmetic token x{count}',
  'milestoneCollectionUnlock': '{collection} collection',
  'milestoneFeatureUnlock': '{feature} unlocked',
  'milestoneFeatureGeneric': 'New feature',
  'milestone.rustyKnife5': 'Getting the feel: tap income +5%',
  'milestone.rustyKnife10': 'Critical Cut unlocked: +1% critical chance',
  'milestone.rustyKnife15': 'Combo system unlocked: +0.25 sn combo duration',
  'milestone.rustyKnife20': 'Skilled cuts: tap income +5%',
  'milestone.rustyKnife25': 'Sharp Knife ready: chest x1',
  'milestone.feature.critical_cut': 'Critical Cut',
  'milestone.feature.combo': 'Combo',
  'milestone.feature.unlock_sharp_knife': 'Sharp Knife',
  'milestone.feature.tips': 'Tips',
  'milestone.feature.auto_collect_bonus': 'Auto collect',
  'milestone.feature.special_orders': 'Special orders',
  'milestone.feature.offline_minimum_claim': 'Minimum offline claim',
  'claimLabel': 'Claim',
  'claimDoubleLabel': 'Claim x2',
  'dismissLabel': 'Skip',
  'adUnavailable': 'Reward ad is not available yet.',
  'shopNavLabel': 'Shop',
  'prestigeNavLabel': 'Prestige',
  'settingsNavLabel': 'Settings',
  'lockedLabel': 'Locked',
  'unlockedLabel': 'Unlocked',
  'lockedUntil': 'Unlocks at {amount} lifetime cash',
  'soundSoonLabel': 'Audio controls are being prepared',
  'hapticsSoonLabel': 'Vibration controls are being prepared',
  'upgrade.knife.name': 'Knife',
  'upgrade.knife.description': 'Multiplies every tap.',
  'upgrade.knife.effectName': 'Click Power',
  'upgrade.knife.item.rustyKnife': 'Rusty Knife',
  'upgrade.knife.item.sharpKnife': 'Sharp Knife',
  'upgrade.knife.item.doubleKnife': 'Double Knife',
  'upgrade.knife.item.electricKnife': 'Electric Knife',
  'upgrade.knife.item.rusty_knife': 'Rusty Knife',
  'upgrade.knife.item.sharp_knife': 'Sharp Knife',
  'upgrade.knife.item.double_knife': 'Double Knife',
  'upgrade.knife.item.electric_knife': 'Electric Knife',
  'upgrade.knife.item.golden_knife': 'Golden Knife',
  'upgrade.knife.item.flaming_knife': 'Flaming Knife',
  'upgrade.knife.item.laser_knife': 'Laser Knife',
  'upgrade.knife.item.doner_excalibur': 'Doner Excalibur',
  'upgrade.knife.item.master_sword': "Master's Sword",
  'upgrade.knife.item.cosmic_doner_knife': 'Cosmic Doner Knife',
  'upgrade.knife.item.galactic_cutter': 'Galactic Cutter',
  'upgrade.knife.item.infinite_knife': 'Infinite Knife',
  'upgrade.oven.name': 'Oven',
  'upgrade.oven.description': 'Multiplies tap and idle income.',
  'upgrade.oven.effectName': 'All Income',
  'upgrade.oven.item.coalOven': 'Coal Oven',
  'upgrade.oven.item.stoneOven': 'Stone Oven',
  'upgrade.oven.item.gasOven': 'Gas Oven',
  'upgrade.oven.item.rotaryOven': 'Rotary Oven',
  'upgrade.oven.item.small_oven': 'Small Oven',
  'upgrade.oven.item.large_oven': 'Large Oven',
  'upgrade.oven.item.double_oven': 'Double Oven',
  'upgrade.oven.item.industrial_oven': 'Industrial Oven',
  'upgrade.oven.item.robotic_oven': 'Robotic Oven',
  'upgrade.oven.item.flame_reactor': 'Flame Reactor',
  'upgrade.oven.item.laser_grill': 'Laser Grill',
  'upgrade.oven.item.space_oven_system': 'Space Oven System',
  'upgrade.oven.item.galactic_oven': 'Galactic Oven',
  'upgrade.oven.item.infinite_heat_core': 'Infinite Heat Core',
  'upgrade.staff.name': 'Staff',
  'upgrade.staff.description': 'Adds passive income each second.',
  'upgrade.staff.effectName': 'Passive Income',
  'upgrade.staff.item.helper': 'Helper',
  'upgrade.staff.item.apprentice': 'Apprentice',
  'upgrade.staff.item.fast_apprentice': 'Fast Apprentice',
  'upgrade.staff.item.usta': 'Usta',
  'upgrade.staff.item.team': 'Kitchen Team',
  'upgrade.staff.item.journeyman': 'Journeyman',
  'upgrade.staff.item.assistant_master': 'Assistant Master',
  'upgrade.staff.item.doner_master': 'Doner Master',
  'upgrade.staff.item.head_master': 'Head Master',
  'upgrade.staff.item.chef': 'Chef',
  'upgrade.staff.item.robot_staff': 'Robot Staff',
  'upgrade.staff.item.ai_master': 'AI Master',
  'upgrade.staff.item.doner_army': 'Doner Army',
  'upgrade.staff.item.franchise_team': 'Franchise Team',
  'upgrade.staff.item.infinite_masters': 'Infinite Masters',
  'upgrade.menu.name': 'Menu',
  'upgrade.menu.description': 'Improves the value of every order.',
  'upgrade.menu.effectName': 'Menu Bonus',
  'upgrade.menu.item.simpleWrap': 'Simple Wrap',
  'upgrade.menu.item.saucedMenu': 'Sauced Menu',
  'upgrade.menu.item.comboMenu': 'Combo Menu',
  'upgrade.menu.item.signatureMenu': 'Signature Menu',
  'upgrade.menu.item.chicken_doner': 'Chicken Doner',
  'upgrade.menu.item.beef_doner': 'Beef Doner',
  'upgrade.menu.item.hatay_style': 'Hatay Style',
  'upgrade.menu.item.sauced_doner': 'Sauced Doner',
  'upgrade.menu.item.gourmet_doner': 'Gourmet Doner',
  'upgrade.menu.item.legendary_sauce_doner': 'Legendary Sauce Doner',
  'upgrade.menu.item.king_wrap': 'King Wrap',
  'upgrade.menu.item.cosmic_doner': 'Cosmic Doner',
  'upgrade.menu.item.universe_doner': "Universe's Doner",
  'upgrade.offline.name': 'Offline',
  'upgrade.offline.description': 'Keeps more idle income while away.',
  'upgrade.offline.effectName': 'Offline Efficiency',
  'upgrade.offline.item.paperLedger': 'Paper Ledger',
  'upgrade.offline.item.warmBox': 'Warm Box',
  'upgrade.offline.item.courierRoute': 'Courier Route',
  'upgrade.offline.item.nightShift': 'Night Shift',
  'upgrade.offline.item.small_safe': 'Small Safe',
  'upgrade.offline.item.secure_safe': 'Secure Safe',
  'upgrade.offline.item.smart_safe': 'Smart Safe',
  'upgrade.offline.item.big_storage': 'Big Storage',
  'upgrade.offline.item.night_shift': 'Night Shift',
  'upgrade.offline.item.franchise_system': 'Franchise System',
  'upgrade.offline.item.auto_branch_network': 'Automatic Branch Network',
  'upgrade.offline.item.global_doner_network': 'Global Doner Network',
  'upgrade.offline.item.infinite_safe_system': 'Infinite Safe System',
};

const Map<String, String> _tr = {
  'appTitle': 'TapTap Döner',
  'tapPrompt': 'Kızartmak için dokun',
  'cashLabel': 'Nakit',
  'idleIncomeLabel': 'Pasif / sn',
  'reputationLabel': 'İtibar',
  'customerQueueTitle': 'Sıradaki müşteri',
  'customerQueueHint': 'Yeni siparişler burada görünür.',
  'customerArrivalIn': '{time} sonra',
  'customerReputationLevel': 'Müşteri seviyesi {level}',
  'customerTypesUnlocked': 'Gelebilen tip: {count}',
  'shopTitle': 'Mutfak Marketi',
  'shopLevelLabel': 'Dükkân Seviyesi',
  'shopLevelUpTitle': 'Dükkân Seviye Atladı',
  'shopUnlockedLabel': 'Açılan',
  'shopIncomeLabel': 'Gelir',
  'shopNextLabel': 'Sonraki',
  'shopMaxLevelLabel': 'Maksimum dükkân seviyesine ulaşıldı',
  'upgradesTitle': 'Geliştirmeler',
  'buyLabel': 'Al',
  'boughtLabel': 'Alındı',
  'levelLabel': 'Sv',
  'currentEffectLabel': 'Mevcut',
  'nextEffectLabel': 'Sonraki',
  'nextItemLabel': 'Sıradaki',
  'maxedLabel': 'Maks',
  'upgradeTierLabel': 'Kademe',
  'upgradeNextLevelLabel': 'Sonraki Seviye',
  'upgradeNextTierLabel': 'Sonraki Kademe',
  'upgradeNextMilestoneLabel': 'Sıradaki Dönüm Noktası',
  'upgradeNextItemPreviewLabel': 'Sıradaki Ekipman',
  'upgradeCostLabel': 'Maliyet',
  'upgradeLevelUpAction': 'Seviye Atlat',
  'upgradeTierUpAction': 'Kademeyi Yükselt',
  'upgradeBuyTenAction': '10x',
  'upgradeBuyMaxAction': 'Maks.',
  'insufficientFundsLabel': 'Yetersiz Para',
  'upgradeMaxLevelLabel': 'Maksimum seviye',
  'upgradeUnlockTitle': 'Yeni Ekipman Açıldı!',
  'milestoneUnlockTitle': 'Dönüm Noktası Açıldı!',
  'upgradeNewEffectLabel': 'Yeni etki:',
  'closeLabel': 'Kapat',
  'prestigeTitle': 'Prestij',
  'prestigeConfirm': 'Bu koşuyu sıfırla ve itibar topla',
  'prestigeAvailable': '{points} itibar hazır',
  'prestigeHint':
      'Prestij itibarını korur; nakit, geliştirmeler ve geçici güçler sıfırlanır.',
  'questLabel': 'Görev',
  'questProgressLabel': 'İlerleme',
  'questRewardLabel': 'Ödül',
  'questClaimLabel': 'Ödülü Al',
  'questCompletedLabel': 'Hazır',
  'quest.starter_tap_10.title': '10 Döner Kes',
  'quest.starter_tap_10.reward': '+50 para',
  'quest.starter_first_upgrade.title': 'İlk Geliştirmeyi Satın Al',
  'quest.starter_first_upgrade.reward': '+25 para',
  'quest.starter_tap_50.title': '50 Döner Kes',
  'quest.starter_tap_50.reward': '+75 para',
  'quest.starter_rusty_knife_5.title': 'Paslı Bıçağı Sv. 5 yap',
  'quest.starter_rusty_knife_5.reward': '+100 para',
  'quest.starter_upgrades_10.title': '10 Geliştirme Satın Al',
  'quest.starter_upgrades_10.reward': '+125 para',
  'quest.starter_tap_150.title': '150 Döner Kes',
  'quest.starter_tap_150.reward': '+150 para',
  'quest.starter_lifetime_500.title': '500 para Topla',
  'quest.starter_lifetime_500.reward': 'Küçük Sandık',
  'quest.starter_upgrades_25.title': '25 Geliştirme Satın Al',
  'quest.starter_upgrades_25.reward': '+200 para',
  'quest.starter_rusty_knife_10.title': 'Paslı Bıçağı Sv. 10 yap',
  'quest.starter_rusty_knife_10.reward': 'Kritik Kesim açılır',
  'quest.starter_critical_3.title': '3 Kritik Kesim Yap',
  'quest.starter_critical_3.reward': '+150 para',
  'quest.starter_lifetime_2500.title': '2.500 para Topla',
  'quest.starter_lifetime_2500.reward': '+200 para',
  'quest.starter_first_staff.title': 'İlk Personeli Al',
  'quest.starter_first_staff.reward': 'Küçük Sandık + 60 sn pasif x2',
  'quest.starter_passive_60.title': '1 dakika pasif gelir kazan',
  'quest.starter_passive_60.reward': '+250 para',
  'quest.starter_passive_180.title': '3 dakika pasif gelir kazan',
  'quest.starter_passive_180.reward': '+300 para',
  'quest.starter_staff_5.title': '5 Personel Al',
  'quest.starter_staff_5.reward': 'Küçük Sandık',
  'quest.starter_staff_10.title': '10 Personel Al',
  'quest.starter_staff_10.reward': '+350 para',
  'quest.starter_staff_25.title': '25 Personel Al',
  'quest.starter_staff_25.reward': 'Küçük Sandık',
  'quest.starter_combo_15.title': "15 Kombo'ya ulaş",
  'questComboUnlockInfo': "Kombo özelliği Paslı Bıçak Lv. 15'te acilir.",
  'quest.starter_combo_15.reward': 'Kombo bonus +%5',
  'quest.starter_lifetime_5000.title': '5.000 para Topla',
  'quest.starter_lifetime_5000.reward': '+300 para',
  'quest.starter_passive_300.title': '5 dakika pasif gelir kazan',
  'quest.starter_passive_300.reward': '+350 para',
  'quest.starter_passive_600.title': '10 dakika pasif gelir kazan',
  'quest.starter_passive_600.reward': '+450 para',
  'quest.starter_critical_10.title': '10 Kritik Kesim Yap',
  'quest.starter_critical_10.reward': '+350 para',
  'quest.starter_combo_30.title': "30 Kombo'ya ulaş",
  'quest.starter_combo_30.reward': 'Kombo bonus +%5',
  'quest.starter_critical_25.title': '25 Kritik Kesim Yap',
  'quest.starter_critical_25.reward': '+500 para',
  'quest.starter_critical_50.title': '50 Kritik Kesim Yap',
  'quest.starter_critical_50.reward': '+650 para',
  'quest.starter_combo_50.title': "50 Kombo'ya ulaş",
  'quest.starter_combo_50.reward': 'Kombo bonus +%5',
  'quest.starter_combo_75.title': "75 Kombo'ya ulaş",
  'quest.starter_combo_75.reward': 'Kombo bonus +%5',
  'quest.starter_tap_500.title': '500 Döner Kes',
  'quest.starter_tap_500.reward': '+500 para',
  'quest.starter_tap_1000.title': '1.000 Döner Kes',
  'quest.starter_tap_1000.reward': '+600 para',
  'quest.starter_knife_item_1.title': 'İlk Bıçağı Tamamla',
  'quest.starter_knife_item_1.reward': 'Usta Sandığı',
  'quest.starter_tap_2500.title': '2.500 Döner Kes',
  'quest.starter_tap_2500.reward': '+750 para',
  'quest.starter_upgrades_50.title': '50 Geliştirme Satın Al',
  'quest.starter_upgrades_50.reward': 'Küçük Sandık',
  'quest.starter_upgrades_75.title': '75 Geliştirme Satın Al',
  'quest.starter_upgrades_75.reward': '+700 para',
  'quest.starter_upgrades_100.title': '100 Geliştirme Satın Al',
  'quest.starter_upgrades_100.reward': 'Usta Sandığı',
  'quest.starter_shop_prepare.title': "Küçük Büfe'ye Hazırlan",
  'quest.starter_shop_prepare.reward': 'Dükkân ilerlemesi açılır',
  'quest.starter_shop_level_2.title': "Küçük Büfe'yi Aç",
  'quest.starter_shop_level_2.reward': 'Genel gelir +%5',
  'quest.starter_lifetime_25000.title': '25.000 para Topla',
  'quest.starter_lifetime_25000.reward': '+750 para',
  'quest.starter_lifetime_50000.title': '50.000 para Topla',
  'quest.starter_lifetime_50000.reward': '+900 para',
  'quest.starter_lifetime_100000.title': '100.000 para Topla',
  'quest.starter_lifetime_100000.reward': 'Usta Sandığı',
  'quest.starter_open_prestige.title': 'Prestij hedefini gör',
  'quest.starter_open_prestige.reward': '+500 para',
  'comboLabel': 'Kombo',
  'comboTierSimple': 'Basit Kombo',
  'comboTierFast': 'Seri Kombo',
  'comboTierFlaming': 'Alevli Kombo',
  'comboTierInsane': 'Manyak Kombo',
  'comboTierLegendary': 'Efsane Kombo',
  'comboTierCosmic': 'Kozmik Kombo',
  'criticalCutLabel': 'Kritik!',
  'settingsTitle': 'Ayarlar',
  'settingsSubtitle': 'Oyun tercihleri',
  'languageTitle': 'Dil',
  'preferencesTitle': 'Tercihler',
  'soundTitle': 'Ses',
  'hapticsTitle': 'Titreşim',
  'comingSoonLabel': 'Yakında',
  'englishLabel': 'İngilizce',
  'turkishLabel': 'Türkçe',
  'offlineTitle': 'Sen yokken',
  'offlineSummaryTitle': 'Kazanç Özeti',
  'offlineBaseRewardLabel': 'Temel Kazanç',
  'offlineDoubleRewardLabel': 'Reklam 2x',
  'offlineDoubleOfferTitle': 'Reklamla ikiye katla',
  'offlineDoubleOfferBody':
      'Ödüllü reklam izleyerek {amount} al. Şimdilik sadece göstermelik.',
  'offlineAdPreviewLabel': 'Reklam entegrasyonu sonra',
  'watchAdDoubleLabel': 'Reklam İzle x2',
  'offlineSummary': 'Üretim en fazla {hours} saat boyunca devam etti.',
  'offlineAmount': 'Uzakta kazanç: {amount}',
  'upgradeItemUnlocked': '{item} açıldı',
  'shopRunCashRequirement': 'Bu turda {amount} kazan',
  'shopUpgradeCountRequirement': '{upgrade} ekipmanını {count} kez geliştir',
  'shopUpgradeItemRequirement': '{upgrade}: {item} kilidini aç',
  'shopPrestigeRequirement': '{count} kez prestij yap',
  'shop.street_stand.name': 'Sokak Tezgâhı',
  'shop.street_stand.unlock': 'Dokunuş + Bıçak',
  'shop.small_buffet.name': 'Küçük Büfe',
  'shop.small_buffet.unlock': 'Personel',
  'shop.neighborhood_doner.name': 'Mahalle Dönercisi',
  'shop.neighborhood_doner.unlock': 'Fırın',
  'shop.busy_street_doner.name': 'İşlek Cadde Dönercisi',
  'shop.busy_street_doner.unlock': 'Menü',
  'shop.mall_doner.name': 'AVM Dönercisi',
  'shop.mall_doner.unlock': 'Çevrimdışı kazanç',
  'shop.luxury_restaurant.name': 'Lüks Restoran',
  'shop.luxury_restaurant.unlock': 'Uzakta kazanç',
  'shop.doner_chain.name': 'Döner Zinciri',
  'shop.doner_chain.unlock': 'Şubeler',
  'shop.city_brand.name': 'Şehir Markası',
  'shop.city_brand.unlock': 'Koleksiyonlar',
  'shop.national_chain.name': 'Ulusal Zincir',
  'shop.national_chain.unlock': 'Gelişmiş hedefler',
  'shop.global_doner_empire.name': 'Küresel Döner İmparatorluğu',
  'shop.global_doner_empire.unlock': 'Küresel genişleme',
  'shop.galactic_doner_center.name': 'Galaktik Döner Merkezi',
  'shop.galactic_doner_center.unlock': 'Galaktik geliştirmeler',
  'shop.infinite_doner_universe.name': 'Sonsuz Döner Evreni',
  'shop.infinite_doner_universe.unlock': 'Sonsuz ilerleme',
  'upgradeItemTransition': '{previous} -> {next}',
  'upgradeMilestonePreview': '{item} Sv. {level}',
  'milestoneTapBonus': 'Dokunuş geliri {value}',
  'milestonePassiveBonus': 'Pasif gelir {value}',
  'milestoneGlobalBonus': 'Genel gelir {value}',
  'milestoneMenuBonus': 'Menü çarpanı {value}',
  'milestoneCriticalChance': 'Kritik şans {value}',
  'milestoneCriticalMultiplier': 'Kritik çarpan {value}',
  'milestoneComboDuration': 'Kombo süresi {value}',
  'milestoneComboMultiplier': 'Kombo çarpanı {value}',
  'milestoneOfflineEfficiency': 'Uzakta verim {value}',
  'milestoneOfflineMaxDuration': 'Uzakta limit {value}',
  'milestoneOfflineAdReward': 'Uzakta reklam ödülü {value}',
  'milestoneTipChance': 'Bahşiş şansı {value}',
  'milestoneTipValue': 'Bahşiş değeri {value}',
  'milestoneSpecialOrder': 'Özel sipariş şansı {value}',
  'milestoneInstantMoney': '+{value} para',
  'milestoneChest': 'Sandık x{count}',
  'milestoneCosmeticToken': 'Kozmetik jeton x{count}',
  'milestoneCollectionUnlock': '{collection} koleksiyonu',
  'milestoneFeatureUnlock': '{feature} açıldı',
  'milestoneFeatureGeneric': 'Yeni özellik',
  'milestone.rustyKnife5': 'Elin alışıyor: dokunuş geliri +%5',
  'milestone.rustyKnife10': 'Kritik Kesim açıldı: kritik şans +%1',
  'milestone.rustyKnife15': 'Kombo sistemi açıldı: kombo süresi +0.25 sn',
  'milestone.rustyKnife20': 'Usta kesimler: dokunuş geliri +%5',
  'milestone.rustyKnife25': 'Keskin Bıçak hazır: sandık x1',
  'milestone.feature.critical_cut': 'Kritik Kesim',
  'milestone.feature.combo': 'Kombo',
  'milestone.feature.unlock_sharp_knife': 'Keskin Bıçak',
  'milestone.feature.tips': 'Bahşiş',
  'milestone.feature.auto_collect_bonus': 'Otomatik toplama',
  'milestone.feature.special_orders': 'Özel siparişler',
  'milestone.feature.offline_minimum_claim': 'Asgari uzakta kazanç',
  'claimLabel': 'Al',
  'claimDoubleLabel': '2x Al',
  'dismissLabel': 'Geç',
  'adUnavailable': 'Ödüllü reklam henüz hazır değil.',
  'shopNavLabel': 'Market',
  'prestigeNavLabel': 'Prestij',
  'settingsNavLabel': 'Ayar',
  'lockedLabel': 'Kilitli',
  'unlockedLabel': 'Açık',
  'lockedUntil': 'Toplam {amount} nakitte açılır',
  'soundSoonLabel': 'Ses kontrolleri hazırlanıyor',
  'hapticsSoonLabel': 'Titreşim kontrolleri hazırlanıyor',
  'upgrade.knife.name': 'Bıçak',
  'upgrade.knife.description': 'Her dokunuşun gelirini çarpar.',
  'upgrade.knife.effectName': 'Dokunuş Gücü',
  'upgrade.knife.item.rustyKnife': 'Paslı Bıçak',
  'upgrade.knife.item.sharpKnife': 'Keskin Bıçak',
  'upgrade.knife.item.doubleKnife': 'Çift Bıçak',
  'upgrade.knife.item.electricKnife': 'Elektrikli Bıçak',
  'upgrade.knife.item.rusty_knife': 'Paslı Bıçak',
  'upgrade.knife.item.sharp_knife': 'Keskin Bıçak',
  'upgrade.knife.item.double_knife': 'Çift Bıçak',
  'upgrade.knife.item.electric_knife': 'Elektrikli Bıçak',
  'upgrade.knife.item.golden_knife': 'Altın Bıçak',
  'upgrade.knife.item.flaming_knife': 'Alevli Bıçak',
  'upgrade.knife.item.laser_knife': 'Lazer Bıçak',
  'upgrade.knife.item.doner_excalibur': 'Döner Excalibur',
  'upgrade.knife.item.master_sword': 'Ustanın Kılıcı',
  'upgrade.knife.item.cosmic_doner_knife': 'Kozmik Döner Bıçağı',
  'upgrade.knife.item.galactic_cutter': 'Galaktik Kesici',
  'upgrade.knife.item.infinite_knife': 'Sonsuz Bıçak',
  'upgrade.oven.name': 'Fırın',
  'upgrade.oven.description': 'Dokunuş ve pasif geliri çarpar.',
  'upgrade.oven.effectName': 'Tüm Gelir',
  'upgrade.oven.item.coalOven': 'Kömür Fırını',
  'upgrade.oven.item.stoneOven': 'Taş Fırın',
  'upgrade.oven.item.gasOven': 'Gazlı Fırın',
  'upgrade.oven.item.rotaryOven': 'Döner Fırın',
  'upgrade.oven.item.small_oven': 'Küçük Fırın',
  'upgrade.oven.item.large_oven': 'Büyük Fırın',
  'upgrade.oven.item.double_oven': 'Çift Fırın',
  'upgrade.oven.item.industrial_oven': 'Endüstriyel Fırın',
  'upgrade.oven.item.robotic_oven': 'Robotik Fırın',
  'upgrade.oven.item.flame_reactor': 'Alev Reaktörü',
  'upgrade.oven.item.laser_grill': 'Lazer Izgara',
  'upgrade.oven.item.space_oven_system': 'Uzay Fırın Sistemi',
  'upgrade.oven.item.galactic_oven': 'Galaktik Fırın',
  'upgrade.oven.item.infinite_heat_core': 'Sonsuz Isı Çekirdeği',
  'upgrade.staff.name': 'Personel',
  'upgrade.staff.description': 'Her saniye pasif gelir ekler.',
  'upgrade.staff.effectName': 'Pasif Gelir',
  'upgrade.staff.item.helper': 'Yardımcı',
  'upgrade.staff.item.apprentice': 'Çırak',
  'upgrade.staff.item.fast_apprentice': 'Hızlı Çırak',
  'upgrade.staff.item.usta': 'Usta',
  'upgrade.staff.item.team': 'Mutfak Ekibi',
  'upgrade.staff.item.journeyman': 'Kalfa',
  'upgrade.staff.item.assistant_master': 'Usta Yardımcısı',
  'upgrade.staff.item.doner_master': 'Döner Ustası',
  'upgrade.staff.item.head_master': 'Baş Usta',
  'upgrade.staff.item.chef': 'Şef',
  'upgrade.staff.item.robot_staff': 'Robot Personel',
  'upgrade.staff.item.ai_master': 'Yapay Zekâ Ustası',
  'upgrade.staff.item.doner_army': 'Döner Ordusu',
  'upgrade.staff.item.franchise_team': 'Franchise Ekibi',
  'upgrade.staff.item.infinite_masters': 'Sonsuz Ustalar',
  'upgrade.menu.name': 'Menü',
  'upgrade.menu.description': 'Her siparişin değerini artırır.',
  'upgrade.menu.effectName': 'Menü Bonusu',
  'upgrade.menu.item.simpleWrap': 'Sade Dürüm',
  'upgrade.menu.item.saucedMenu': 'Soslu Menü',
  'upgrade.menu.item.comboMenu': 'Kombo Menü',
  'upgrade.menu.item.signatureMenu': 'İmza Menü',
  'upgrade.menu.item.chicken_doner': 'Tavuk Döner',
  'upgrade.menu.item.beef_doner': 'Et Döner',
  'upgrade.menu.item.hatay_style': 'Hatay Usulü',
  'upgrade.menu.item.sauced_doner': 'Soslu Döner',
  'upgrade.menu.item.gourmet_doner': 'Gurme Döner',
  'upgrade.menu.item.legendary_sauce_doner': 'Efsane Soslu Döner',
  'upgrade.menu.item.king_wrap': 'Kral Dürüm',
  'upgrade.menu.item.cosmic_doner': 'Kozmik Döner',
  'upgrade.menu.item.universe_doner': 'Evrenin Döneri',
  'upgrade.offline.name': 'Uzakta',
  'upgrade.offline.description': 'Uzakta daha fazla pasif gelir korur.',
  'upgrade.offline.effectName': 'Uzakta Verim',
  'upgrade.offline.item.paperLedger': 'Kâğıt Defter',
  'upgrade.offline.item.warmBox': 'Sıcak Kutu',
  'upgrade.offline.item.courierRoute': 'Kurye Rotası',
  'upgrade.offline.item.nightShift': 'Gece Vardiyası',
  'upgrade.offline.item.small_safe': 'Küçük Kasa',
  'upgrade.offline.item.secure_safe': 'Güvenli Kasa',
  'upgrade.offline.item.smart_safe': 'Akıllı Kasa',
  'upgrade.offline.item.big_storage': 'Büyük Depo',
  'upgrade.offline.item.night_shift': 'Gece Vardiyası',
  'upgrade.offline.item.franchise_system': 'Franchise Sistemi',
  'upgrade.offline.item.auto_branch_network': 'Otomatik Şube Ağı',
  'upgrade.offline.item.global_doner_network': 'Genel Döner Ağı',
  'upgrade.offline.item.infinite_safe_system': 'Sonsuz Kasa Sistemi',
};
