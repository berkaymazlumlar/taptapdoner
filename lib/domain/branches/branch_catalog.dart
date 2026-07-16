import 'dart:math' as math;

import 'package:taptapdoner/domain/branches/branch_models.dart';
import 'package:taptapdoner/domain/economy/number_units.dart';
import 'package:taptapdoner/domain/progression/collection2_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/state/game_state.dart';

class BranchRequirementStatus {
  const BranchRequirementStatus({required this.label, required this.completed});

  final String label;
  final bool completed;
}

abstract final class BranchCatalog {
  static const branchIncomeUnlockShopLevel = 7;
  static const managerUnlockLevel = 20;
  static const firstManagerGrantMarker = '__system:first_manager_grant';
  static const maxBranchLevel = 50;
  static const branchMilestoneIncomeBonus = 0.05;
  static const milestoneLevels = <int>[10, 20, 30, 40, 50];

  static const regions = <BranchRegionDefinition>[
    BranchRegionDefinition(
      id: 'local',
      name: 'Yerel',
      order: 0,
      requiredRegionId: null,
      assetKey: 'placeholder_region_local',
    ),
    BranchRegionDefinition(
      id: 'istanbul',
      name: 'İstanbul',
      order: 1,
      requiredRegionId: 'local',
      assetKey: 'placeholder_region_istanbul',
    ),
    BranchRegionDefinition(
      id: 'turkiye',
      name: 'Türkiye',
      order: 2,
      requiredRegionId: 'istanbul',
      assetKey: 'placeholder_region_turkiye',
    ),
    BranchRegionDefinition(
      id: 'global',
      name: 'Global',
      order: 3,
      requiredRegionId: 'turkiye',
      assetKey: 'placeholder_region_global',
    ),
    BranchRegionDefinition(
      id: 'space',
      name: 'Uzay',
      order: 4,
      requiredRegionId: 'global',
      assetKey: 'placeholder_region_space',
    ),
  ];

