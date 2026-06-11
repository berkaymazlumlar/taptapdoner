import 'package:taptapdoner/domain/upgrades/upgrade_logic.dart'
    as upgrade_logic;
import 'package:taptapdoner/domain/upgrades/upgrade_models.dart';

double getTrackEffectById(List<UpgradeTrack> tracks, String id) {
  final track = tracks.firstWhere((track) => track.id == id);
  return upgrade_logic.getCurrentEffect(track);
}

double calculateTapIncome({
  required double baseTap,
  required double knifeEffect,
  required double ovenEffect,
  required double menuEffect,
  required double shopMultiplier,
  required double prestigeMultiplier,
  required double turboMultiplier,
  double collectionTapMultiplier = 1,
  double collectionGlobalMultiplier = 1,
  double temporaryBoostMultiplier = 1,
  double comboMultiplier = 1,
  double criticalMultiplier = 1,
}) {
  return baseTap *
      knifeEffect *
      ovenEffect *
      menuEffect *
      shopMultiplier *
      prestigeMultiplier *
      collectionTapMultiplier *
      collectionGlobalMultiplier *
      temporaryBoostMultiplier *
      turboMultiplier *
      comboMultiplier *
      criticalMultiplier;
}

double calculatePassiveIncomePerSecond({
  required double staffEffect,
  required double ovenEffect,
  required double menuEffect,
  required double shopMultiplier,
  required double prestigeMultiplier,
  double collectionPassiveMultiplier = 1,
  double collectionGlobalMultiplier = 1,
  double temporaryBoostMultiplier = 1,
}) {
  return staffEffect *
      ovenEffect *
      menuEffect *
      shopMultiplier *
      prestigeMultiplier *
      collectionPassiveMultiplier *
      collectionGlobalMultiplier *
      temporaryBoostMultiplier;
}

double calculateOfflineIncome({
  required double passiveIncomePerSecond,
  required double offlineSeconds,
  required double offlineEfficiency,
}) {
  return passiveIncomePerSecond * offlineSeconds * offlineEfficiency;
}
