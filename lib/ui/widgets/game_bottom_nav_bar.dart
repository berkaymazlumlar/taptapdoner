import 'package:flutter/material.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/ui_footer_menu_tray.dart';

enum GameBottomNavTab { kitchen, shop, prestige }

class GameBottomNavBar extends StatelessWidget {
  const GameBottomNavBar({
    required this.activeTab,
    required this.onOpenKitchen,
    required this.onOpenShop,
    required this.onOpenPrestige,
    super.key,
  });

  final GameBottomNavTab activeTab;
  final VoidCallback onOpenKitchen;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenPrestige;

  @override
  Widget build(BuildContext context) {
    final items = <UiFooterMenuTrayItem>[
      UiFooterMenuTrayItem(
        key: const ValueKey('bottom-nav-kitchen-button'),
        icon: Icons.restaurant_rounded,
        label: 'Kitchen',
        selected: activeTab == GameBottomNavTab.kitchen,
        onPressed: onOpenKitchen,
      ),
      UiFooterMenuTrayItem(
        key: const ValueKey('bottom-nav-shop-button'),
        icon: Icons.storefront_rounded,
        label: 'Shop',
        selected: activeTab == GameBottomNavTab.shop,
        onPressed: onOpenShop,
      ),
      UiFooterMenuTrayItem(
        key: const ValueKey('bottom-nav-prestige-button'),
        icon: Icons.workspace_premium_rounded,
        label: 'Prestige',
        selected: activeTab == GameBottomNavTab.prestige,
        onPressed: onOpenPrestige,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        key: const ValueKey('bottom-nav-shell'),
        decoration: BoxDecoration(
          boxShadow: RoastedShadows.surface,
          borderRadius: BorderRadius.circular(RoastedFooterTrayMetrics.radius),
        ),
        child: UiFooterMenuTray(items: items),
      ),
    );
  }
}
