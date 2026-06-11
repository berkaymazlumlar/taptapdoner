import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/economy_engine.dart';
import 'package:taptapdoner/domain/progression/achievement_catalog.dart';
import 'package:taptapdoner/domain/progression/collection_catalog.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/progression/prestige_shop_catalog.dart';
import 'package:taptapdoner/domain/progression/shop_progression_catalog.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/quests/starter_quest_engine.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/background/background_production_calculator.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/services/save/shared_preferences_save_repository.dart';

typedef Clock = DateTime Function();

class TapOutcome {
  const TapOutcome({
    required this.coins,
    required this.combo,
    required this.comboMultiplier,
    required this.isCritical,
    required this.criticalMultiplier,
    required this.goldenDonerHit,
    required this.goldenDonerCompleted,
    required this.goldenDonerReward,
    required this.goldenDonerHits,
    required this.goldenDonerRequiredHits,
  });

  final int coins;
  final int combo;
  final double comboMultiplier;
  final bool isCritical;
  final double criticalMultiplier;
  final bool goldenDonerHit;
  final bool goldenDonerCompleted;
  final int goldenDonerReward;
  final int goldenDonerHits;
  final int goldenDonerRequiredHits;
}

class GameController extends ChangeNotifier {
  GameController({
    EconomyConfig? config,
    SaveRepository? saveRepository,
    RewardedAdService? adService,
    Clock? clock,
    math.Random? random,
  }) : config = config ?? EconomyConfig.standard(),
       _saveRepository = saveRepository ?? SharedPreferencesSaveRepository(),
       _adService = adService ?? const NoopRewardedAdService(),
       _clock = clock ?? _defaultClock,
       _random = random ?? math.Random() {
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
    _activePlaySnapshotListenable = ValueNotifier<ActivePlaySnapshot>(
      _computeActivePlaySnapshot(nowUtc: nowUtc),
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
    _progressionSnapshotListenable = ValueNotifier<ProgressionSnapshot>(
      _computeProgressionSnapshot(),
    );
  }

  static DateTime _defaultClock() => DateTime.now().toUtc();
  static const Duration _activeTickInterval = Duration(milliseconds: 100);

  final EconomyConfig config;
  final SaveRepository _saveRepository;
  final RewardedAdService _adService;
  final Clock _clock;
  final math.Random _random;

  late final EconomyEngine _engine;
  late final StarterQuestEngine _questEngine;
  late final BackgroundProductionCalculator _backgroundCalculator;
  late GameState _state;
  late final ValueNotifier<GameHudSnapshot> _hudSnapshotListenable;
  late final ValueNotifier<RushSnapshot> _rushSnapshotListenable;
  late final ValueNotifier<ActivePlaySnapshot> _activePlaySnapshotListenable;
  late final ValueNotifier<QuestSnapshot?> _questSnapshotListenable;
  late final ValueNotifier<ShopSnapshot> _shopSnapshotListenable;
  late final ValueNotifier<PrestigeSnapshot> _prestigeSnapshotListenable;
  late final ValueNotifier<ProgressionSnapshot> _progressionSnapshotListenable;
  Future<void> _saveQueue = Future<void>.value();
  Timer? _activeTickTimer;
  DateTime? _lastActiveTickAtUtc;

  bool _isInitialized = false;
  double _passiveCarry = 0;
  double _notifyAccumulator = 0;
  PurchaseResult? _lastPurchaseResult;
  LastChestRewardSnapshot? _lastChestRewardSnapshot;
  ShopLevelUpSnapshot? _pendingShopLevelUpSnapshot;

  GameState get state => _state;
  PurchaseResult? get lastPurchaseResult => _lastPurchaseResult;
  ValueListenable<GameHudSnapshot> get hudSnapshotListenable =>
      _hudSnapshotListenable;
  ValueListenable<RushSnapshot> get rushSnapshotListenable =>
      _rushSnapshotListenable;
  ValueListenable<ActivePlaySnapshot> get activePlaySnapshotListenable =>
      _activePlaySnapshotListenable;
  ValueListenable<QuestSnapshot?> get questSnapshotListenable =>
      _questSnapshotListenable;
  ValueListenable<ShopSnapshot> get shopSnapshotListenable =>
      _shopSnapshotListenable;
  ValueListenable<PrestigeSnapshot> get prestigeSnapshotListenable =>
      _prestigeSnapshotListenable;
  ValueListenable<ProgressionSnapshot> get progressionSnapshotListenable =>
      _progressionSnapshotListenable;
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

  ShopLevelUpSnapshot? consumeShopLevelUpSnapshot() {
    final snapshot = _pendingShopLevelUpSnapshot;
    _pendingShopLevelUpSnapshot = null;
    return snapshot;
  }

  Future<void> initialize({required String fallbackLocaleCode}) async {
    final localeCode = _normalizeLocale(fallbackLocaleCode);
    final restored = await _saveRepository.load(config);
    final nowUtc = _clock();
    if (restored == null) {
      _state = _questEngine.refresh(
        GameState.initial(config, nowUtc: nowUtc, localeCode: localeCode),
      );
      _refreshProgressionState();
      _refreshActivePlayState(nowUtc);
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
    _refreshProgressionState();
    _refreshActivePlayState(nowUtc);
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
    var activePlayStateChanged = false;
    var notifyLegacyListeners = false;
    var questStateChanged = false;
    var progressionStateChanged = false;

    activePlayStateChanged = _refreshActivePlayState(nowUtc);

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
      progressionStateChanged = _refreshProgressionState();
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
    if (progressionStateChanged) {
      _refreshProgressionViewModel();
    }

    if (refreshEconomySnapshots || _notifyAccumulator >= 0.2) {
      _notifyAccumulator = 0;
      _refreshRushViewModel(nowUtc: nowUtc);
    }
    if (activePlayStateChanged ||
        _state.goldenDoner.isActiveAt(nowUtc) ||
        _state.stats.currentCombo > 0) {
      _refreshActivePlayViewModel(nowUtc: nowUtc);
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

  Future<TapOutcome> tap() async {
    final nowUtc = _clock();
    final outcome = _applyTapOutcome(nowUtc);
    final questStateChanged = _refreshQuestState();
    _refreshProgressionState();
    _refreshViewModels(nowUtc: nowUtc);
    if (questStateChanged) {
      _refreshQuestViewModel();
    }
    _refreshProgressionViewModel();
    notifyListeners();
    return outcome;
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
    final milestoneReward = result.milestoneGrant?.reward;
    if (milestoneReward?.type == MilestoneRewardType.chest) {
      _grantChest(ChestType.small, quantity: milestoneReward?.quantity ?? 1);
    }
    final questStateChanged = _refreshQuestState();
    _refreshProgressionState();
    _refreshEconomyViewModels();
    _refreshProgressionViewModel();
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
    _refreshProgressionState();
    _refreshViewModels();
    if (questStateChanged) {
      _refreshQuestViewModel();
    }
    notifyListeners();
    unawaited(_queueSave());
    return true;
  }

  Future<bool> claimActiveQuestReward() async {
    final activeQuestId = _questSnapshotListenable.value?.questId;
    final questReward = activeQuestId == null
        ? null
        : StarterQuestCatalog.byId[activeQuestId]?.reward;
    final previousState = _state;
    _state = _questEngine.claimActiveReward(_state, nowUtc: _clock());
    if (identical(previousState, _state) || previousState == _state) {
      return false;
    }
    if (questReward != null && questReward.chests > 0) {
      _grantChest(questReward.chestType, quantity: questReward.chests);
    }
    _refreshProgressionState();
    _refreshViewModels();
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<bool> claimAchievementReward(String achievementId) async {
    _refreshProgressionState();
    final achievement = AchievementCatalog.byId[achievementId];
    final progress = _state.achievements[achievementId];
    if (achievement == null ||
        progress == null ||
        !progress.isCompleted ||
        progress.isRewardClaimed) {
      return false;
    }

    var nextState = _applyAchievementReward(_state, achievement.reward);
    final nextAchievements = Map<String, AchievementProgress>.from(
      nextState.achievements,
    );
    nextAchievements[achievementId] = progress.copyWith(
      isCompleted: true,
      isRewardClaimed: true,
      currentValue: math.max(progress.currentValue, achievement.targetValue),
    );
    _state = nextState.copyWith(
      achievements: Map<String, AchievementProgress>.unmodifiable(
        nextAchievements,
      ),
    );
    _refreshProgressionState();
    _refreshViewModels();
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<LastChestRewardSnapshot?> openChest(ChestType type) async {
    if (_state.chestInventory.count(type) <= 0) {
      return null;
    }
    final reward = _rollChestReward(type);
    _state = _state.copyWith(
      chestInventory: _state.chestInventory.remove(type),
      stats: _state.stats.copyWith(chestsOpened: _state.stats.chestsOpened + 1),
    );
    _state = _applyChestReward(_state, reward, nowUtc: _clock());
    _lastChestRewardSnapshot = LastChestRewardSnapshot(
      chestType: type,
      rewardType: reward.rewardType,
      amount: reward.amount,
      label: _chestRewardLabel(reward),
    );
    _refreshProgressionState();
    _refreshViewModels();
    notifyListeners();
    await _queueSave();
    return _lastChestRewardSnapshot;
  }

  Future<bool> applyPrestige() async {
    if (availablePrestigePoints <= 0) {
      return false;
    }
    _state = _engine.applyPrestige(_state, nowUtc: _clock());
    _state = _questEngine.refresh(_state);
    _refreshProgressionState();
    _refreshViewModels();
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<bool> buyPrestigeUpgrade(String upgradeId) async {
    final result = _engine.buyPrestigeUpgrade(_state, upgradeId);
    if (!result.success) {
      return false;
    }
    _state = result.state;
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
    _refreshProgressionState();
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
    _refreshActivePlayState(_clock());
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
    _refreshProgressionState();
    _refreshActivePlayState(nowUtc);
    _refreshViewModels(nowUtc: nowUtc);
    await _queueSave();
    notifyListeners();
  }

  Future<void> claimOfflineReward({int multiplier = 1}) async {
    final nowUtc = _clock();
    final reward = _state.pendingOfflineCash * multiplier;
    _state = _engine.applyOfflineReward(_state, reward, nowUtc: nowUtc);
    _state = _questEngine.refresh(_state);
    _refreshProgressionState();
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
    final nowUtc = _clock();
    _refreshProgressionState();
    _refreshActivePlayState(nowUtc);
    _refreshViewModels(nowUtc: nowUtc);
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    stopTicking();
    _hudSnapshotListenable.dispose();
    _rushSnapshotListenable.dispose();
    _activePlaySnapshotListenable.dispose();
    _questSnapshotListenable.dispose();
    _shopSnapshotListenable.dispose();
    _prestigeSnapshotListenable.dispose();
    _progressionSnapshotListenable.dispose();
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
    _refreshActivePlayViewModel(nowUtc: nowUtc);
    _refreshQuestViewModel();
    _refreshProgressionViewModel();
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

  void _refreshActivePlayViewModel({DateTime? nowUtc}) {
    _setSnapshotIfChanged(
      _activePlaySnapshotListenable,
      _computeActivePlaySnapshot(nowUtc: (nowUtc ?? _clock()).toUtc()),
    );
  }

  void _refreshQuestViewModel() {
    _setSnapshotIfChanged(_questSnapshotListenable, _computeQuestSnapshot());
  }

  void _refreshProgressionViewModel() {
    _setSnapshotIfChanged(
      _progressionSnapshotListenable,
      _computeProgressionSnapshot(),
    );
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

  bool _refreshProgressionState() {
    final beforeAchievements = _state.achievements;
    final beforeCollection = _state.collection;
    final beforeShopProgression = _state.shopProgression;
    _state = _unlockCollectionItemsForCurrentUpgrades(_state);
    _state = _refreshShopProgression(_state);
    _state = _refreshAchievementProgress(_state);
    return !mapEquals(beforeAchievements, _state.achievements) ||
        beforeCollection.unlockedItemIds != _state.collection.unlockedItemIds ||
        beforeCollection.claimedBonusItemIds !=
            _state.collection.claimedBonusItemIds ||
        beforeShopProgression.currentShopLevel !=
            _state.shopProgression.currentShopLevel ||
        beforeShopProgression.highestShopLevel !=
            _state.shopProgression.highestShopLevel ||
        beforeShopProgression.unlockedShopIds !=
            _state.shopProgression.unlockedShopIds;
  }

  GameState _refreshShopProgression(GameState state) {
    final eligibleLevel = ShopProgressionCatalog.eligibleLevel(state, config);
    if (eligibleLevel <= state.shopProgression.currentShopLevel) {
      return state;
    }
    final previousShop = ShopProgressionCatalog.byLevel(
      state.shopProgression.currentShopLevel,
    );
    final nextShop = ShopProgressionCatalog.byLevel(eligibleLevel);
    _pendingShopLevelUpSnapshot = ShopLevelUpSnapshot(
      previousLevelName: previousShop.name,
      currentLevelName: nextShop.name,
      unlockLabel: nextShop.unlockLabel,
      incomeMultiplier: nextShop.incomeMultiplier,
    );
    final progression = state.shopProgression.unlockThroughLevel(eligibleLevel);
    return state.copyWith(
      shopProgression: progression,
      stats: state.stats.copyWith(
        shopLevel: math.max(state.stats.shopLevel, eligibleLevel),
      ),
    );
  }

  GameState _unlockCollectionItemsForCurrentUpgrades(GameState state) {
    var collection = state.collection;
    for (final definition in config.upgrades) {
      final totalLevel = _engine.upgradeTotalLevel(state, definition.id);
      if (totalLevel <= 0) {
        continue;
      }
      final activeIndex = state.upgrade(definition.id).itemIndex;
      for (var index = 0; index <= activeIndex; index += 1) {
        if (index >= definition.items.length) {
          break;
        }
        collection = collection.unlock(
          collectionItemId(definition.id, definition.items[index].key),
        );
      }
    }
    return collection == state.collection
        ? state
        : state.copyWith(collection: collection);
  }

  GameState _refreshAchievementProgress(GameState state) {
    final nextProgress = <String, AchievementProgress>{};
    for (final achievement in AchievementCatalog.achievements) {
      final existing =
          state.achievements[achievement.id] ??
          AchievementProgress(achievementId: achievement.id);
      final currentValue = math.max(
        existing.currentValue,
        _achievementCurrentValue(state, achievement),
      );
      final completed =
          existing.isCompleted || currentValue >= achievement.targetValue;
      nextProgress[achievement.id] = existing.copyWith(
        currentValue: currentValue,
        isCompleted: completed,
      );
    }
    if (mapEquals(state.achievements, nextProgress)) {
      return state;
    }
    return state.copyWith(
      achievements: Map<String, AchievementProgress>.unmodifiable(nextProgress),
    );
  }

  double _achievementCurrentValue(GameState state, Achievement achievement) {
    return switch (achievement.id) {
      'tap_10' || 'tap_100' => state.stats.tapCount.toDouble(),
      'money_100' || 'money_1000' => state.lifetimeCash.toDouble(),
      'upgrade_1' || 'upgrade_10' =>
        math
            .max(state.stats.totalUpgradesPurchased, _totalUpgradeLevels(state))
            .toDouble(),
      'staff_1' =>
        _engine.upgradeTotalLevel(state, UpgradeId.staff) > 0 ? 1 : 0,
      'turbo_1' => state.stats.turboUsedCount.toDouble(),
      'combo_15' => state.stats.maxCombo.toDouble(),
      'critical_3' => state.stats.criticalCutCount.toDouble(),
      'golden_1' => state.stats.goldenDonerCollected.toDouble(),
      'chest_1' => state.stats.chestsOpened.toDouble(),
      'collection_5' => state.collection.unlockedItemIds.length.toDouble(),
      'prestige_1' => state.prestige.reputation.toDouble(),
      _ => 0,
    };
  }

  int _totalUpgradeLevels(GameState state) {
    var total = 0;
    for (final definition in config.upgrades) {
      total += _engine.upgradeTotalLevel(state, definition.id);
    }
    return total;
  }

  GameState _applyAchievementReward(GameState state, AchievementReward reward) {
    switch (reward.type) {
      case AchievementRewardType.cash:
        return _engine.addCoins(state, reward.amount.round());
      case AchievementRewardType.chest:
        final chestType = reward.chestType ?? ChestType.small;
        return state.copyWith(
          chestInventory: state.chestInventory.add(chestType),
        );
      case AchievementRewardType.cosmeticToken:
        return state.copyWith(
          milestones: state.milestones.copyWith(
            cosmeticTokens:
                state.milestones.cosmeticTokens + reward.amount.round(),
          ),
        );
      case AchievementRewardType.permanentTapBonus:
      case AchievementRewardType.permanentPassiveBonus:
      case AchievementRewardType.permanentGlobalBonus:
        return state;
    }
  }

  void _grantChest(ChestType type, {int quantity = 1}) {
    if (quantity <= 0) {
      return;
    }
    _state = _state.copyWith(
      chestInventory: _state.chestInventory.add(type, quantity: quantity),
    );
  }

  ChestReward _rollChestReward(ChestType type) {
    final roll = _random.nextDouble();
    switch (type) {
      case ChestType.small:
        if (roll < 0.55) {
          return ChestReward(
            rewardType: ChestRewardType.money,
            amount: math.max(75, _engine.tapValue(_state) * 50).toDouble(),
          );
        }
        if (roll < 0.85) {
          return const ChestReward(
            rewardType: ChestRewardType.temporaryIncomeBoost,
            amount: 2,
            durationSeconds: 45,
          );
        }
        return const ChestReward(
          rewardType: ChestRewardType.cosmeticToken,
          amount: 1,
        );
      case ChestType.master:
        if (roll < 0.45) {
          return ChestReward(
            rewardType: ChestRewardType.money,
            amount: math
                .max(
                  500,
                  math.max(
                    _engine.tapValue(_state) * 200,
                    _engine.passiveIncomePerSecond(_state) * 180,
                  ),
                )
                .toDouble(),
          );
        }
        if (roll < 0.80) {
          return const ChestReward(
            rewardType: ChestRewardType.temporaryIncomeBoost,
            amount: 2,
            durationSeconds: 180,
          );
        }
        return const ChestReward(
          rewardType: ChestRewardType.cosmeticToken,
          amount: 3,
        );
      case ChestType.gold:
        if (roll < 0.40) {
          return ChestReward(
            rewardType: ChestRewardType.money,
            amount: math
                .max(
                  5000,
                  math.max(
                    _engine.tapValue(_state) * 1000,
                    _engine.passiveIncomePerSecond(_state) * 600,
                  ),
                )
                .toDouble(),
          );
        }
        if (roll < 0.75) {
          return const ChestReward(
            rewardType: ChestRewardType.temporaryIncomeBoost,
            amount: 2,
            durationSeconds: 600,
          );
        }
        return const ChestReward(
          rewardType: ChestRewardType.cosmeticToken,
          amount: 8,
        );
    }
  }

  GameState _applyChestReward(
    GameState state,
    ChestReward reward, {
    required DateTime nowUtc,
  }) {
    switch (reward.rewardType) {
      case ChestRewardType.money:
        return _engine.addCoins(state, reward.amount.round());
      case ChestRewardType.temporaryIncomeBoost:
        return state.copyWith(
          passiveBoost: TimedEffectState(
            endsAtUtc: nowUtc.add(
              Duration(seconds: reward.durationSeconds ?? 45),
            ),
          ),
        );
      case ChestRewardType.turboCharge:
        return state.copyWith(
          rush: state.rush.copyWith(clearCooldownEndsAtUtc: true),
        );
      case ChestRewardType.cosmeticToken:
        return state.copyWith(
          milestones: state.milestones.copyWith(
            cosmeticTokens:
                state.milestones.cosmeticTokens + reward.amount.round(),
          ),
        );
      case ChestRewardType.permanentTapBonus:
        return state.copyWith(
          milestones: state.milestones.copyWith(
            tapBonusPercent: state.milestones.tapBonusPercent + reward.amount,
          ),
        );
      case ChestRewardType.permanentPassiveBonus:
        return state.copyWith(
          milestones: state.milestones.copyWith(
            passiveBonusPercent:
                state.milestones.passiveBonusPercent + reward.amount,
          ),
        );
      case ChestRewardType.permanentGlobalBonus:
        return state.copyWith(
          milestones: state.milestones.copyWith(
            globalBonusPercent:
                state.milestones.globalBonusPercent + reward.amount,
          ),
        );
    }
  }

  String _chestRewardLabel(ChestReward reward) {
    return switch (reward.rewardType) {
      ChestRewardType.money => '+${reward.amount.round()} cash',
      ChestRewardType.temporaryIncomeBoost =>
        'x${reward.amount.round()} income for ${reward.durationSeconds ?? 0}s',
      ChestRewardType.turboCharge => 'Turbo ready',
      ChestRewardType.cosmeticToken =>
        'Cosmetic token x${reward.amount.round()}',
      ChestRewardType.permanentTapBonus =>
        'Tap income +${(reward.amount * 100).round()}%',
      ChestRewardType.permanentPassiveBonus =>
        'Passive income +${(reward.amount * 100).round()}%',
      ChestRewardType.permanentGlobalBonus =>
        'Global income +${(reward.amount * 100).round()}%',
    };
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

  bool _refreshActivePlayState(DateTime nowUtc) {
    final previousState = _state;
    _state = _expireComboIfNeeded(_state, nowUtc);
    _state = _expireGoldenDonerIfNeeded(_state, nowUtc);

    if (!_state.milestones.hasFeature('golden_doner')) {
      return previousState != _state;
    }
    if (_state.goldenDoner.isActiveAt(nowUtc)) {
      return previousState != _state;
    }
    final nextSpawnAt = _state.goldenDoner.nextSpawnAtUtc;
    if (nextSpawnAt == null) {
      _state = _state.copyWith(
        goldenDoner: _scheduleNextGoldenDoner(_state.goldenDoner, nowUtc),
      );
      return true;
    }
    if (!nextSpawnAt.isAfter(nowUtc)) {
      _state = _state.copyWith(
        goldenDoner: GoldenDonerState(
          activeUntilUtc: nowUtc.add(config.goldenDonerActiveDuration),
          lastSpawnAtUtc: nowUtc,
          requiredHits: config.goldenDonerRequiredHits,
          currentHits: 0,
          rewardPreview: _engine.goldenDonerReward(_state, nowUtc: nowUtc),
        ),
      );
      return true;
    }

    return previousState != _state;
  }

  GameState _expireComboIfNeeded(GameState state, DateTime nowUtc) {
    if (!state.milestones.hasFeature('combo') ||
        state.stats.currentCombo <= 0) {
      return state;
    }
    final lastTapAt = state.stats.lastTapAtUtc;
    if (lastTapAt == null) {
      return state.copyWith(stats: state.stats.copyWith(currentCombo: 0));
    }
    if (nowUtc.difference(lastTapAt) <= _engine.comboExpireDuration(state)) {
      return state;
    }
    return state.copyWith(stats: state.stats.copyWith(currentCombo: 0));
  }

  GameState _expireGoldenDonerIfNeeded(GameState state, DateTime nowUtc) {
    final goldenDoner = state.goldenDoner;
    if (goldenDoner.activeUntilUtc == null || goldenDoner.isActiveAt(nowUtc)) {
      return state;
    }
    return state.copyWith(
      goldenDoner: _scheduleNextGoldenDoner(goldenDoner.clearActive(), nowUtc),
    );
  }

  GoldenDonerState _scheduleNextGoldenDoner(
    GoldenDonerState state,
    DateTime nowUtc,
  ) {
    return state.copyWith(nextSpawnAtUtc: nowUtc.add(_goldenDonerInterval()));
  }

  Duration _goldenDonerInterval() {
    final minInterval = config.goldenDonerMinSpawnInterval;
    final maxInterval = config.goldenDonerMaxSpawnInterval;
    if (maxInterval <= minInterval) {
      return _scaledGoldenDonerInterval(minInterval);
    }
    final range = maxInterval.inMilliseconds - minInterval.inMilliseconds;
    final raw =
        minInterval +
        Duration(milliseconds: (_random.nextDouble() * range).round());
    return _scaledGoldenDonerInterval(raw);
  }

  Duration _scaledGoldenDonerInterval(Duration raw) {
    final multiplier = _engine.goldenDonerIntervalMultiplier(_state);
    return Duration(
      milliseconds: math.max(1000, (raw.inMilliseconds * multiplier).round()),
    );
  }

  TapOutcome _applyTapOutcome(DateTime nowUtc) {
    _refreshActivePlayState(nowUtc);

    final comboUnlocked = _state.milestones.hasFeature('combo');
    final previousStats = _state.stats;
    final nextTapCount = previousStats.tapCount + 1;
    var nextCombo = 0;
    var nextMaxCombo = previousStats.maxCombo;
    if (comboUnlocked) {
      final lastTapAt = previousStats.lastTapAtUtc;
      final keepsCombo =
          previousStats.currentCombo > 0 &&
          lastTapAt != null &&
          nowUtc.difference(lastTapAt) <= _engine.comboExpireDuration(_state);
      nextCombo = keepsCombo ? previousStats.currentCombo + 1 : 1;
      nextMaxCombo = math.max(nextMaxCombo, nextCombo);
    }

    _state = _state.copyWith(
      stats: previousStats.copyWith(
        tapCount: nextTapCount,
        currentCombo: nextCombo,
        maxCombo: nextMaxCombo,
        lastTapAtUtc: nowUtc,
      ),
    );

    final comboMultiplier = _engine.comboMultiplierForCount(nextCombo, _state);
    final criticalChance = _engine.criticalChance(_state);
    final isCritical =
        criticalChance > 0 && _random.nextDouble() < criticalChance;
    final criticalMultiplier = isCritical
        ? _engine.criticalMultiplier(_state)
        : 1.0;
    if (isCritical) {
      _state = _state.copyWith(
        stats: _state.stats.copyWith(
          criticalCutCount: _state.stats.criticalCutCount + 1,
        ),
      );
    }

    final tapCoins = _engine.tapValueForActivePlay(
      _state,
      nowUtc: nowUtc,
      comboMultiplier: comboMultiplier,
      criticalMultiplier: criticalMultiplier,
    );
    _state = _engine.addCoins(_state, tapCoins);

    var goldenDonerHit = false;
    var goldenDonerCompleted = false;
    var goldenDonerReward = 0;
    var goldenDonerHits = _state.goldenDoner.currentHits;
    final goldenDonerRequiredHits = _state.goldenDoner.requiredHits;
    if (_state.goldenDoner.isActiveAt(nowUtc)) {
      goldenDonerHit = true;
      goldenDonerHits = _state.goldenDoner.currentHits + 1;
      if (goldenDonerHits >= _state.goldenDoner.requiredHits) {
        goldenDonerCompleted = true;
        goldenDonerReward = _state.goldenDoner.rewardPreview;
        _state = _engine.addCoins(_state, goldenDonerReward);
        _state = _state.copyWith(
          goldenDoner: _scheduleNextGoldenDoner(
            _state.goldenDoner.clearActive(),
            nowUtc,
          ),
          stats: _state.stats.copyWith(
            goldenDonerCollected: _state.stats.goldenDonerCollected + 1,
          ),
        );
      } else {
        _state = _state.copyWith(
          goldenDoner: _state.goldenDoner.copyWith(
            currentHits: goldenDonerHits,
          ),
        );
      }
    }

    return TapOutcome(
      coins: tapCoins,
      combo: nextCombo,
      comboMultiplier: comboMultiplier,
      isCritical: isCritical,
      criticalMultiplier: criticalMultiplier,
      goldenDonerHit: goldenDonerHit,
      goldenDonerCompleted: goldenDonerCompleted,
      goldenDonerReward: goldenDonerReward,
      goldenDonerHits: goldenDonerHits,
      goldenDonerRequiredHits: goldenDonerRequiredHits,
    );
  }

  GameHudSnapshot _computeHudSnapshot({required DateTime nowUtc}) {
    return GameHudSnapshot(
      cash: _state.cash,
      passiveIncomePerSecond: _engine.passiveIncomePerSecond(
        _state,
        nowUtc: nowUtc,
      ),
      reputation: _state.prestige.totalPrestigePoints,
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

  ActivePlaySnapshot _computeActivePlaySnapshot({required DateTime nowUtc}) {
    final comboUnlocked = _state.milestones.hasFeature('combo');
    final criticalUnlocked = _state.milestones.hasFeature('critical_cut');
    final goldenDonerUnlocked = _state.milestones.hasFeature('golden_doner');
    final comboRemaining =
        comboUnlocked &&
            _state.stats.currentCombo > 0 &&
            _state.stats.lastTapAtUtc != null
        ? _displayDuration(
            _engine.comboExpireDuration(_state) -
                nowUtc.difference(_state.stats.lastTapAtUtc!),
          )
        : Duration.zero;
    return ActivePlaySnapshot(
      comboUnlocked: comboUnlocked,
      currentCombo: comboUnlocked ? _state.stats.currentCombo : 0,
      maxCombo: _state.stats.maxCombo,
      comboMultiplier: _engine.comboMultiplierForCount(
        _state.stats.currentCombo,
        _state,
      ),
      comboRemaining: comboRemaining,
      criticalUnlocked: criticalUnlocked,
      criticalChance: _engine.criticalChance(_state),
      criticalMultiplier: _engine.criticalMultiplier(_state),
      goldenDonerUnlocked: goldenDonerUnlocked,
      goldenDonerActive: _state.goldenDoner.isActiveAt(nowUtc),
      goldenDonerRemaining: _displayDuration(
        _state.goldenDoner.remainingActive(nowUtc),
      ),
      goldenDonerHits: _state.goldenDoner.currentHits,
      goldenDonerRequiredHits: _state.goldenDoner.requiredHits,
      goldenDonerRewardPreview: _state.goldenDoner.rewardPreview,
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

    final currentShop = ShopProgressionCatalog.byLevel(
      _state.shopProgression.currentShopLevel,
    );
    final nextShop = ShopProgressionCatalog.nextAfter(currentShop.level);
    final progression = ShopProgressionSnapshot(
      currentLevel: currentShop.level,
      currentName: currentShop.name,
      highestLevel: _state.shopProgression.highestShopLevel,
      incomeMultiplier: currentShop.incomeMultiplier,
      nextLevel: nextShop?.level,
      nextName: nextShop?.name,
      nextIncomeMultiplier: nextShop?.incomeMultiplier,
      requirements: nextShop == null
          ? const <ShopRequirementSnapshot>[]
          : nextShop.requirements
                .map(
                  (requirement) => ShopRequirementSnapshot(
                    label: requirement.label(),
                    completed: requirement.isMet(_state, config),
                  ),
                )
                .toList(growable: false),
    );

    return ShopSnapshot(
      hud: hud,
      upgrades: Map<UpgradeId, ShopUpgradeSnapshot>.unmodifiable(upgrades),
      progression: progression,
    );
  }

  PrestigeSnapshot _computePrestigeSnapshot() {
    final availablePoints = _engine.availablePrestigePoints(_state);
    return PrestigeSnapshot(
      availablePoints: availablePoints,
      reputation: _state.prestige.totalPrestigePoints,
      unspentPoints: _state.prestige.unspentPrestigePoints,
      prestigeCount: _state.prestige.prestigeCount,
      runCashEarned: _state.prestige.runCashEarned,
      threshold: config.prestigeThreshold,
      currentMultiplier: _engine.prestigeMultiplier(_state),
      newMultiplier: _engine.prestigeMultiplierForPoints(
        _state.prestige.totalPrestigePoints + availablePoints,
      ),
      shopUpgrades: PrestigeShopCatalog.upgrades
          .map((upgrade) {
            final level = _state.prestige.prestigeUpgradeLevel(upgrade.id);
            final cost = upgrade.costForLevel(level);
            final maxed = level >= upgrade.maxLevel;
            return PrestigeShopUpgradeSnapshot(
              id: upgrade.id,
              name: upgrade.name,
              description: upgrade.description,
              effectType: upgrade.effectType,
              level: level,
              maxLevel: upgrade.maxLevel,
              cost: cost,
              canAfford:
                  !maxed && _state.prestige.unspentPrestigePoints >= cost,
              maxed: maxed,
              currentEffectLabel: upgrade.effectLabel(level),
              nextEffectLabel: upgrade.effectLabel(level + 1),
            );
          })
          .toList(growable: false),
      resetItems: const [
        'Current money, all upgrade progress, current shop level, temporary boosts, combo, Golden Doner, and turbo state',
        'Current run quest progress',
      ],
      keptItems: const [
        'Total prestige points and unspent prestige points',
        'Prestige shop upgrades',
        'Highest shop level reached',
        'Achievements and collections',
        'Prestige multiplier',
        'Total lifetime stats',
        'IAP purchases',
        'Ad removal status',
        'Permanent premium boosts',
      ],
    );
  }

  ProgressionSnapshot _computeProgressionSnapshot() {
    final achievements = AchievementCatalog.achievements
        .map((achievement) {
          final progress =
              _state.achievements[achievement.id] ??
              AchievementProgress(achievementId: achievement.id);
          return AchievementProgressSnapshot(
            id: achievement.id,
            title: achievement.title,
            description: achievement.description,
            category: achievement.category,
            currentValue: progress.currentValue,
            targetValue: achievement.targetValue,
            completed: progress.isCompleted,
            rewardClaimed: progress.isRewardClaimed,
            rewardLabel: _achievementRewardLabel(achievement.reward),
          );
        })
        .toList(growable: false);

    AchievementProgressSnapshot? latestClaimableAchievement;
    for (final achievement in achievements) {
      if (achievement.canClaim) {
        latestClaimableAchievement = achievement;
        break;
      }
    }

    final collectionItems = CollectionCatalog.itemsForConfig(config)
        .map(
          (item) => CollectionItemSnapshot(
            id: item.id,
            category: item.category,
            name: _collectionItemDisplayName(item),
            rarity: item.rarity,
            unlocked: _state.collection.isUnlocked(item.id),
            bonusLabel: _collectionBonusLabel(item.permanentBonus),
          ),
        )
        .toList(growable: false);

    return ProgressionSnapshot(
      achievements: achievements,
      collections: collectionItems,
      chests: ChestInventorySnapshot(
        counts: Map<ChestType, int>.unmodifiable({
          for (final type in ChestType.values)
            type: _state.chestInventory.count(type),
        }),
      ),
      latestClaimableAchievement: latestClaimableAchievement,
      lastChestReward: _lastChestRewardSnapshot,
    );
  }

  String _achievementRewardLabel(AchievementReward reward) {
    return switch (reward.type) {
      AchievementRewardType.cash => '+${reward.amount.round()} cash',
      AchievementRewardType.chest =>
        '${_chestTypeLabel(reward.chestType ?? ChestType.small)} chest',
      AchievementRewardType.permanentTapBonus =>
        'Tap +${(reward.amount * 100).round()}%',
      AchievementRewardType.permanentPassiveBonus =>
        'Passive +${(reward.amount * 100).round()}%',
      AchievementRewardType.permanentGlobalBonus =>
        'Global +${(reward.amount * 100).round()}%',
      AchievementRewardType.cosmeticToken => 'Token x${reward.amount.round()}',
    };
  }

  String _collectionItemDisplayName(CollectionItem item) {
    return item.name
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _collectionBonusLabel(PermanentBonus? bonus) {
    if (bonus == null) {
      return 'No bonus';
    }
    final amount = '+${(bonus.percent * 100).round()}%';
    return switch (bonus.type) {
      PermanentBonusType.tap => '$amount tap',
      PermanentBonusType.passive => '$amount passive',
      PermanentBonusType.global => '$amount global',
    };
  }

  String _chestTypeLabel(ChestType type) {
    return switch (type) {
      ChestType.small => 'Small',
      ChestType.master => 'Master',
      ChestType.gold => 'Gold',
    };
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
