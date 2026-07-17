import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:taptapdoner/app/game_view_models.dart';
import 'package:taptapdoner/domain/branches/branch_catalog.dart';
import 'package:taptapdoner/domain/customers/customer_order_models.dart';
import 'package:taptapdoner/domain/economy/currency_math.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/economy_engine.dart';
import 'package:taptapdoner/domain/economy/number_units.dart';
import 'package:taptapdoner/domain/goals/goal_catalog.dart';
import 'package:taptapdoner/domain/goals/goal_engine.dart';
import 'package:taptapdoner/domain/goals/goal_models.dart';
import 'package:taptapdoner/domain/progression/achievement_catalog.dart';
import 'package:taptapdoner/domain/progression/chest_drop_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/progression/collection_catalog.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';
import 'package:taptapdoner/domain/progression/prestige_shop_catalog.dart';
import 'package:taptapdoner/domain/progression/shop_progression_catalog.dart';
import 'package:taptapdoner/domain/quests/starter_quest_catalog.dart';
import 'package:taptapdoner/domain/quests/starter_quest_engine.dart';
import 'package:taptapdoner/domain/random_events/random_event_catalog.dart';
import 'package:taptapdoner/domain/random_events/random_event_models.dart';
import 'package:taptapdoner/domain/random_events/random_event_service.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
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
  });

  final num coins;
  final int combo;
  final double comboMultiplier;
  final bool isCritical;
  final double criticalMultiplier;
}

class _CustomerOrderUpdateResult {
  const _CustomerOrderUpdateResult({
    this.stateChanged = false,
    this.economyChanged = false,
    this.progressionChanged = false,
  });

  final bool stateChanged;
  final bool economyChanged;
  final bool progressionChanged;

  _CustomerOrderUpdateResult merge(_CustomerOrderUpdateResult other) {
    return _CustomerOrderUpdateResult(
      stateChanged: stateChanged || other.stateChanged,
      economyChanged: economyChanged || other.economyChanged,
      progressionChanged: progressionChanged || other.progressionChanged,
    );
  }
}

class GameController extends ChangeNotifier {
  GameController({
    EconomyConfig? config,
    SaveRepository? saveRepository,
    RewardedAdService? adService,
    Clock? clock,
    math.Random? random,
    bool freePurchasesEnabled = false,
  }) : config = config ?? EconomyConfig.standard(),
       _saveRepository = saveRepository ?? SharedPreferencesSaveRepository(),
       _adService = adService ?? const NoopRewardedAdService(),
       _clock = clock ?? _defaultClock,
       _random = random ?? math.Random(),
       _freePurchasesEnabled = freePurchasesEnabled {
    _engine = EconomyEngine(
      this.config,
      freePurchasesEnabled: _freePurchasesEnabled,
    );
    _questEngine = StarterQuestEngine(this.config);
    _goalEngine = const GoalEngine();
    _randomEventService = const RandomEventService();
    _backgroundCalculator = BackgroundProductionCalculator(
      config: this.config,
      engine: _engine,
    );
    final nowUtc = _clock();
    _state = _questEngine.refresh(
      GameState.initial(this.config, nowUtc: nowUtc),
    );
    _state = _state.copyWith(
      goals: _goalEngine.refresh(
        _state,
        config: this.config,
        nowUtc: nowUtc,
        random: _random,
      ),
    );
    _hudSnapshotListenable = ValueNotifier<GameHudSnapshot>(
      _computeHudSnapshot(nowUtc: nowUtc),
    );
    _randomEventSnapshotListenable = ValueNotifier<RandomEventSnapshot?>(
      _computeRandomEventSnapshot(nowUtc: nowUtc),
    );
    _activePlaySnapshotListenable = ValueNotifier<ActivePlaySnapshot>(
      _computeActivePlaySnapshot(nowUtc: nowUtc),
    );
    _customerOrderSnapshotListenable = ValueNotifier<CustomerOrderSnapshot>(
      _computeCustomerOrderSnapshot(nowUtc: nowUtc),
    );
    _questSnapshotListenable = ValueNotifier<QuestSnapshot?>(
      _computeQuestSnapshot(),
    );
    _goalSnapshotListenable = ValueNotifier<GoalBoardSnapshot>(
      _computeGoalSnapshot(nowUtc: nowUtc),
    );
    _branchSnapshotListenable = ValueNotifier<BranchBoardSnapshot>(
      _computeBranchSnapshot(nowUtc: nowUtc),
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
  final bool _freePurchasesEnabled;

  late final EconomyEngine _engine;
  late final StarterQuestEngine _questEngine;
  late final GoalEngine _goalEngine;
  late final RandomEventService _randomEventService;
  late final BackgroundProductionCalculator _backgroundCalculator;
  late GameState _state;
  late final ValueNotifier<GameHudSnapshot> _hudSnapshotListenable;
  late final ValueNotifier<RandomEventSnapshot?> _randomEventSnapshotListenable;
  late final ValueNotifier<ActivePlaySnapshot> _activePlaySnapshotListenable;
  late final ValueNotifier<CustomerOrderSnapshot>
  _customerOrderSnapshotListenable;
  late final ValueNotifier<QuestSnapshot?> _questSnapshotListenable;
  late final ValueNotifier<GoalBoardSnapshot> _goalSnapshotListenable;
  late final ValueNotifier<BranchBoardSnapshot> _branchSnapshotListenable;
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
  int _debugRandomEventCursor = 0;

  GameState get state => _state;
  PurchaseResult? get lastPurchaseResult => _lastPurchaseResult;
  ValueListenable<GameHudSnapshot> get hudSnapshotListenable =>
      _hudSnapshotListenable;
  ValueListenable<RandomEventSnapshot?> get randomEventSnapshotListenable =>
      _randomEventSnapshotListenable;
  ValueListenable<ActivePlaySnapshot> get activePlaySnapshotListenable =>
      _activePlaySnapshotListenable;
  ValueListenable<CustomerOrderSnapshot> get customerOrderSnapshotListenable =>
      _customerOrderSnapshotListenable;
  ValueListenable<QuestSnapshot?> get questSnapshotListenable =>
      _questSnapshotListenable;
  ValueListenable<GoalBoardSnapshot> get goalSnapshotListenable =>
      _goalSnapshotListenable;
  ValueListenable<BranchBoardSnapshot> get branchSnapshotListenable =>
      _branchSnapshotListenable;
  ValueListenable<ShopSnapshot> get shopSnapshotListenable =>
      _shopSnapshotListenable;
  ValueListenable<PrestigeSnapshot> get prestigeSnapshotListenable =>
      _prestigeSnapshotListenable;
  ValueListenable<ProgressionSnapshot> get progressionSnapshotListenable =>
      _progressionSnapshotListenable;
  bool get isInitialized => _isInitialized;
  bool get isTicking => _activeTickTimer?.isActive ?? false;
  bool get freePurchasesEnabled => _freePurchasesEnabled;
  bool get hasPendingOfflineReward => _state.pendingOfflineCash > 0;
  bool get canDoubleOfflineReward => _adService.isAvailable;
  num get tapValue => _hudSnapshotListenable.value.tapValue;
  double get passiveIncomePerSecond =>
      _hudSnapshotListenable.value.passiveIncomePerSecond;
  int get availablePrestigePoints =>
      _prestigeSnapshotListenable.value.availablePoints;
  bool get _debugUnlimitedChestsEnabled => _freePurchasesEnabled;
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
      _refreshCustomerUnlockState();
      _refreshGoalState(nowUtc);
      _scheduleInitialCustomerSpawnIfNeeded(nowUtc);
      _refreshActivePlayState(nowUtc);
      _refreshViewModels(nowUtc: nowUtc);
      _showInitialDebugRandomEvent(nowUtc);
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
      _queueOfflineRewardWithBranchAccounting(restored, grant, nowUtc: nowUtc),
    );
    _refreshProgressionState();
    _refreshCustomerUnlockState();
    _refreshGoalState(nowUtc);
    _scheduleInitialCustomerSpawnIfNeeded(nowUtc);
    _refreshActivePlayState(nowUtc);
    _refreshViewModels(nowUtc: nowUtc);
    _showInitialDebugRandomEvent(nowUtc);
    _isInitialized = true;
    await _queueSave();
    notifyListeners();
  }

  void tick(Duration elapsed) {
    if (!_isInitialized || elapsed <= Duration.zero) {
      return;
    }
    final nowUtc = _clock();
    final rawPassiveRate = _hudSnapshotListenable.value.passiveIncomePerSecond;
    final passiveRate = CurrencyMath.clampDouble(rawPassiveRate);
    final earned = CurrencyMath.clampDouble(
      passiveRate * elapsed.inMilliseconds / 1000,
    );
    _passiveCarry = CurrencyMath.clampDouble(_passiveCarry + earned);
    _notifyAccumulator += elapsed.inMilliseconds / 1000;

    final wholeCoins = CurrencyMath.floorDouble(_passiveCarry);
    var refreshEconomySnapshots = rawPassiveRate != passiveRate;
    var activePlayStateChanged = false;
    var passiveBoostStateChanged = false;
    var notifyLegacyListeners = false;
    var questStateChanged = false;
    var progressionStateChanged = false;
    var customerOrderStateChanged = false;
    var goalStateChanged = false;
    var randomEventStateChanged = false;

    goalStateChanged = _refreshGoalState(nowUtc);
    activePlayStateChanged = _refreshActivePlayState(nowUtc);
    randomEventStateChanged = _refreshRandomEventState(nowUtc);
    if (randomEventStateChanged) {
      refreshEconomySnapshots = true;
      activePlayStateChanged = true;
    }

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
      if (!_passiveCarry.isFinite) {
        _passiveCarry = 0;
      } else {
        _passiveCarry -= wholeCoins;
      }
      _state = _engine.addCoins(_state, wholeCoins);
      final branchRate = _engine.branchIncomePerSecond(_state, nowUtc: nowUtc);
      if (branchRate > 0 && passiveRate > 0) {
        _state = _state.copyWith(
          branches: _state.branches.addIncome(
            wholeCoins * (branchRate / passiveRate),
          ),
        );
      }
      goalStateChanged =
          _recordGoalEvent(
            GoalObjectiveType.earnMoney,
            wholeCoins.toDouble(),
            nowUtc: nowUtc,
          ) ||
          goalStateChanged;
      progressionStateChanged = _refreshProgressionState();
      refreshEconomySnapshots = true;
      notifyLegacyListeners = true;
    }

    if (!_state.passiveBoost.isActiveAt(nowUtc) &&
        _state.passiveBoost.endsAtUtc != null) {
      _state = _state.copyWith(
        passiveBoost: _state.passiveBoost.copyWith(clearEndsAtUtc: true),
      );
      refreshEconomySnapshots = true;
      passiveBoostStateChanged = true;
    }

    questStateChanged = _refreshQuestState() || questStateChanged;

    final goalsBeforeCustomerUpdate = _state.goals;
    final customerOrderUpdate = _advanceCustomerOrders(
      nowUtc: nowUtc,
      elapsed: elapsed,
      passiveCoinsEarned: wholeCoins,
    );
    goalStateChanged =
        goalStateChanged || goalsBeforeCustomerUpdate != _state.goals;
    customerOrderStateChanged = customerOrderUpdate.stateChanged;
    refreshEconomySnapshots =
        refreshEconomySnapshots || customerOrderUpdate.economyChanged;
    progressionStateChanged =
        progressionStateChanged || customerOrderUpdate.progressionChanged;
    notifyLegacyListeners =
        notifyLegacyListeners || customerOrderUpdate.economyChanged;
    if (customerOrderUpdate.economyChanged ||
        customerOrderUpdate.progressionChanged) {
      questStateChanged = _refreshQuestState() || questStateChanged;
      progressionStateChanged =
          _refreshProgressionState() || progressionStateChanged;
    }

    if (refreshEconomySnapshots) {
      _refreshEconomyViewModels(nowUtc: nowUtc);
    }
    if (questStateChanged) {
      _refreshQuestViewModel();
    }
    if (goalStateChanged) {
      _refreshGoalViewModel(nowUtc: nowUtc);
    }
    if (progressionStateChanged) {
      _refreshProgressionViewModel();
    }

    if (refreshEconomySnapshots || _notifyAccumulator >= 0.2) {
      _notifyAccumulator = 0;
    }
    if (activePlayStateChanged ||
        passiveBoostStateChanged ||
        _state.passiveBoost.isActiveAt(nowUtc) ||
        _state.randomEvents.activeModifiers.isNotEmpty ||
        _state.stats.currentCombo > 0) {
      _refreshActivePlayViewModel(nowUtc: nowUtc);
    }
    if (customerOrderStateChanged) {
      _refreshCustomerOrderViewModel(nowUtc: nowUtc);
    }
    if (randomEventStateChanged) {
      _refreshRandomEventViewModel(nowUtc: nowUtc);
    }

