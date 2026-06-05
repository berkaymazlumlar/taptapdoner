import 'dart:math' as math;

import 'package:taptapdoner/domain/upgrades/upgrade_models.dart';

class UpgradeTrackLogic {
  const UpgradeTrackLogic._();

  static UpgradeItemTier getCurrentItem(UpgradeTrack track) {
    return track.tiers[track.itemIndex];
  }

  static UpgradeItemTier? getNextItem(UpgradeTrack track) {
    final nextIndex = track.itemIndex + 1;

    if (nextIndex >= track.tiers.length) {
      return null;
    }

    return track.tiers[nextIndex];
  }

  static double getCurrentEffect(UpgradeTrack track) {
    final item = getCurrentItem(track);
    return item.baseEffect + ((track.level - 1) * item.levelEffect);
  }

  static double getNextEffect(UpgradeTrack track) {
    final item = getCurrentItem(track);

    if (track.level < item.maxLevel) {
      return item.baseEffect + (track.level * item.levelEffect);
    }

    final nextItem = getNextItem(track);

    if (nextItem == null) {
      return getCurrentEffect(track);
    }

    return nextItem.baseEffect;
  }

  static double getUpgradeCost(UpgradeTrack track) {
    final item = getCurrentItem(track);
    if (track.level >= item.maxLevel) {
      final nextItem = getNextItem(track);
      if (nextItem != null) {
        return nextItem.baseCost;
      }
    }
    return item.baseCost *
        math.pow(item.costMultiplier, track.level - 1).toDouble();
  }

  static bool isMaxed(UpgradeTrack track) {
    final currentItem = getCurrentItem(track);
    final hasNextItem = getNextItem(track) != null;

    return track.level >= currentItem.maxLevel && !hasNextItem;
  }

  static bool willUpgradeToNextItem(UpgradeTrack track) {
    final currentItem = getCurrentItem(track);
    return track.level >= currentItem.maxLevel && getNextItem(track) != null;
  }

  static UpgradeTrack upgradeTrack(UpgradeTrack track) {
    final currentItem = getCurrentItem(track);

    if (track.level < currentItem.maxLevel) {
      return track.copyWith(level: track.level + 1);
    }

    final nextItem = getNextItem(track);

    if (nextItem == null) {
      return track;
    }

    return track.copyWith(itemIndex: track.itemIndex + 1, level: 1);
  }
}

UpgradeItemTier getCurrentItem(UpgradeTrack track) {
  return UpgradeTrackLogic.getCurrentItem(track);
}

UpgradeItemTier? getNextItem(UpgradeTrack track) {
  return UpgradeTrackLogic.getNextItem(track);
}

double getCurrentEffect(UpgradeTrack track) {
  return UpgradeTrackLogic.getCurrentEffect(track);
}

double getNextEffect(UpgradeTrack track) {
  return UpgradeTrackLogic.getNextEffect(track);
}

double getUpgradeCost(UpgradeTrack track) {
  return UpgradeTrackLogic.getUpgradeCost(track);
}

bool isMaxed(UpgradeTrack track) {
  return UpgradeTrackLogic.isMaxed(track);
}

bool willUpgradeToNextItem(UpgradeTrack track) {
  return UpgradeTrackLogic.willUpgradeToNextItem(track);
}

UpgradeTrack upgradeTrack(UpgradeTrack track) {
  return UpgradeTrackLogic.upgradeTrack(track);
}