  static const branches = <BranchDefinition>[
    BranchDefinition(
      id: 'main_branch',
      name: 'Ana Şube',
      cityName: 'Merkez',
      regionId: 'local',
      description: 'Markanın ilk zincir şubesi.',
      baseUnlockCost: 1_000_000,
      baseIncomePerSecond: 12,
      incomeMultiplierPerLevel: 1.075,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 7,
      requiredPrestigeCount: 1,
      requiredLifetimeCash: 5_000_000,
      assetKey: 'placeholder_branch_main',
    ),
    BranchDefinition(
      id: 'neighborhood_branch',
      name: 'Mahalle Şubesi',
      cityName: 'Yerel Bölge',
      regionId: 'local',
      description: 'Sadık mahalle müşterilerini taşır.',
      baseUnlockCost: 2_500_000,
      baseIncomePerSecond: 22,
      incomeMultiplierPerLevel: 1.075,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 7,
      requiredPrestigeCount: 1,
      requiredLifetimeCash: 10_000_000,
      assetKey: 'placeholder_branch_neighborhood',
    ),
    BranchDefinition(
      id: 'busy_street_branch',
      name: 'İşlek Cadde Şubesi',
      cityName: 'Cadde',
      regionId: 'local',
      description: 'Yoğun yaya trafiğinden pasif gelir üretir.',
      baseUnlockCost: 7_500_000,
      baseIncomePerSecond: 45,
      incomeMultiplierPerLevel: 1.078,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 7,
      requiredPrestigeCount: 1,
      requiredLifetimeCash: 25_000_000,
      assetKey: 'placeholder_branch_busy_street',
    ),
    BranchDefinition(
      id: 'kadikoy_branch',
      name: 'Kadıköy Şubesi',
      cityName: 'Kadıköy',
      regionId: 'istanbul',
      description: 'İstanbul zincirinin ilk kuvvetli durağı.',
      baseUnlockCost: 20_000_000,
      baseIncomePerSecond: 85,
      incomeMultiplierPerLevel: 1.08,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 7,
      requiredPrestigeCount: 2,
      requiredLifetimeCash: 50_000_000,
      assetKey: 'placeholder_branch_kadikoy',
    ),
    BranchDefinition(
      id: 'besiktas_branch',
      name: 'Beşiktaş Şubesi',
      cityName: 'Beşiktaş',
      regionId: 'istanbul',
      description: 'Akşam yoğunluğunu markaya çevirir.',
      baseUnlockCost: 35_000_000,
      baseIncomePerSecond: 125,
      incomeMultiplierPerLevel: 1.08,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 7,
      requiredPrestigeCount: 2,
      requiredLifetimeCash: 80_000_000,
      assetKey: 'placeholder_branch_besiktas',
    ),
    BranchDefinition(
      id: 'taksim_branch',
      name: 'Taksim Şubesi',
      cityName: 'Taksim',
      regionId: 'istanbul',
      description: 'Turist akışını pasif gelire bağlar.',
      baseUnlockCost: 55_000_000,
      baseIncomePerSecond: 175,
      incomeMultiplierPerLevel: 1.08,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 7,
      requiredPrestigeCount: 2,
      requiredLifetimeCash: 120_000_000,
      assetKey: 'placeholder_branch_taksim',
    ),
    BranchDefinition(
      id: 'mall_branch',
      name: 'AVM Şubesi',
      cityName: 'AVM',
      regionId: 'istanbul',
      description: 'Daha düzenli ve yüksek hacimli satış noktası.',
      baseUnlockCost: 85_000_000,
      baseIncomePerSecond: 240,
      incomeMultiplierPerLevel: 1.082,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 7,
      requiredPrestigeCount: 2,
      requiredLifetimeCash: 180_000_000,
      assetKey: 'placeholder_branch_mall',
    ),
    BranchDefinition(
      id: 'airport_branch',
      name: 'Havalimanı Şubesi',
      cityName: 'Havalimanı',
      regionId: 'istanbul',
      description: 'Yüksek fiyatlı hızlı servis noktası.',
      baseUnlockCost: 130_000_000,
      baseIncomePerSecond: 330,
      incomeMultiplierPerLevel: 1.082,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 7,
      requiredPrestigeCount: 2,
      requiredLifetimeCash: 250_000_000,
      assetKey: 'placeholder_branch_airport',
    ),
    BranchDefinition(
      id: 'izmir_branch',
      name: 'İzmir Şubesi',
      cityName: 'İzmir',
      regionId: 'turkiye',
      description: 'Ege kıyısında ulusal büyümeyi başlatır.',
      baseUnlockCost: 220_000_000,
      baseIncomePerSecond: 520,
      incomeMultiplierPerLevel: 1.084,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 8,
      requiredPrestigeCount: 3,
      requiredLifetimeCash: 500_000_000,
      assetKey: 'placeholder_branch_izmir',
    ),
    BranchDefinition(
      id: 'ankara_branch',
      name: 'Ankara Şubesi',
      cityName: 'Ankara',
      regionId: 'turkiye',
      description: 'Başkentte kurumsal sipariş akışı.',
      baseUnlockCost: 340_000_000,
      baseIncomePerSecond: 720,
      incomeMultiplierPerLevel: 1.084,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 8,
      requiredPrestigeCount: 3,
      requiredLifetimeCash: 750_000_000,
      assetKey: 'placeholder_branch_ankara',
    ),
    BranchDefinition(
      id: 'antalya_branch',
      name: 'Antalya Şubesi',
      cityName: 'Antalya',
      regionId: 'turkiye',
      description: 'Sezonluk turizm yoğunluğunu yakalar.',
      baseUnlockCost: 520_000_000,
      baseIncomePerSecond: 980,
      incomeMultiplierPerLevel: 1.084,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 8,
      requiredPrestigeCount: 3,
      requiredLifetimeCash: 1_100_000_000,
      assetKey: 'placeholder_branch_antalya',
    ),
    BranchDefinition(
      id: 'bursa_branch',
      name: 'Bursa Şubesi',
      cityName: 'Bursa',
      regionId: 'turkiye',
      description: 'Sanayi ve aile müşterilerini taşır.',
      baseUnlockCost: 760_000_000,
      baseIncomePerSecond: 1_300,
      incomeMultiplierPerLevel: 1.086,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 8,
      requiredPrestigeCount: 3,
      requiredLifetimeCash: 1_600_000_000,
      assetKey: 'placeholder_branch_bursa',
    ),
    BranchDefinition(
      id: 'cappadocia_branch',
      name: 'Kapadokya Turist Şubesi',
      cityName: 'Kapadokya',
      regionId: 'turkiye',
      description: 'Turist rotasında marka bilinirliği üretir.',
      baseUnlockCost: 1_100_000_000,
      baseIncomePerSecond: 1_750,
      incomeMultiplierPerLevel: 1.086,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 8,
      requiredPrestigeCount: 3,
      requiredLifetimeCash: 2_200_000_000,
      assetKey: 'placeholder_branch_cappadocia',
    ),
    BranchDefinition(
      id: 'berlin_branch',
      name: 'Berlin Şubesi',
      cityName: 'Berlin',
      regionId: 'global',
      description: 'Avrupa açılımının ilk bayrağı.',
      baseUnlockCost: 2_500_000_000,
      baseIncomePerSecond: 3_200,
      incomeMultiplierPerLevel: 1.088,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 9,
      requiredPrestigeCount: 4,
      requiredLifetimeCash: 5_000_000_000,
      assetKey: 'placeholder_branch_berlin',
    ),
    BranchDefinition(
      id: 'london_branch',
      name: 'Londra Şubesi',
      cityName: 'Londra',
      regionId: 'global',
      description: 'Global marka değerini büyütür.',
      baseUnlockCost: 4_000_000_000,
      baseIncomePerSecond: 4_400,
      incomeMultiplierPerLevel: 1.088,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 9,
      requiredPrestigeCount: 4,
      requiredLifetimeCash: 7_500_000_000,
      assetKey: 'placeholder_branch_london',
    ),
    BranchDefinition(
      id: 'new_york_branch',
      name: 'New York Şubesi',
      cityName: 'New York',
      regionId: 'global',
      description: 'Yüksek kira, yüksek pasif gelir.',
      baseUnlockCost: 6_500_000_000,
      baseIncomePerSecond: 6_000,
      incomeMultiplierPerLevel: 1.09,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 9,
      requiredPrestigeCount: 4,
      requiredLifetimeCash: 11_000_000_000,
      assetKey: 'placeholder_branch_new_york',
    ),
    BranchDefinition(
      id: 'dubai_branch',
      name: 'Dubai Şubesi',
      cityName: 'Dubai',
      regionId: 'global',
      description: 'Premium servis gelirini pasife taşır.',
      baseUnlockCost: 9_000_000_000,
      baseIncomePerSecond: 8_000,
      incomeMultiplierPerLevel: 1.09,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 9,
      requiredPrestigeCount: 4,
      requiredLifetimeCash: 16_000_000_000,
      assetKey: 'placeholder_branch_dubai',
    ),
    BranchDefinition(
      id: 'tokyo_branch',
      name: 'Tokyo Şubesi',
      cityName: 'Tokyo',
      regionId: 'global',
      description: 'Verimli servis disipliniyle ağır pasif gelir.',
      baseUnlockCost: 13_000_000_000,
      baseIncomePerSecond: 10_500,
      incomeMultiplierPerLevel: 1.09,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 9,
      requiredPrestigeCount: 4,
      requiredLifetimeCash: 22_000_000_000,
      assetKey: 'placeholder_branch_tokyo',
    ),
    BranchDefinition(
      id: 'moon_branch',
      name: 'Ay Şubesi',
      cityName: 'Ay',
      regionId: 'space',
      description: 'Absürt oyun sonu için düşük yerçekimi servisi.',
      baseUnlockCost: 45_000_000_000,
      baseIncomePerSecond: 24_000,
      incomeMultiplierPerLevel: 1.092,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 10,
      requiredPrestigeCount: 5,
      requiredLifetimeCash: 70_000_000_000,
      assetKey: 'placeholder_branch_moon',
    ),
    BranchDefinition(
      id: 'mars_branch',
      name: 'Mars Şubesi',
      cityName: 'Mars',
      regionId: 'space',
      description: 'Koloni ekonomisinde ilk döner noktası.',
      baseUnlockCost: 90_000_000_000,
      baseIncomePerSecond: 42_000,
      incomeMultiplierPerLevel: 1.094,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 10,
      requiredPrestigeCount: 5,
      requiredLifetimeCash: 130_000_000_000,
      assetKey: 'placeholder_branch_mars',
    ),
    BranchDefinition(
      id: 'galactic_branch',
      name: 'Galaktik Şube',
      cityName: 'Galaksi',
      regionId: 'space',
      description: 'Yıldızlar arası marka ağı.',
      baseUnlockCost: 180_000_000_000,
      baseIncomePerSecond: 72_000,
      incomeMultiplierPerLevel: 1.096,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 11,
      requiredPrestigeCount: 7,
      requiredLifetimeCash: 260_000_000_000,
      assetKey: 'placeholder_branch_galactic',
    ),
    BranchDefinition(
      id: 'infinite_doner_center',
      name: 'Sonsuz Döner Merkezi',
      cityName: 'Sonsuzluk',
      regionId: 'space',
      description: 'Markanın teorik son noktası.',
      baseUnlockCost: 400_000_000_000,
      baseIncomePerSecond: 125_000,
      incomeMultiplierPerLevel: 1.10,
      maxLevel: maxBranchLevel,
      requiredShopLevel: 12,
      requiredPrestigeCount: 10,
      requiredLifetimeCash: 600_000_000_000,
      assetKey: 'placeholder_branch_infinite',
    ),
  ];

