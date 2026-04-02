import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taptapdoner/domain/stations/station_catalog.dart';
import 'package:taptapdoner/domain/stations/upgrade_catalog.dart';

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
  String get stationsTitle => _value('stationsTitle');
  String get upgradesTitle => _value('upgradesTitle');
  String get buyLabel => _value('buyLabel');
  String get boughtLabel => _value('boughtLabel');
  String get levelLabel => _value('levelLabel');
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

  String prestigeAvailable(int points) {
    return _template('prestigeAvailable', {'points': points.toString()});
  }

  String lockedUntil(String amount) {
    return _template('lockedUntil', {'amount': amount});
  }

  String stationName(StationId id) => _value('station.${id.key}.name');

  String stationDescription(StationId id) =>
      _value('station.${id.key}.description');

  String upgradeName(UpgradeId id) => _value('upgrade.${id.key}.name');

  String upgradeDescription(UpgradeId id) =>
      _value('upgrade.${id.key}.description');

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
  'stationsTitle': 'Stations',
  'upgradesTitle': 'Upgrades',
  'buyLabel': 'Buy',
  'boughtLabel': 'Owned',
  'levelLabel': 'Lvl',
  'closeLabel': 'Close',
  'rushLabel': 'Rush',
  'rushReady': 'Rush ready',
  'rushActive': 'Rush active: {time}',
  'rushCooling': 'Cooling down: {time}',
  'prestigeTitle': 'Prestige',
  'prestigeConfirm': 'Reset this run and collect reputation',
  'prestigeAvailable': '{points} reputation ready',
  'prestigeHint':
      'Prestige keeps your reputation and resets stations, cash, and upgrades.',
  'settingsTitle': 'Settings',
  'languageTitle': 'Language',
  'englishLabel': 'English',
  'turkishLabel': 'Turkish',
  'offlineTitle': 'While you were away',
  'offlineSummary': 'Production continued for up to {hours}h.',
  'offlineAmount': 'Offline earnings: {amount}',
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
  'station.donerSpit.name': 'Doner Spit',
  'station.donerSpit.description': 'The main rotisserie turning all day long.',
  'station.prepStation.name': 'Prep Station',
  'station.prepStation.description':
      'Fresh wraps, chopped greens, quick hands.',
  'station.drinkFridge.name': 'Drink Fridge',
  'station.drinkFridge.description': 'Ayran and soda boost every basket.',
  'station.cashDesk.name': 'Cash Desk',
  'station.cashDesk.description': 'Faster lines mean more steady income.',
  'station.courierScooter.name': 'Courier Scooter',
  'station.courierScooter.description': 'Take the doner rush across town.',
  'upgrade.tapGloves.name': 'Tap Gloves',
  'upgrade.tapGloves.description': 'Adds +1 cash to every tap.',
  'upgrade.sharpKnife.name': 'Sharp Knife',
  'upgrade.sharpKnife.description': 'Doubles your tap income.',
  'upgrade.greaseMaintenance.name': 'Grease Maintenance',
  'upgrade.greaseMaintenance.description': 'All stations produce 25% more.',
  'upgrade.brandBoard.name': 'Brand Board',
  'upgrade.brandBoard.description': 'Global income gets a 1.5x boost.',
  'upgrade.rushTraining.name': 'Rush Training',
  'upgrade.rushTraining.description': 'Rush lasts longer and returns sooner.',
};

const Map<String, String> _tr = {
  'appTitle': 'TapTap Doner',
  'tapPrompt': 'Kizartmak icin dokun',
  'cashLabel': 'Nakit',
  'idleIncomeLabel': 'Pasif / sn',
  'reputationLabel': 'Itibar',
  'shopTitle': 'Mutfak Marketi',
  'stationsTitle': 'Istasyonlar',
  'upgradesTitle': 'Gelismeler',
  'buyLabel': 'Al',
  'boughtLabel': 'Alindi',
  'levelLabel': 'Sv',
  'closeLabel': 'Kapat',
  'rushLabel': 'Rush',
  'rushReady': 'Rush hazir',
  'rushActive': 'Rush aktif: {time}',
  'rushCooling': 'Bekleme: {time}',
  'prestigeTitle': 'Prestij',
  'prestigeConfirm': 'Bu kosuyu sifirla ve itibar topla',
  'prestigeAvailable': '{points} itibar hazir',
  'prestigeHint':
      'Prestij itibarini korur; istasyonlar, nakit ve gelismeler sifirlanir.',
  'settingsTitle': 'Ayarlar',
  'languageTitle': 'Dil',
  'englishLabel': 'Ingilizce',
  'turkishLabel': 'Turkce',
  'offlineTitle': 'Sen yokken',
  'offlineSummary': 'Uretim en fazla {hours} saat boyunca devam etti.',
  'offlineAmount': 'Offline kazanc: {amount}',
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
  'station.donerSpit.name': 'Doner Tezgahi',
  'station.donerSpit.description': 'Gun boyu donen ana tezgah.',
  'station.prepStation.name': 'Hazirlik Tezgahi',
  'station.prepStation.description': 'Yufka, yesillik ve hizli eller.',
  'station.drinkFridge.name': 'Icecek Dolabi',
  'station.drinkFridge.description': 'Ayran ve gazoz sepetleri buyutur.',
  'station.cashDesk.name': 'Kasa Bankosu',
  'station.cashDesk.description': 'Hizli sira daha duzenli gelir demek.',
  'station.courierScooter.name': 'Kurye Motoru',
  'station.courierScooter.description': 'Doner temposunu tum mahalleye tasir.',
  'upgrade.tapGloves.name': 'Tap Eldiveni',
  'upgrade.tapGloves.description': 'Her dokunusa +1 nakit ekler.',
  'upgrade.sharpKnife.name': 'Keskin Bicak',
  'upgrade.sharpKnife.description': 'Dokunus gelirini ikiye katlar.',
  'upgrade.greaseMaintenance.name': 'Yag Bakimi',
  'upgrade.greaseMaintenance.description': 'Tum istasyonlar %25 fazla uretir.',
  'upgrade.brandBoard.name': 'Marka Tabelasi',
  'upgrade.brandBoard.description': 'Tum gelirleri 1.5x carpar.',
  'upgrade.rushTraining.name': 'Rush Egitimi',
  'upgrade.rushTraining.description':
      'Rush daha uzun surer, daha cabuk geri gelir.',
};
