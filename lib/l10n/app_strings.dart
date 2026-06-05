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

  String upgradeMilestonePreview(String itemName, int level) {
    return _template('upgradeMilestonePreview', {
      'item': itemName,
      'level': level.toString(),
    });
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