    if (notifyLegacyListeners || randomEventStateChanged) {
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
    var goalStateChanged = _refreshGoalState(nowUtc);
    final outcome = _applyTapOutcome(nowUtc);
    goalStateChanged =
        _recordGoalEvent(GoalObjectiveType.tapCount, 1, nowUtc: nowUtc) ||
        goalStateChanged;
    final earnedCoins = outcome.coins;
    if (earnedCoins > 0) {
      goalStateChanged =
          _recordGoalEvent(
            GoalObjectiveType.earnMoney,
            earnedCoins.toDouble(),
            nowUtc: nowUtc,
          ) ||
          goalStateChanged;
    }
    if (outcome.combo > 0) {
      goalStateChanged =
          _recordGoalEvent(
            GoalObjectiveType.reachCombo,
            outcome.combo.toDouble(),
            nowUtc: nowUtc,
            useMaxProgress: true,
          ) ||
          goalStateChanged;
    }
    if (outcome.isCritical) {
      goalStateChanged =
          _recordGoalEvent(
            GoalObjectiveType.triggerCritical,
            1,
            nowUtc: nowUtc,
          ) ||
          goalStateChanged;
    }
    final goalsBeforeCustomerUpdate = _state.goals;
    var customerOrderUpdate = _recordCustomerOrderEvent(
      OrderObjectiveType.tapCount,
      1,
      nowUtc: nowUtc,
    );
    if (outcome.coins > 0) {
      customerOrderUpdate = customerOrderUpdate.merge(
        _recordCustomerOrderEvent(
          OrderObjectiveType.earnMoney,
          outcome.coins.toDouble(),
          nowUtc: nowUtc,
        ),
      );
    }
    if (outcome.combo > 0) {
      customerOrderUpdate = customerOrderUpdate.merge(
        _recordCustomerOrderEvent(
          OrderObjectiveType.reachCombo,
          outcome.combo.toDouble(),
          nowUtc: nowUtc,
          useMaxProgress: true,
        ),
      );
    }
    if (outcome.isCritical) {
      customerOrderUpdate = customerOrderUpdate.merge(
        _recordCustomerOrderEvent(
          OrderObjectiveType.triggerCritical,
          1,
          nowUtc: nowUtc,
        ),
      );
    }
    goalStateChanged =
        goalStateChanged || goalsBeforeCustomerUpdate != _state.goals;
    final progressionStateChanged = customerOrderUpdate.progressionChanged
        ? _refreshProgressionState()
        : _refreshTapProgressionState();
    final questStateChanged = _refreshQuestState();
    _refreshHudViewModel(nowUtc: nowUtc);
    if (customerOrderUpdate.economyChanged) {}
    _refreshActivePlayViewModel(nowUtc: nowUtc);
    if (questStateChanged) {
      _refreshQuestViewModel();
    }
    if (goalStateChanged) {
      _refreshGoalViewModel(nowUtc: nowUtc);
    }
    if (customerOrderUpdate.stateChanged) {
      _refreshCustomerOrderViewModel(nowUtc: nowUtc);
    }
    if (progressionStateChanged) {
      _refreshProgressionViewModel();
    }
    notifyListeners();
    return outcome;
  }

