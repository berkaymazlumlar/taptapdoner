import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/ui/layout/responsive_layout_spec.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/panel_card.dart';
import 'package:taptapdoner/ui/widgets/ui_action_button.dart';
import 'package:taptapdoner/ui/widgets/ui_stat_pill.dart';

void main() {
  final spec = ResponsiveLayoutSpec.fromSize(const Size(360, 640));

  testWidgets('shared widgets are code-native and avoid svg layers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  PanelCard(child: const Text('Panel content')),
                  UiActionButton(
                    label: 'Buy',
                    spec: spec,
                    onPressed: () {},
                    badge: '3',
                  ),
                  UiStatPill(label: 'Income', value: '42/s', spec: spec),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byWidgetPredicate(_isSvgRuntimeWidget), findsNothing);

    final panelShell = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('panel-card-fallback-shell')),
    );
    final panelInsetShell = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('panel-card-inset-glow-shell')),
    );
    final buttonShell = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('ui-action-button-fallback-shell')),
    );
    final pillShell = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('ui-stat-pill-fallback-shell')),
    );

    expect((panelShell.decoration as BoxDecoration).gradient, isNotNull);
    expect(
      (panelShell.decoration as BoxDecoration).border,
      Border.all(
        color: RoastedColors.outlineVariant.withValues(
          alpha: RoastedOpacity.ghostEdge,
        ),
      ),
    );
    final panelInsetDecoration = panelInsetShell.decoration as BoxDecoration;
    expect(panelInsetDecoration.gradient, isNotNull);
    expect(
      (panelInsetDecoration.gradient as LinearGradient).colors.first,
      RoastedColors.primaryFixed.withValues(alpha: 0.14),
    );
    expect((buttonShell.decoration as BoxDecoration).gradient, isNotNull);
    expect((pillShell.decoration as BoxDecoration).color, isNotNull);

    expect(find.text('Panel content'), findsOneWidget);
    expect(find.text('Buy'), findsOneWidget);
    expect(find.text('INCOME'), findsOneWidget);
    expect(find.text('42/s'), findsOneWidget);
  });

  testWidgets(
    'primary action button sinks into primary fixed dim when pressed',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: UiActionButton(
                label: 'Rush',
                spec: spec,
                onPressed: () {},
                badge: '1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(UiActionButton));
      final gesture = await tester.startGesture(center);
      await tester.pump();

      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, 0.95);

      final shell = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('ui-action-button-fallback-shell')),
      );
      final decoration = shell.decoration as BoxDecoration;
      expect(
        (decoration.gradient as LinearGradient).colors.first,
        RoastedColors.primaryFixedDim,
      );
      expect(
        find.byKey(const ValueKey('ui-action-button-pressed-inset-shell')),
        findsOneWidget,
      );

      await gesture.up();
    },
  );

  test(
    'pubspec and shared widget sources do not reintroduce svg runtime UI',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(
        pubspec,
        isNot(contains(RegExp(r'^\s*flutter_svg\s*:', multiLine: true))),
      );
      expect(pubspec, isNot(contains('assets/ui/panels/')));
      expect(pubspec, isNot(contains('assets/ui/buttons/')));
      expect(pubspec, isNot(contains('assets/ui/badges/')));
      expect(pubspec, isNot(contains('assets/ui/decor/')));

      for (final path in const [
        'lib/ui/widgets/panel_card.dart',
        'lib/ui/widgets/ui_action_button.dart',
        'lib/ui/widgets/ui_stat_pill.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('flutter_svg')));
        expect(source, isNot(contains('SvgPicture')));
        expect(source, isNot(contains('ResilientSvgAsset')));
      }
    },
  );

  testWidgets('panel card keeps content above the decorative chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PanelCard(child: const SizedBox(width: 120, height: 80)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final panelSize = tester.getSize(
      find.byKey(const ValueKey('panel-card-fallback-shell')),
    );
    expect(panelSize.width, greaterThan(0));
    expect(panelSize.height, greaterThan(0));
  });

  testWidgets('ui action button keeps compact badge shell on success', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: UiActionButton(
              label: 'Buy',
              spec: spec,
              onPressed: () {},
              badge: '3',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byWidgetPredicate(_isSvgRuntimeWidget), findsNothing);

    final badgeSize = tester.getSize(
      find.byKey(const ValueKey('ui-action-button-badge-shell')),
    );
    expect(badgeSize.width, 28);
    expect(badgeSize.height, 28);

    final buttonRect = tester.getRect(
      find.byKey(const ValueKey('ui-action-button-fallback-shell')),
    );
    final badgeRect = tester.getRect(
      find.byKey(const ValueKey('ui-action-button-badge-shell')),
    );
    expect(badgeRect.top, closeTo(buttonRect.top + 6, 0.5));
    expect(badgeRect.right, closeTo(buttonRect.right - 8, 0.5));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('stat pill lays out safely inside a loose wrap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [UiStatPill(label: 'Fuel', value: '128', spec: spec)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byWidgetPredicate(_isSvgRuntimeWidget), findsNothing);

    final pillSize = tester.getSize(
      find.byKey(const ValueKey('ui-stat-pill-fallback-shell')),
    );
    expect(pillSize.width, greaterThan(0));
    expect(pillSize.height, greaterThan(0));
  });
}

bool _isSvgRuntimeWidget(Widget widget) {
  final typeName = widget.runtimeType.toString().toLowerCase();
  return typeName.contains('svg');
}