  static final byId = Map<String, BranchDefinition>.unmodifiable({
    for (final branch in branches) branch.id: branch,
  });

  static final regionById = Map<String, BranchRegionDefinition>.unmodifiable({
    for (final region in regions) region.id: region,
  });

  static bool isBranchActionAvailable(GameState state) {
    return state.shopProgression.currentShopLevel >=
        branchIncomeUnlockShopLevel;
  }

  static bool isBranchSystemVisible(GameState state) {
    return isBranchActionAvailable(state) ||
        state.shopProgression.highestShopLevel >= branchIncomeUnlockShopLevel ||
        state.branches.unlockedBranchCount > 0;
  }

  static bool isBranchIncomeActive(GameState state) {
    return state.shopProgression.highestShopLevel >=
            branchIncomeUnlockShopLevel ||
        state.branches.unlockedBranchCount > 0;
  }

  static int unlockCost(BranchDefinition definition) {
    return math.max(0, definition.baseUnlockCost.round());
  }

  static int levelUpCost(BranchDefinition definition, BranchProgress progress) {
    if (!progress.isUnlocked || progress.level >= definition.maxLevel) {
      return 0;
    }
    final level = math.max(1, progress.level);
    final scaled =
        definition.baseUnlockCost *
        0.22 *
        math.pow(1.115, level - 1) *
        (1 + (level / 35));
    return math.max(1000, scaled.round());
  }

