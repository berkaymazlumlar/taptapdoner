import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_definitions.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_logic.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_models.dart';

void main() {
  test('static definitions include all tracks at item 0 level 1', () {
    final tracks = defaultUpgradeTracks();

    expect(
      tracks.map((track) => track.id),
      containsAll(['knife', 'oven', 'staff', 'menu', 'offline']),
    );
    expect(tracks, hasLength(5));

    for (final track in tracks) {
      expect(track.itemIndex, 0, reason: '${track.id} starts on first item');
      expect(track.level, 1, reason: '${track.id} starts at Lv.1');
      expect(track.tiers, isNotEmpty);
      expect(track.tiers.every((tier) => tier.maxLevel == 25), isTrue);
      expect(
        track.tiers.every((tier) => tier.milestoneRewards.length == 5),
        isTrue,
      );
    }

    expect(UpgradeDefinitions.track('knife').tiers, hasLength(12));
    expect(UpgradeDefinitions.track('staff').tiers, hasLength(12));
    expect(UpgradeDefinitions.track('oven').tiers, hasLength(10));
    expect(UpgradeDefinitions.track('menu').tiers, hasLength(9));
    expect(UpgradeDefinitions.track('offline').tiers, hasLength(9));
  });

  test('current and next item can be calculated', () {
    final knife = UpgradeDefinitions.track('knife');

    expect(getCurrentItem(knife).name, 'Pasli Bicak');
    expect(getNextItem(knife)?.name, 'Keskin Bicak');
  });

  test('current effect, next effect, and upgrade cost can be calculated', () {
    final knife = UpgradeDefinitions.track('knife').copyWith(level: 3);

    expect(getCurrentEffect(knife), closeTo(1.16, 0.0001));
    expect(getNextEffect(knife), closeTo(1.24, 0.0001));
    expect(getUpgradeCost(knife), closeTo(20 * math.pow(1.22, 2), 0.0001));
  });

  test('normal level upgrade increments active item level', () {
    final knife = UpgradeDefinitions.track('knife');

    final upgraded = upgradeTrack(knife);

    expect(upgraded.itemIndex, 0);
    expect(upgraded.level, 2);
  });

  test('level twenty-five advances to next item level one', () {
    final knifeLv25 = UpgradeDefinitions.track('knife').copyWith(level: 25);

    expect(willUpgradeToNextItem(knifeLv25), isTrue);
    expect(getUpgradeCost(knifeLv25), closeTo(600, 0.0001));

    final upgraded = upgradeTrack(knifeLv25);

    expect(upgraded.itemIndex, 1);
    expect(upgraded.level, 1);
    expect(getCurrentItem(upgraded).name, 'Keskin Bicak');
  });

  test('final item level twenty-five is maxed and cannot advance', () {
    final knife = UpgradeDefinitions.track('knife');
    final maxed = knife.copyWith(
      itemIndex: knife.tiers.length - 1,
      level: knife.tiers.last.maxLevel,
    );

    expect(isMaxed(maxed), isTrue);
    expect(getNextItem(maxed), isNull);
    expect(getNextEffect(maxed), getCurrentEffect(maxed));
    expect(upgradeTrack(maxed), same(maxed));
  });

  test('effect metadata is assigned for track behavior categories', () {
    expect(
      UpgradeDefinitions.track('knife').effectType,
      UpgradeEffectType.tapMultiplier,
    );
    expect(
      UpgradeDefinitions.track('oven').effectType,
      UpgradeEffectType.globalIncomeMultiplier,
    );
    expect(
      UpgradeDefinitions.track('staff').effectType,
      UpgradeEffectType.passiveIncome,
    );
    expect(
      UpgradeDefinitions.track('menu').effectType,
      UpgradeEffectType.menuMultiplier,
    );
    expect(
      UpgradeDefinitions.track('offline').effectType,
      UpgradeEffectType.offlineEfficiency,
    );
  });
}
