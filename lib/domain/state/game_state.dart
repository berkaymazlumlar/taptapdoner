import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/stations/station_catalog.dart';
import 'package:taptapdoner/domain/stations/upgrade_catalog.dart';

class StationState {
  const StationState({required this.id, required this.level});

  final StationId id;
  final int level;

  StationState copyWith({int? level}) {
    return StationState(id: id, level: level ?? this.level);
  }

  Map<String, dynamic> toJson() {
    return {'id': id.key, 'level': level};
  }

  factory StationState.fromJson(Map<String, dynamic> json) {
    final id = stationIdFromKey(json['id'] as String? ?? '');
    if (id == null) {
      throw const FormatException('Unknown station id');
    }
    return StationState(id: id, level: (json['level'] as num? ?? 0).toInt());
  }
}

class UpgradeState {
  const UpgradeState({required this.id, required this.purchased});

  final UpgradeId id;
  final bool purchased;

  UpgradeState copyWith({bool? purchased}) {
    return UpgradeState(id: id, purchased: purchased ?? this.purchased);
  }

  Map<String, dynamic> toJson() {
    return {'id': id.key, 'purchased': purchased};
  }

  factory UpgradeState.fromJson(Map<String, dynamic> json) {
    final id = upgradeIdFromKey(json['id'] as String? ?? '');
    if (id == null) {
      throw const FormatException('Unknown upgrade id');
    }
    return UpgradeState(id: id, purchased: json['purchased'] as bool? ?? false);
  }
}

class PrestigeState {
  const PrestigeState({required this.reputation, required this.runCashEarned});

  final int reputation;
  final int runCashEarned;

  PrestigeState copyWith({int? reputation, int? runCashEarned}) {
    return PrestigeState(
      reputation: reputation ?? this.reputation,
      runCashEarned: runCashEarned ?? this.runCashEarned,
    );
  }

  Map<String, dynamic> toJson() {
    return {'reputation': reputation, 'runCashEarned': runCashEarned};
  }

  factory PrestigeState.fromJson(Map<String, dynamic>? json) {
    return PrestigeState(
      reputation: (json?['reputation'] as num? ?? 0).toInt(),
      runCashEarned: (json?['runCashEarned'] as num? ?? 0).toInt(),
    );
  }
}

class TimedEffectState {
  const TimedEffectState({this.endsAtUtc, this.cooldownEndsAtUtc});

  final DateTime? endsAtUtc;
  final DateTime? cooldownEndsAtUtc;

  TimedEffectState copyWith({
    DateTime? endsAtUtc,
    DateTime? cooldownEndsAtUtc,
    bool clearEndsAtUtc = false,
    bool clearCooldownEndsAtUtc = false,
  }) {
    return TimedEffectState(
      endsAtUtc: clearEndsAtUtc ? null : (endsAtUtc ?? this.endsAtUtc),
      cooldownEndsAtUtc: clearCooldownEndsAtUtc
          ? null
          : (cooldownEndsAtUtc ?? this.cooldownEndsAtUtc),
    );
  }

  bool isActiveAt(DateTime nowUtc) {
    return endsAtUtc?.isAfter(nowUtc) ?? false;
  }

  bool isCoolingDownAt(DateTime nowUtc) {
    return cooldownEndsAtUtc?.isAfter(nowUtc) ?? false;
  }

  Duration remainingActive(DateTime nowUtc) {
    if (!isActiveAt(nowUtc)) {
      return Duration.zero;
    }
    return endsAtUtc!.difference(nowUtc);
  }

  Duration remainingCooldown(DateTime nowUtc) {
    if (!isCoolingDownAt(nowUtc)) {
      return Duration.zero;
    }
    return cooldownEndsAtUtc!.difference(nowUtc);
  }

  Map<String, dynamic> toJson() {
    return {
      'endsAtUtc': endsAtUtc?.toIso8601String(),
      'cooldownEndsAtUtc': cooldownEndsAtUtc?.toIso8601String(),
    };
  }

  factory TimedEffectState.fromJson(Map<String, dynamic>? json) {
    return TimedEffectState(
      endsAtUtc: json?['endsAtUtc'] == null
          ? null
          : DateTime.tryParse(json!['endsAtUtc'] as String)?.toUtc(),
      cooldownEndsAtUtc: json?['cooldownEndsAtUtc'] == null
          ? null
          : DateTime.tryParse(json!['cooldownEndsAtUtc'] as String)?.toUtc(),
    );
  }
}

