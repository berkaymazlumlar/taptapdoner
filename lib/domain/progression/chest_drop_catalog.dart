import 'dart:math' as math;

import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';

abstract final class ChestDropCatalog {
  static const _tables = <ChestDropTable>[
    ChestDropTable(
      chestType: ChestType.small,
      drops: [
        WeightedDrop(
          rewardType: ChestRewardType.money,
          amount: 75,
          weight: 28,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.temporaryIncomeBoost,
          amount: 2,
          weight: 12,
          rarity: Rarity.rare,
          durationSeconds: 45,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.reputation,
          amount: 4,
          weight: 8,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_student_regular',
          amount: 3,
          weight: 12,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_night_worker',
          amount: 2,
          weight: 8,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_apprentice',
          amount: 3,
          weight: 10,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_journeyman',
          amount: 2,
          weight: 7,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_new_sign',
          amount: 2,
          weight: 7,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_spice_shelf',
          amount: 2,
          weight: 5,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.knifeSkinShard,
          itemId: 'moment_first_shift',
          amount: 3,
          weight: 4,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.reputation,
          amount: 6,
          weight: 3,
          rarity: Rarity.common,
        ),
      ],
    ),
    ChestDropTable(
      chestType: ChestType.master,
      drops: [
        WeightedDrop(
          rewardType: ChestRewardType.money,
          amount: 500,
          weight: 22,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.temporaryIncomeBoost,
          amount: 2,
          weight: 14,
          rarity: Rarity.rare,
          durationSeconds: 180,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_taxi_driver',
          amount: 4,
          weight: 14,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_food_blogger',
          amount: 4,
          weight: 10,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_cashier',
          amount: 4,
          weight: 12,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_sauce_master',
          amount: 4,
          weight: 10,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_red_neon',
          amount: 3,
          weight: 6,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.permanentTapBonus,
          amount: 1,
          weight: 4,
          rarity: Rarity.epic,
        ),
      ],
    ),
    ChestDropTable(
      chestType: ChestType.gold,
      drops: [
        WeightedDrop(
          rewardType: ChestRewardType.money,
          amount: 5000,
          weight: 20,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.temporaryIncomeBoost,
          amount: 2,
          weight: 12,
          rarity: Rarity.rare,
          durationSeconds: 600,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.reputation,
          amount: 20,
          weight: 8,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_gourmet_critic',
          amount: 5,
          weight: 13,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_doner_master',
          amount: 5,
          weight: 12,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_gold_counter',
          amount: 4,
          weight: 10,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_modern_menu_board',
          amount: 4,
          weight: 9,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.knifeSkinShard,
          itemId: 'moment_neon_rush',
          amount: 6,
          weight: 4,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.permanentPassiveBonus,
          amount: 1,
          weight: 6,
          rarity: Rarity.legendary,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.permanentGlobalBonus,
          amount: 1,
          weight: 2,
          rarity: Rarity.legendary,
        ),
      ],
    ),
    ChestDropTable(
      chestType: ChestType.recipe,
      drops: [
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_student_regular',
          amount: 3,
          weight: 20,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_night_worker',
          amount: 3,
          weight: 16,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_taxi_driver',
          amount: 5,
          weight: 16,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_food_blogger',
          amount: 5,
          weight: 14,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_gourmet_critic',
          amount: 6,
          weight: 10,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.recipeShard,
          itemId: 'customer_cosmic_traveler',
          amount: 4,
          weight: 1,
          rarity: Rarity.mythic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.money,
          amount: 300,
          weight: 10,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.reputation,
          amount: 8,
          weight: 9,
          rarity: Rarity.rare,
        ),
      ],
    ),
    ChestDropTable(
      chestType: ChestType.staff,
      drops: [
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_apprentice',
          amount: 5,
          weight: 22,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_journeyman',
          amount: 5,
          weight: 19,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_cashier',
          amount: 7,
          weight: 17,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_sauce_master',
          amount: 7,
          weight: 16,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_doner_master',
          amount: 8,
          weight: 11,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_courier',
          amount: 8,
          weight: 9,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_robot_master',
          amount: 10,
          weight: 5,
          rarity: Rarity.legendary,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_influencer_chef',
          amount: 20,
          weight: 1,
          rarity: Rarity.mythic,
        ),
      ],
    ),
    ChestDropTable(
      chestType: ChestType.decor,
      drops: [
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_new_sign',
          amount: 3,
          weight: 14,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_spice_shelf',
          amount: 3,
          weight: 14,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_red_neon',
          amount: 5,
          weight: 13,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_modern_menu_board',
          amount: 5,
          weight: 13,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_gold_counter',
          amount: 6,
          weight: 9,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_vip_table',
          amount: 6,
          weight: 8,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_mall_stand',
          amount: 5,
          weight: 4,
          rarity: Rarity.legendary,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_galactic_sign',
          amount: 5,
          weight: 3,
          rarity: Rarity.legendary,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_infinite_doner_statue',
          amount: 4,
          weight: 1,
          rarity: Rarity.mythic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.reputation,
          amount: 12,
          weight: 6,
          rarity: Rarity.common,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.money,
          amount: 500,
          weight: 15,
          rarity: Rarity.common,
        ),
      ],
    ),
    ChestDropTable(
      chestType: ChestType.prestige,
      drops: [
        WeightedDrop(
          rewardType: ChestRewardType.prestigeShard,
          amount: 4,
          weight: 22,
          rarity: Rarity.rare,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.prestigeShard,
          amount: 8,
          weight: 8,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_robot_master',
          amount: 6,
          weight: 10,
          rarity: Rarity.legendary,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.staffCardShard,
          itemId: 'staff_influencer_chef',
          amount: 5,
          weight: 5,
          rarity: Rarity.mythic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.decorShard,
          itemId: 'decor_galactic_sign',
          amount: 6,
          weight: 10,
          rarity: Rarity.legendary,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.knifeSkinShard,
          itemId: 'moment_golden_service',
          amount: 10,
          weight: 6,
          rarity: Rarity.legendary,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.knifeSkinShard,
          itemId: 'moment_cosmic_opening',
          amount: 20,
          weight: 1,
          rarity: Rarity.mythic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.permanentTapBonus,
          amount: 2,
          weight: 8,
          rarity: Rarity.legendary,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.permanentPassiveBonus,
          amount: 2,
          weight: 3,
          rarity: Rarity.mythic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.reputation,
          amount: 30,
          weight: 16,
          rarity: Rarity.epic,
        ),
        WeightedDrop(
          rewardType: ChestRewardType.permanentGlobalBonus,
          amount: 2,
          weight: 2,
          rarity: Rarity.legendary,
        ),
      ],
    ),
  ];

  static WeightedDrop roll(ChestType type, math.Random random) {
    return tableFor(type).roll(random);
  }

  static ChestDropTable tableFor(ChestType type) {
    for (final table in _tables) {
      if (table.chestType == type) {
        return table;
      }
    }
    return _tables.first;
  }
}
