import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/goals/goal_catalog.dart';
import 'package:taptapdoner/domain/goals/goal_models.dart';
import 'package:taptapdoner/domain/progression/chest_drop_catalog.dart';
import 'package:taptapdoner/domain/progression/collection2_catalog.dart';
import 'package:taptapdoner/domain/progression/faz5_models.dart';

void main() {
  test('card catalog keeps the four distinct collection categories', () {
    expect(Collection2Catalog.customerCards, hasLength(6));
    expect(Collection2Catalog.masterCards, hasLength(8));
    expect(Collection2Catalog.decorItems, hasLength(9));
    expect(Collection2Catalog.momentCards, hasLength(4));
  });

  test('every collection card has at least one chest source', () {
    final droppableIds = <String>{
      for (final type in ChestType.values)
        for (final drop in ChestDropCatalog.tableFor(type).drops)
          if (drop.itemId != null) drop.itemId!,
    };
    final catalogIds = <String>{
      for (final item in Collection2Catalog.customerCards) item.id,
      for (final item in Collection2Catalog.masterCards) item.id,
      for (final item in Collection2Catalog.decorItems) item.id,
      for (final item in Collection2Catalog.momentCards) item.id,
    };

    expect(droppableIds, containsAll(catalogIds));
  });

  test('chef chest always grants master cards', () {
    final table = ChestDropCatalog.tableFor(ChestType.staff);

    expect(table.drops, isNotEmpty);
    expect(
      table.drops.every(
        (drop) => drop.rewardType == ChestRewardType.staffCardShard,
      ),
      isTrue,
    );
    expect(table.drops.fold<int>(0, (total, drop) => total + drop.weight), 100);
  });

  test('common masters unlock within about ten targeted chef chests', () {
    final table = ChestDropCatalog.tableFor(ChestType.staff);

    for (final staffId in const ['staff_apprentice', 'staff_journeyman']) {
      final definition = Collection2Catalog.masterCardById[staffId]!;
      final drop = table.drops.singleWhere((drop) => drop.itemId == staffId);
      final hitsToUnlock = (definition.requiredCards / drop.amount).ceil();
      final expectedChests = hitsToUnlock / (drop.weight / 100);

      expect(expectedChests, lessThanOrEqualTo(11));
    }
  });

  test('branch goals add chef chest sources', () {
    for (final goalId in const [
      'daily_branch_level_3',
      'weekly_branch_milestones_2',
    ]) {
      final rewards = GoalCatalog.byId[goalId]!.rewards;
      expect(
        rewards.any(
          (reward) =>
              reward.type == GoalRewardType.chest &&
              reward.chestType == ChestType.staff,
        ),
        isTrue,
      );
    }
  });
}
