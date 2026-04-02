import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/stations/station_catalog.dart';
import 'package:taptapdoner/domain/stations/upgrade_catalog.dart';
import 'package:taptapdoner/services/save/shared_preferences_save_repository.dart';

void main() {
  final config = EconomyConfig.standard();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save repository round-trips state', () async {
    final repository = SharedPreferencesSaveRepository();
    final state = GameState.initial(
      config,
      nowUtc: DateTime.utc(2026, 4, 1, 12),
      localeCode: 'tr',
    ).copyWith(cash: 1234, pendingOfflineCash: 87);

    await repository.save(state);
    final loaded = await repository.load(config);

    expect(loaded, isNotNull);
    expect(loaded!.cash, 1234);
    expect(loaded.pendingOfflineCash, 87);
    expect(loaded.localeCode, 'tr');
  });

  test('corrupt payload returns null', () async {
    SharedPreferences.setMockInitialValues({'taptapdoner.save': '{bad json'});
    final repository = SharedPreferencesSaveRepository();

    final loaded = await repository.load(config);

    expect(loaded, isNull);
  });

  test('unknown ids are ignored while known entries survive', () async {
    SharedPreferences.setMockInitialValues({
      'taptapdoner.save':
          '''
      {
        "schemaVersion": 1,
        "cash": 0,
        "lifetimeCash": 0,
        "pendingOfflineCash": 0,
        "stations": [
          {"id":"${config.stations.first.id.key}","level":3},
          {"id":"futureStation","level":9}
        ],
        "upgrades": [
          {"id":"${config.upgrades.first.id.key}","purchased":true},
          {"id":"futureUpgrade","purchased":true}
        ],
        "prestige": {"reputation": 0, "runCashEarned": 0},
        "rush": {},
        "lastActiveAtUtc": "2026-04-01T12:00:00.000Z",
        "lastSavedAtUtc": "2026-04-01T12:00:00.000Z",
        "localeCode": "en"
      }
      ''',
    });
    final repository = SharedPreferencesSaveRepository();

    final loaded = await repository.load(config);

    expect(loaded, isNotNull);
    expect(loaded!.station(config.stations.first.id).level, 3);
    expect(loaded.upgrade(config.upgrades.first.id).purchased, isTrue);
  });
}
