import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/branches/branch_models.dart';
import 'package:taptapdoner/domain/economy/economy_config.dart';
import 'package:taptapdoner/domain/progression/collection2_models.dart';
import 'package:taptapdoner/domain/state/game_state.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/services/save/save_repository.dart';
import 'package:taptapdoner/ui/pages/branch_page.dart';

void main() {
  testWidgets(
    'region buttons filter branches and Turkish names are preserved',
    (tester) async {
      final config = EconomyConfig.standard();
      final nowUtc = DateTime.utc(2026, 7, 15, 12);
      final controller =
          GameController(
            config: config,
            saveRepository: _MemorySaveRepository(),
            adService: const NoopRewardedAdService(),
            clock: () => nowUtc,
          )..hydrate(
            GameState.initial(
              config,
              nowUtc: nowUtc,
            ).copyWith(localeCode: 'tr'),
          );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: AppStrings.localizationsDelegates,
          home: Scaffold(body: BranchPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Şubeler'), findsOneWidget);
      expect(find.textContaining('Yerel 0/3'), findsOneWidget);
      expect(find.textContaining('İstanbul 0/5'), findsOneWidget);
      expect(find.textContaining('Türkiye 0/5'), findsOneWidget);
      final incomeLabelRect = tester.getRect(find.text('GELİR'));
      final totalLabelRect = tester.getRect(find.text('TOPLAM'));
      final stateLabelRect = tester.getRect(find.text('DURUM'));
      expect(totalLabelRect.top, incomeLabelRect.top);
      expect(stateLabelRect.top, incomeLabelRect.top);
      expect(
        find.byKey(const ValueKey('branch-card-main_branch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('branch-card-kadikoy_branch')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('branch-region-istanbul')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('branch-card-main_branch')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('branch-card-kadikoy_branch')),
        findsOneWidget,
      );
      expect(find.text('Kadıköy Şubesi'), findsOneWidget);
    },
  );

  testWidgets('manager sheet compares, assigns, and unassigns staff', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final config = EconomyConfig.standard();
    final nowUtc = DateTime.utc(2026, 7, 15, 12);
    final initial = GameState.initial(config, nowUtc: nowUtc).copyWith(
      localeCode: 'tr',
      branches: const BranchSystemState(
        branchProgress: <String, BranchProgress>{
          'main_branch': BranchProgress(
            branchId: 'main_branch',
            isUnlocked: true,
            level: 20,
          ),
          'neighborhood_branch': BranchProgress(
            branchId: 'neighborhood_branch',
            isUnlocked: true,
            level: 20,
            assignedManagerId: 'staff_journeyman',
          ),
        },
      ),
      collection2: const Collection2State(
        masterCards: <String, int>{
          'staff_apprentice': 10,
          'staff_journeyman': 10,
        },
        masterCardLevels: <String, int>{
          'staff_apprentice': 1,
          'staff_journeyman': 1,
        },
      ),
    );
    final controller = GameController(
      config: config,
      saveRepository: _MemorySaveRepository(),
      adService: const NoopRewardedAdService(),
      clock: () => nowUtc,
    )..hydrate(initial);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: AppStrings.localizationsDelegates,
        home: Scaffold(body: BranchPage(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();

    final chooseButton = find.text('Yönetici Seç');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(chooseButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('manager-income-comparison')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('manager-option-staff_apprentice')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('manager-option-staff_journeyman')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('manager-sheet-close-button')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('manager-option-staff_apprentice')),
        matching: find.text('Çırak Ali'),
      ),
      findsOneWidget,
    );
    expect(find.text('Mahalle Şubesi şubesinde görevli'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('manager-option-staff_apprentice')),
    );
    await tester.pumpAndSettle();
    expect(
      controller.state.branches.progressFor('main_branch').assignedManagerId,
      'staff_apprentice',
    );

    final changeButton = find.descendant(
      of: find.byKey(const ValueKey('branch-card-main_branch')),
      matching: find.text('Değiştir'),
    );
    await tester.ensureVisible(changeButton);
    await tester.tap(changeButton);
    await tester.pumpAndSettle();
    expect(find.text('Görevden Al'), findsOneWidget);
    await tester.tap(find.text('Görevden Al'));
    await tester.pumpAndSettle();
    expect(
      controller.state.branches.progressFor('main_branch').assignedManagerId,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}

class _MemorySaveRepository implements SaveRepository {
  GameState? _state;

  @override
  Future<void> clear() async => _state = null;

  @override
  Future<GameState?> load(EconomyConfig config) async => _state;

  @override
  Future<void> save(GameState state) async => _state = state;
}
