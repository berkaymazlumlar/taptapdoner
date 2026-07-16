import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/ui_circular_action_button.dart';

void main() {
  testWidgets('footer-style circular actions support tap and badge layout', (
    tester,
  ) async {
    var tapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UiCircularActionButton(
                  icon: DonerIcons.shop,
                  label: 'Shop',
                  badge: '2',
                  selected: true,
                  onPressed: () {
                    tapped++;
                  },
                  tone: UiCircularActionButtonTone.secondary,
                ),
                const SizedBox(width: 12),
                UiCircularActionButton(
                  icon: DonerIcons.prestige,
                  label: 'Prestige',
                  onPressed: () {
                    tapped += 10;
                  },
                  tone: UiCircularActionButtonTone.neutral,
                ),
                const SizedBox(width: 12),
                UiCircularActionButton(
                  icon: DonerIcons.goals,
                  label: 'Goals',
                  badge: '1',
                  selected: true,
                  onPressed: () {
                    tapped += 100;
                  },
                  tone: UiCircularActionButtonTone.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shopShell = tester.getRect(
      find
          .byKey(const ValueKey('ui-circular-action-button-fallback-shell'))
          .at(0),
    );
    final shopBadge = tester.getRect(
      find.byKey(const ValueKey('ui-circular-action-button-badge-shell')).at(0),
    );
    expect(shopBadge.right, closeTo(shopShell.right - 6, 0.5));
    expect(shopBadge.top, closeTo(shopShell.top + 6, 0.5));

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    expect(tapped, 1);

    await tester.tap(
      find
          .byKey(const ValueKey('ui-circular-action-button-fallback-shell'))
          .at(2),
    );
    await tester.pumpAndSettle();
    expect(tapped, 101);

    final enabledText = tester.widget<Text>(find.text('Prestige'));
    expect(enabledText.style?.color, RoastedColors.onSurface);
  });

  testWidgets('disabled circular action labels dim coherently', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: UiCircularActionButton(
              icon: DonerIcons.prestige,
              label: 'Prestige',
              badge: '3',
              tone: UiCircularActionButtonTone.secondary,
              onPressed: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(find.text('Prestige'));
    final badge = tester.widget<Text>(find.text('3'));
    final shell = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('ui-circular-action-button-fallback-shell')),
    );

    expect(
      label.style?.color,
      RoastedColors.onTertiaryFixedVariant.withValues(alpha: 0.78),
    );
    expect(
      badge.style?.color,
      RoastedColors.onTertiaryFixedVariant.withValues(alpha: 0.88),
    );
    expect((shell.decoration as BoxDecoration).shape, BoxShape.circle);
  });

  testWidgets('primary circular action button sinks on press', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: UiCircularActionButton(
              icon: DonerIcons.goals,
              label: 'Goals',
              tone: UiCircularActionButtonTone.primary,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final center = tester.getCenter(
      find.byKey(const ValueKey('ui-circular-action-button-fallback-shell')),
    );
    final gesture = await tester.startGesture(center);
    await tester.pump();

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 0.95);

    final shell = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('ui-circular-action-button-fallback-shell')),
    );
    final decoration = shell.decoration as BoxDecoration;
    expect(
      (decoration.gradient as LinearGradient).colors.first,
      RoastedColors.primaryFixedDim,
    );
    expect(
      find.byKey(
        const ValueKey('ui-circular-action-button-pressed-inset-shell'),
      ),
      findsOneWidget,
    );

    await gesture.up();
  });
}
