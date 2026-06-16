import 'dart:math' as math;

import 'package:taptapdoner/domain/branches/branch_catalog.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/goals/goal_catalog.dart';
import 'package:taptapdoner/domain/goals/goal_models.dart';
import 'package:taptapdoner/domain/state/game_state.dart';

class GoalEngine {
  const GoalEngine();

  GoalSystemState refresh(
    GameState state, {
    required EconomyConfig config,
    required DateTime nowUtc,
    required math.Random random,
    bool forcePrestigeRunRefresh = false,
  }) {
    final todayKey = goalLocalDateKey(nowUtc);
    final weekKey = goalIsoWeekKey(nowUtc);
    final goals = state.goals;

    var nextGoals = goals;

    final shouldResetDaily =
        goals.lastDailyResetDate != todayKey || goals.activeDailyGoals.isEmpty;
    if (shouldResetDaily) {
      nextGoals = nextGoals.copyWith(
        activeDailyGoals: _generate(
          state,
          config: config,
          random: random,
          category: GoalCategory.daily,
          count: GoalCatalog.dailyGoalCount,
          nowUtc: nowUtc,
          expiresAtMillis: _nextLocalMidnightMillis(nowUtc),
        ),
        lastDailyResetDate: todayKey,
      );
    } else {
      nextGoals = nextGoals.copyWith(
        activeDailyGoals: _expireGoals(nextGoals.activeDailyGoals, nowUtc),
      );
    }

    final shouldResetWeekly =
        goals.lastWeeklyResetWeek != weekKey || goals.activeWeeklyGoals.isEmpty;
    if (shouldResetWeekly) {
      nextGoals = nextGoals.copyWith(
        activeWeeklyGoals: _generate(
          state,
          config: config,
          random: random,
          category: GoalCategory.weekly,
          count: GoalCatalog.weeklyGoalCount,
          nowUtc: nowUtc,
          expiresAtMillis: _nextLocalWeekStartMillis(nowUtc),
        ),
        lastWeeklyResetWeek: weekKey,
      );
    } else {
      nextGoals = nextGoals.copyWith(
        activeWeeklyGoals: _expireGoals(nextGoals.activeWeeklyGoals, nowUtc),
      );
    }

    if (state.prestige.prestigeCount <= 0) {
      nextGoals = nextGoals.copyWith(
        activePrestigeRunGoals: const <GoalProgress>[],
        runGoalPrestigeCount: 0,
      );
    } else if (forcePrestigeRunRefresh ||
        nextGoals.runGoalPrestigeCount != state.prestige.prestigeCount ||
        nextGoals.activePrestigeRunGoals.isEmpty) {
      nextGoals = nextGoals.copyWith(
        activePrestigeRunGoals: _generate(
          state,
          config: config,
          random: random,
          category: GoalCategory.prestigeRun,
          count: GoalCatalog.prestigeRunGoalCount,
          nowUtc: nowUtc,
          expiresAtMillis: null,
        ),
        runGoalPrestigeCount: state.prestige.prestigeCount,
      );
    } else {
      nextGoals = nextGoals.copyWith(
        activePrestigeRunGoals: _expireGoals(
          nextGoals.activePrestigeRunGoals,
          nowUtc,
        ),
      );
    }

    nextGoals = nextGoals.copyWith(activeEventGoals: const <GoalProgress>[]);

    return nextGoals;
  }

  GoalSystemState recordProgress(
    GoalSystemState goals,
    GoalObjectiveType objectiveType,
    double value, {
    required DateTime nowUtc,
    bool useMaxProgress = false,
  }) {
    if (value <= 0) {
      return goals;
    }

    List<GoalProgress> updateList(List<GoalProgress> entries) {
      var changed = false;
      final next = entries
          .map((progress) {
            if (progress.isExpiredAt(nowUtc)) {
              if (progress.status == GoalStatus.expired) {
                return progress;
              }
              changed = true;
              return progress.copyWith(status: GoalStatus.expired);
            }
            final definition = GoalCatalog.byId[progress.goalId];
            if (definition == null ||
                definition.objectiveType != objectiveType ||
                progress.status != GoalStatus.active ||
                progress.rewardClaimed) {
              return progress;
            }
            final nextValue = useMaxProgress
                ? math.max(progress.currentValue, value)
                : progress.currentValue + value;
            final clamped = math.min(progress.targetValue, nextValue);
            if (clamped == progress.currentValue) {
              return progress;
            }
            changed = true;
            return progress.copyWith(
              currentValue: clamped,
              status: clamped >= progress.targetValue
                  ? GoalStatus.completed
                  : GoalStatus.active,
            );
          })
          .toList(growable: false);
      return changed ? List<GoalProgress>.unmodifiable(next) : entries;
    }

    final nextDaily = updateList(goals.activeDailyGoals);
    final nextWeekly = updateList(goals.activeWeeklyGoals);
    final nextRun = updateList(goals.activePrestigeRunGoals);
    final nextEvent = updateList(goals.activeEventGoals);

    if (identical(nextDaily, goals.activeDailyGoals) &&
        identical(nextWeekly, goals.activeWeeklyGoals) &&
        identical(nextRun, goals.activePrestigeRunGoals) &&
        identical(nextEvent, goals.activeEventGoals)) {
      return goals;
    }
    return goals.copyWith(
      activeDailyGoals: nextDaily,
      activeWeeklyGoals: nextWeekly,
      activePrestigeRunGoals: nextRun,
      activeEventGoals: nextEvent,
    );
  }