  static bool canUnlock(
    GameState state,
    BranchDefinition definition, {
    bool ignoreCostRequirement = false,
  }) {
    final progress = state.branches.progressFor(definition.id);
    if (progress.isUnlocked) {
      return false;
    }
    if (!isBranchActionAvailable(state)) {
      return false;
    }
    if (!state.branches.unlockedRegionIds.contains(definition.regionId)) {
      return false;
    }
    if (state.shopProgression.currentShopLevel < definition.requiredShopLevel) {
      return false;
    }
    if (state.prestige.prestigeCount < definition.requiredPrestigeCount) {
      return false;
    }
    if (state.lifetimeCash < definition.requiredLifetimeCash) {
      return false;
    }
    final cost = unlockCost(definition);
    return ignoreCostRequirement || state.cash >= cost;
  }

  static bool canLevelUp(
    GameState state,
    BranchDefinition definition, {
    bool ignoreCostRequirement = false,
  }) {
    final progress = state.branches.progressFor(definition.id);
    if (!progress.isUnlocked || progress.level >= definition.maxLevel) {
      return false;
    }
    if (!isBranchActionAvailable(state)) {
      return false;
    }
    final cost = levelUpCost(definition, progress);
    return ignoreCostRequirement || state.cash >= cost;
  }

  static List<BranchRequirementStatus> unlockRequirements(
    GameState state,
    BranchDefinition definition, {
    bool ignoreCostRequirement = false,
  }) {
    final cost = unlockCost(definition);
    final locale = state.localeCode;
    final isTurkish = locale == 'tr';
    return [
      BranchRequirementStatus(
        label: isTurkish
            ? 'Bölge: ${regionById[definition.regionId]?.name ?? definition.regionId}'
            : 'Region: ${_englishRegionName(definition.regionId)}',
        completed: state.branches.unlockedRegionIds.contains(
          definition.regionId,
        ),
      ),
      BranchRequirementStatus(
        label: isTurkish
            ? 'Dükkân Sv. ${definition.requiredShopLevel}'
            : 'Shop Lv. ${definition.requiredShopLevel}',
        completed:
            state.shopProgression.currentShopLevel >=
            definition.requiredShopLevel,
      ),
      BranchRequirementStatus(
        label: isTurkish
            ? 'Prestij ${definition.requiredPrestigeCount}'
            : 'Prestige ${definition.requiredPrestigeCount}',
        completed:
            state.prestige.prestigeCount >= definition.requiredPrestigeCount,
      ),
      BranchRequirementStatus(
        label: isTurkish
            ? 'Toplam kazanç ${formatNumberWithUnitNames(definition.requiredLifetimeCash, locale: locale)}'
            : 'Lifetime ${formatNumberWithUnitNames(definition.requiredLifetimeCash, locale: locale)}',
        completed: state.lifetimeCash >= definition.requiredLifetimeCash,
      ),
      BranchRequirementStatus(
        label: isTurkish
            ? 'Maliyet ${formatNumberWithUnitNames(ignoreCostRequirement ? 0 : cost, locale: locale)}'
            : 'Cost ${formatNumberWithUnitNames(ignoreCostRequirement ? 0 : cost, locale: locale)}',
        completed: ignoreCostRequirement || state.cash >= cost,
      ),
    ];
  }

