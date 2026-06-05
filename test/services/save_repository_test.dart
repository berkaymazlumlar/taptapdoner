import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/services/save/shared_preferences_save_repository.dart';

void main() {
  final config = EconomyConfig.standard();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save repository round-trips state', () async {
    final knife = config.upgrade(UpgradeId.knife);
    final repository = SharedPreferencesSaveRepository();
    final state =
        GameState.initial(
          config,
          nowUtc: DateTime.utc(2026, 4, 1, 12),
          localeCode: 'tr',
        ).copyWith(
          cash: 1234,
          pendingOfflineCash: 87,
          upgrades: {
            for (final definition in config.upgrades)
              definition.id: definition.id == UpgradeId.knife
                  ? UpgradeState.fromTotalLevel(
                      definition: knife,
                      totalLevel: 30,
                    )
                  : UpgradeState.fromTotalLevel(
                      definition: definition,
                      totalLevel: 0,
                    ),
          },
        );

    await repository.save(state);
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('taptapdoner.save')!;
    final loaded = await repository.load(config);

    expect(raw, contains('"id":"knife"'));
    expect(raw, contains('"itemIndex":1'));
    expect(raw, contains('"level":6'));
    expect(raw, isNot(contains('stations')));
    expect(raw, isNot(contains('baseCost')));
    expect(raw, isNot(contains('tiers')));
    expect(loaded, isNotNull);
    expect(loaded!.cash, 1234);
    expect(loaded.pendingOfflineCash, 87);
    expect(loaded.localeCode, 'tr');
    expect(loaded.upgrade(UpgradeId.knife).itemIndex, 1);
    expect(loaded.upgrade(UpgradeId.knife).level, 6);
  });

  test('corrupt payload returns null', () async {
    SharedPreferences.setMockInitialValues({'taptapdoner.save': '{bad json'});
    final repository = SharedPreferencesSaveRepository();

    final loaded = await repository.load(config);

    expect(loaded, isNull);
  });

  test(
    'unknown ids and legacy stations are ignored while known upgrades survive',
    () async {
      SharedPreferences.setMockInitialValues({
        'taptapdoner.save':
            '''
      {
        "schemaVersion": 1,
        "cash": 0,
        "lifetimeCash": 0,
        "pendingOfflineCash": 0,
        "stations": [
          {"id":"donerSpit","level":3},
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
      expect(loaded!.toJson().containsKey('stations'), isFalse);
      expect(loaded.upgrade(config.upgrades.first.id).purchased, isTrue);
    },
  );

  test('missing upgrade list creates default upgrade progress', () async {
    SharedPreferences.setMockInitialValues({
      'taptapdoner.save': '''
      {
        "schemaVersion": 3,
        "cash": 55,
        "lifetimeCash": 55,
        "pendingOfflineCash": 0,
        "stations": [],
        "prestige": {"reputation": 4, "runCashEarned": 500},
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
    expect(loaded!.cash, 55);
    for (final upgrade in config.upgrades) {
      expect(loaded.upgrade(upgrade.id).itemIndex, 0, reason: upgrade.id.key);
      expect(loaded.upgrade(upgrade.id).level, 1, reason: upgrade.id.key);
    }
  });

  test(
    'invalid upgrade progress is clamped and unknown tracks are ignored',
    () async {
      SharedPreferences.setMockInitialValues({
        'taptapdoner.save': '''
      {
        "schemaVersion": 3,
        "cash": 0,
        "lifetimeCash": 0,
        "pendingOfflineCash": 0,
        "stations": [],
        "upgrades": [
          {"id":"knife","itemIndex":-4,"level":0},
          {"id":"oven","itemIndex":999,"level":999},
          {"id":"staff","itemIndex":1,"level":999},
          {"id":"futureUpgrade","itemIndex":1,"level":4}
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
      expect(loaded!.upgrade(UpgradeId.knife).itemIndex, 0);
      expect(loaded.upgrade(UpgradeId.knife).level, 1);
      expect(
        loaded.upgrade(UpgradeId.oven).itemIndex,
        config.upgrade(UpgradeId.oven).items.length - 1,
      );
      expect(
        loaded.upgrade(UpgradeId.oven).level,
        config.upgrade(UpgradeId.oven).items.last.maxLevel,
      );
      expect(loaded.upgrade(UpgradeId.staff).itemIndex, 1);
      expect(
        loaded.upgrade(UpgradeId.staff).level,
        config.upgrade(UpgradeId.staff).items[1].maxLevel,
      );
      expect(loaded.upgrade(UpgradeId.menu).itemIndex, 0);
      expect(loaded.upgrade(UpgradeId.menu).level, 1);
    },
  );

  test(
    'old upgrade saves migrate without losing money or prestige data',
    () async {
      SharedPreferences.setMockInitialValues({
        'taptapdoner.save': '''
      {
        "schemaVersion": 2,
        "cash": 12345,
        "lifetimeCash": 999999,
        "pendingOfflineCash": 432,
        "stations": [],
        "upgrades": [
          {"id":"knife","level":10},
          {"id":"rushTraining","purchased":true}
        ],
        "prestige": {"reputation": 7, "runCashEarned": 7654321},
        "rush": {},
        "lastActiveAtUtc": "2026-04-01T12:00:00.000Z",
        "lastSavedAtUtc": "2026-04-01T12:00:00.000Z",
        "localeCode": "tr"
      }
      ''',
      });
      final repository = SharedPreferencesSaveRepository();

      final loaded = await repository.load(config);

      expect(loaded, isNotNull);
      expect(loaded!.cash, 12345);
      expect(loaded.lifetimeCash, 999999);
      expect(loaded.pendingOfflineCash, 432);
      expect(loaded.prestige.reputation, 7);
      expect(loaded.prestige.runCashEarned, 7654321);
      expect(loaded.localeCode, 'tr');
      expect(loaded.upgrade(UpgradeId.knife).itemIndex, 0);
      expect(loaded.upgrade(UpgradeId.knife).level, 10);
      expect(loaded.upgrade(UpgradeId.turbo).itemIndex, 0);
      expect(loaded.upgrade(UpgradeId.turbo).level, 2);
    },
  );
}
