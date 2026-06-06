import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/economy_engine.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/quests/starter_quest_engine.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/background/background_production_calculator.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/services/save/shared_preferences_save_repository.dart';

typedef Clock = DateTime Function();

class GameController extends ChangeNotifier {
  GameController({
    EconomyConfig? config,
    SaveRepository? saveRepository,
    RewardedAdService? adService,
    Clock? clock,
  }) : config = config ?? EconomyConfig.standard(),
       _saveRepository = saveRepository ?? SharedPreferencesSaveRepository(),
       _adService = adService ?? const NoopRewardedAdService(),
       _clock = clock ?? _defaultClock {
    _engine = EconomyEngine(this.config);
    _questEngine = StarterQuestEngine(this.config);
    _backgroundCalculator = BackgroundProductionCalculator(
      config: this.config,
      engine: _engine,
    );
    _state = _questEngine.refresh(
      GameState.initial(this.config, nowUtc: _clock()),
    );
    final nowUtc = _clock();
    _hudSnapshotListenable = ValueNotifier<GameHudSnapshot>(
      _computeHudSnapshot(nowUtc: nowUtc),
    );
    _rushSnapshotListenable = ValueNotifier<RushSnapshot>(
      _computeRushSnapshot(nowUtc: nowUtc),
    );
    _questSnapshotListenable = ValueNotifier<QuestSnapshot?>(
      _computeQuestSnapshot(),
    );
    _shopSnapshotListenable = ValueNotifier<ShopSnapshot>(
      _computeShopSnapshot(nowUtc: nowUtc),
    );
    _prestigeSnapshotListenable = ValueNotifier<PrestigeSnapshot>(
      _computePrestigeSnapshot(),
    );
  }

  static DateTime _defaultClock() => DateTime.now().toUtc();
  static const Duration _activeTickInterval = Duration(milliseconds: 100);
  static const Duration _comboWindow = Duration(seconds: 2);
  static const int _criticalTapCadence = 7;
  static const int _goldenDonerTapCadence = 50;

  final EconomyConfig config;
  final SaveRepository _saveRepository;
  final RewardedAdService _adService;
  final Clock _clock;

  late final EconomyEngine _engine;
  late final StarterQuestEngine _questEngine;
  late final BackgroundProductionCalculator _backgroundCalculator;
  late GameState _state;
  late final ValueNotifier<GameHudSnapshot> _hudSnapshotListenable;
  late final ValueNotifier<RushSnapshot> _rushSnapshotListenable;
  late final ValueNotifier<QuestSnapshot?> _questSnapshotListenable;
  late final ValueNotifier<ShopSnapshot> _shopSnapshotListenable;
  late final ValueNotifier<PrestigeSnapshot> _prestigeSnapshotListenable;
  Future<void> _saveQueue = Future<void>.value();
  Timer? _activeTickTimer;
  DateTime? _lastActiveTickAtUtc;

  bool _isInitialized = false;
  double _passiveCarry = 0;
  double _notifyAccumulator = 0;
  PurchaseResult? _lastPurchaseResult;

  GameState get state => _state;
  PurchaseResult? get lastPurchaseResult => _lastPurchaseResult;
  ValueListenable<GameHudSnapshot> get hudSnapshotListenable =>
      _hudSnapshotListenable;
  ValueListenable<RushSnapshot> get rushSnapshotListenable =>
      _rushSnapshotListenable;
  ValueListenable<QuestSnapshot?> get questSnapshotListenable =>
      _questSnapshotListenable;
  ValueListenable<ShopSnapshot> get shopSnapshotListenable =>
      _shopSnapshotListenable;
  ValueListenable<PrestigeSnapshot> get prestigeSnapshotListenable =>
      _prestigeSnapshotListenable;
  bool get isInitialized => _isInitialized;
  bool get isTicking => _activeTickTimer?.isActive ?? false;
  bool get isRushActive => _rushSnapshotListenable.value.isActive;
  bool get canStartRush => _rushSnapshotListenable.value.canStart;
  bool get hasPendingOfflineReward => _state.pendingOfflineCash > 0;
  bool get canDoubleOfflineReward => _adService.isAvailable;
  int get tapValue => _hudSnapshotListenable.value.tapValue;
  double get passiveIncomePerSecond =>
      _hudSnapshotListenable.value.passiveIncomePerSecond;
  int get availablePrestigePoints =>
      _prestigeSnapshotListenable.value.availablePoints;
  Duration get rushRemaining => _rushSnapshotListenable.value.remaining;
  Duration get rushCooldownRemaining =>
      _rushSnapshotListenable.value.cooldownRemaining;
  List<UpgradeDefinition> get upgrades => config.upgrades;

