import 'package:flutter/material.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';
import 'package:taptapdoner/ui/widgets/ui_footer_menu_tray.dart';

enum GameBottomNavTab {
  kitchen,
  shop,
  branches,
  collection,
  prestige,
  goals,
  chests,
}

class GameBottomNavBar extends StatelessWidget {
  const GameBottomNavBar({
    required this.activeTab,
    required this.onOpenKitchen,
    required this.onOpenShop,
    required this.onOpenBranches,
    required this.onOpenCollection,
    required this.onOpenPrestige,
    super.key,
  });

  final GameBottomNavTab activeTab;
  final VoidCallback onOpenKitchen;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenBranches;
  final VoidCallback onOpenCollection;
  final VoidCallback onOpenPrestige;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final items = <UiFooterMenuTrayItem>[
      UiFooterMenuTrayItem(
        key: const ValueKey('bottom-nav-kitchen-button'),
        icon: DonerIcons.kitchen,
        label: strings.isTurkish ? 'MUTFAK' : 'Kitchen',
        selected: activeTab == GameBottomNavTab.kitchen,
        onPressed: onOpenKitchen,
      ),
      UiFooterMenuTrayItem(
        key: const ValueKey('bottom-nav-shop-button'),
        icon: DonerIcons.shop,
        label: strings.isTurkish ? 'DÜKKÂN' : strings.shopNavLabel,
        selected: activeTab == GameBottomNavTab.shop,
        onPressed: onOpenShop,
      ),
      UiFooterMenuTrayItem(
        key: const ValueKey('bottom-nav-branches-button'),
        icon: DonerIcons.branch,
        label: strings.isTurkish ? 'ŞUBE' : 'Branches',
        selected: activeTab == GameBottomNavTab.branches,
        onPressed: onOpenBranches,
      ),
      UiFooterMenuTrayItem(
        key: const ValueKey('bottom-nav-collection-button'),
        icon: DonerIcons.collection,
        label: strings.isTurkish ? 'KOLEKSİYON' : 'Collection',
        selected: activeTab == GameBottomNavTab.collection,
        onPressed: onOpenCollection,
      ),
      UiFooterMenuTrayItem(
        key: const ValueKey('bottom-nav-prestige-button'),
        icon: DonerIcons.prestige,
        label: strings.prestigeNavLabel,
        selected: activeTab == GameBottomNavTab.prestige,
        onPressed: onOpenPrestige,
      ),
    ];

    return Container(
      key: const ValueKey('bottom-nav-shell'),
      decoration: BoxDecoration(
        boxShadow: RoastedShadows.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RoastedFooterTrayMetrics.radius),
        ),
      ),
      child: UiFooterMenuTray(items: items),
    );
  }
}