  bool isGoalEligible(
    GoalDefinition goal,
    GameState state, {
    required EconomyConfig config,
  }) {
    if (state.shopProgression.currentShopLevel < goal.minShopLevel) {
      return false;
    }
    if (state.customerReputation.currentLevel < goal.minReputationLevel) {
      return false;
    }
    if (state.prestige.prestigeCount < goal.minPrestigeCount) {
      return false;
    }
    if (goal.category == GoalCategory.prestigeRun &&
        state.prestige.prestigeCount <= 0) {
      return false;
    }
    if (goal.category == GoalCategory.event) {
      return false;
    }
    for (final featureKey in goal.requiredFeatureKeys) {
      if (!state.milestones.hasFeature(featureKey)) {
        return false;
      }
    }
    return _isObjectiveSystemUnlocked(goal.objectiveType, state, config);
  }

  List<GoalProgress> _generate(
    GameState state, {
    required EconomyConfig config,
    required math.Random random,
    required GoalCategory category,
    required int count,
    required DateTime nowUtc,
    required int? expiresAtMillis,
  }) {
    final eligible = GoalCatalog.definitionsFor(category)
        .where((goal) => isGoalEligible(goal, state, config: config))
        .toList(growable: true);
    final selected = <GoalDefinition>[];
    while (eligible.isNotEmpty && selected.length < count) {
      final totalWeight = eligible.fold<int>(
        0,
        (total, goal) => total + goal.weight,
      );
      var roll = random.nextInt(math.max(1, totalWeight));
      var selectedIndex = 0;
      for (var index = 0; index < eligible.length; index += 1) {
        roll -= eligible[index].weight;
        if (roll < 0) {
          selectedIndex = index;
          break;
        }
      }
      selected.add(eligible.removeAt(selectedIndex));
    }
    return List<GoalProgress>.unmodifiable(
      selected.map(
        (goal) => GoalProgress(
          goalId: goal.id,
          targetValue: goal.targetValue,
          generatedAtMillis: nowUtc.millisecondsSinceEpoch,
          expiresAtMillis: expiresAtMillis,
        ),
      ),
    );
  }

  List<GoalProgress> _expireGoals(List<GoalProgress> goals, DateTime nowUtc) {
    var changed = false;
    final next = goals
        .map((progress) {
          if (!progress.isExpiredAt(nowUtc) ||
              progress.status == GoalStatus.expired) {
            return progress;
          }
          changed = true;
          return progress.copyWith(status: GoalStatus.expired);
        })
        .toList(growable: false);
    return changed ? List<GoalProgress>.unmodifiable(next) : goals;
  }

  bool _isObjectiveSystemUnlocked(
    GoalObjectiveType objectiveType,
    GameState state,
    EconomyConfig config,
  ) {
    return switch (objectiveType) {
      GoalObjectiveType.tapCount ||
      GoalObjectiveType.earnMoney ||
      GoalObjectiveType.buyUpgrades ||
      GoalObjectiveType.openChests ||
      GoalObjectiveType.useTurbo ||
      GoalObjectiveType.levelUpShop ||
      GoalObjectiveType.completeMilestones ||
      GoalObjectiveType.unlockCollectionItem => true,
      GoalObjectiveType.unlockBranches ||
      GoalObjectiveType.upgradeBranchLevels ||
      GoalObjectiveType.reachTotalBranchLevel ||
      GoalObjectiveType.reachBranchMilestones ||
      GoalObjectiveType.completeBranchRegions =>
        BranchCatalog.isBranchActionAvailable(state),
      GoalObjectiveType.assignBranchManager =>
        BranchCatalog.isBranchActionAvailable(state) &&
            BranchCatalog.availableManagerIds(state).isNotEmpty &&
            state.branches.branchProgress.values.any(
              BranchCatalog.isManagerSlotUnlocked,
            ),
      GoalObjectiveType.completeCustomerOrders ||
      GoalObjectiveType.completeSpecificCustomerType ||
      GoalObjectiveType.gainReputation => _isCustomerOrderSystemUnlocked(state),
      GoalObjectiveType.triggerCritical => state.milestones.hasFeature(
        'critical_cut',
      ),
      GoalObjectiveType.reachCombo => state.milestones.hasFeature('combo'),
      GoalObjectiveType.collectGoldenDoner => state.milestones.hasFeature(
        'golden_doner',
      ),
      GoalObjectiveType.doPrestige =>
        state.prestige.prestigeCount > 0 ||
            state.stats.openPrestigeScreenOnce ||
            state.prestige.runCashEarned >= config.prestigeThreshold,
      GoalObjectiveType.completeEvent => false,
    };
  }

  bool _isCustomerOrderSystemUnlocked(GameState state) {
    return state.customerOrders.unlockedCustomerTypeIds.isNotEmpty;
  }

  int _nextLocalMidnightMillis(DateTime nowUtc) {
    final local = nowUtc.toLocal();
    final next = DateTime(local.year, local.month, local.day + 1);
    return next.toUtc().millisecondsSinceEpoch;
  }

  int _nextLocalWeekStartMillis(DateTime nowUtc) {
    final local = nowUtc.toLocal();
    final localDate = DateTime(local.year, local.month, local.day);
    final nextMonday = localDate.add(
      Duration(days: DateTime.daysPerWeek - localDate.weekday + 1),
    );
    return nextMonday.toUtc().millisecondsSinceEpoch;
  }
}