  static BranchSystemState normalizedState(BranchSystemState state) {
    final nextProgress = <String, BranchProgress>{};
    for (final definition in branches) {
      final existing = state.branchProgress[definition.id];
      if (existing == null) {
        nextProgress[definition.id] = BranchProgress(branchId: definition.id);
        continue;
      }
      final level = existing.isUnlocked
          ? existing.level.clamp(1, definition.maxLevel).toInt()
          : 0;
      nextProgress[definition.id] = BranchProgress(
        branchId: definition.id,
        isUnlocked: existing.isUnlocked,
        level: level,
        assignedManagerId: existing.assignedManagerId,
      );
    }
    final validRegionIds = regionById.keys.toSet();
    final unlockedRegions =
        state.unlockedRegionIds.where(validRegionIds.contains).toSet()
          ..add('local');
    return state.copyWith(
      branchProgress: Map<String, BranchProgress>.unmodifiable(nextProgress),
      unlockedRegionIds: Set<String>.unmodifiable(unlockedRegions),
    );
  }

  static BranchSystemState refreshState(BranchSystemState state) {
    return refreshMilestones(refreshRegionUnlocks(normalizedState(state)));
  }

  static BranchSystemState refreshRegionUnlocks(BranchSystemState state) {
    final unlocked = Set<String>.from(state.unlockedRegionIds)..add('local');
    for (final region in regions) {
      final requiredRegionId = region.requiredRegionId;
      if (requiredRegionId == null) {
        continue;
      }
      if (isRegionComplete(state, requiredRegionId)) {
        unlocked.add(region.id);
      }
    }
    return unlocked.length == state.unlockedRegionIds.length
        ? state
        : state.copyWith(unlockedRegionIds: Set<String>.unmodifiable(unlocked));
  }

  static BranchSystemState refreshMilestones(BranchSystemState state) {
    final milestones = Set<String>.from(state.claimedBranchMilestones);
    for (final definition in branches) {
      final progress = state.progressFor(definition.id);
      if (!progress.isUnlocked) {
        continue;
      }
      for (final level in milestoneLevels) {
        if (progress.level >= level) {
          milestones.add(milestoneKey(definition.id, level));
        }
      }
    }
    return milestones.length == state.claimedBranchMilestones.length
        ? state
        : state.copyWith(
            claimedBranchMilestones: Set<String>.unmodifiable(milestones),
          );
  }

  static String milestoneKey(String branchId, int level) {
    return '$branchId:$level';
  }

  static int claimedLevelMilestoneCount(BranchSystemState state) {
    return state.claimedBranchMilestones
        .where((key) => key != firstManagerGrantMarker)
        .length;
  }

  static bool isRegionComplete(BranchSystemState state, String regionId) {
    final regionBranches = branches
        .where((branch) => branch.regionId == regionId)
        .toList(growable: false);
    return regionBranches.isNotEmpty &&
        regionBranches.every((branch) => state.isUnlocked(branch.id));
  }

  static Set<String> completedRegionIds(BranchSystemState state) {
    return regions
        .where((region) => isRegionComplete(state, region.id))
        .map((region) => region.id)
        .toSet();
  }

