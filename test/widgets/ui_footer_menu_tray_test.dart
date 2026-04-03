import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/ui_footer_menu_tray.dart';

void main() {
  testWidgets('footer tray keeps labels tappable and badges aligned', (
    tester,
  ) async {
    var shopTapped = 0;
    var prestigeTapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: UiFooterMenuTray(
                items: [
                  UiFooterMenuTrayItem(
                    icon: Icons.shopping_basket,
                    label: 'Shop',
                    badge: '2',
                    selected: true,
                    onPressed: () {
                      shopTapped++;
                    },
                  ),
                  UiFooterMenuTrayItem(
                    icon: Icons.workspace_premium,
                    label: 'Prestige',
                    onPressed: () {
                      prestigeTapped++;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final trayShell = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('ui-footer-menu-tray-fallback-shell')),
    );
    final trayDecoration = trayShell.decoration as BoxDecoration;
    expect(trayDecoration.borderRadius, isNotNull);
    expect(trayDecoration.boxShadow, isNotEmpty);

    final shopBadge = tester.getRect(
      find.byKey(const ValueKey('ui-footer-menu-tray-badge-shell-0')),
    );
    final shopIconShell = tester.getRect(
      find.byKey(const ValueKey('ui-footer-menu-tray-icon-shell-0')),
    );
    expect(shopBadge.right, greaterThan(shopIconShell.right - 2));
    expect(shopBadge.top, lessThan(shopIconShell.top + 4));

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    expect(shopTapped, 1);

    await tester.tap(find.text('Prestige'));
    await tester.pumpAndSettle();
    expect(prestigeTapped, 1);
  });

  testWidgets('disabled tray labels and icons dim coherently', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: UiFooterMenuTray(
                items: [
                  UiFooterMenuTrayItem(
                    icon: Icons.shopping_basket,
                    label: 'Shop',
                    onPressed: null,
                  ),
                  UiFooterMenuTrayItem(
                    icon: Icons.workspace_premium,
                    label: 'Prestige',
                    onPressed: null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(find.text('Shop'));
    final icon = tester.widget<Icon>(find.byIcon(Icons.shopping_basket));

    expect(
      label.style?.color,
      RoastedColors.onTertiaryFixedVariant.withValues(alpha: 0.76),
    );
    expect(
      icon.color,
      RoastedColors.onTertiaryFixedVariant.withValues(alpha: 0.82),
    );
  });
}
