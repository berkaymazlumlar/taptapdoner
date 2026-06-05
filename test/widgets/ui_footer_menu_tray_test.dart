import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/ui_footer_menu_tray.dart';

void main() {
  testWidgets('footer tray keeps icon actions tappable and badges aligned', (
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
                    key: const ValueKey('shop-footer-action'),
                    icon: DonerIcons.shop,
                    label: 'Shop',
                    badge: '2',
                    selected: true,
                    onPressed: () {
                      shopTapped++;
                    },
                  ),
                  UiFooterMenuTrayItem(
                    key: const ValueKey('prestige-footer-action'),
                    icon: DonerIcons.prestige,
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
    expect(find.text('Shop'), findsNothing);
    expect(find.text('Prestige'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shop-footer-action')));
    await tester.pumpAndSettle();
    expect(shopTapped, 1);

    await tester.tap(find.byKey(const ValueKey('prestige-footer-action')));
    await tester.pumpAndSettle();
    expect(prestigeTapped, 1);
  });

  testWidgets('disabled tray icons dim coherently', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: UiFooterMenuTray(
                items: [
                  UiFooterMenuTrayItem(
                    icon: DonerIcons.shop,
                    label: 'Shop',
                    onPressed: null,
                  ),
                  UiFooterMenuTrayItem(
                    icon: DonerIcons.prestige,
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

    final icon = tester.widget<FaIcon>(
      find.byWidgetPredicate(
        (widget) => widget is FaIcon && widget.icon == DonerIcons.shop.data,
      ),
    );

    expect(find.text('Shop'), findsNothing);
    expect(
      icon.color,
      RoastedColors.onTertiaryFixedVariant.withValues(alpha: 0.82),
    );
  });
}
