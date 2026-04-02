import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/economy/economy_engine.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/domain/stations/station_catalog.dart';
import 'package:taptapdoner/domain/stations/upgrade_catalog.dart';
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
    _backgroundCalculator = BackgroundProductionCalculator(
      config: this.config,
      engine: _engine,
    );
    _state = GameState.initial(this.config, nowUtc: _clock());
  }

  static DateTime _defaultClock() => DateTime.now().toUtc();

  final EconomyConfig config;
  final SaveRepository _saveRepository;
  final RewardedAdService _adService;
  final Clock _clock;

  late final EconomyEngine _engine;
  late final BackgroundProductionCalculator _backgroundCalculator;
  late GameState _state;
  Future<void> _saveQueue = Future<void>.value();

  bool _isInitialized = false;
  double _passiveCarry = 0;
  double _notifyAccumulator = 0;

  GameState get state => _state;
  bool get isInitialized => _isInitialized;
  bool get isRushActive => _state.rush.isActiveAt(_clock());
  bool get canStartRush => _engine.canStartRush(_state, nowUtc: _clock());
  bool get hasPendingOfflineReward => _state.pendingOfflineCash > 0;
  bool get canDoubleOfflineReward => _adService.isAvailable;
  int get tapValue => _engine.tapValue(_state, nowUtc: _clock());
  double get passiveIncomePerSecond =>
      _engine.passiveIncomePerSecond(_state, nowUtc: _clock());
  int get availablePrestigePoints => _engine.availablePrestigePoints(_state);
  Duration get rushRemaining => _state.rush.remainingActive(_clock());
  Duration get rushCooldownRemaining => _state.rush.remainingCooldown(_clock());
  List<StationDefinition> get stations => config.stations;
  List<UpgradeDefinition> get upgrades => config.upgrades;

  Future<void> initialize({required String fallbackLocaleCode}) async {
    final localeCode = _normalizeLocale(fallbackLocaleCode);
    final restored = await _saveRepository.load(config);
    final nowUtc = _clock();
    if (restored == null) {
      _state = GameState.initial(
        config,
        nowUtc: nowUtc,
        localeCode: localeCode,
      );
      _isInitialized = true;
      await _queueSave();
      notifyListeners();
      return;
    }

    final grant = _backgroundCalculator.calculate(
      state: restored,
      nowUtc: nowUtc,
    );
    _state = _engine.queueOfflineReward(restored, grant.coins, nowUtc: nowUtc);
    _isInitialized = true;
    await _queueSave();
    notifyListeners();
  }

  void tick(Duration elapsed) {
    if (!_isInitialized || elapsed <= Duration.zero) {
      return;
    }
    final nowUtc = _clock();
    final earned = passiveIncomePerSecond * elapsed.inMilliseconds / 1000;
    _passiveCarry += earned;
    _notifyAccumulator += elapsed.inMilliseconds / 1000;

    final wholeCoins = _passiveCarry.floor();
    if (wholeCoins > 0) {
      _passiveCarry -= wholeCoins;
      _state = _engine.addCoins(_state, wholeCoins);
    }

    if (wholeCoins > 0 || _notifyAccumulator >= 0.2) {
      _notifyAccumulator = 0;
      notifyListeners();
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
    }
  }

  Future<void> tap() async {
    _state = _engine.applyTap(_state, nowUtc: _clock());
    notifyListeners();
  }

  Future<bool> buyStation(StationId id) async {
    final result = _engine.buyStationLevel(_state, id);
    if (!result.success) {
      return false;
    }
    _state = result.state;
    notifyListeners();
    unawaited(_queueSave());
    return true;
  }

  Future<bool> buyUpgrade(UpgradeId id) async {
    final result = _engine.buyUpgrade(_state, id);
    if (!result.success) {
      return false;
    }
    _state = result.state;
    notifyListeners();
    unawaited(_queueSave());
    return true;
  }

  Future<bool> startRush() async {
    if (!canStartRush) {
      return false;
    }
    _state = _engine.startRush(_state, nowUtc: _clock());
    notifyListeners();
    unawaited(_queueSave());
    return true;
  }

  Future<bool> applyPrestige() async {
    if (availablePrestigePoints <= 0) {
      return false;
    }
    _state = _engine.applyPrestige(_state, nowUtc: _clock());
    notifyListeners();
    await _queueSave();
    return true;
  }

  Future<void> setLocaleCode(String localeCode) async {
    _state = _state.copyWith(
      localeCode: _normalizeLocale(localeCode),
      lastSavedAtUtc: _clock(),
    );
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
    _state = _engine.queueOfflineReward(_state, grant.coins, nowUtc: nowUtc);
    await _queueSave();
    notifyListeners();
  }

  Future<void> claimOfflineReward({int multiplier = 1}) async {
    final nowUtc = _clock();
    final reward = _state.pendingOfflineCash * multiplier;
    _state = _engine.applyOfflineReward(_state, reward, nowUtc: nowUtc);
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
    notifyListeners();
    await _queueSave();
  }

  int stationCost(StationId id) {
    final definition = config.station(id);
    return _engine.stationCost(definition, _state.station(id));
  }

  bool isStationUnlocked(StationId id) {
    return _engine.isStationUnlocked(_state, config.station(id));
  }

  double stationIncomePerSecond(StationId id) {
    return _engine.stationIncomePerSecond(_state, id, nowUtc: _clock());
  }

  void hydrate(GameState nextState) {
    _state = nextState;
    _isInitialized = true;
    notifyListeners();
  }

  String _normalizeLocale(String localeCode) {
    return localeCode == 'tr' ? 'tr' : 'en';
  }

  Future<void> _queueSave() {
    final snapshot = _state.copyWith(lastSavedAtUtc: _clock());
    _state = snapshot;
    _saveQueue = _saveQueue.catchError((_) {}).then((_) {
      return _saveRepository.save(snapshot);
    });
    return _saveQueue;
  }
}