  static List<BranchDefinition> branchesForRegion(String regionId) {
    return branches
        .where((branch) => branch.regionId == regionId)
        .toList(growable: false);
  }

  static String regionName(String regionId, {required String localeCode}) {
    if (localeCode == 'tr') {
      return regionById[regionId]?.name ?? regionId;
    }
    return _englishRegionName(regionId);
  }

  static String _englishRegionName(String regionId) {
    return switch (regionId) {
      'local' => 'Local',
      'istanbul' => 'Istanbul',
      'turkiye' => 'Turkey',
      'global' => 'Global',
      'space' => 'Space',
      _ => regionId,
    };
  }

  static double rawBranchIncomeFor(
    BranchDefinition definition,
    BranchProgress progress,
    Collection2State collection2,
  ) {
    if (!progress.isUnlocked || progress.level <= 0) {
      return 0;
    }
    final base =
        definition.baseIncomePerSecond *
        math.pow(definition.incomeMultiplierPerLevel, progress.level - 1);
    final milestoneMultiplier =
        1 +
        (reachedMilestoneCount(progress.level) * branchMilestoneIncomeBonus);
    final managerMultiplier =
        1 + managerIncomeBonus(collection2, progress.assignedManagerId);
    return base * milestoneMultiplier * managerMultiplier;
  }

  static double rawBranchIncomePerSecond(GameState state) {
    var total = 0.0;
    for (final definition in branches) {
      total += rawBranchIncomeFor(
        definition,
        state.branches.progressFor(definition.id),
        state.collection2,
      );
    }
    return total;
  }

  static int reachedMilestoneCount(int level) {
    return milestoneLevels.where((milestone) => level >= milestone).length;
  }

  static bool isManagerSlotUnlocked(BranchProgress progress) {
    return progress.isUnlocked && progress.level >= managerUnlockLevel;
  }

  static List<String> availableManagerIds(
    GameState state, {
    String? forBranchId,
  }) {
    final assigned = <String>{};
    for (final progress in state.branches.branchProgress.values) {
      if (progress.branchId == forBranchId) {
        continue;
      }
      final managerId = progress.assignedManagerId;
      if (managerId != null && managerId.isNotEmpty) {
        assigned.add(managerId);
      }
    }
    return Collection2Catalog.staffCards
        .where((staff) => state.collection2.isStaffCardUnlocked(staff.id))
        .map((staff) => staff.id)
        .where((staffId) => !assigned.contains(staffId))
        .toList(growable: false);
  }

  static bool canAssignManager(
    GameState state, {
    required String branchId,
    required String managerId,
  }) {
    final progress = state.branches.progressFor(branchId);
    if (!isManagerSlotUnlocked(progress)) {
      return false;
    }
    if (!state.collection2.isStaffCardUnlocked(managerId)) {
      return false;
    }
    return availableManagerIds(
      state,
      forBranchId: branchId,
    ).contains(managerId);
  }

  static bool canUnassignManager(GameState state, {required String branchId}) {
    if (!byId.containsKey(branchId)) {
      return false;
    }
    final managerId = state.branches.progressFor(branchId).assignedManagerId;
    return managerId != null && managerId.isNotEmpty;
  }

  static String? managerName(String? managerId) {
    if (managerId == null || managerId.isEmpty) {
      return null;
    }
    return Collection2Catalog.staffCardById[managerId]?.name;
  }

  static double managerIncomeBonus(
    Collection2State collection2,
    String? managerId,
  ) {
    if (managerId == null || managerId.isEmpty) {
      return 0;
    }
    final definition = Collection2Catalog.staffCardById[managerId];
    if (definition == null) {
      return 0;
    }
    final level = collection2.staffCardLevel(managerId);
    if (level <= 0) {
      return 0;
    }
    final leveled = definition.bonusValuePerLevel * level;
    return switch (definition.bonusType) {
      StaffCardBonusType.passiveIncome => 0.06 + leveled,
      StaffCardBonusType.offlineIncome => 0.04 + leveled,
      StaffCardBonusType.autoTapPower => 0.05 + leveled,
      StaffCardBonusType.customerReward => 0.03 + leveled,
      StaffCardBonusType.reputationGain => 0.03 + leveled,
      StaffCardBonusType.tipChance ||
      StaffCardBonusType.customerOrderDuration => 0.02 + leveled,
    };
  }
}