  Future<bool> buyUpgrade(UpgradeId id, {int quantity = 1}) async {
    final result = _engine.buyUpgrade(_state, id, quantity: quantity);
    _lastPurchaseResult = result;
    if (!result.success) {
      return false;
    }
    final nowUtc = _clock();
    final previousShopLevel = _state.shopProgression.currentShopLevel;
    final purchasedCount = result.purchasedCount;
    _state = result.state.copyWith(
      stats: result.state.stats.copyWith(
        totalUpgradesPurchased:
            _state.stats.totalUpgradesPurchased + purchasedCount,
      ),
    );
    for (final grant in result.milestoneGrants) {
      if (grant.reward.type == MilestoneRewardType.chest) {
        _grantChest(ChestType.small, quantity: grant.reward.quantity);
      }
    }
    final goalsBeforeCustomerUpdate = _state.goals;
    final customerOrderUpdate = _recordCustomerOrderEvent(
      OrderObjectiveType.buyUpgrade,
      purchasedCount.toDouble(),
      nowUtc: nowUtc,
    );
    var goalStateChanged = goalsBeforeCustomerUpdate != _state.goals;
    goalStateChanged =
        _recordGoalEvent(
          GoalObjectiveType.buyUpgrades,
          purchasedCount.toDouble(),
          nowUtc: nowUtc,
        ) ||
        goalStateChanged;
    if (result.milestoneGrants.isNotEmpty) {
      goalStateChanged =
          _recordGoalEvent(
            GoalObjectiveType.completeMilestones,
            result.milestoneGrants.length.toDouble(),
            nowUtc: nowUtc,
          ) ||
          goalStateChanged;
    }
    final questStateChanged = _refreshQuestState();
    _refreshProgressionState();
    if (_state.shopProgression.currentShopLevel > previousShopLevel) {
      goalStateChanged =
          _recordGoalEvent(
            GoalObjectiveType.levelUpShop,
            (_state.shopProgression.currentShopLevel - previousShopLevel)
                .toDouble(),
            nowUtc: nowUtc,
          ) ||
          goalStateChanged;
    }
    _refreshEconomyViewModels();
    if (customerOrderUpdate.stateChanged) {
      _refreshCustomerOrderViewModel();
    }
    if (goalStateChanged) {
      _refreshGoalViewModel(nowUtc: nowUtc);
    }
    _refreshProgressionViewModel();
    if (questStateChanged) {
      _refreshQuestViewModel();
    }
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<bool> buyMaxUpgrade(UpgradeId id) async {
    final preview = _engine.previewMaxUpgradePurchase(_state, id);
    if (preview.purchasedCount <= 0) {
      _lastPurchaseResult = preview;
      return false;
    }
    return buyUpgrade(id, quantity: preview.purchasedCount);
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

  Future<bool> claimGoalReward(String goalId) async {
    final nowUtc = _clock();
    _refreshGoalState(nowUtc);
    final definition = GoalCatalog.byId[goalId];
    final progress = _state.goals.progressFor(goalId);
    if (definition == null ||
        progress == null ||
        !progress.canClaimAt(nowUtc)) {
      return false;
    }

    var nextState = _applyGoalRewards(_state, definition.rewards, nowUtc);
    nextState = nextState.copyWith(
      goals: nextState.goals.updateGoal(
        goalId,
        (progress) => progress.copyWith(
          rewardClaimed: true,
          status: GoalStatus.completed,
          currentValue: math.max(progress.currentValue, progress.targetValue),
        ),
      ),
    );
    _state = nextState;
    _refreshCustomerUnlockState();
    _refreshProgressionState();
    _refreshViewModels(nowUtc: nowUtc);
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<LastChestRewardSnapshot?> openChest(ChestType type) async {
    final hasStoredChest = _state.chestInventory.count(type) > 0;
    if (!hasStoredChest && !_debugUnlimitedChestsEnabled) {
      return null;
    }
    final nowUtc = _clock();
    var goalStateChanged = _refreshGoalState(nowUtc);
    final reward = _rollChestReward(type);
    final cashBefore = _state.cash;
    final reputationBefore = _state.customerReputation.totalReputation;
    final collectionUnlocksBefore = _collectionUnlockCount(_state);
    _state = _state.copyWith(
      chestInventory: _debugUnlimitedChestsEnabled
          ? _state.chestInventory
          : _state.chestInventory.remove(type),
      stats: _state.stats.copyWith(chestsOpened: _state.stats.chestsOpened + 1),
    );
    _state = _applyChestReward(_state, reward, nowUtc: nowUtc);
    goalStateChanged =
        _recordGoalEvent(GoalObjectiveType.openChests, 1, nowUtc: nowUtc) ||
        goalStateChanged;
    final earnedCash = _state.cash - cashBefore;
    if (earnedCash > 0) {
      goalStateChanged =
          _recordGoalEvent(
            GoalObjectiveType.earnMoney,
            earnedCash.toDouble(),
            nowUtc: nowUtc,
          ) ||
          goalStateChanged;
    }
    final gainedReputation =
        _state.customerReputation.totalReputation - reputationBefore;
    if (gainedReputation > 0) {
      goalStateChanged =
          _recordGoalEvent(
            GoalObjectiveType.gainReputation,
            gainedReputation.toDouble(),
            nowUtc: nowUtc,
          ) ||
          goalStateChanged;
    }
    final unlockedCollections =
        _collectionUnlockCount(_state) - collectionUnlocksBefore;
    if (unlockedCollections > 0) {
      goalStateChanged =
          _recordGoalEvent(
            GoalObjectiveType.unlockCollectionItem,
            unlockedCollections.toDouble(),
            nowUtc: nowUtc,
          ) ||
          goalStateChanged;
    }
    _lastChestRewardSnapshot = LastChestRewardSnapshot(
      chestType: type,
      rewardType: reward.rewardType,
      amount: reward.amount,
      label: _chestRewardLabel(reward),
    );
    final customerOrderUpdate = _recordCustomerOrderEvent(
      OrderObjectiveType.openChest,
      1,
      nowUtc: nowUtc,
    );
    goalStateChanged = goalStateChanged || customerOrderUpdate.stateChanged;
    _refreshProgressionState();
    _refreshViewModels();
    if (customerOrderUpdate.stateChanged) {
      _refreshCustomerOrderViewModel();
    }
    if (goalStateChanged) {
      _refreshGoalViewModel(nowUtc: nowUtc);
    }
    notifyListeners();
    await _queueSave();
    return _lastChestRewardSnapshot;
  }

  Future<bool> applyPrestige() async {
    if (availablePrestigePoints <= 0) {
      return false;
    }
    final nowUtc = _clock();
    _state = _engine.applyPrestige(_state, nowUtc: nowUtc);
    _recordGoalEvent(GoalObjectiveType.doPrestige, 1, nowUtc: nowUtc);
    _refreshGoalState(nowUtc, forcePrestigeRunRefresh: true);
    _state = _questEngine.refresh(_state);
    _refreshProgressionState();
    _refreshViewModels(nowUtc: nowUtc);
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

  Future<bool> unlockBranch(String branchId) async {
    final nowUtc = _clock();
    _refreshProgressionState();
    final definition = BranchCatalog.byId[branchId];
    if (definition == null ||
        !BranchCatalog.canUnlock(
          _state,
          definition,
          ignoreCostRequirement: _freePurchasesEnabled,
        )) {
      return false;
    }
    final cost = _effectivePurchaseCost(BranchCatalog.unlockCost(definition));
    final progress = _state.branches.progressFor(branchId);
    final completedRegionsBefore = BranchCatalog.completedRegionIds(
      _state.branches,
    );
    _state = _state.copyWith(
      cash: CurrencyMath.subtract(_state.cash, cost),
      branches: _state.branches.updateProgress(
        progress.copyWith(
          isUnlocked: true,
          level: 1,
          clearAssignedManagerId: true,
        ),
      ),
    );
    _state = _refreshBranchProgression(_state);
    var goalStateChanged = _recordGoalEvent(
      GoalObjectiveType.unlockBranches,
      1,
      nowUtc: nowUtc,
    );
    goalStateChanged =
        _recordGoalEvent(
          GoalObjectiveType.reachTotalBranchLevel,
          _state.branches.totalBranchLevel.toDouble(),
          nowUtc: nowUtc,
          useMaxProgress: true,
        ) ||
        goalStateChanged;
    goalStateChanged =
        _recordCompletedBranchRegions(completedRegionsBefore, nowUtc: nowUtc) ||
        goalStateChanged;
    _refreshViewModels(nowUtc: nowUtc);
    if (goalStateChanged) {
      _refreshGoalViewModel(nowUtc: nowUtc);
    }
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<bool> levelUpBranch(String branchId) async {
    final nowUtc = _clock();
    _refreshProgressionState();
    final definition = BranchCatalog.byId[branchId];
    if (definition == null ||
        !BranchCatalog.canLevelUp(
          _state,
          definition,
          ignoreCostRequirement: _freePurchasesEnabled,
        )) {
      return false;
    }
    final progress = _state.branches.progressFor(branchId);
    final cost = _effectivePurchaseCost(
      BranchCatalog.levelUpCost(definition, progress),
    );
    final milestonesBefore = BranchCatalog.claimedLevelMilestoneCount(
      _state.branches,
    );
    final completedRegionsBefore = BranchCatalog.completedRegionIds(
      _state.branches,
    );
    _state = _state.copyWith(
      cash: CurrencyMath.subtract(_state.cash, cost),
      branches: _state.branches.updateProgress(
        progress.copyWith(level: progress.level + 1),
      ),
    );
    _state = _refreshBranchProgression(_state);
    var goalStateChanged = _recordGoalEvent(
      GoalObjectiveType.upgradeBranchLevels,
      1,
      nowUtc: nowUtc,
    );
    goalStateChanged =
        _recordGoalEvent(
          GoalObjectiveType.reachTotalBranchLevel,
          _state.branches.totalBranchLevel.toDouble(),
          nowUtc: nowUtc,
          useMaxProgress: true,
        ) ||
        goalStateChanged;
    final newMilestones =
        BranchCatalog.claimedLevelMilestoneCount(_state.branches) -
        milestonesBefore;
    if (newMilestones > 0) {
      goalStateChanged =
          _recordGoalEvent(
            GoalObjectiveType.reachBranchMilestones,
            newMilestones.toDouble(),
            nowUtc: nowUtc,
          ) ||
          goalStateChanged;
    }
    goalStateChanged =
        _recordCompletedBranchRegions(completedRegionsBefore, nowUtc: nowUtc) ||
        goalStateChanged;
    _refreshViewModels(nowUtc: nowUtc);
    if (goalStateChanged) {
      _refreshGoalViewModel(nowUtc: nowUtc);
    }
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<bool> assignBranchManager(String branchId, String managerId) async {
    final nowUtc = _clock();
    _refreshProgressionState();
    if (!BranchCatalog.canAssignManager(
      _state,
      branchId: branchId,
      managerId: managerId,
    )) {
      return false;
    }
    final progress = _state.branches.progressFor(branchId);
    if (progress.assignedManagerId == managerId) {
      return false;
    }
    _state = _state.copyWith(
      branches: _state.branches.updateProgress(
        progress.copyWith(assignedManagerId: managerId),
      ),
    );
    final goalStateChanged = _recordGoalEvent(
      GoalObjectiveType.assignBranchManager,
      1,
      nowUtc: nowUtc,
    );
    _refreshViewModels(nowUtc: nowUtc);
    if (goalStateChanged) {
      _refreshGoalViewModel(nowUtc: nowUtc);
    }
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<bool> unassignBranchManager(String branchId) async {
    _refreshProgressionState();
    if (!BranchCatalog.canUnassignManager(_state, branchId: branchId)) {
      return false;
    }
    final progress = _state.branches.progressFor(branchId);
    _state = _state.copyWith(
      branches: _state.branches.updateProgress(
        progress.copyWith(clearAssignedManagerId: true),
      ),
    );
    _refreshViewModels(nowUtc: _clock());
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<bool> assignFirstAvailableBranchManager(String branchId) async {
    final managerIds = BranchCatalog.availableManagerIds(
      _state,
      forBranchId: branchId,
    );
    if (managerIds.isEmpty) {
      return false;
    }
    return assignBranchManager(branchId, managerIds.first);
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
    final nowUtc = _clock();
    _refreshGoalState(nowUtc);
    _refreshActivePlayState(nowUtc);
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
      _queueOfflineRewardWithBranchAccounting(_state, grant, nowUtc: nowUtc),
    );
    _refreshProgressionState();
    _refreshCustomerUnlockState();
    _refreshGoalState(nowUtc);
    _refreshActivePlayState(nowUtc);
    _refreshViewModels(nowUtc: nowUtc);
    await _queueSave();
    notifyListeners();
  }

  GameState _queueOfflineRewardWithBranchAccounting(
    GameState state,
    ProductionGrant grant, {
    required DateTime nowUtc,
  }) {
    var nextState = _engine.queueOfflineReward(
      state,
      grant.coins,
      nowUtc: nowUtc,
    );
    if (grant.coins <= 0) {
      return nextState;
    }
    final passiveRate = _engine.passiveIncomePerSecond(
      state,
      nowUtc: nowUtc,
      includeTemporaryBoost: false,
    );
    final branchRate = _engine.branchIncomePerSecond(
      state,
      nowUtc: nowUtc,
      includeTemporaryBoost: false,
    );
    if (branchRate <= 0 || passiveRate <= 0) {
      return nextState;
    }
    return nextState.copyWith(
      branches: nextState.branches.addIncome(
        grant.coins * (branchRate / passiveRate),
      ),
    );
  }

  Future<void> claimOfflineReward({int multiplier = 1}) async {
    final nowUtc = _clock();
    final reward = _state.pendingOfflineCash * multiplier;
    _refreshGoalState(nowUtc);
    _state = _engine.applyOfflineReward(_state, reward, nowUtc: nowUtc);
    _recordGoalEvent(
      GoalObjectiveType.earnMoney,
      reward.toDouble(),
      nowUtc: nowUtc,
    );
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

  Future<void> dismissRandomEvent() async {
    final activeEventId = _state.randomEvents.activeEventId;
    if (activeEventId == null) {
      return;
    }
    final nowUtc = _clock();
    _state = _state.copyWith(
      randomEvents: _state.randomEvents.copyWith(clearActiveEventId: true),
    );
    _refreshRandomEventViewModel(nowUtc: nowUtc);
    notifyListeners();
    await _queueSave();
  }

  Future<void> showDebugRandomEvent() async {
    if (!kDebugMode) {
      return;
    }
    final nowUtc = _clock();
    _showDebugRandomEvent(nowUtc);
    _refreshRandomEventViewModel(nowUtc: nowUtc);
    notifyListeners();
    await _queueSave();
  }

  Future<RandomEventResolutionSnapshot?> chooseRandomEvent(
    String choiceKey,
  ) async {
    final activeEventId = _state.randomEvents.activeEventId;
    final event = RandomEventCatalog.byId[activeEventId];
    final choice = event?.choiceByKey(choiceKey);
    if (event == null || choice == null) {
      return null;
    }
    if (choice.requiresRewardedAd) {
      final reward = await _adService.showOfflineRewardDouble();
      if (reward != RewardOutcome.granted) {
        return null;
      }
    }
    final nowUtc = _clock();
    final outcome = _randomEventService.resolveOutcome(choice, _random);
    final effectLabel = _applyRandomEventOutcome(event, outcome, nowUtc);
    _refreshGoalState(nowUtc);
    _refreshQuestState();
    _refreshProgressionState();
    _refreshViewModels(nowUtc: nowUtc);
    notifyListeners();
    await _queueSave();
    return RandomEventResolutionSnapshot(
      eventTitle: event.title,
      choiceLabel: choice.label,
      outcomeKey: outcome.key,
      resultText: outcome.resultText,
      effectLabel: effectLabel,
    );
  }

  Future<void> dismissOfflineReward() async {
    _state = _engine.clearPendingOfflineReward(_state, nowUtc: _clock());
    _refreshViewModels();
    notifyListeners();
    await _queueSave();
  }

  void prepareKitchenView() {
    final nowUtc = _clock();
    _refreshGoalState(nowUtc);
    _refreshActivePlayState(nowUtc);
    _refreshRandomEventState(nowUtc);
    _refreshHudViewModel(nowUtc: nowUtc);
    _refreshActivePlayViewModel(nowUtc: nowUtc);
    _refreshCustomerOrderViewModel(nowUtc: nowUtc);
    _refreshQuestViewModel();
    _refreshGoalViewModel(nowUtc: nowUtc);
    _refreshProgressionViewModel();
    _refreshRandomEventViewModel(nowUtc: nowUtc);
  }

  void prepareShopView() {
    final nowUtc = _clock();
    _refreshProgressionState();
    _refreshEconomyViewModels(nowUtc: nowUtc);
    _refreshQuestViewModel();
    _refreshGoalViewModel(nowUtc: nowUtc);
    _refreshProgressionViewModel();
  }

  void prepareBranchView() {
    final nowUtc = _clock();
    _refreshProgressionState();
    _refreshHudViewModel(nowUtc: nowUtc);
    _refreshBranchViewModel(nowUtc: nowUtc);
    _refreshGoalViewModel(nowUtc: nowUtc);
  }

  void prepareGoalsView() {
    final nowUtc = _clock();
    _refreshGoalState(nowUtc);
    _refreshProgressionState();
    _refreshGoalViewModel(nowUtc: nowUtc);
    _refreshProgressionViewModel();
  }

  void preparePrestigeView() {
    final nowUtc = _clock();
    _refreshProgressionState();
    _refreshHudViewModel(nowUtc: nowUtc);
    _refreshPrestigeViewModel();
    _refreshGoalViewModel(nowUtc: nowUtc);
  }

  void hydrate(GameState nextState) {
    _state = _questEngine.refresh(nextState);
    final nowUtc = _clock();
    _refreshProgressionState();
    _refreshCustomerUnlockState();
    _refreshGoalState(nowUtc);
    _scheduleInitialCustomerSpawnIfNeeded(nowUtc);
    _refreshActivePlayState(nowUtc);
    _refreshViewModels(nowUtc: nowUtc);
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    stopTicking();
    _hudSnapshotListenable.dispose();
    _randomEventSnapshotListenable.dispose();
    _activePlaySnapshotListenable.dispose();
    _customerOrderSnapshotListenable.dispose();
    _questSnapshotListenable.dispose();
    _goalSnapshotListenable.dispose();
    _shopSnapshotListenable.dispose();
    _prestigeSnapshotListenable.dispose();
    _progressionSnapshotListenable.dispose();
    super.dispose();
  }

  String _normalizeLocale(String localeCode) {
    return localeCode == 'tr' ? 'tr' : 'en';
  }

  bool _refreshRandomEventState(DateTime nowUtc) {
    var changed = false;
    final pruned = _state.randomEvents.pruneExpired(nowUtc);
    if (pruned != _state.randomEvents) {
      _state = _state.copyWith(randomEvents: pruned);
      changed = true;
    }

    final event = _randomEventService.pickRandomEvent(
      allEvents: RandomEventCatalog.events,
      state: _state,
      nowUtc: nowUtc,
      random: _random,
    );
    if (event == null) {
      return changed;
    }

    _state = _state.copyWith(
      randomEvents: _state.randomEvents.markShown(event, nowUtc),
    );
    unawaited(_queueSave());
    return true;
  }

  void _showInitialDebugRandomEvent(DateTime nowUtc) {
    if (!kDebugMode || _state.randomEvents.activeEventId != null) {
      return;
    }
    _showDebugRandomEvent(nowUtc);
  }

  void _showDebugRandomEvent(DateTime nowUtc) {
    final events = RandomEventCatalog.events;
    if (events.isEmpty) {
      return;
    }
    final currentEventId = _state.randomEvents.activeEventId;
    var event = events[_debugRandomEventCursor % events.length];
    _debugRandomEventCursor += 1;
    if (events.length > 1 && event.id == currentEventId) {
      event = events[_debugRandomEventCursor % events.length];
      _debugRandomEventCursor += 1;
    }
    _state = _state.copyWith(
      randomEvents: _state.randomEvents
          .copyWith(clearActiveEventId: true)
          .markShown(event, nowUtc),
    );
  }

  String _applyRandomEventOutcome(
    RandomEventDefinition event,
    RandomEventOutcome outcome,
    DateTime nowUtc,
  ) {
    final effect = outcome.effect;
    final passiveRate = math.max(1.0, passiveIncomePerSecond);
    final currentCash = _state.cash;
    switch (effect.type) {
      case RandomEventEffectType.instantMoney:
        final coins = CurrencyMath.roundDouble(passiveRate * effect.value);
        if (coins > 0) {
          _state = _engine.addCoins(_state, coins);
          _recordGoalEvent(
            GoalObjectiveType.earnMoney,
            coins.toDouble(),
            nowUtc: nowUtc,
          );
        }
        _applyInlineReputationGain(effect, nowUtc);
        return '+${_formatAmount(coins)} ${_state.localeCode == 'tr' ? 'para' : 'cash'}';
      case RandomEventEffectType.moneyCost:
        final capSeconds = double.tryParse(effect.target ?? '') ?? 300;
        final cost = math.min<double>(
          currentCash * effect.value,
          passiveRate * capSeconds,
        );
        final coins = CurrencyMath.roundDouble(cost);
        _state = _state.copyWith(
          cash: CurrencyMath.subtract(_state.cash, coins),
        );
        return '-${_formatAmount(coins)} ${_state.localeCode == 'tr' ? 'para' : 'cash'}';
      case RandomEventEffectType.tapBoost:
        _addRandomEventModifier(
          event,
          RandomEventModifierType.tapIncome,
          effect,
          nowUtc,
        );
        return 'Tap x${effect.value.toStringAsFixed(1)}';
      case RandomEventEffectType.tapPenalty:
        _addRandomEventModifier(
          event,
          RandomEventModifierType.tapIncome,
          effect,
          nowUtc,
        );
        return 'Tap -${((1 - effect.value) * 100).round()}%';
      case RandomEventEffectType.passiveBoost:
        _applyInlineCost(effect, nowUtc, passiveRate);
        _addRandomEventModifier(
          event,
          RandomEventModifierType.passiveIncome,
          effect,
          nowUtc,
        );
        return 'Pasif +${((effect.value - 1) * 100).round()}%';
      case RandomEventEffectType.passivePenalty:
        _addRandomEventModifier(
          event,
          RandomEventModifierType.passiveIncome,
          effect,
          nowUtc,
        );
        return 'Pasif -${((1 - effect.value) * 100).round()}%';
      case RandomEventEffectType.globalBoost:
        _applyInlineCost(effect, nowUtc, passiveRate);
        _addRandomEventModifier(
          event,
          RandomEventModifierType.globalIncome,
          effect,
          nowUtc,
        );
        return effect.value >= 2
            ? 'Tüm gelir x${effect.value.toStringAsFixed(0)}'
            : 'Tüm gelir +${((effect.value - 1) * 100).round()}%';
      case RandomEventEffectType.globalPenalty:
        _addRandomEventModifier(
          event,
          RandomEventModifierType.globalIncome,
          effect,
          nowUtc,
        );
        return 'Tüm gelir -${((1 - effect.value) * 100).round()}%';
      case RandomEventEffectType.menuBoost:
        _addRandomEventModifier(
          event,
          RandomEventModifierType.menuMultiplier,
          effect,
          nowUtc,
        );
        return 'Menü +${((effect.value - 1) * 100).round()}%';
      case RandomEventEffectType.menuPenalty:
        _addRandomEventModifier(
          event,
          RandomEventModifierType.menuMultiplier,
          effect,
          nowUtc,
        );
        return 'Menü -${((1 - effect.value) * 100).round()}%';
      case RandomEventEffectType.upgradeDiscount:
        _applyInlineCost(effect, nowUtc, passiveRate);
        _addRandomEventModifier(
          event,
          RandomEventModifierType.upgradeCost,
          effect,
          nowUtc,
        );
        return 'Upgrade maliyeti -${((1 - effect.value) * 100).round()}%';
      case RandomEventEffectType.upgradeCostPenalty:
        _addRandomEventModifier(
          event,
          RandomEventModifierType.upgradeCost,
          effect,
          nowUtc,
        );
        return 'Upgrade maliyeti +${((effect.value - 1) * 100).round()}%';
      case RandomEventEffectType.reputationGain:
        final reputation = math.max(0, effect.value.round());
        _state = _state.copyWith(
          customerReputation: _state.customerReputation.add(reputation),
        );
        return '+$reputation itibar';
      case RandomEventEffectType.reputationBoost:
      case RandomEventEffectType.reputationPenalty:
      case RandomEventEffectType.permanentBonus:
      case RandomEventEffectType.challengeStart:
      case RandomEventEffectType.noEffect:
        return 'Etki yok';
    }
  }

  void _addRandomEventModifier(
    RandomEventDefinition event,
    RandomEventModifierType type,
    RandomEventEffect effect,
    DateTime nowUtc,
  ) {
    final duration = effect.duration ?? const Duration(minutes: 5);
    final modifier = TimedModifierState(
      id: '${event.id}_${type.name}_${nowUtc.millisecondsSinceEpoch}',
      sourceEventId: event.id,
      type: type,
      value: effect.value,
      expiresAtUtc: nowUtc.add(duration),
    );
    _state = _state.copyWith(
      randomEvents: _state.randomEvents.copyWith(
        activeModifiers: <TimedModifierState>[
          ..._state.randomEvents.activeModifiers.where(
            (entry) => entry.isActiveAt(nowUtc),
          ),
          modifier,
        ],
      ),
    );
  }

  void _applyInlineCost(
    RandomEventEffect effect,
    DateTime nowUtc,
    double passiveRate,
  ) {
    final target = effect.target ?? '';
    if (!target.startsWith('cost:')) {
      return;
    }
    final percent = double.tryParse(target.substring('cost:'.length)) ?? 0;
    if (percent <= 0) {
      return;
    }
    final cap = passiveRate * 300;
    final cost = CurrencyMath.roundDouble(
      math.min<double>(_state.cash * percent, cap),
    );
    _state = _state.copyWith(cash: CurrencyMath.subtract(_state.cash, cost));
  }

  void _applyInlineReputationGain(RandomEventEffect effect, DateTime nowUtc) {
    final target = effect.target ?? '';
    if (!target.startsWith('reputation:')) {
      return;
    }
    final reputation =
        int.tryParse(target.substring('reputation:'.length)) ?? 0;
    if (reputation <= 0) {
      return;
    }
    _state = _state.copyWith(
      customerReputation: _state.customerReputation.add(reputation),
    );
    _recordGoalEvent(
      GoalObjectiveType.gainReputation,
      reputation.toDouble(),
      nowUtc: nowUtc,
    );
  }

  String _formatAmount(num value) {
    return formatNumberWithUnitNames(value, locale: _state.localeCode);
  }

  Future<void> _queueSave() {
    final snapshot = _state.copyWith(lastSavedAtUtc: _clock());
    _state = snapshot;
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
    _refreshRandomEventViewModel(nowUtc: nowUtc);
    _refreshActivePlayViewModel(nowUtc: nowUtc);
    _refreshCustomerOrderViewModel(nowUtc: nowUtc);
    _refreshQuestViewModel();
    _refreshGoalViewModel(nowUtc: nowUtc);
    _refreshBranchViewModel(nowUtc: nowUtc);
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
    _setSnapshotIfChanged(
      _branchSnapshotListenable,
      _computeBranchSnapshot(nowUtc: effectiveNow),
    );
  }

  void _refreshHudViewModel({DateTime? nowUtc}) {
    _setSnapshotIfChanged(
      _hudSnapshotListenable,
      _computeHudSnapshot(nowUtc: (nowUtc ?? _clock()).toUtc()),
    );
  }

  void _refreshPrestigeViewModel() {
    _setSnapshotIfChanged(
      _prestigeSnapshotListenable,
      _computePrestigeSnapshot(),
    );
  }

  void _refreshRandomEventViewModel({DateTime? nowUtc}) {
    _setSnapshotIfChanged(
      _randomEventSnapshotListenable,
      _computeRandomEventSnapshot(nowUtc: (nowUtc ?? _clock()).toUtc()),
    );
  }

  void _refreshActivePlayViewModel({DateTime? nowUtc}) {
    _setSnapshotIfChanged(
      _activePlaySnapshotListenable,
      _computeActivePlaySnapshot(nowUtc: (nowUtc ?? _clock()).toUtc()),
    );
  }

  void _refreshCustomerOrderViewModel({DateTime? nowUtc}) {
    _setSnapshotIfChanged(
      _customerOrderSnapshotListenable,
      _computeCustomerOrderSnapshot(nowUtc: (nowUtc ?? _clock()).toUtc()),
    );
  }

  void _refreshQuestViewModel() {
    _setSnapshotIfChanged(_questSnapshotListenable, _computeQuestSnapshot());
  }

  void _refreshGoalViewModel({DateTime? nowUtc}) {
    _setSnapshotIfChanged(
      _goalSnapshotListenable,
      _computeGoalSnapshot(nowUtc: (nowUtc ?? _clock()).toUtc()),
    );
  }

  void _refreshBranchViewModel({DateTime? nowUtc}) {
    _setSnapshotIfChanged(
      _branchSnapshotListenable,
      _computeBranchSnapshot(nowUtc: (nowUtc ?? _clock()).toUtc()),
    );
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

  bool _refreshGoalState(
    DateTime nowUtc, {
    bool forcePrestigeRunRefresh = false,
  }) {
    final beforeGoals = _state.goals;
    final nextGoals = _goalEngine.refresh(
      _state,
      config: config,
      nowUtc: nowUtc,
      random: _random,
      forcePrestigeRunRefresh: forcePrestigeRunRefresh,
    );
    if (beforeGoals == nextGoals) {
      return false;
    }
    _state = _state.copyWith(goals: nextGoals);
    return true;
  }

  bool _recordGoalEvent(
    GoalObjectiveType objectiveType,
    double value, {
    required DateTime nowUtc,
    bool useMaxProgress = false,
  }) {
    if (value <= 0) {
      return false;
    }
    final beforeGoals = _state.goals;
    final nextGoals = _goalEngine.recordProgress(
      beforeGoals,
      objectiveType,
      value,
      nowUtc: nowUtc,
      useMaxProgress: useMaxProgress,
    );
    if (beforeGoals == nextGoals) {
      return false;
    }
    _state = _state.copyWith(goals: nextGoals);
    if (_hasNewCompletedGoal(beforeGoals, nextGoals)) {
      unawaited(_queueSave());
    }
    return true;
  }

  bool _hasNewCompletedGoal(GoalSystemState previous, GoalSystemState next) {
    final previousById = {
      for (final progress in previous.allActiveGoals) progress.goalId: progress,
    };
    for (final progress in next.allActiveGoals) {
      if (progress.status != GoalStatus.completed || progress.rewardClaimed) {
        continue;
      }
      if (previousById[progress.goalId]?.status != GoalStatus.completed) {
        return true;
      }
    }
    return false;
  }

  bool _recordCompletedBranchRegions(
    Set<String> completedRegionsBefore, {
    required DateTime nowUtc,
  }) {
    final completedRegionsAfter = BranchCatalog.completedRegionIds(
      _state.branches,
    );
    final newlyCompleted = completedRegionsAfter
        .where((regionId) => !completedRegionsBefore.contains(regionId))
        .length;
    if (newlyCompleted <= 0) {
      return false;
    }
    return _recordGoalEvent(
      GoalObjectiveType.completeBranchRegions,
      newlyCompleted.toDouble(),
      nowUtc: nowUtc,
    );
  }

  bool _refreshProgressionState() {
    final beforeAchievements = _state.achievements;
    final beforeCollection = _state.collection;
    final beforeCollection2 = _state.collection2;
    final beforeShopProgression = _state.shopProgression;
    final beforeBranches = _state.branches;
    _state = _unlockCollectionItemsForCurrentUpgrades(_state);
    _state = _refreshCollection2SetBonuses(_state);
    _state = _refreshShopProgression(_state);
    _state = _refreshBranchProgression(_state);
    _state = _refreshAchievementProgress(_state);
    return !mapEquals(beforeAchievements, _state.achievements) ||
        beforeCollection.unlockedItemIds != _state.collection.unlockedItemIds ||
        beforeCollection.claimedBonusItemIds !=
            _state.collection.claimedBonusItemIds ||
        beforeCollection2 != _state.collection2 ||
        beforeShopProgression.currentShopLevel !=
            _state.shopProgression.currentShopLevel ||
        beforeShopProgression.highestShopLevel !=
            _state.shopProgression.highestShopLevel ||
        beforeShopProgression.unlockedShopIds !=
            _state.shopProgression.unlockedShopIds ||
        beforeBranches != _state.branches;
  }

  bool _refreshTapProgressionState() {
    final beforeAchievements = _state.achievements;
    final beforeShopProgression = _state.shopProgression;
    _state = _refreshShopProgression(_state);
    _state = _refreshAchievementProgress(_state);
    return !mapEquals(beforeAchievements, _state.achievements) ||
        beforeShopProgression.currentShopLevel !=
            _state.shopProgression.currentShopLevel ||
        beforeShopProgression.highestShopLevel !=
            _state.shopProgression.highestShopLevel ||
        beforeShopProgression.unlockedShopIds !=
            _state.shopProgression.unlockedShopIds;
  }

  bool _refreshCustomerUnlockState() {
    final unlocked = CustomerOrderCatalog.unlockedTypeIdsForLevel(
      _state.customerReputation.currentLevel,
      existing: _state.customerOrders.unlockedCustomerTypeIds,
    );
    if (setEquals(unlocked, _state.customerOrders.unlockedCustomerTypeIds)) {
      return false;
    }
    _state = _state.copyWith(
      customerOrders: _state.customerOrders.copyWith(
        unlockedCustomerTypeIds: unlocked,
      ),
    );
    return true;
  }

  _CustomerOrderUpdateResult _advanceCustomerOrders({
    required DateTime nowUtc,
    required Duration elapsed,
    required num passiveCoinsEarned,
  }) {
    if (elapsed <= Duration.zero) {
      return const _CustomerOrderUpdateResult();
    }
    final elapsedSeconds = elapsed.inMilliseconds / 1000;
    final activeOrder = _state.customerOrders.activeOrder;
    if (activeOrder != null) {
      var result = const _CustomerOrderUpdateResult();
      final activeSeconds = math.min(
        elapsedSeconds,
        activeOrder.remainingSeconds,
      );

      if (activeOrder.objectiveType == OrderObjectiveType.waitPassiveSeconds &&
          activeSeconds > 0) {
        result = result.merge(
          _recordCustomerOrderEvent(
            OrderObjectiveType.waitPassiveSeconds,
            activeSeconds,
            nowUtc: nowUtc,
          ),
        );
      }

      final orderAfterPassiveTime = _state.customerOrders.activeOrder;
      if (orderAfterPassiveTime == null) {
        return result;
      }

      if (orderAfterPassiveTime.objectiveType == OrderObjectiveType.earnMoney &&
          passiveCoinsEarned > 0 &&
          activeSeconds > 0) {
        final eligibleCoins = elapsedSeconds <= 0
            ? passiveCoinsEarned
            : (passiveCoinsEarned * (activeSeconds / elapsedSeconds)).floor();
        result = result.merge(
          _recordCustomerOrderEvent(
            OrderObjectiveType.earnMoney,
            eligibleCoins.toDouble(),
            nowUtc: nowUtc,
          ),
        );
      }

      final refreshedOrder = _state.customerOrders.activeOrder;
      if (refreshedOrder == null) {
        return result;
      }

      final remainingSeconds = math.max(
        0.0,
        refreshedOrder.remainingSeconds - elapsedSeconds,
      );
      if (remainingSeconds <= 0 && !refreshedOrder.isComplete) {
        return result.merge(_failActiveCustomerOrder(nowUtc));
      }
      if (remainingSeconds == refreshedOrder.remainingSeconds) {
        return result;
      }
      _state = _state.copyWith(
        customerOrders: _state.customerOrders.copyWith(
          activeOrder: refreshedOrder.copyWith(
            remainingSeconds: remainingSeconds,
          ),
        ),
      );
      return result.merge(const _CustomerOrderUpdateResult(stateChanged: true));
    }

    final remainingSeconds = math.max(
      0.0,
      _state.customerOrders.spawnRemainingSeconds - elapsedSeconds,
    );
    if (remainingSeconds <= 0) {
      return _spawnCustomerOrder(nowUtc);
    }
    _state = _state.copyWith(
      customerOrders: _state.customerOrders.copyWith(
        spawnRemainingSeconds: remainingSeconds,
        nextSpawnTimeMillis: nowUtc
            .add(Duration(milliseconds: (remainingSeconds * 1000).round()))
            .millisecondsSinceEpoch,
      ),
    );
    return const _CustomerOrderUpdateResult(stateChanged: true);
  }

  _CustomerOrderUpdateResult _recordCustomerOrderEvent(
    OrderObjectiveType objectiveType,
    double value, {
    required DateTime nowUtc,
    bool useMaxProgress = false,
  }) {
    if (value <= 0) {
      return const _CustomerOrderUpdateResult();
    }
    final order = _state.customerOrders.activeOrder;
    if (order == null ||
        order.rewardClaimed ||
        order.objectiveType != objectiveType) {
      return const _CustomerOrderUpdateResult();
    }
    final nextValue = useMaxProgress
        ? math.max(order.currentValue, value)
        : order.currentValue + value;
    final clampedValue = math.min(order.targetValue, nextValue);
    if (clampedValue == order.currentValue) {
      return const _CustomerOrderUpdateResult();
    }
    final updatedOrder = order.copyWith(currentValue: clampedValue);
    _state = _state.copyWith(
      customerOrders: _state.customerOrders.copyWith(activeOrder: updatedOrder),
    );
    var result = const _CustomerOrderUpdateResult(stateChanged: true);
    if (updatedOrder.isComplete) {
      result = result.merge(_completeActiveCustomerOrder(nowUtc));
    }
    return result;
  }

  _CustomerOrderUpdateResult _completeActiveCustomerOrder(DateTime nowUtc) {
    final order = _state.customerOrders.activeOrder;
    if (order == null) {
      return const _CustomerOrderUpdateResult();
    }
    if (order.rewardClaimed ||
        _state.customerOrders.completedOrderIds.contains(order.id)) {
      _state = _state.copyWith(
        customerOrders: _scheduleNextCustomerSpawn(
          _state.customerOrders.copyWith(clearActiveOrder: true),
          nowUtc,
        ),
      );
      unawaited(_queueSave());
      return const _CustomerOrderUpdateResult(stateChanged: true);
    }

    var result = _applyCustomerOrderRewards(order, nowUtc);
    _recordGoalEvent(
      GoalObjectiveType.completeCustomerOrders,
      1,
      nowUtc: nowUtc,
    );
    final completedIds = Set<String>.from(
      _state.customerOrders.completedOrderIds,
    )..add(order.id);
    final completedByType = Map<String, int>.from(
      _state.customerOrders.completedByType,
    );
    completedByType[order.customerTypeId] =
        (completedByType[order.customerTypeId] ?? 0) + 1;
    final nextOrders = _scheduleNextCustomerSpawn(
      _state.customerOrders.copyWith(
        clearActiveOrder: true,
        completedOrderIds: Set<String>.unmodifiable(completedIds),
        completedOrderCount: _state.customerOrders.completedOrderCount + 1,
        completedByType: Map<String, int>.unmodifiable(completedByType),
      ),
      nowUtc,
    );
    _state = _state.copyWith(customerOrders: nextOrders);
    unawaited(_queueSave());
    result = result.merge(const _CustomerOrderUpdateResult(stateChanged: true));
    return result;
  }

  _CustomerOrderUpdateResult _failActiveCustomerOrder(DateTime nowUtc) {
    if (_state.customerOrders.activeOrder == null) {
      return const _CustomerOrderUpdateResult();
    }
    _state = _state.copyWith(
      customerOrders: _scheduleNextCustomerSpawn(
        _state.customerOrders.copyWith(
          clearActiveOrder: true,
          failedOrderCount: _state.customerOrders.failedOrderCount + 1,
        ),
        nowUtc,
      ),
    );
    unawaited(_queueSave());
    return const _CustomerOrderUpdateResult(stateChanged: true);
  }

  _CustomerOrderUpdateResult _applyCustomerOrderRewards(
    CustomerOrder order,
    DateTime nowUtc,
  ) {
    var stateChanged = false;
    var economyChanged = false;
    var progressionChanged = false;

    for (final reward in order.rewards) {
      switch (reward.type) {
        case OrderRewardType.money:
        case OrderRewardType.tip:
          final coins = CurrencyMath.roundDouble(reward.amount);
          if (coins > 0) {
            _state = _engine.addCoins(_state, coins);
            _recordGoalEvent(
              GoalObjectiveType.earnMoney,
              coins.toDouble(),
              nowUtc: nowUtc,
            );
            stateChanged = true;
            economyChanged = true;
          }
          break;
        case OrderRewardType.reputation:
          final reputation = reward.amount.round();
          if (reputation > 0) {
            _state = _state.copyWith(
              customerReputation: _state.customerReputation.add(reputation),
            );
            _recordGoalEvent(
              GoalObjectiveType.gainReputation,
              reputation.toDouble(),
              nowUtc: nowUtc,
            );
            _refreshCustomerUnlockState();
            stateChanged = true;
          }
          break;
        case OrderRewardType.recipeShard:
          _state = _applyCollection2RewardToState(
            _state,
            ChestRewardType.recipeShard,
            amount: reward.amount.round(),
            itemId: reward.itemId,
          );
          stateChanged = true;
          progressionChanged = true;
          economyChanged = true;
          break;
        case OrderRewardType.staffCardShard:
          _state = _applyCollection2RewardToState(
            _state,
            ChestRewardType.staffCardShard,
            amount: reward.amount.round(),
            itemId: reward.itemId,
          );
          stateChanged = true;
          progressionChanged = true;
          economyChanged = true;
          break;
        case OrderRewardType.decorShard:
          _state = _applyCollection2RewardToState(
            _state,
            ChestRewardType.decorShard,
            amount: reward.amount.round(),
            itemId: reward.itemId,
          );
          stateChanged = true;
          progressionChanged = true;
          economyChanged = true;
          break;
        case OrderRewardType.knifeSkinShard:
          _state = _applyCollection2RewardToState(
            _state,
            ChestRewardType.knifeSkinShard,
            amount: reward.amount.round(),
            itemId: reward.itemId,
          );
          stateChanged = true;
          progressionChanged = true;
          economyChanged = true;
          break;
        case OrderRewardType.chest:
          final quantity = math.max(1, reward.amount.round());
          _grantChest(reward.chestType ?? ChestType.small, quantity: quantity);
          stateChanged = true;
          progressionChanged = true;
          break;
        case OrderRewardType.temporaryBoost:
          final durationSeconds = math.max(1, reward.durationSeconds ?? 30);
          _state = _state.copyWith(
            passiveBoost: TimedEffectState(
              endsAtUtc: nowUtc.add(Duration(seconds: durationSeconds)),
            ),
          );
          stateChanged = true;
          economyChanged = true;
          break;
      }
    }

    return _CustomerOrderUpdateResult(
      stateChanged: stateChanged,
      economyChanged: economyChanged,
      progressionChanged: progressionChanged,
    );
  }

  _CustomerOrderUpdateResult _spawnCustomerOrder(DateTime nowUtc) {
    if (_state.customerOrders.activeOrder != null) {
      return const _CustomerOrderUpdateResult();
    }
    final template = _pickCustomerOrderTemplate();
    if (template == null) {
      _state = _state.copyWith(
        customerOrders: _scheduleNextCustomerSpawn(
          _state.customerOrders,
          nowUtc,
        ),
      );
      return const _CustomerOrderUpdateResult(stateChanged: true);
    }
    final collection2Bonuses = Collection2Catalog.bonusTotalsFor(
      _state.collection2,
    );
    final order = template.createOrder(
      instanceId:
          '${template.id}_${nowUtc.millisecondsSinceEpoch}_${(_random.nextDouble() * 100000).round()}',
      localeCode: _state.localeCode,
      passiveIncomePerSecond: _engine.passiveIncomePerSecond(
        _state,
        nowUtc: nowUtc,
      ),
      tapValue: _engine.tapValue(_state, nowUtc: nowUtc),
      reputationLevel: _state.customerReputation.currentLevel,
      milestoneTipValuePercent: _state.milestones.tipValuePercent,
      collectionCustomerRewardPercent:
          collection2Bonuses.customerRewardBonusPercent,
      collectionTipValuePercent: collection2Bonuses.tipValueBonusPercent,
      collectionTipChancePercent: collection2Bonuses.tipChanceBonusPercent,
      collectionReputationGainPercent:
          collection2Bonuses.reputationGainBonusPercent,
      collectionOrderDurationBonusPercent:
          collection2Bonuses.customerOrderDurationBonusPercent,
    );
    _state = _state.copyWith(
      customerOrders: _state.customerOrders.copyWith(
        activeOrder: order,
        lastSpawnTimeMillis: nowUtc.millisecondsSinceEpoch,
        nextSpawnTimeMillis: 0,
        spawnRemainingSeconds: 0,
      ),
    );
    unawaited(_queueSave());
    return const _CustomerOrderUpdateResult(stateChanged: true);
  }

  CustomerOrderTemplate? _pickCustomerOrderTemplate() {
    final eligible = CustomerOrderCatalog.templates
        .where(_isCustomerOrderTemplateEligible)
        .toList(growable: false);
    if (eligible.isEmpty) {
      return null;
    }
    final totalWeight = eligible.fold<double>(
      0,
      (total, template) => total + template.weight,
    );
    var roll = _random.nextDouble() * totalWeight;
    for (final template in eligible) {
      roll -= template.weight;
      if (roll <= 0) {
        return template;
      }
    }
    return eligible.last;
  }

  bool _isCustomerOrderTemplateEligible(CustomerOrderTemplate template) {
    if (!_state.customerOrders.unlockedCustomerTypeIds.contains(
      template.customerTypeId,
    )) {
      return false;
    }
    final type = CustomerOrderCatalog.customerTypeById(template.customerTypeId);
    if (_state.customerReputation.currentLevel <
        math.max(type.minReputationLevel, template.minReputationLevel)) {
      return false;
    }
    if (_state.shopProgression.currentShopLevel <
        math.max(type.minShopLevel, template.minShopLevel)) {
      return false;
    }
    if (_state.prestige.prestigeCount <
        math.max(type.minPrestigeCount, template.minPrestigeCount)) {
      return false;
    }
    for (final featureKey in template.requiredFeatureKeys) {
      if (!_state.milestones.hasFeature(featureKey)) {
        return false;
      }
    }
    return true;
  }

  CustomerSystemState _scheduleNextCustomerSpawn(
    CustomerSystemState customerOrders,
    DateTime nowUtc,
  ) {
    final interval = _customerSpawnInterval();
    return customerOrders.copyWith(
      nextSpawnTimeMillis: nowUtc.add(interval).millisecondsSinceEpoch,
      spawnRemainingSeconds: interval.inMilliseconds / 1000,
    );
  }

  void _scheduleInitialCustomerSpawnIfNeeded(DateTime nowUtc) {
    final customerOrders = _state.customerOrders;
    if (customerOrders.activeOrder != null ||
        customerOrders.lastSpawnTimeMillis > 0 ||
        customerOrders.completedOrderCount > 0 ||
        customerOrders.failedOrderCount > 0) {
      return;
    }
    final interval = _firstCustomerSpawnInterval();
    _state = _state.copyWith(
      customerOrders: customerOrders.copyWith(
        nextSpawnTimeMillis: nowUtc.add(interval).millisecondsSinceEpoch,
        spawnRemainingSeconds: interval.inMilliseconds / 1000,
      ),
    );
  }

  Duration _firstCustomerSpawnInterval() {
    return _applyCustomerSpawnSpeedBonus(
      Duration(seconds: 180 + (_random.nextDouble() * 120).round()),
    );
  }

  Duration _customerSpawnInterval() {
    final level = _state.shopProgression.currentShopLevel;
    final minSeconds = switch (level) {
      <= 1 => 120,
      2 => 100,
      3 => 90,
      4 => 75,
      _ => 60,
    };
    final maxSeconds = math.min(150, minSeconds + 30);
    final roll = _random.nextDouble();
    return _applyCustomerSpawnSpeedBonus(
      Duration(
        seconds: minSeconds + ((maxSeconds - minSeconds) * roll).round(),
      ),
    );
  }

  Duration _applyCustomerSpawnSpeedBonus(Duration raw) {
    final bonus = Collection2Catalog.bonusTotalsFor(
      _state.collection2,
    ).customerSpawnSpeedPercent;
    if (bonus <= 0) {
      return raw;
    }
    final adjustedMilliseconds = (raw.inMilliseconds / (1 + bonus)).round();
    return Duration(milliseconds: math.max(30 * 1000, adjustedMilliseconds));
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
    final strings = AppStrings.forLanguageCode(state.localeCode);
    _pendingShopLevelUpSnapshot = ShopLevelUpSnapshot(
      previousLevelName: strings.shopLevelName(previousShop.id),
      currentLevelName: strings.shopLevelName(nextShop.id),
      unlockLabel: strings.shopUnlockLabel(nextShop.id),
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

  GameState _refreshBranchProgression(GameState state) {
    final branches = BranchCatalog.refreshState(state.branches);
    var nextState = branches == state.branches
        ? state
        : state.copyWith(branches: branches);
    if (branches.claimedBranchMilestones.contains(
          BranchCatalog.firstManagerGrantMarker,
        ) ||
        !branches.branchProgress.values.any(
          (progress) =>
              progress.isUnlocked &&
              progress.level >= BranchCatalog.managerUnlockLevel,
        )) {
      return nextState;
    }

    final markedMilestones = Set<String>.from(branches.claimedBranchMilestones)
      ..add(BranchCatalog.firstManagerGrantMarker);
    nextState = nextState.copyWith(
      branches: branches.copyWith(
        claimedBranchMilestones: Set<String>.unmodifiable(markedMilestones),
      ),
    );
    final alreadyHasStaff = Collection2Catalog.masterCards.any(
      (staff) => nextState.collection2.isMasterCardUnlocked(staff.id),
    );
    if (alreadyHasStaff) {
      return nextState;
    }
    final apprentice = Collection2Catalog.masterCardById['staff_apprentice'];
    if (apprentice == null) {
      return nextState;
    }
    final grant = Collection2Catalog.addStaffCards(
      nextState.collection2,
      apprentice.id,
      apprentice.requiredCards,
    );
    return nextState.copyWith(collection2: grant.state);
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

  GameState _refreshCollection2SetBonuses(GameState state) {
    final result = Collection2Catalog.refreshSetBonuses(state.collection2);
    return result.state == state.collection2
        ? state
        : state.copyWith(collection2: result.state);
  }

  int _collectionUnlockCount(GameState state) {
    return state.collection.unlockedItemIds.length +
        state.collection2.unlockedContentCount;
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
      'combo_15' =>
        _engine.activeComboForCount(state.stats.maxCombo, state).toDouble(),
      'critical_3' => state.stats.criticalCutCount.toDouble(),
      'chest_1' => state.stats.chestsOpened.toDouble(),
      'collection_5' => _collectionUnlockCount(state).toDouble(),
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
        return _engine.addCoins(state, CurrencyMath.roundDouble(reward.amount));
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

  GameState _applyGoalRewards(
    GameState state,
    List<GoalReward> rewards,
    DateTime nowUtc,
  ) {
    var nextState = state;
    for (final reward in rewards) {
      switch (reward.type) {
        case GoalRewardType.money:
          final coins = CurrencyMath.roundDouble(reward.amount);
          if (coins > 0) {
            nextState = _engine.addCoins(nextState, coins);
          }
          break;
        case GoalRewardType.reputation:
          final reputation = reward.amount.round();
          if (reputation > 0) {
            nextState = _addCustomerReputation(nextState, reputation);
          }
          break;
        case GoalRewardType.chest:
          final quantity = math.max(1, reward.amount.round());
          nextState = nextState.copyWith(
            chestInventory: nextState.chestInventory.add(
              reward.chestType ?? ChestType.small,
              quantity: quantity,
            ),
          );
          break;
        case GoalRewardType.temporaryBoost:
          final durationSeconds = math.max(1, reward.durationSeconds ?? 30);
          nextState = nextState.copyWith(
            passiveBoost: TimedEffectState(
              endsAtUtc: nowUtc.add(Duration(seconds: durationSeconds)),
            ),
          );
          break;
        case GoalRewardType.prestigePoint:
          final points = reward.amount.round();
          if (points > 0) {
            nextState = nextState.copyWith(
              prestige: nextState.prestige.copyWith(
                totalPrestigePoints:
                    nextState.prestige.totalPrestigePoints + points,
                unspentPrestigePoints:
                    nextState.prestige.unspentPrestigePoints + points,
              ),
            );
          }
          break;
        case GoalRewardType.recipeShard:
          nextState = _applyCollection2RewardToState(
            nextState,
            ChestRewardType.recipeShard,
            amount: reward.amount.round(),
            itemId: reward.itemId,
          );
          break;
        case GoalRewardType.staffCardShard:
          nextState = _applyCollection2RewardToState(
            nextState,
            ChestRewardType.staffCardShard,
            amount: reward.amount.round(),
            itemId: reward.itemId,
          );
          break;
        case GoalRewardType.decorShard:
          nextState = _applyCollection2RewardToState(
            nextState,
            ChestRewardType.decorShard,
            amount: reward.amount.round(),
            itemId: reward.itemId,
          );
          break;
        case GoalRewardType.knifeSkinShard:
          nextState = _applyCollection2RewardToState(
            nextState,
            ChestRewardType.knifeSkinShard,
            amount: reward.amount.round(),
            itemId: reward.itemId,
          );
          break;
        case GoalRewardType.prestigeShard:
          nextState = _applyCollection2RewardToState(
            nextState,
            ChestRewardType.prestigeShard,
            amount: reward.amount.round(),
            itemId: reward.itemId,
          );
          break;
      }
    }
    return nextState;
  }

  void _grantChest(ChestType type, {int quantity = 1}) {
    if (quantity <= 0) {
      return;
    }
    _state = _state.copyWith(
      chestInventory: _state.chestInventory.add(type, quantity: quantity),
    );
  }

  GameState _addCustomerReputation(GameState state, int amount) {
    if (amount <= 0) {
      return state;
    }
    final multiplier = Collection2Catalog.bonusTotalsFor(
      state.collection2,
    ).reputationGainMultiplier;
    final gained = math.max(1, CurrencyMath.roundInt(amount * multiplier));
    return state.copyWith(
      customerReputation: state.customerReputation.add(gained),
    );
  }

  GameState _applyCollection2RewardToState(
    GameState state,
    ChestRewardType rewardType, {
    required int amount,
    String? itemId,
    Rarity rarity = Rarity.common,
  }) {
    if (amount <= 0) {
      return state;
    }
    final result = Collection2Catalog.applyChestReward(
      state: state.collection2,
      rewardType: rewardType,
      amount: amount,
      rarity: rarity,
      itemId: itemId,
      random: _random,
    );
    var nextState = state.copyWith(collection2: result.state);
    if (result.overflowReputation > 0) {
      nextState = _addCustomerReputation(nextState, result.overflowReputation);
    }
    if (result.prestigePoints > 0) {
      nextState = nextState.copyWith(
        prestige: nextState.prestige.copyWith(
          totalPrestigePoints:
              nextState.prestige.totalPrestigePoints + result.prestigePoints,
          unspentPrestigePoints:
              nextState.prestige.unspentPrestigePoints + result.prestigePoints,
        ),
      );
    }
    return nextState;
  }

  ChestReward _rollChestReward(ChestType type) {
    final drop = ChestDropCatalog.roll(type, _random);
    final amount = switch (drop.rewardType) {
      ChestRewardType.money => _scaledChestMoney(type, drop.amount),
      ChestRewardType.permanentTapBonus ||
      ChestRewardType.permanentPassiveBonus ||
      ChestRewardType.permanentGlobalBonus => drop.amount / 100,
      _ => drop.amount.toDouble(),
    };
    return ChestReward(
      rewardType: drop.rewardType,
      amount: amount,
      durationSeconds: drop.durationSeconds,
      itemId: drop.itemId,
      rarity: drop.rarity,
    );
  }

  double _scaledChestMoney(ChestType type, int minimumAmount) {
    final tap = _engine.tapValue(_state);
    final passive = _engine.passiveIncomePerSecond(_state);
    return switch (type) {
      ChestType.small => math.max(minimumAmount, tap * 50).toDouble(),
      ChestType.master =>
        math.max(minimumAmount, math.max(tap * 200, passive * 180)).toDouble(),
      ChestType.gold =>
        math.max(minimumAmount, math.max(tap * 1000, passive * 600)).toDouble(),
      ChestType.recipe || ChestType.staff || ChestType.decor =>
        math.max(minimumAmount, math.max(tap * 120, passive * 120)).toDouble(),
      ChestType.prestige =>
        math.max(minimumAmount, math.max(tap * 300, passive * 240)).toDouble(),
    };
  }

  GameState _applyChestReward(
    GameState state,
    ChestReward reward, {
    required DateTime nowUtc,
  }) {
    switch (reward.rewardType) {
      case ChestRewardType.money:
        final bonus = Collection2Catalog.bonusTotalsFor(
          state.collection2,
        ).chestRewardMultiplier;
        return _engine.addCoins(
          state,
          CurrencyMath.roundDouble(reward.amount * bonus),
        );
      case ChestRewardType.reputation:
        return _addCustomerReputation(state, reward.amount.round());
      case ChestRewardType.temporaryIncomeBoost:
        return state.copyWith(
          passiveBoost: TimedEffectState(
            endsAtUtc: nowUtc.add(
              Duration(seconds: reward.durationSeconds ?? 45),
            ),
          ),
        );
      case ChestRewardType.cosmeticToken:
        return state.copyWith(
          milestones: state.milestones.copyWith(
            cosmeticTokens:
                state.milestones.cosmeticTokens + reward.amount.round(),
          ),
        );
      case ChestRewardType.recipeShard:
      case ChestRewardType.staffCardShard:
      case ChestRewardType.decorShard:
      case ChestRewardType.knifeSkinShard:
      case ChestRewardType.prestigeShard:
        return _applyCollection2RewardToState(
          state,
          reward.rewardType,
          amount: reward.amount.round(),
          itemId: reward.itemId,
          rarity: reward.rarity,
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
    final isTr = _state.localeCode == 'tr';
    return switch (reward.rewardType) {
      ChestRewardType.money =>
        '+${_formatAmount(reward.amount)} ${isTr ? 'para' : 'cash'}',
      ChestRewardType.reputation =>
        '+${_formatAmount(reward.amount)} ${isTr ? 'itibar' : 'reputation'}',
      ChestRewardType.temporaryIncomeBoost =>
        'x${_formatMultiplier(reward.amount)} ${isTr ? 'gelir, ${reward.durationSeconds ?? 0} sn' : 'income for ${reward.durationSeconds ?? 0}s'}',
      ChestRewardType.cosmeticToken =>
        '${isTr ? 'Kozmetik jeton' : 'Cosmetic token'} x${_formatAmount(reward.amount)}',
      ChestRewardType.recipeShard =>
        '${_collection2ItemName(reward.itemId) ?? (isTr ? 'Müşteri kartı' : 'Customer card')} x${_formatAmount(reward.amount)}',
      ChestRewardType.staffCardShard =>
        '${_collection2ItemName(reward.itemId) ?? (isTr ? 'Usta kartı' : 'Master card')} x${_formatAmount(reward.amount)}',
      ChestRewardType.decorShard =>
        '${_collection2ItemName(reward.itemId) ?? 'Decor shard'} x${_formatAmount(reward.amount)}',
      ChestRewardType.knifeSkinShard =>
        '${_collection2ItemName(reward.itemId) ?? (isTr ? 'Özel an kartı' : 'Moment card')} x${_formatAmount(reward.amount)}',
      ChestRewardType.prestigeShard =>
        '${isTr ? 'Prestij parçası' : 'Prestige shard'} x${_formatAmount(reward.amount)}',
      ChestRewardType.permanentTapBonus =>
        '${isTr ? 'Dokunma geliri' : 'Tap income'} +${(reward.amount * 100).round()}%',
      ChestRewardType.permanentPassiveBonus =>
        '${isTr ? 'Pasif gelir' : 'Passive income'} +${(reward.amount * 100).round()}%',
      ChestRewardType.permanentGlobalBonus =>
        '${isTr ? 'Genel gelir' : 'Global income'} +${(reward.amount * 100).round()}%',
    };
  }

  String _customerOrderRewardLabel(List<OrderReward> rewards) {
    if (rewards.isEmpty) {
      return _state.localeCode == 'tr' ? 'Ödül yok' : 'No reward';
    }
    return rewards.map(_customerOrderSingleRewardLabel).join(' + ');
  }

  String _customerOrderSingleRewardLabel(OrderReward reward) {
    final isTr = _state.localeCode == 'tr';
    return switch (reward.type) {
      OrderRewardType.money =>
        '+${_formatAmount(reward.amount)} ${isTr ? 'para' : 'cash'}',
      OrderRewardType.tip =>
        '+${_formatAmount(reward.amount)} ${isTr ? 'bahşiş' : 'tip'}',
      OrderRewardType.reputation =>
        '+${_formatAmount(reward.amount)} ${isTr ? 'Un' : 'Rep'}',
      OrderRewardType.chest =>
        '${_chestTypeLabel(reward.chestType ?? ChestType.small)} ${isTr ? 'sandık' : 'chest'}',
      OrderRewardType.temporaryBoost =>
        '${reward.durationSeconds ?? 30}s x${_formatMultiplier(reward.amount)} ${isTr ? 'boost' : 'boost'}',
      OrderRewardType.recipeShard => _collectionRewardLabel(
        reward.itemId,
        reward.amount,
        isTr ? 'Müşteri kartı' : 'Customer card',
      ),
      OrderRewardType.staffCardShard => _collectionRewardLabel(
        reward.itemId,
        reward.amount,
        isTr ? 'Usta kartı' : 'Master card',
      ),
      OrderRewardType.decorShard => _collectionRewardLabel(
        reward.itemId,
        reward.amount,
        isTr ? 'Dekor parçası' : 'Decor shard',
      ),
      OrderRewardType.knifeSkinShard => _collectionRewardLabel(
        reward.itemId,
        reward.amount,
        isTr ? 'Özel an kartı' : 'Moment card',
      ),
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

  TapOutcome _applyTapOutcome(DateTime nowUtc) {
    _refreshActivePlayState(nowUtc);

    final comboUnlocked = _state.milestones.hasFeature('combo');
    final previousStats = _state.stats;
    final nextTapCount = previousStats.tapCount + 1;
    var nextCombo = 0;
    var nextMaxCombo = _engine.activeComboForCount(
      previousStats.maxCombo,
      _state,
    );
    if (comboUnlocked) {
      final lastTapAt = previousStats.lastTapAtUtc;
      final keepsCombo =
          previousStats.currentCombo > 0 &&
          lastTapAt != null &&
          nowUtc.difference(lastTapAt) <= _engine.comboExpireDuration(_state);
      nextCombo = keepsCombo ? previousStats.currentCombo + 1 : 1;
      nextMaxCombo = math.max(
        nextMaxCombo,
        _engine.activeComboForCount(nextCombo, _state),
      );
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
    final activeCombo = _engine.activeComboForCount(nextCombo, _state);
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

    return TapOutcome(
      coins: tapCoins,
      combo: activeCombo,
      comboMultiplier: comboMultiplier,
      isCritical: isCritical,
      criticalMultiplier: criticalMultiplier,
    );
  }

  GameHudSnapshot _computeHudSnapshot({required DateTime nowUtc}) {
    return GameHudSnapshot(
      cash: _state.cash,
      passiveIncomePerSecond: CurrencyMath.clampDouble(
        _engine.passiveIncomePerSecond(_state, nowUtc: nowUtc),
      ),
      reputation: _state.prestige.totalPrestigePoints,
      tapValue: _engine.tapValue(_state, nowUtc: nowUtc),
    );
  }

  RandomEventSnapshot? _computeRandomEventSnapshot({required DateTime nowUtc}) {
    final activeEventId = _state.randomEvents.activeEventId;
    final event = RandomEventCatalog.byId[activeEventId];
    if (event == null) {
      return null;
    }
    final modifierCount = _state.randomEvents.activeModifiers
        .where((modifier) => modifier.isActiveAt(nowUtc))
        .length;
    return RandomEventSnapshot(
      event: event,
      remainingModifierCount: modifierCount,
    );
  }

  ActivePlaySnapshot _computeActivePlaySnapshot({required DateTime nowUtc}) {
    final comboUnlocked = _state.milestones.hasFeature('combo');
    final criticalUnlocked = _state.milestones.hasFeature('critical_cut');
    final activeCombo = _engine.activeComboForCount(
      _state.stats.currentCombo,
      _state,
    );
    final comboRemaining =
        comboUnlocked && activeCombo > 0 && _state.stats.lastTapAtUtc != null
        ? _displayDuration(
            _engine.comboExpireDuration(_state) -
                nowUtc.difference(_state.stats.lastTapAtUtc!),
          )
        : Duration.zero;
    return ActivePlaySnapshot(
      comboUnlocked: comboUnlocked,
      currentCombo: comboUnlocked ? activeCombo : 0,
      maxCombo: _engine.activeComboForCount(_state.stats.maxCombo, _state),
      comboMultiplier: _engine.comboMultiplierForCount(
        _state.stats.currentCombo,
        _state,
      ),
      comboRemaining: comboRemaining,
      criticalUnlocked: criticalUnlocked,
      criticalChance: _engine.criticalChance(_state),
      criticalMultiplier: _engine.criticalMultiplier(_state),
      temporaryIncomeBoostActive: _state.passiveBoost.isActiveAt(nowUtc),
      temporaryIncomeBoostRemaining: _displayDuration(
        _state.passiveBoost.remainingActive(nowUtc),
      ),
      activeEffects: _computeActiveEffectSnapshots(nowUtc),
    );
  }

  List<ActiveEffectSnapshot> _computeActiveEffectSnapshots(DateTime nowUtc) {
    final isTr = _state.localeCode == 'tr';
    final effects = <ActiveEffectSnapshot>[];
    if (_state.passiveBoost.isActiveAt(nowUtc)) {
      effects.add(
        ActiveEffectSnapshot(
          id: 'passive_boost',
          label: isTr ? 'x2 Gelir' : 'x2 Income',
          remaining: _displayDuration(
            _state.passiveBoost.remainingActive(nowUtc),
          ),
          isPositive: true,
        ),
      );
    }

    for (final modifier in _state.randomEvents.activeModifiers) {
      if (!modifier.isActiveAt(nowUtc)) {
        continue;
      }
      effects.add(
        ActiveEffectSnapshot(
          id: modifier.id,
          label: _randomEventModifierLabel(modifier, isTr: isTr),
          remaining: _displayDuration(modifier.expiresAtUtc.difference(nowUtc)),
          isPositive: _isPositiveRandomEventModifier(modifier),
        ),
      );
    }

    return List<ActiveEffectSnapshot>.unmodifiable(effects);
  }

  String _randomEventModifierLabel(
    TimedModifierState modifier, {
    required bool isTr,
  }) {
    final value = modifier.value;
    final percent = ((value - 1).abs() * 100).round();
    final sign = value >= 1 ? '+' : '-';
    return switch (modifier.type) {
      RandomEventModifierType.tapIncome =>
        value >= 2 ? 'Tap x${_formatMultiplier(value)}' : 'Tap $sign$percent%',
      RandomEventModifierType.passiveIncome =>
        isTr ? 'Pasif $sign$percent%' : 'Passive $sign$percent%',
      RandomEventModifierType.globalIncome =>
        value >= 2
            ? (isTr
                  ? 'Gelir x${_formatMultiplier(value)}'
                  : 'Income x${_formatMultiplier(value)}')
            : (isTr ? 'Gelir $sign$percent%' : 'Income $sign$percent%'),
      RandomEventModifierType.menuMultiplier =>
        isTr ? 'Menü $sign$percent%' : 'Menu $sign$percent%',
      RandomEventModifierType.upgradeCost =>
        value < 1
            ? (isTr ? 'Upgrade Maliyeti -$percent%' : 'Upgrade Cost -$percent%')
            : (isTr
                  ? 'Upgrade Maliyeti +$percent%'
                  : 'Upgrade Cost +$percent%'),
      RandomEventModifierType.reputationGain =>
        isTr ? 'İtibar $sign$percent%' : 'Reputation $sign$percent%',
    };
  }

  bool _isPositiveRandomEventModifier(TimedModifierState modifier) {
    return switch (modifier.type) {
      RandomEventModifierType.upgradeCost => modifier.value <= 1,
      RandomEventModifierType.tapIncome ||
      RandomEventModifierType.passiveIncome ||
      RandomEventModifierType.globalIncome ||
      RandomEventModifierType.menuMultiplier ||
      RandomEventModifierType.reputationGain => modifier.value >= 1,
    };
  }

  String _formatMultiplier(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  CustomerOrderSnapshot _computeCustomerOrderSnapshot({
    required DateTime nowUtc,
  }) {
    final reputation = _state.customerReputation;
    final customerOrders = _state.customerOrders;
    final activeOrder = customerOrders.activeOrder;
    return CustomerOrderSnapshot(
      reputationLevel: reputation.currentLevel,
      reputationInCurrentLevel: reputation.reputationInCurrentLevel,
      reputationRequiredForNextLevel: reputation.requiredForNextLevel,
      totalReputation: reputation.totalReputation,
      completedOrderCount: customerOrders.completedOrderCount,
      failedOrderCount: customerOrders.failedOrderCount,
      unlockedCustomerTypeCount: customerOrders.unlockedCustomerTypeIds.length,
      nextSpawnRemaining: _displayDuration(
        Duration(
          milliseconds: (customerOrders.spawnRemainingSeconds * 1000).round(),
        ),
      ),
      activeOrder: activeOrder == null
          ? null
          : ActiveCustomerOrderSnapshot(
              id: activeOrder.id,
              customerTypeId: activeOrder.customerTypeId,
              customerName: activeOrder.customerName,
              title: activeOrder.title,
              description: activeOrder.description,
              currentValue: activeOrder.currentValue,
              targetValue: activeOrder.targetValue,
              remaining: _displayDuration(
                Duration(
                  milliseconds: (activeOrder.remainingSeconds * 1000).round(),
                ),
              ),
              rewardLabel: _customerOrderRewardLabel(activeOrder.rewards),
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

  GoalBoardSnapshot _computeGoalSnapshot({required DateTime nowUtc}) {
    List<GoalProgressSnapshot> mapGoals(List<GoalProgress> goals) {
      return goals
          .map((progress) {
            final definition = GoalCatalog.byId[progress.goalId];
            if (definition == null) {
              return null;
            }
            final effectiveStatus =
                progress.isExpiredAt(nowUtc) && !progress.rewardClaimed
                ? GoalStatus.expired
                : progress.status;
            return GoalProgressSnapshot(
              id: progress.goalId,
              title: definition.title,
              description: definition.description,
              category: definition.category,
              currentValue: progress.currentValue,
              targetValue: progress.targetValue,
              status: effectiveStatus,
              rewardClaimed: progress.rewardClaimed,
              rewardLabel: definition.rewards
                  .map(_goalRewardLabel)
                  .join(_state.localeCode == 'tr' ? ' + ' : ' + '),
              expiresAtMillis: progress.expiresAtMillis,
            );
          })
          .whereType<GoalProgressSnapshot>()
          .toList(growable: false);
    }

    return GoalBoardSnapshot(
      dailyGoals: mapGoals(_state.goals.activeDailyGoals),
      weeklyGoals: mapGoals(_state.goals.activeWeeklyGoals),
      prestigeRunGoals: mapGoals(_state.goals.activePrestigeRunGoals),
      eventGoals: mapGoals(_state.goals.activeEventGoals),
    );
  }

  BranchBoardSnapshot _computeBranchSnapshot({required DateTime nowUtc}) {
    final totalContribution = BranchCatalog.totalIncomeContribution(_state);
    final effectiveBranchIncome = _engine.branchIncomePerSecond(
      _state,
      nowUtc: nowUtc,
    );
    final incomeScale = totalContribution <= 0
        ? 0.0
        : effectiveBranchIncome / totalContribution;

    final regions = BranchCatalog.regions
        .map((region) {
          final regionBranches = BranchCatalog.branchesForRegion(region.id);
          final unlockedCount = regionBranches
              .where((branch) => _state.branches.isUnlocked(branch.id))
              .length;
          return BranchRegionSnapshot(
            id: region.id,
            name: BranchCatalog.regionName(
              region.id,
              localeCode: _state.localeCode,
            ),
            unlocked: _state.branches.unlockedRegionIds.contains(region.id),
            completed: BranchCatalog.isRegionComplete(
              _state.branches,
              region.id,
            ),
            unlockedBranchCount: unlockedCount,
            totalBranchCount: regionBranches.length,
            assetKey: region.assetKey,
          );
        })
        .toList(growable: false);

    final branches = BranchCatalog.branches
        .map((definition) {
          final progress = _state.branches.progressFor(definition.id);
          final nextProgress =
              progress.isUnlocked && progress.level < definition.maxLevel
              ? progress.copyWith(level: progress.level + 1)
              : progress;
          final availableManagers = BranchCatalog.availableManagerIds(
            _state,
            forBranchId: definition.id,
          );
          final suggestedManagerId =
              progress.assignedManagerId == null && availableManagers.isNotEmpty
              ? availableManagers.first
              : null;
          final region = BranchCatalog.regionById[definition.regionId];
          return BranchProgressSnapshot(
            id: definition.id,
            name: definition.name,
            cityName: definition.cityName,
            regionId: definition.regionId,
            regionName: BranchCatalog.regionName(
              region?.id ?? definition.regionId,
              localeCode: _state.localeCode,
            ),
            description: definition.description,
            assetKey: definition.assetKey,
            unlocked: progress.isUnlocked,
            level: progress.level,
            maxLevel: definition.maxLevel,
            unlockCost: _effectivePurchaseCost(
              BranchCatalog.unlockCost(definition),
            ),
            levelUpCost: _effectivePurchaseCost(
              BranchCatalog.levelUpCost(definition, progress),
            ),
            canUnlock: BranchCatalog.canUnlock(
              _state,
              definition,
              ignoreCostRequirement: _freePurchasesEnabled,
            ),
            canLevelUp: BranchCatalog.canLevelUp(
              _state,
              definition,
              ignoreCostRequirement: _freePurchasesEnabled,
            ),
            incomePerSecond:
                BranchCatalog.incomeContributionFor(
                  definition,
                  progress,
                  _state.collection2,
                ) *
                incomeScale,
            nextIncomePerSecond:
                BranchCatalog.incomeContributionFor(
                  definition,
                  nextProgress,
                  _state.collection2,
                ) *
                incomeScale,
            requirements:
                BranchCatalog.unlockRequirements(
                      _state,
                      definition,
                      ignoreCostRequirement: _freePurchasesEnabled,
                    )
                    .map(
                      (requirement) => BranchRequirementSnapshot(
                        label: requirement.label,
                        completed: requirement.completed,
                      ),
                    )
                    .toList(growable: false),
            reachedMilestoneCount: BranchCatalog.reachedMilestoneCount(
              progress.level,
            ),
            totalMilestoneCount: BranchCatalog.milestoneLevels.length,
            managerSlotUnlocked: BranchCatalog.isManagerSlotUnlocked(progress),
            canAssignManager:
                suggestedManagerId != null &&
                BranchCatalog.canAssignManager(
                  _state,
                  branchId: definition.id,
                  managerId: suggestedManagerId,
                ),
            assignedManagerId: progress.assignedManagerId,
            assignedManagerName: _collection2ItemName(
              progress.assignedManagerId,
            ),
            suggestedManagerId: suggestedManagerId,
            suggestedManagerName: _collection2ItemName(suggestedManagerId),
          );
        })
        .toList(growable: false);

    return BranchBoardSnapshot(
      systemVisible: BranchCatalog.isBranchSystemVisible(_state),
      incomeActive: BranchCatalog.isBranchIncomeActive(_state),
      branchIncomePerSecond: effectiveBranchIncome,
      totalBranchIncomeEarned: _state.branches.totalBranchIncomeEarned,
      unlockedBranchCount: _state.branches.unlockedBranchCount,
      totalBranchCount: BranchCatalog.branches.length,
      totalBranchLevel: _state.branches.totalBranchLevel,
      regions: regions,
      branches: branches,
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
      final cost = _effectiveUpgradeCost(
        _engine.upgradeCost(upgrade, state),
        nowUtc,
      );
      final itemLevel = upgrade.itemLevelForTotalLevel(totalLevel);
      final currentItem = _engine.currentUpgradeItem(_state, upgrade.id);
      final nextItem = _engine.nextUpgradeItem(_state, upgrade.id);
      final nextMilestone = upgrade.nextMilestoneForLevel(totalLevel);
      final nextMilestoneItem = upgrade.nextMilestoneItemForLevel(totalLevel);
      final remainingLevels = math.max(0, upgrade.maxLevel - totalLevel);
      final tenQuantity = math.min(10, remainingLevels);
      final tenCost = _effectiveUpgradeCost(
        _engine.upgradeCostForQuantity(upgrade, state, tenQuantity),
        nowUtc,
      );
      final tenPreview = _engine.previewUpgradePurchase(
        _state,
        upgrade.id,
        quantity: tenQuantity,
      );
      final maxPreview = _engine.previewMaxUpgradePurchase(_state, upgrade.id);
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
        buyTenCost: tenCost,
        canAffordTen:
            !maxed &&
            tenQuantity > 0 &&
            tenPreview.purchasedCount == tenQuantity,
        maxAffordableQuantity: maxPreview.purchasedCount,
        maxAffordableCost: _effectiveUpgradeCost(maxPreview.cost, nowUtc),
      );
    }

    final strings = AppStrings.forLanguageCode(_state.localeCode);
    final currentShop = ShopProgressionCatalog.byLevel(
      _state.shopProgression.currentShopLevel,
    );
    final nextShop = ShopProgressionCatalog.nextAfter(currentShop.level);
    final progression = ShopProgressionSnapshot(
      currentLevel: currentShop.level,
      currentName: strings.shopLevelName(currentShop.id),
      highestLevel: _state.shopProgression.highestShopLevel,
      incomeMultiplier: currentShop.incomeMultiplier,
      nextLevel: nextShop?.level,
      nextName: nextShop == null ? null : strings.shopLevelName(nextShop.id),
      nextIncomeMultiplier: nextShop?.incomeMultiplier,
      requirements: nextShop == null
          ? const <ShopRequirementSnapshot>[]
          : nextShop.requirements
                .map(
                  (requirement) => ShopRequirementSnapshot(
                    label: _shopRequirementLabel(requirement, strings),
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

  String _shopRequirementLabel(
    ShopLevelRequirement requirement,
    AppStrings strings,
  ) {
    return switch (requirement.type) {
      ShopLevelRequirementType.runCashEarned => strings.shopRunCashRequirement(
        requirement.target,
      ),
      ShopLevelRequirementType.upgradeTotalLevel =>
        strings.shopUpgradeCountRequirement(
          strings.upgradeName(requirement.upgradeId!),
          requirement.target,
        ),
      ShopLevelRequirementType.upgradeItemUnlocked =>
        strings.shopUpgradeItemRequirement(
          strings.upgradeName(requirement.upgradeId!),
          strings.upgradeItemName(requirement.upgradeId!, requirement.itemKey!),
        ),
      ShopLevelRequirementType.prestigeCount => strings.shopPrestigeRequirement(
        requirement.target,
      ),
    };
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
            final cost = _effectivePurchaseCost(upgrade.costForLevel(level));
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
              currentEffectLabel: upgrade.effectLabel(
                level,
                localeCode: _state.localeCode,
              ),
              nextEffectLabel: upgrade.effectLabel(
                level + 1,
                localeCode: _state.localeCode,
              ),
            );
          })
          .toList(growable: false),
      resetItems: const [
        'Current money, all upgrade progress, current shop level, temporary boosts, and combo state',
        'Current run quest progress',
        'Active customer order and customer spawn timer',
        'Branch income activation until this run reaches Shop Lv. 7 again',
      ],
      keptItems: const [
        'Total prestige points and unspent prestige points',
        'Prestige shop upgrades',
        'Highest shop level reached',
        'Branch unlocks, branch levels, branch milestones, region unlocks, managers, and total branch income earned',
        'Achievements, customer cards, master cards, decor cards, moment cards, and set bonuses',
        'Customer reputation level, unlocked customer types, and lifetime customer order stats',
        'Prestige multiplier',
        'Total lifetime stats',
        'IAP purchases',
        'Ad removal status',
        'Permanent premium boosts',
      ],
    );
  }

  int _effectivePurchaseCost(int rawCost) {
    return _freePurchasesEnabled ? 0 : rawCost;
  }

  num _effectiveUpgradeCost(num rawCost, DateTime nowUtc) {
    if (_freePurchasesEnabled) {
      return 0;
    }
    final multiplier = randomEventModifierProduct(
      _state.randomEvents,
      RandomEventModifierType.upgradeCost,
      nowUtc: nowUtc,
    );
    return math.max(0, CurrencyMath.roundDouble(rawCost * multiplier));
  }

  ProgressionSnapshot _computeProgressionSnapshot() {
    final strings = AppStrings.forLanguageCode(_state.localeCode);
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
    final collection2 = _state.collection2;
    final customerCollections = Collection2Catalog.customerCards
        .map(
          (item) => Collection2ItemSnapshot(
            id: item.id,
            kind: Collection2ItemKind.customer,
            name: strings.collection2ItemName(item.id, fallback: item.name),
            rarity: item.rarity,
            currentShards: collection2.customerCardCount(item.id),
            requiredShards: item.requiredShards,
            level: collection2.customerCardLevel(item.id),
            maxLevel: item.maxLevel,
            unlocked: collection2.isCustomerCardUnlocked(item.id),
            equipped: false,
            bonusLabel: _customerBonusLabel(
              item,
              collection2.customerCardLevel(item.id),
            ),
            assetKey: item.assetKey,
          ),
        )
        .toList(growable: false);
    final masterCollections = Collection2Catalog.masterCards
        .map(
          (item) => Collection2ItemSnapshot(
            id: item.id,
            kind: Collection2ItemKind.master,
            name: strings.collection2ItemName(item.id, fallback: item.name),
            rarity: item.rarity,
            currentShards: collection2.masterCardCount(item.id),
            requiredShards: item.requiredCards,
            level: collection2.masterCardLevel(item.id),
            maxLevel: item.maxLevel,
            unlocked: collection2.isMasterCardUnlocked(item.id),
            equipped: false,
            bonusLabel: _staffBonusLabel(
              item,
              collection2.masterCardLevel(item.id),
            ),
            assetKey: item.assetKey,
          ),
        )
        .toList(growable: false);
    final decorCollections = Collection2Catalog.decorItems
        .map(
          (item) => Collection2ItemSnapshot(
            id: item.id,
            kind: Collection2ItemKind.decor,
            name: strings.collection2ItemName(item.id, fallback: item.name),
            rarity: item.rarity,
            currentShards: collection2.decorShardCount(item.id),
            requiredShards: item.requiredShards,
            level: collection2.isDecorUnlocked(item.id) ? 1 : 0,
            maxLevel: 1,
            unlocked: collection2.isDecorUnlocked(item.id),
            equipped: collection2.equippedDecorIds.contains(item.id),
            bonusLabel: _decorBonusLabel(item),
            assetKey: item.assetKey,
          ),
        )
        .toList(growable: false);
    final momentCollections = Collection2Catalog.momentCards
        .map(
          (item) => Collection2ItemSnapshot(
            id: item.id,
            kind: Collection2ItemKind.moment,
            name: strings.collection2ItemName(item.id, fallback: item.name),
            rarity: item.rarity,
            currentShards: collection2.momentCardCount(item.id),
            requiredShards: item.requiredShards,
            level: collection2.isMomentCardUnlocked(item.id) ? 1 : 0,
            maxLevel: 1,
            unlocked: collection2.isMomentCardUnlocked(item.id),
            equipped: false,
            bonusLabel: _momentBonusLabel(item),
            assetKey: item.assetKey,
          ),
        )
        .toList(growable: false);
    final collectionSets = Collection2Catalog.setBonuses
        .map(
          (set) => CollectionSetSnapshot(
            id: set.id,
            name: strings.collection2ItemName(set.id, fallback: set.name),
            completed: Collection2Catalog.isSetComplete(collection2, set),
            claimed: collection2.claimedSetBonuses.contains(set.id),
            bonusLabel: _setBonusLabel(set),
            requirementLabel: _setRequirementLabel(set),
          ),
        )
        .toList(growable: false);

    return ProgressionSnapshot(
      achievements: achievements,
      collections: collectionItems,
      customerCollections: customerCollections,
      masterCollections: masterCollections,
      decorCollections: decorCollections,
      momentCollections: momentCollections,
      collectionSets: collectionSets,
      chests: ChestInventorySnapshot(
        counts: Map<ChestType, int>.unmodifiable({
          for (final type in ChestType.values) type: _debugChestCount(type),
        }),
      ),
      latestClaimableAchievement: latestClaimableAchievement,
      lastChestReward: _lastChestRewardSnapshot,
    );
  }

  int _debugChestCount(ChestType type) {
    if (_debugUnlimitedChestsEnabled) {
      return math.max(99, _state.chestInventory.count(type));
    }
    return _state.chestInventory.count(type);
  }

  String _achievementRewardLabel(AchievementReward reward) {
    final isTr = _state.localeCode == 'tr';
    return switch (reward.type) {
      AchievementRewardType.cash =>
        '+${_formatAmount(reward.amount)} ${isTr ? 'para' : 'cash'}',
      AchievementRewardType.chest =>
        '${_chestTypeLabel(reward.chestType ?? ChestType.small)} chest',
      AchievementRewardType.permanentTapBonus =>
        'Tap +${(reward.amount * 100).round()}%',
      AchievementRewardType.permanentPassiveBonus =>
        'Passive +${(reward.amount * 100).round()}%',
      AchievementRewardType.permanentGlobalBonus =>
        'Global +${(reward.amount * 100).round()}%',
      AchievementRewardType.cosmeticToken =>
        'Token x${_formatAmount(reward.amount)}',
    };
  }

  String _goalRewardLabel(GoalReward reward) {
    final isTr = _state.localeCode == 'tr';
    return switch (reward.type) {
      GoalRewardType.money =>
        '+${_formatAmount(reward.amount)} ${isTr ? 'para' : 'cash'}',
      GoalRewardType.reputation =>
        '+${_formatAmount(reward.amount)} ${isTr ? 'un' : 'rep'}',
      GoalRewardType.chest =>
        '${_chestTypeLabel(reward.chestType ?? ChestType.small)} ${isTr ? 'sandık' : 'chest'}',
      GoalRewardType.temporaryBoost =>
        '${reward.durationSeconds ?? 30}s x${_formatMultiplier(reward.amount)} boost',
      GoalRewardType.recipeShard => _collectionRewardLabel(
        reward.itemId,
        reward.amount,
        isTr ? 'Müşteri kartı' : 'Customer card',
      ),
      GoalRewardType.staffCardShard => _collectionRewardLabel(
        reward.itemId,
        reward.amount,
        isTr ? 'Usta kartı' : 'Master card',
      ),
      GoalRewardType.decorShard => _collectionRewardLabel(
        reward.itemId,
        reward.amount,
        isTr ? 'Dekor parçası' : 'Decor shard',
      ),
      GoalRewardType.knifeSkinShard => _collectionRewardLabel(
        reward.itemId,
        reward.amount,
        isTr ? 'Özel an kartı' : 'Moment card',
      ),
      GoalRewardType.prestigePoint =>
        '+${_formatAmount(reward.amount)} ${isTr ? 'prestij puani' : 'prestige point'}',
      GoalRewardType.prestigeShard =>
        isTr ? 'Prestij parçası' : 'Prestige shard',
    };
  }

  String _collectionRewardLabel(
    String? itemId,
    double amount,
    String fallback,
  ) {
    final name = _collection2ItemName(itemId) ?? fallback;
    final quantity = amount.round();
    return quantity > 0 ? '$name x${_formatAmount(quantity)}' : name;
  }

  String? _collection2ItemName(String? itemId) {
    if (itemId == null || itemId.isEmpty) {
      return null;
    }
    final fallback =
        Collection2Catalog.customerCardById[itemId]?.name ??
        Collection2Catalog.masterCardById[itemId]?.name ??
        Collection2Catalog.decorById[itemId]?.name ??
        Collection2Catalog.momentCardById[itemId]?.name;
    if (fallback == null) {
      return null;
    }
    return AppStrings.forLanguageCode(
      _state.localeCode,
    ).collection2ItemName(itemId, fallback: fallback);
  }

  String _customerBonusLabel(CustomerCard item, int level) {
    return _leveledBonusLabel(
      value: item.bonusValuePerLevel,
      level: level,
      target: switch (item.bonusType) {
        CustomerCardBonusType.menuMultiplier => 'menu',
        CustomerCardBonusType.tipValue => 'tip',
        CustomerCardBonusType.customerReward => 'customer',
        CustomerCardBonusType.globalIncome => 'global',
      },
    );
  }

  String _staffBonusLabel(MasterCard item, int level) {
    return _leveledBonusLabel(
      value: item.bonusValuePerLevel,
      level: level,
      target: switch (item.bonusType) {
        StaffCardBonusType.passiveIncome => 'passive',
        StaffCardBonusType.tipChance => 'tip chance',
        StaffCardBonusType.customerOrderDuration => 'order time',
        StaffCardBonusType.customerReward => 'customer',
        StaffCardBonusType.offlineIncome => 'offline',
        StaffCardBonusType.autoTapPower => 'tap',
        StaffCardBonusType.reputationGain => 'reputation',
      },
    );
  }

  String _decorBonusLabel(DecorItem item) {
    return _flatBonusLabel(item.bonusValue, switch (item.bonusType) {
      DecorBonusType.globalIncome => 'global',
      DecorBonusType.customerSpawnSpeed => 'spawn',
      DecorBonusType.tipValue => 'tip',
      DecorBonusType.reputationGain => 'reputation',
      DecorBonusType.chestReward => 'chest',
      DecorBonusType.shopMultiplier => 'shop',
    });
  }

  String _momentBonusLabel(MomentCard item) {
    return _flatBonusLabel(item.bonusValue, switch (item.bonusType) {
      MomentCardBonusType.tapIncome => 'tap',
      MomentCardBonusType.globalIncome => 'global',
      MomentCardBonusType.reputationGain => 'reputation',
    });
  }

  String _setBonusLabel(CollectionSetBonus set) {
    return _flatBonusLabel(set.bonusValue, switch (set.bonusType) {
      CollectionSetBonusType.tapIncome => 'tap',
      CollectionSetBonusType.passiveIncome => 'passive',
      CollectionSetBonusType.globalIncome => 'global',
    });
  }

  String _setRequirementLabel(CollectionSetBonus set) {
    final customer = _collection2ItemName(set.customerCardId);
    final master = _collection2ItemName(set.masterCardId);
    final decor = _collection2ItemName(set.decorId);
    final moment = _collection2ItemName(set.momentCardId);
    return [moment, master, customer, decor].whereType<String>().join(' + ');
  }

  String _leveledBonusLabel({
    required double value,
    required int level,
    required String target,
  }) {
    final current = value * math.max(1, level);
    return '${_flatBonusLabel(current, target)} / level';
  }

  String _flatBonusLabel(double value, String target) {
    return '+${(value * 100).toStringAsFixed(value < 0.01 ? 1 : 0)}% $target';
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
      ChestType.recipe => 'Customer',
      ChestType.staff => 'Chef',
      ChestType.decor => 'Decor',
      ChestType.prestige => 'Prestige',
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
