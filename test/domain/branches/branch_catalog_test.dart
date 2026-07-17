import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/domain/branches/branch_catalog.dart';
import 'package:taptapdoner/domain/branches/branch_models.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/state/game_state.dart';

void main() {
  test('all branch names preserve their exact Turkish spelling', () {
    const expectedNames = <String, String>{
      'main_branch': 'Ana Şube',
      'neighborhood_branch': 'Mahalle Şubesi',
      'busy_street_branch': 'İşlek Cadde Şubesi',
      'kadikoy_branch': 'Kadıköy Şubesi',
      'besiktas_branch': 'Beşiktaş Şubesi',
      'taksim_branch': 'Taksim Şubesi',
      'mall_branch': 'AVM Şubesi',
      'airport_branch': 'Havalimanı Şubesi',
      'izmir_branch': 'İzmir Şubesi',
      'ankara_branch': 'Ankara Şubesi',
      'antalya_branch': 'Antalya Şubesi',
      'bursa_branch': 'Bursa Şubesi',
      'cappadocia_branch': 'Kapadokya Turist Şubesi',
      'berlin_branch': 'Berlin Şubesi',
      'london_branch': 'Londra Şubesi',
      'new_york_branch': 'New York Şubesi',
      'dubai_branch': 'Dubai Şubesi',
      'tokyo_branch': 'Tokyo Şubesi',
      'moon_branch': 'Ay Şubesi',
      'mars_branch': 'Mars Şubesi',
      'galactic_branch': 'Galaktik Şube',
      'infinite_doner_center': 'Sonsuz Döner Merkezi',
    };

    expect(BranchCatalog.branches, hasLength(expectedNames.length));
    for (final branch in BranchCatalog.branches) {
      expect(
        branch.name,
        expectedNames[branch.id],
        reason: '${branch.id} için Türkçe ad bozuk.',
      );
    }
  });

  test('branch cities and regions preserve Turkish characters', () {
    expect(BranchCatalog.byId['neighborhood_branch']?.cityName, 'Yerel Bölge');
    expect(BranchCatalog.byId['kadikoy_branch']?.cityName, 'Kadıköy');
    expect(BranchCatalog.byId['besiktas_branch']?.cityName, 'Beşiktaş');
    expect(BranchCatalog.byId['airport_branch']?.cityName, 'Havalimanı');
    expect(BranchCatalog.byId['izmir_branch']?.cityName, 'İzmir');
    expect(BranchCatalog.regions.map((region) => region.name), [
      'Yerel',
      'İstanbul',
      'Türkiye',
      'Global',
      'Uzay',
    ]);
  });

  test('manager validation prevents one card from managing two branches', () {
    final config = EconomyConfig.standard();
    final nowUtc = DateTime.utc(2026, 7, 16);
    final state = GameState.initial(config, nowUtc: nowUtc).copyWith(
      collection2: const Collection2State(
        masterCards: {'staff_apprentice': 0},
        masterCardLevels: {'staff_apprentice': 1},
      ),
      branches: const BranchSystemState(
        branchProgress: {
          'main_branch': BranchProgress(
            branchId: 'main_branch',
            isUnlocked: true,
            level: 20,
            assignedManagerId: 'staff_apprentice',
          ),
          'neighborhood_branch': BranchProgress(
            branchId: 'neighborhood_branch',
            isUnlocked: true,
            level: 20,
          ),
        },
      ),
    );

    expect(
      BranchCatalog.canAssignManager(
        state,
        branchId: 'neighborhood_branch',
        managerId: 'staff_apprentice',
      ),
      isFalse,
    );
    expect(
      BranchCatalog.canAssignManager(
        state,
        branchId: 'main_branch',
        managerId: 'staff_apprentice',
      ),
      isTrue,
    );
    expect(
      BranchCatalog.canUnassignManager(state, branchId: 'main_branch'),
      isTrue,
    );
  });

  test('assigned manager increases only that branch income', () {
    final definition = BranchCatalog.byId['main_branch']!;
    const collection2 = Collection2State(
      masterCards: {'staff_apprentice': 0},
      masterCardLevels: {'staff_apprentice': 1},
    );
    const withoutManager = BranchProgress(
      branchId: 'main_branch',
      isUnlocked: true,
      level: 20,
    );
    const withManager = BranchProgress(
      branchId: 'main_branch',
      isUnlocked: true,
      level: 20,
      assignedManagerId: 'staff_apprentice',
    );

    final base = BranchCatalog.rawBranchIncomeFor(
      definition,
      withoutManager,
      collection2,
    );
    final managed = BranchCatalog.rawBranchIncomeFor(
      definition,
      withManager,
      collection2,
    );

    expect(managed, closeTo(base * 1.11, 0.000001));
    expect(
      BranchCatalog.incomeContributionFor(definition, withManager, collection2),
      closeTo(
        BranchCatalog.incomeContributionFor(
              definition,
              withoutManager,
              collection2,
            ) *
            1.11,
        0.000001,
      ),
    );
  });

  test('maxed branches contribute a meaningful share by region', () {
    const collection2 = Collection2State();

    double maxedContribution(String branchId) {
      final definition = BranchCatalog.byId[branchId]!;
      return BranchCatalog.incomeContributionFor(
        definition,
        BranchProgress(
          branchId: branchId,
          isUnlocked: true,
          level: definition.maxLevel,
        ),
        collection2,
      );
    }

    expect(maxedContribution('airport_branch'), closeTo(0.075, 0.000001));
    expect(
      BranchCatalog.branchesForRegion('local').fold<double>(
        0,
        (total, branch) => total + maxedContribution(branch.id),
      ),
      closeTo(0.15, 0.000001),
    );
    expect(
      BranchCatalog.branchesForRegion('istanbul').fold<double>(
        0,
        (total, branch) => total + maxedContribution(branch.id),
      ),
      closeTo(0.375, 0.000001),
    );
  });
}