  Future<void> initialize({required String fallbackLocaleCode}) async {
    final localeCode = _normalizeLocale(fallbackLocaleCode);
    final restored = await _saveRepository.load(config);
    final nowUtc = _clock();
    if (restored == null) {
      _state = _questEngine.refresh(
        GameState.initial(config, nowUtc: nowUtc, localeCode: localeCode),
      );
      _refreshViewModels(nowUtc: nowUtc);
      _isInitialized = true;
      await _queueSave();
      notifyListeners();
      return;
    }

    final grant = _backgroundCalculator.calculate(
      state: restored,
      nowUtc: nowUtc,
    );
    _state = _questEngine.refresh(
      _engine.queueOfflineReward(restored, grant.coins, nowUtc: nowUtc),
    );
    _refreshViewModels(nowUtc: nowUtc);
    _isInitialized = true;
    await _queueSave();
    notifyListeners();
  }

  void tick(Duration elapsed) {
    if (!_isInitialized || elapsed <= Duration.zero) {
      return;
    }
    final nowUtc = _clock();
    final wasRushActive = _rushSnapshotListenable.value.isActive;
    final passiveRate = _hudSnapshotListenable.value.passiveIncomePerSecond;
    final earned = passiveRate * elapsed.inMilliseconds / 1000;
    _passiveCarry += earned;
    _notifyAccumulator += elapsed.inMilliseconds / 1000;

    final wholeCoins = _passiveCarry.floor();
    var refreshEconomySnapshots = false;
    var notifyLegacyListeners = false;
    var questStateChanged = false;

    if (passiveRate > 0) {
      _state = _state.copyWith(
        stats: _state.stats.copyWith(
          passiveIncomeActiveSeconds:
              _state.stats.passiveIncomeActiveSeconds +
              (elapsed.inMilliseconds / 1000),
        ),
      );
    }

    if (wholeCoins > 0) {
      _passiveCarry -= wholeCoins;
      _state = _engine.addCoins(_state, wholeCoins);
      refreshEconomySnapshots = true;
      notifyLegacyListeners = true;
    }

    if (!_state.rush.isActiveAt(nowUtc) &&
        !_state.rush.isCoolingDownAt(nowUtc) &&
        _state.rush.endsAtUtc != null) {
      _state = _state.copyWith(
        rush: _state.rush.copyWith(
          clearEndsAtUtc: true,
          clearCooldownEndsAtUtc: true,
        ),
      );
      refreshEconomySnapshots = true;
    }

    if (!_state.passiveBoost.isActiveAt(nowUtc) &&
        _state.passiveBoost.endsAtUtc != null) {
      _state = _state.copyWith(
        passiveBoost: _state.passiveBoost.copyWith(clearEndsAtUtc: true),
      );
      refreshEconomySnapshots = true;
    }

    final isRushActiveNow = _state.rush.isActiveAt(nowUtc);
    if (wasRushActive != isRushActiveNow) {
      refreshEconomySnapshots = true;
    }

    questStateChanged = _refreshQuestState() || questStateChanged;

    if (refreshEconomySnapshots) {
      _refreshEconomyViewModels(nowUtc: nowUtc);
    }
    if (questStateChanged) {
      _refreshQuestViewModel();
    }

    if (refreshEconomySnapshots || _notifyAccumulator >= 0.2) {
      _notifyAccumulator = 0;
      _refreshRushViewModel(nowUtc: nowUtc);
    }

    if (notifyLegacyListeners) {
      notifyListeners();
    }
  }

  void startTicking() {
    if (isTicking) {
      return;
    }

    _lastActiveTickAtUtc = _clock();
    _activeTickTimer = Timer.periodic(_activeTickInterval, (_) {
      _tickFromClock();
    });
  }

  void stopTicking() {
    _tickFromClock();
    _activeTickTimer?.cancel();
    _activeTickTimer = null;
    _lastActiveTickAtUtc = null;
  }

  Future<void> tap() async {
    final nowUtc = _clock();
    _state = _engine.applyTap(_state, nowUtc: nowUtc);
    _recordTapStats(nowUtc);
    final questStateChanged = _refreshQuestState();
    _refreshEconomyViewModels();
    if (questStateChanged) {
      _refreshQuestViewModel();
    }
    notifyListeners();
  }

