import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/upgrades/upgrade_catalog.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/layout/responsive_layout_spec.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';
import 'modal_panel_frame.dart';

class ShopOverlay extends StatelessWidget {
  const ShopOverlay({
    required this.controller,
    required this.onClose,
    super.key,
  });

  final GameController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      key: const ValueKey('shop-overlay-root'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spec = ResponsiveLayoutSpec.fromSize(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          final modalConstraints = spec.modalConstraints(
            heightFactor: spec.isCompactHeight ? 0.88 : 0.8,
          );
          return Align(
            alignment: spec.isCompactHeight
                ? Alignment.bottomCenter
                : Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(spec.pagePadding),
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return ConstrainedBox(
                    constraints: modalConstraints,
                    child: ModalPanelFrame(
                      key: const ValueKey('shop-modal-panel'),
                      padding: EdgeInsets.all(spec.modalPadding),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  strings.shopTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              IconButton(
                                onPressed: onClose,
                                icon: const FaIcon(DonerIcons.close),
                                tooltip: strings.closeLabel,
                              ),
                            ],
                          ),
                          SizedBox(height: spec.isCompactHeight ? 6 : 8),
                          Expanded(
                            child: Scrollbar(
                              child: ListView(
                                physics: const ClampingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                padding: EdgeInsets.zero,
                                children: [
                                  Text(
                                    strings.upgradesTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(height: spec.inlineGap),
                                  for (final upgrade in controller.upgrades)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: spec.inlineGap,
                                      ),
                                      child: _UpgradeCard(
                                        controller: controller,
                                        upgrade: upgrade,
                                        spec: spec,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.controller,
    required this.upgrade,
    required this.spec,
  });

  final GameController controller;
  final UpgradeDefinition upgrade;
  final ResponsiveLayoutSpec spec;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final state = controller.state.upgrade(upgrade.id);
    final totalLevel = upgrade.totalLevelForPosition(
      itemIndex: state.itemIndex,
      itemLevel: state.level,
    );
    final maxed = upgrade.isMaxLevel(totalLevel);
    final cost = upgrade.costForLevel(totalLevel);
    final canAfford = !maxed && controller.state.cash >= cost;

    return DecoratedBox(
      key: ValueKey('shop-upgrade-card-${upgrade.id.key}'),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6D2B17).withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(spec.isCompactHeight ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.upgradeName(upgrade.id),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              strings.upgradeItemName(
                upgrade.id,
                upgrade.itemForLevel(totalLevel).key,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              strings.upgradeDescription(upgrade.id),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: spec.inlineGap),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: Size.fromHeight(spec.actionButtonHeight),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: canAfford
                    ? () => controller.buyUpgrade(upgrade.id)
                    : null,
                child: Text(
                  maxed
                      ? strings.maxedLabel
                      : '${strings.buyLabel} ${formatCompactNumber(context, cost)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