class GameState {
  const GameState({
    required this.schemaVersion,
    required this.cash,
    required this.lifetimeCash,
    required this.pendingOfflineCash,
    required this.stations,
    required this.upgrades,
    required this.prestige,
    required this.rush,
    required this.lastActiveAtUtc,
    required this.lastSavedAtUtc,
    required this.localeCode,
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final int cash;
  final int lifetimeCash;
  final int pendingOfflineCash;
  final Map<StationId, StationState> stations;
  final Map<UpgradeId, UpgradeState> upgrades;
  final PrestigeState prestige;
  final TimedEffectState rush;
  final DateTime lastActiveAtUtc;
  final DateTime lastSavedAtUtc;
  final String localeCode;

  factory GameState.initial(
    EconomyConfig config, {
    DateTime? nowUtc,
    String localeCode = 'en',
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    return GameState(
      schemaVersion: currentSchemaVersion,
      cash: 0,
      lifetimeCash: 0,
      pendingOfflineCash: 0,
      stations: {
        for (final definition in config.stations)
          definition.id: StationState(id: definition.id, level: 0),
      },
      upgrades: {
        for (final definition in config.upgrades)
          definition.id: UpgradeState(id: definition.id, purchased: false),
      },
      prestige: const PrestigeState(reputation: 0, runCashEarned: 0),
      rush: const TimedEffectState(),
      lastActiveAtUtc: now,
      lastSavedAtUtc: now,
      localeCode: localeCode,
    );
  }

  StationState station(StationId id) => stations[id]!;

  UpgradeState upgrade(UpgradeId id) => upgrades[id]!;

  GameState copyWith({
    int? schemaVersion,
    int? cash,
    int? lifetimeCash,
    int? pendingOfflineCash,
    Map<StationId, StationState>? stations,
    Map<UpgradeId, UpgradeState>? upgrades,
    PrestigeState? prestige,
    TimedEffectState? rush,
    DateTime? lastActiveAtUtc,
    DateTime? lastSavedAtUtc,
    String? localeCode,
  }) {
    return GameState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      cash: cash ?? this.cash,
      lifetimeCash: lifetimeCash ?? this.lifetimeCash,
      pendingOfflineCash: pendingOfflineCash ?? this.pendingOfflineCash,
      stations: stations ?? this.stations,
      upgrades: upgrades ?? this.upgrades,
      prestige: prestige ?? this.prestige,
      rush: rush ?? this.rush,
      lastActiveAtUtc: lastActiveAtUtc ?? this.lastActiveAtUtc,
      lastSavedAtUtc: lastSavedAtUtc ?? this.lastSavedAtUtc,
      localeCode: localeCode ?? this.localeCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'cash': cash,
      'lifetimeCash': lifetimeCash,
      'pendingOfflineCash': pendingOfflineCash,
      'stations': stations.values.map((value) => value.toJson()).toList(),
      'upgrades': upgrades.values.map((value) => value.toJson()).toList(),
      'prestige': prestige.toJson(),
      'rush': rush.toJson(),
      'lastActiveAtUtc': lastActiveAtUtc.toIso8601String(),
      'lastSavedAtUtc': lastSavedAtUtc.toIso8601String(),
      'localeCode': localeCode,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json, EconomyConfig config) {
    final fallback = GameState.initial(
      config,
      localeCode: json['localeCode'] as String? ?? 'en',
    );
    final schemaVersion =
        (json['schemaVersion'] as num? ?? currentSchemaVersion).toInt();
    if (schemaVersion > currentSchemaVersion) {
      return fallback;
    }

    final parsedStations = <StationId, StationState>{};
    final stationList = json['stations'];
    if (stationList is List) {
      for (final entry in stationList.whereType<Map<dynamic, dynamic>>()) {
        final map = entry.map((key, value) => MapEntry(key.toString(), value));
        try {
          final state = StationState.fromJson(map);
          parsedStations[state.id] = state;
        } on FormatException {
          continue;
        }
      }
    }

    final parsedUpgrades = <UpgradeId, UpgradeState>{};
    final upgradeList = json['upgrades'];
    if (upgradeList is List) {
      for (final entry in upgradeList.whereType<Map<dynamic, dynamic>>()) {
        final map = entry.map((key, value) => MapEntry(key.toString(), value));
        try {
          final state = UpgradeState.fromJson(map);
          parsedUpgrades[state.id] = state;
        } on FormatException {
          continue;
        }
      }
    }

    return GameState(
      schemaVersion: schemaVersion,
      cash: (json['cash'] as num? ?? 0).toInt(),
      lifetimeCash: (json['lifetimeCash'] as num? ?? 0).toInt(),
      pendingOfflineCash: (json['pendingOfflineCash'] as num? ?? 0).toInt(),
      stations: {
        for (final definition in config.stations)
          definition.id:
              parsedStations[definition.id] ??
              StationState(id: definition.id, level: 0),
      },
      upgrades: {
        for (final definition in config.upgrades)
          definition.id:
              parsedUpgrades[definition.id] ??
              UpgradeState(id: definition.id, purchased: false),
      },
      prestige: PrestigeState.fromJson(
        json['prestige'] as Map<String, dynamic>?,
      ),
      rush: TimedEffectState.fromJson(json['rush'] as Map<String, dynamic>?),
      lastActiveAtUtc:
          DateTime.tryParse(
            json['lastActiveAtUtc'] as String? ?? '',
          )?.toUtc() ??
          fallback.lastActiveAtUtc,
      lastSavedAtUtc:
          DateTime.tryParse(json['lastSavedAtUtc'] as String? ?? '')?.toUtc() ??
          fallback.lastSavedAtUtc,
      localeCode: json['localeCode'] as String? ?? fallback.localeCode,
    );
  }
}