  Future<bool> buyUpgrade(UpgradeId id) async {
    final result = _engine.buyUpgrade(_state, id);
    _lastPurchaseResult = result;
    if (!result.success) {
      return false;
    }
    _state = result.state.copyWith(
      stats: result.state.stats.copyWith(
        totalUpgradesPurchased: _state.stats.totalUpgradesPurchased + 1,
      ),
    );
    final questStateChanged = _refreshQuestState();
    _refreshEconomyViewModels();
    if (questStateChanged) {
      _refreshQuestViewModel();
    }
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<bool> startRush() async {
    if (!canStartRush) {
      return false;
    }
    _state = _engine.startRush(_state, nowUtc: _clock());
    _state = _state.copyWith(
      stats: _state.stats.copyWith(
        turboUsedCount: _state.stats.turboUsedCount + 1,
      ),
    );
    final questStateChanged = _refreshQuestState();
    _refreshViewModels();
    if (questStateChanged) {
      _refreshQuestViewModel();
    }
    notifyListeners();
    unawaited(_queueSave());
    return true;
  }

  Future<bool> claimActiveQuestReward() async {
    final previousState = _state;
    _state = _questEngine.claimActiveReward(_state, nowUtc: _clock());
    if (identical(previousState, _state) || previousState == _state) {
      return false;
    }
    _refreshViewModels();
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<bool> applyPrestige() async {
    if (availablePrestigePoints <= 0) {
      return false;
    }
    _state = _engine.applyPrestige(_state, nowUtc: _clock());
    _state = _questEngine.refresh(_state);
    _refreshViewModels();
    notifyListeners();
    await _queueSave();
    return true;
  }

  void markPrestigeScreenOpened() {
    if (_state.stats.openPrestigeScreenOnce) {
      return;
    }
    _state = _state.copyWith(
      stats: _state.stats.copyWith(openPrestigeScreenOnce: true),
    );
    final questStateChanged = _refreshQuestState();
    if (questStateChanged) {
      _refreshQuestViewModel();
    }
    notifyListeners();
    unawaited(_queueSave());
  }

  Future<void> setLocaleCode(String localeCode) async {
    _state = _state.copyWith(
      localeCode: _normalizeLocale(localeCode),
      lastSavedAtUtc: _clock(),
    );
    _refreshViewModels();
    notifyListeners();
    await _queueSave();
  }

  Future<void> checkpointLifecycle() async {
    if (!_isInitialized) {
      return;
    }
    await _queueSave();
  }

  Future<void> reconcileBackground() async {
    if (!_isInitialized) {
      return;
    }
    final nowUtc = _clock();
    final grant = _backgroundCalculator.calculate(
      state: _state,
      nowUtc: nowUtc,
    );
    _state = _questEngine.refresh(
      _engine.queueOfflineReward(_state, grant.coins, nowUtc: nowUtc),
    );
    _refreshViewModels(nowUtc: nowUtc);
    await _queueSave();
    notifyListeners();
  }

  Future<void> claimOfflineReward({int multiplier = 1}) async {
    final nowUtc = _clock();
    final reward = _state.pendingOfflineCash * multiplier;
    _state = _engine.applyOfflineReward(_state, reward, nowUtc: nowUtc);
    _state = _questEngine.refresh(_state);
    _refreshViewModels(nowUtc: nowUtc);
    notifyListeners();
    await _queueSave();
  }

  Future<RewardOutcome> claimOfflineRewardWithAd() async {
    final result = await _adService.showOfflineRewardDouble();
    if (result == RewardOutcome.granted) {
      await claimOfflineReward(multiplier: 2);
    }
    return result;
  }

  Future<void> dismissOfflineReward() async {
    _state = _engine.clearPendingOfflineReward(_state, nowUtc: _clock());
    _refreshViewModels();
    notifyListeners();
    await _queueSave();
  }

  void hydrate(GameState nextState) {
    _state = _questEngine.refresh(nextState);
    _refreshViewModels();
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    stopTicking();
    _hudSnapshotListenable.dispose();
    _rushSnapshotListenable.dispose();
    _questSnapshotListenable.dispose();
    _shopSnapshotListenable.dispose();
    _prestigeSnapshotListenable.dispose();
    super.dispose();
  }

  String _normalizeLocale(String localeCode) {
    return localeCode == 'tr' ? 'tr' : 'en';
  }

  Future<void> _queueSave() {
    final snapshot = _state.copyWith(lastSavedAtUtc: _clock());
    _state = snapshot;
    _refreshViewModels();
    _saveQueue = _saveQueue.catchError((_) {}).then((_) {
      return _saveRepository.save(snapshot);
    });
    return _saveQueue;
  }

  void _tickFromClock() {
    if (!_isInitialized) {
      return;
    }

    final nowUtc = _clock();
    final previousTickAtUtc = _lastActiveTickAtUtc ?? nowUtc;
    _lastActiveTickAtUtc = nowUtc;
    tick(nowUtc.difference(previousTickAtUtc));
  }

  void _refreshViewModels({DateTime? nowUtc}) {
    _refreshEconomyViewModels(nowUtc: nowUtc);
    _refreshRushViewModel(nowUtc: nowUtc);
    _refreshQuestViewModel();
  }

  void _refreshEconomyViewModels({DateTime? nowUtc}) {
    final effectiveNow = (nowUtc ?? _clock()).toUtc();
    final hudSnapshot = _computeHudSnapshot(nowUtc: effectiveNow);
    _setSnapshotIfChanged(_hudSnapshotListenable, hudSnapshot);
    _setSnapshotIfChanged(
      _shopSnapshotListenable,
      _computeShopSnapshot(nowUtc: effectiveNow, hudSnapshot: hudSnapshot),
    );
    _setSnapshotIfChanged(
      _prestigeSnapshotListenable,
      _computePrestigeSnapshot(),
    );
  }

  void _refreshRushViewModel({DateTime? nowUtc}) {
    _setSnapshotIfChanged(
      _rushSnapshotListenable,
      _computeRushSnapshot(nowUtc: (nowUtc ?? _clock()).toUtc()),
    );
  }

  void _refreshQuestViewModel() {
    _setSnapshotIfChanged(_questSnapshotListenable, _computeQuestSnapshot());
  }

  bool _refreshQuestState() {
    final previousQuests = _state.quests;
    final nextState = _questEngine.refresh(_state);
    final questStateChanged = !mapEquals(previousQuests, nextState.quests);
    final statsChanged = nextState.stats.shopLevel != _state.stats.shopLevel;
    if (!questStateChanged && !statsChanged) {
      return false;
    }
    _state = nextState;
    if (_hasNewCompletedQuest(previousQuests, nextState.quests)) {
      unawaited(_queueSave());
    }
    return true;
  }

  bool _hasNewCompletedQuest(
    Map<String, QuestProgress> previous,
    Map<String, QuestProgress> next,
  ) {
    for (final entry in next.entries) {
      if (entry.value.status != QuestStatus.completed ||
          entry.value.rewardClaimed) {
        continue;
      }
      if (previous[entry.key]?.status != QuestStatus.completed) {
        return true;
      }
    }
    return false;
  }

  void _recordTapStats(DateTime nowUtc) {
    final stats = _state.stats;
    final nextTapCount = stats.tapCount + 1;
    var nextCurrentCombo = 0;
    var nextMaxCombo = stats.maxCombo;
    if (_state.milestones.hasFeature('combo')) {
      final lastTapAt = stats.lastTapAtUtc;
      final keepsCombo =
          lastTapAt != null && nowUtc.difference(lastTapAt) <= _comboWindow;
      nextCurrentCombo = keepsCombo ? stats.currentCombo + 1 : 1;
      nextMaxCombo = math.max(nextMaxCombo, nextCurrentCombo);
    }

    var nextCriticalCount = stats.criticalCutCount;
    if (_state.milestones.hasFeature('critical_cut') &&
        nextTapCount % _criticalTapCadence == 0) {
      nextCriticalCount += 1;
    }

    var nextGoldenDonerCollected = stats.goldenDonerCollected;
    var goldenDonerReward = 0;
    if (_state.milestones.hasFeature('golden_doner') &&
        nextTapCount % _goldenDonerTapCadence == 0) {
      nextGoldenDonerCollected += 1;
      goldenDonerReward = math.max(
        50,
        math.max(tapValue * 25, (passiveIncomePerSecond * 120).round()),
      );
    }

    _state = _state.copyWith(
      stats: stats.copyWith(
        tapCount: nextTapCount,
        currentCombo: nextCurrentCombo,
        maxCombo: nextMaxCombo,
        criticalCutCount: nextCriticalCount,
        goldenDonerCollected: nextGoldenDonerCollected,
        lastTapAtUtc: nowUtc,
      ),
    );

    if (goldenDonerReward > 0) {
      _state = _engine.addCoins(_state, goldenDonerReward);
    }
  }

  GameHudSnapshot _computeHudSnapshot({required DateTime nowUtc}) {
    return GameHudSnapshot(
      cash: _state.cash,
      passiveIncomePerSecond: _engine.passiveIncomePerSecond(
        _state,
        nowUtc: nowUtc,
      ),
      reputation: _state.prestige.reputation,
      tapValue: _engine.tapValue(_state, nowUtc: nowUtc),
    );
  }

  RushSnapshot _computeRushSnapshot({required DateTime nowUtc}) {
    return RushSnapshot(
      isActive: _state.rush.isActiveAt(nowUtc),
      canStart: _engine.canStartRush(_state, nowUtc: nowUtc),
      remaining: _displayDuration(_state.rush.remainingActive(nowUtc)),
      cooldownRemaining: _displayDuration(
        _state.rush.remainingCooldown(nowUtc),
      ),
    );
  }

  QuestSnapshot? _computeQuestSnapshot() {
    final progress = _questEngine.activeQuest(_state);
    if (progress == null) {
      return null;
    }
    return QuestSnapshot(
      questId: progress.questId,
      status: progress.status,
      currentValue: progress.currentValue,
      targetValue: progress.targetValue,
      rewardClaimed: progress.rewardClaimed,
    );
  }

  ShopSnapshot _computeShopSnapshot({
    required DateTime nowUtc,
    GameHudSnapshot? hudSnapshot,
  }) {
    final hud = hudSnapshot ?? _computeHudSnapshot(nowUtc: nowUtc);
    final upgrades = <UpgradeId, ShopUpgradeSnapshot>{};
    for (final upgrade in config.upgrades) {
      final state = _state.upgrade(upgrade.id);
      final totalLevel = _engine.upgradeTotalLevel(_state, upgrade.id);
      final maxed = _engine.isUpgradeMaxed(upgrade, state);
      final cost = _engine.upgradeCost(upgrade, state);
      final itemLevel = upgrade.itemLevelForTotalLevel(totalLevel);
      final currentItem = _engine.currentUpgradeItem(_state, upgrade.id);
      final nextItem = _engine.nextUpgradeItem(_state, upgrade.id);
      final nextMilestone = upgrade.nextMilestoneForLevel(totalLevel);
      final nextMilestoneItem = upgrade.nextMilestoneItemForLevel(totalLevel);
      upgrades[upgrade.id] = ShopUpgradeSnapshot(
        totalLevel: totalLevel,
        itemLevel: itemLevel,
        maxItemLevel: currentItem.maxLevel,
        maxLevel: upgrade.maxLevel,
        currentItemTier: currentItem.tier,
        currentItemKey: currentItem.key,
        nextItemKey: nextItem?.key,
        nextItemEffect: nextItem?.effectForItemLevel(1),
        nextMilestoneItemKey: nextMilestoneItem?.key,
        nextMilestoneLevel: nextMilestone?.level,
        nextMilestoneReward: nextMilestone,
        currentEffect: _engine.upgradeEffect(_state, upgrade.id),
        nextEffect: _engine.nextUpgradeEffect(_state, upgrade.id),
        maxed: maxed,
        unlocksNextItem:
            !maxed && totalLevel > 0 && itemLevel == currentItem.maxLevel,
        cost: cost,
        canAfford: !maxed && _state.cash >= cost,
      );
    }

    return ShopSnapshot(
      hud: hud,
      upgrades: Map<UpgradeId, ShopUpgradeSnapshot>.unmodifiable(upgrades),
    );
  }

  PrestigeSnapshot _computePrestigeSnapshot() {
    final availablePoints = _engine.availablePrestigePoints(_state);
    return PrestigeSnapshot(
      availablePoints: availablePoints,
      reputation: _state.prestige.reputation,
      runCashEarned: _state.prestige.runCashEarned,
      threshold: config.prestigeThreshold,
      currentMultiplier: _engine.prestigeMultiplier(_state),
      newMultiplier: _engine.prestigeMultiplierForPoints(
        _state.prestige.reputation + availablePoints,
      ),
      resetItems: const [
        'Current money, all upgrade progress, temporary boosts, and turbo state',
      ],
      keptItems: const [
        'Prestige points',
        'Prestige multiplier',
        'Total lifetime stats',
        'IAP purchases',
        'Ad removal status',
        'Permanent premium boosts',
      ],
    );
  }

  Duration _displayDuration(Duration duration) {
    if (duration <= Duration.zero) {
      return Duration.zero;
    }
    return Duration(seconds: duration.inSeconds);
  }

  void _setSnapshotIfChanged<T>(ValueNotifier<T> notifier, T nextValue) {
    if (notifier.value == nextValue) {
      return;
    }
    notifier.value = nextValue;
  }
}
