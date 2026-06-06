import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';

class AppStrings {
  AppStrings(this.locale);

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
  String get shopTitle => _value('shopTitle');
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
  String get insufficientFundsLabel => _value('insufficientFundsLabel');
  String get upgradeMaxLevelLabel => _value('upgradeMaxLevelLabel');
  String get upgradeUnlockTitle => _value('upgradeUnlockTitle');
  String get milestoneUnlockTitle => _value('milestoneUnlockTitle');
  String get upgradeNewEffectLabel => _value('upgradeNewEffectLabel');
  String get closeLabel => _value('closeLabel');
  String get rushLabel => _value('rushLabel');
  String get rushReady => _value('rushReady');
  String get prestigeTitle => _value('prestigeTitle');
  String get prestigeConfirm => _value('prestigeConfirm');
  String get settingsTitle => _value('settingsTitle');
  String get languageTitle => _value('languageTitle');
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

  String rushStatus(Duration remaining, Duration cooldown) {
    if (remaining > Duration.zero) {
      return _template('rushActive', {'time': _formatDuration(remaining)});
    }
    if (cooldown > Duration.zero) {
      return _template('rushCooling', {'time': _formatDuration(cooldown)});
    }
    return rushReady;
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

  String upgradeItemUnlocked(String itemName) {
    return _template('upgradeItemUnlocked', {'item': itemName});
  }

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
      MilestoneRewardType.turboBonusPercent => _template(
        'milestoneTurboBonus',
        {'value': _signedPercent(reward.value)},
      ),
      MilestoneRewardType.turboChargeSpeed => _template(
        'milestoneTurboCharge',
        {'value': _signedPercent(reward.value)},
      ),
      MilestoneRewardType.turboDuration => _template('milestoneTurboDuration', {
        'value': _seconds(reward.value),
      }),
      MilestoneRewardType.turboCooldownReduction => _template(
        'milestoneTurboCooldown',
        {'value': _signedPercent(reward.value)},
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
      MilestoneRewardType.goldenDonerChance => _template(
        'milestoneGoldenChance',
        {'value': _signedPercent(reward.value)},
      ),
      MilestoneRewardType.goldenDonerRewardPercent => _template(
        'milestoneGoldenReward',
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
        'value': reward.value.round().toString(),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes <= 0) {
      return '${seconds}s';
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

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
    return '+${_trimNumber(value)}s';
  }

  String _minutes(double seconds) {
    final minutes = seconds / 60;
    return '+${_trimNumber(minutes)}m';
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
  'shopTitle': 'Kitchen Shop',
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
  'insufficientFundsLabel': 'Need Cash',
  'upgradeMaxLevelLabel': 'Maximum level',
  'upgradeUnlockTitle': 'New Equipment Unlocked!',
  'milestoneUnlockTitle': 'Milestone Unlocked!',
  'upgradeNewEffectLabel': 'New effect:',
  'closeLabel': 'Close',
  'rushLabel': 'Turbo',
  'rushReady': 'Turbo ready',
  'rushActive': 'Turbo active: {time}',
  'rushCooling': 'Cooling down: {time}',
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
  'quest.starter_rusty_knife_5.title': 'Make Rusty Knife Lv. 5',
  'quest.starter_rusty_knife_5.reward': '+100 cash',
  'quest.starter_lifetime_500.title': 'Collect 500 cash',
  'quest.starter_lifetime_500.reward': 'Small Chest',
  'quest.starter_rusty_knife_10.title': 'Make Rusty Knife Lv. 10',
  'quest.starter_rusty_knife_10.reward': 'Critical Cut unlock',
  'quest.starter_critical_3.title': 'Do 3 Critical Cuts',
  'quest.starter_critical_3.reward': '+150 cash',
  'quest.starter_first_staff.title': 'Hire the First Staff',
  'quest.starter_first_staff.reward': 'Small Chest + 60s passive x2',
  'quest.starter_passive_60.title': 'Earn passive income for 1 minute',
  'quest.starter_passive_60.reward': '+250 cash',
  'quest.starter_combo_15.title': 'Reach 15 Combo',
  'questComboUnlockInfo': 'Combo unlocks at Rusty Knife Lv. 15.',
  'quest.starter_combo_15.reward': 'Combo bonus +5%',
  'quest.starter_turbo_use.title': 'Use Turbo',
  'quest.starter_turbo_use.reward': 'Turbo charge +100%',
  'quest.starter_golden_1.title': 'Catch 1 Golden Doner',
  'quest.starter_golden_1.reward': 'Small Chest',
  'quest.starter_knife_item_1.title': 'Complete the First Knife',
  'quest.starter_knife_item_1.reward': 'Master Chest',
  'quest.starter_shop_prepare.title': 'Prepare for the Small Buffet',
  'quest.starter_shop_prepare.reward': 'Shop progression unlock',
  'quest.starter_shop_level_2.title': 'Open the Small Buffet',
  'quest.starter_shop_level_2.reward': 'Global income +5%',
  'quest.starter_open_prestige.title': 'View the Prestige Goal',
  'quest.starter_open_prestige.reward': '+500 cash',
  'settingsTitle': 'Settings',
  'languageTitle': 'Language',
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
  'milestoneTurboBonus': 'Turbo power {value}',
  'milestoneTurboCharge': 'Turbo charge speed {value}',
  'milestoneTurboDuration': 'Turbo duration {value}',
  'milestoneTurboCooldown': 'Turbo cooldown {value}',
  'milestoneOfflineEfficiency': 'Offline efficiency {value}',
  'milestoneOfflineMaxDuration': 'Offline cap {value}',
  'milestoneOfflineAdReward': 'Offline ad reward {value}',
  'milestoneGoldenChance': 'Golden Doner chance {value}',
  'milestoneGoldenReward': 'Golden Doner reward {value}',
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
  'milestone.rustyKnife15': 'Combo system unlocked: +0.25s combo duration',
  'milestone.rustyKnife20': 'Golden Doner can appear: +0.25% chance',
  'milestone.rustyKnife25': 'Sharp Knife ready: chest x1',
  'milestone.feature.critical_cut': 'Critical Cut',
  'milestone.feature.combo': 'Combo',
  'milestone.feature.golden_doner': 'Golden Doner',
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
  'soundSoonLabel': 'Sound settings later',
  'hapticsSoonLabel': 'Haptics settings later',
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
  'upgrade.menu.item.golden_doner': 'Golden Doner',
  'upgrade.menu.item.legendary_sauce_doner': 'Legendary Sauce Doner',
  'upgrade.menu.item.king_wrap': 'King Wrap',
  'upgrade.menu.item.cosmic_doner': 'Cosmic Doner',
  'upgrade.menu.item.universe_doner': "Universe's Doner",
  'upgrade.turbo.name': 'Turbo',
  'upgrade.turbo.description': 'Raises the active turbo tap multiplier.',
  'upgrade.turbo.effectName': 'Turbo Power',
  'upgrade.turbo.item.spicySauce': 'Spicy Sauce',
  'upgrade.turbo.item.kitchenRush': 'Kitchen Rush',
  'upgrade.turbo.item.streetRush': 'Street Rush',
  'upgrade.turbo.item.goldenRush': 'Golden Rush',
  'upgrade.turbo.item.turbo_cut': 'Turbo Cut',
  'upgrade.turbo.item.fast_cut': 'Fast Cut',
  'upgrade.turbo.item.flaming_turbo': 'Flaming Turbo',
  'upgrade.turbo.item.master_mode': 'Master Mode',
  'upgrade.turbo.item.doner_storm': 'Doner Storm',
  'upgrade.turbo.item.apocalypse_cut': 'Apocalypse Cut',
  'upgrade.turbo.item.light_speed_cut': 'Light Speed Cut',
  'upgrade.turbo.item.cosmic_turbo': 'Cosmic Turbo',
  'upgrade.turbo.item.infinite_turbo': 'Infinite Turbo',
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
  'appTitle': 'TapTap Doner',
  'tapPrompt': 'Kizartmak icin dokun',
  'cashLabel': 'Nakit',
  'idleIncomeLabel': 'Pasif / sn',
  'reputationLabel': 'Itibar',
  'shopTitle': 'Mutfak Marketi',
  'upgradesTitle': 'Gelismeler',
  'buyLabel': 'Al',
  'boughtLabel': 'Alindi',
  'levelLabel': 'Sv',
  'currentEffectLabel': 'Mevcut',
  'nextEffectLabel': 'Sonraki',
  'nextItemLabel': 'Siradaki',
  'maxedLabel': 'Maks',
  'upgradeTierLabel': 'Kademe',
  'upgradeNextLevelLabel': 'Sonraki Level',
  'upgradeNextTierLabel': 'Sonraki Kademe',
  'upgradeNextMilestoneLabel': 'Siradaki Milestone',
  'upgradeNextItemPreviewLabel': 'Siradaki Item',
  'upgradeCostLabel': 'Maliyet',
  'upgradeLevelUpAction': 'Level Atlat',
  'upgradeTierUpAction': 'Kademeyi Yukselt',
  'insufficientFundsLabel': 'Yetersiz Para',
  'upgradeMaxLevelLabel': 'Maksimum seviye',
  'upgradeUnlockTitle': 'Yeni Ekipman Acildi!',
  'milestoneUnlockTitle': 'Milestone Acildi!',
  'upgradeNewEffectLabel': 'Yeni etki:',
  'closeLabel': 'Kapat',
  'rushLabel': 'Turbo',
  'rushReady': 'Turbo hazir',
  'rushActive': 'Turbo aktif: {time}',
  'rushCooling': 'Bekleme: {time}',
  'prestigeTitle': 'Prestij',
  'prestigeConfirm': 'Bu kosuyu sifirla ve itibar topla',
  'prestigeAvailable': '{points} itibar hazir',
  'prestigeHint':
      'Prestij itibarini korur; nakit, gelismeler ve gecici gucler sifirlanir.',
  'questLabel': 'Gorev',
  'questProgressLabel': 'Ilerleme',
  'questRewardLabel': 'Odul',
  'questClaimLabel': 'Odulu Al',
  'questCompletedLabel': 'Hazir',
  'quest.starter_tap_10.title': '10 Doner Kes',
  'quest.starter_tap_10.reward': '+50 para',
  'quest.starter_first_upgrade.title': "Ilk Upgrade'i Satin Al",
  'quest.starter_first_upgrade.reward': '+25 para',
  'quest.starter_rusty_knife_5.title': 'Pasli Bicak Lv. 5 yap',
  'quest.starter_rusty_knife_5.reward': '+100 para',
  'quest.starter_lifetime_500.title': '500 para Topla',
  'quest.starter_lifetime_500.reward': 'Kucuk Sandik',
  'quest.starter_rusty_knife_10.title': 'Pasli Bicak Lv. 10 yap',
  'quest.starter_rusty_knife_10.reward': 'Kritik Kesim acilir',
  'quest.starter_critical_3.title': '3 Kritik Kesim Yap',
  'quest.starter_critical_3.reward': '+150 para',
  'quest.starter_first_staff.title': 'Ilk Personeli Al',
  'quest.starter_first_staff.reward': 'Kucuk Sandik + 60 sn pasif x2',
  'quest.starter_passive_60.title': '1 dakika pasif gelir kazan',
  'quest.starter_passive_60.reward': '+250 para',
  'quest.starter_combo_15.title': "15 Combo'ya ulas",
  'questComboUnlockInfo': "Combo ozelligi Pasli Bicak Lv. 15'te acilir.",
  'quest.starter_combo_15.reward': 'Combo bonus +%5',
  'quest.starter_turbo_use.title': 'Turbo Kullan',
  'quest.starter_turbo_use.reward': 'Turbo dolum +%100',
  'quest.starter_golden_1.title': '1 Altin Doner Yakala',
  'quest.starter_golden_1.reward': 'Kucuk Sandik',
  'quest.starter_knife_item_1.title': 'Ilk Bicagi Tamamla',
  'quest.starter_knife_item_1.reward': 'Usta Sandigi',
  'quest.starter_shop_prepare.title': "Kucuk Bufe'ye Hazirlan",
  'quest.starter_shop_prepare.reward': 'Dukkan progression acilir',
  'quest.starter_shop_level_2.title': "Kucuk Bufe'yi Ac",
  'quest.starter_shop_level_2.reward': 'Global gelir +%5',
  'quest.starter_open_prestige.title': 'Prestij hedefini gor',
  'quest.starter_open_prestige.reward': '+500 para',
  'settingsTitle': 'Ayarlar',
  'languageTitle': 'Dil',
  'englishLabel': 'Ingilizce',
  'turkishLabel': 'Turkce',
  'offlineTitle': 'Sen yokken',
  'offlineSummaryTitle': 'Kazanc Ozeti',
  'offlineBaseRewardLabel': 'Temel Kazanc',
  'offlineDoubleRewardLabel': 'Reklam 2x',
  'offlineDoubleOfferTitle': 'Reklamla ikiye katla',
  'offlineDoubleOfferBody':
      'Odullu reklam izleyerek {amount} al. Simdilik sadece gostermelik.',
  'offlineAdPreviewLabel': 'Reklam entegrasyonu sonra',
  'watchAdDoubleLabel': 'Reklam Izle x2',
  'offlineSummary': 'Uretim en fazla {hours} saat boyunca devam etti.',
  'offlineAmount': 'Offline kazanc: {amount}',
  'upgradeItemUnlocked': '{item} acildi',
  'upgradeItemTransition': '{previous} -> {next}',
  'upgradeMilestonePreview': '{item} Lv. {level}',
  'milestoneTapBonus': 'Tap geliri {value}',
  'milestonePassiveBonus': 'Pasif gelir {value}',
  'milestoneGlobalBonus': 'Global gelir {value}',
  'milestoneMenuBonus': 'Menu carpani {value}',
  'milestoneCriticalChance': 'Kritik sans {value}',
  'milestoneCriticalMultiplier': 'Kritik carpan {value}',
  'milestoneComboDuration': 'Combo suresi {value}',
  'milestoneComboMultiplier': 'Combo carpani {value}',
  'milestoneTurboBonus': 'Turbo gucu {value}',
  'milestoneTurboCharge': 'Turbo dolum hizi {value}',
  'milestoneTurboDuration': 'Turbo suresi {value}',
  'milestoneTurboCooldown': 'Turbo bekleme {value}',
  'milestoneOfflineEfficiency': 'Offline verim {value}',
  'milestoneOfflineMaxDuration': 'Offline limit {value}',
  'milestoneOfflineAdReward': 'Offline reklam odulu {value}',
  'milestoneGoldenChance': 'Altin Doner sansi {value}',
  'milestoneGoldenReward': 'Altin Doner odulu {value}',
  'milestoneTipChance': 'Bahsis sansi {value}',
  'milestoneTipValue': 'Bahsis degeri {value}',
  'milestoneSpecialOrder': 'Ozel siparis sansi {value}',
  'milestoneInstantMoney': '+{value} para',
  'milestoneChest': 'Sandik x{count}',
  'milestoneCosmeticToken': 'Kozmetik jeton x{count}',
  'milestoneCollectionUnlock': '{collection} koleksiyonu',
  'milestoneFeatureUnlock': '{feature} acildi',
  'milestoneFeatureGeneric': 'Yeni ozellik',
  'milestone.rustyKnife5': 'Elin alisiyor: tap geliri +%5',
  'milestone.rustyKnife10': 'Kritik Kesim acildi: kritik sans +%1',
  'milestone.rustyKnife15': 'Combo sistemi acildi: combo suresi +0.25s',
  'milestone.rustyKnife20': 'Altin Doner gorunebilir: sans +%0.25',
  'milestone.rustyKnife25': 'Keskin Bicak hazir: sandik x1',
  'milestone.feature.critical_cut': 'Kritik Kesim',
  'milestone.feature.combo': 'Combo',
  'milestone.feature.golden_doner': 'Altin Doner',
  'milestone.feature.unlock_sharp_knife': 'Keskin Bicak',
  'milestone.feature.tips': 'Bahsis',
  'milestone.feature.auto_collect_bonus': 'Otomatik toplama',
  'milestone.feature.special_orders': 'Ozel siparisler',
  'milestone.feature.offline_minimum_claim': 'Minimum offline claim',
  'claimLabel': 'Al',
  'claimDoubleLabel': '2x Al',
  'dismissLabel': 'Gec',
  'adUnavailable': 'Odullu reklam henuz hazir degil.',
  'shopNavLabel': 'Market',
  'prestigeNavLabel': 'Prestij',
  'settingsNavLabel': 'Ayar',
  'lockedLabel': 'Kilitli',
  'unlockedLabel': 'Acik',
  'lockedUntil': 'Toplam {amount} nakitte acilir',
  'soundSoonLabel': 'Ses ayarlari sonra eklenecek',
  'hapticsSoonLabel': 'Titrisim ayarlari sonra eklenecek',
  'upgrade.knife.name': 'Bicak',
  'upgrade.knife.description': 'Her dokunusun gelirini carpar.',
  'upgrade.knife.effectName': 'Click Gucu',
  'upgrade.knife.item.rustyKnife': 'Pasli Bicak',
  'upgrade.knife.item.sharpKnife': 'Keskin Bicak',
  'upgrade.knife.item.doubleKnife': 'Cift Bicak',
  'upgrade.knife.item.electricKnife': 'Elektrikli Bicak',
  'upgrade.knife.item.rusty_knife': 'Pasli Bicak',
  'upgrade.knife.item.sharp_knife': 'Keskin Bicak',
  'upgrade.knife.item.double_knife': 'Cift Bicak',
  'upgrade.knife.item.electric_knife': 'Elektrikli Bicak',
  'upgrade.knife.item.golden_knife': 'Altin Bicak',
  'upgrade.knife.item.flaming_knife': 'Alevli Bicak',
  'upgrade.knife.item.laser_knife': 'Lazer Bicak',
  'upgrade.knife.item.doner_excalibur': 'Doner Excalibur',
  'upgrade.knife.item.master_sword': 'Ustanin Kilici',
  'upgrade.knife.item.cosmic_doner_knife': 'Kozmik Doner Bicagi',
  'upgrade.knife.item.galactic_cutter': 'Galaktik Kesici',
  'upgrade.knife.item.infinite_knife': 'Sonsuz Bicak',
  'upgrade.oven.name': 'Firin',
  'upgrade.oven.description': 'Dokunus ve pasif geliri carpar.',
  'upgrade.oven.effectName': 'Tum Gelir',
  'upgrade.oven.item.coalOven': 'Komur Firini',
  'upgrade.oven.item.stoneOven': 'Tas Firin',
  'upgrade.oven.item.gasOven': 'Gazli Firin',
  'upgrade.oven.item.rotaryOven': 'Doner Firin',
  'upgrade.oven.item.small_oven': 'Kucuk Firin',
  'upgrade.oven.item.large_oven': 'Buyuk Firin',
  'upgrade.oven.item.double_oven': 'Cift Firin',
  'upgrade.oven.item.industrial_oven': 'Endustriyel Firin',
  'upgrade.oven.item.robotic_oven': 'Robotik Firin',
  'upgrade.oven.item.flame_reactor': 'Alev Reaktoru',
  'upgrade.oven.item.laser_grill': 'Lazer Izgara',
  'upgrade.oven.item.space_oven_system': 'Uzay Firin Sistemi',
  'upgrade.oven.item.galactic_oven': 'Galaktik Firin',
  'upgrade.oven.item.infinite_heat_core': 'Sonsuz Isi Cekirdegi',
  'upgrade.staff.name': 'Personel',
  'upgrade.staff.description': 'Her saniye pasif gelir ekler.',
  'upgrade.staff.effectName': 'Pasif Gelir',
  'upgrade.staff.item.helper': 'Yardimci',
  'upgrade.staff.item.apprentice': 'Cirak',
  'upgrade.staff.item.fast_apprentice': 'Hizli Cirak',
  'upgrade.staff.item.usta': 'Usta',
  'upgrade.staff.item.team': 'Mutfak Ekibi',
  'upgrade.staff.item.journeyman': 'Kalfa',
  'upgrade.staff.item.assistant_master': 'Usta Yardimcisi',
  'upgrade.staff.item.doner_master': 'Doner Ustasi',
  'upgrade.staff.item.head_master': 'Bas Usta',
  'upgrade.staff.item.chef': 'Sef',
  'upgrade.staff.item.robot_staff': 'Robot Personel',
  'upgrade.staff.item.ai_master': 'Yapay Zeka Ustasi',
  'upgrade.staff.item.doner_army': 'Doner Ordusu',
  'upgrade.staff.item.franchise_team': 'Franchise Ekibi',
  'upgrade.staff.item.infinite_masters': 'Sonsuz Ustalar',
  'upgrade.menu.name': 'Menu',
  'upgrade.menu.description': 'Her siparisin degerini artirir.',
  'upgrade.menu.effectName': 'Menu Bonusu',
  'upgrade.menu.item.simpleWrap': 'Sade Durum',
  'upgrade.menu.item.saucedMenu': 'Soslu Menu',
  'upgrade.menu.item.comboMenu': 'Kombo Menu',
  'upgrade.menu.item.signatureMenu': 'Imza Menu',
  'upgrade.menu.item.chicken_doner': 'Tavuk Doner',
  'upgrade.menu.item.beef_doner': 'Et Doner',
  'upgrade.menu.item.hatay_style': 'Hatay Usulu',
  'upgrade.menu.item.sauced_doner': 'Soslu Doner',
  'upgrade.menu.item.gourmet_doner': 'Gurme Doner',
  'upgrade.menu.item.golden_doner': 'Altin Doner',
  'upgrade.menu.item.legendary_sauce_doner': 'Efsane Soslu Doner',
  'upgrade.menu.item.king_wrap': 'Kral Durum',
  'upgrade.menu.item.cosmic_doner': 'Kozmik Doner',
  'upgrade.menu.item.universe_doner': 'Evrenin Doneri',
  'upgrade.turbo.name': 'Turbo',
  'upgrade.turbo.description': 'Aktif turbo dokunus carpanini yukseltir.',
  'upgrade.turbo.effectName': 'Turbo Gucu',
  'upgrade.turbo.item.spicySauce': 'Aci Sos',
  'upgrade.turbo.item.kitchenRush': 'Mutfak Rush',
  'upgrade.turbo.item.streetRush': 'Sokak Rush',
  'upgrade.turbo.item.goldenRush': 'Altin Rush',
  'upgrade.turbo.item.turbo_cut': 'Turbo Kesim',
  'upgrade.turbo.item.fast_cut': 'Hizli Kesim',
  'upgrade.turbo.item.flaming_turbo': 'Alevli Turbo',
  'upgrade.turbo.item.master_mode': 'Usta Modu',
  'upgrade.turbo.item.doner_storm': 'Doner Firtinasi',
  'upgrade.turbo.item.apocalypse_cut': 'Kiyamet Kesimi',
  'upgrade.turbo.item.light_speed_cut': 'Isik Hizi Kesim',
  'upgrade.turbo.item.cosmic_turbo': 'Kozmik Turbo',
  'upgrade.turbo.item.infinite_turbo': 'Sonsuz Turbo',
  'upgrade.offline.name': 'Offline',
  'upgrade.offline.description': 'Uzakta daha fazla pasif gelir korur.',
  'upgrade.offline.effectName': 'Offline Verim',
  'upgrade.offline.item.paperLedger': 'Kagit Defter',
  'upgrade.offline.item.warmBox': 'Sicak Kutu',
  'upgrade.offline.item.courierRoute': 'Kurye Rotasi',
  'upgrade.offline.item.nightShift': 'Gece Vardiyasi',
  'upgrade.offline.item.small_safe': 'Kucuk Kasa',
  'upgrade.offline.item.secure_safe': 'Guvenli Kasa',
  'upgrade.offline.item.smart_safe': 'Akilli Kasa',
  'upgrade.offline.item.big_storage': 'Buyuk Depo',
  'upgrade.offline.item.night_shift': 'Gece Vardiyasi',
  'upgrade.offline.item.franchise_system': 'Franchise Sistemi',
  'upgrade.offline.item.auto_branch_network': 'Otomatik Sube Agi',
  'upgrade.offline.item.global_doner_network': 'Global Doner Agi',
  'upgrade.offline.item.infinite_safe_system': 'Sonsuz Kasa Sistemi',
};
