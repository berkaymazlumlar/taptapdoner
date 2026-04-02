abstract final class OverlayIds {
  static const gameShell = 'gameShell';
  static const hud = 'hud';
  static const tapZone = 'tapZone';
  static const actionDock = 'actionDock';
  static const shop = 'shop';
  static const prestige = 'prestige';
  static const settings = 'settings';
  static const offlineReward = 'offlineReward';

  static const persistent = [gameShell];

  static const modal = [shop, prestige, settings, offlineReward];
}
