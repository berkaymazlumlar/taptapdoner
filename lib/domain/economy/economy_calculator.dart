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
  required double prestigeMultiplier,
  required double turboMultiplier,
}) {
  return baseTap *
      knifeEffect *
      ovenEffect *
      menuEffect *
      prestigeMultiplier *
      turboMultiplier;
}

double calculatePassiveIncomePerSecond({
  required double staffEffect,
  required double ovenEffect,
  required double menuEffect,
  required double prestigeMultiplier,
}) {
  return staffEffect * ovenEffect * menuEffect * prestigeMultiplier;
}

double calculateOfflineIncome({
  required double passiveIncomePerSecond,
  required double offlineSeconds,
  required double offlineEfficiency,
}) {
  return passiveIncomePerSecond * offlineSeconds * offlineEfficiency;
}
