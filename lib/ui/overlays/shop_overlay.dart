import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/domain/stations/station_catalog.dart';
import 'package:taptapdoner/domain/stations/upgrade_catalog.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/layout/responsive_layout_spec.dart';
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
                                icon: const Icon(Icons.close),
                                tooltip: strings.closeLabel,
                              ),
                            ],
                          ),
                          SizedBox(height: spec.isCompactHeight ? 6 : 8),
                          Expanded(
                            child: Scrollbar(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  Text(
                                    strings.stationsTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(height: spec.inlineGap),
                                  for (final station in controller.stations)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom: spec.inlineGap,
                                      ),
                                      child: _StationCard(
                                        controller: controller,
                                        station: station,
                                        spec: spec,
                                      ),
                                    ),
                                  SizedBox(height: spec.sectionGap),
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

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.controller,
    required this.station,
    required this.spec,
  });

  final GameController controller;
  final StationDefinition station;
  final ResponsiveLayoutSpec spec;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final unlocked = controller.isStationUnlocked(station.id);
    final stationState = controller.state.station(station.id);
    final cost = controller.stationCost(station.id);
    final canAfford = unlocked && controller.state.cash >= cost;
    final stationIncome = controller.stationIncomePerSecond(station.id);

    return DecoratedBox(
      key: ValueKey('shop-station-card-${station.id.key}'),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFFFF6E7) : const Color(0xFFF2E6D6),
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
              strings.stationName(station.id),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              strings.stationDescription(station.id),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: spec.inlineGap,
              runSpacing: spec.inlineGap,
              children: [
                Chip(
                  label: Text(
                    '${strings.levelLabel} ${stationState.level}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    '${formatCompactDecimal(context, stationIncome)}/s',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!unlocked)
                  Chip(
                    label: Text(
                      strings.lockedUntil(
                        formatCompactNumber(
                          context,
                          station.unlockAtLifetimeCash,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
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
                    ? () => controller.buyStation(station.id)
                    : null,
                child: Text(
                  unlocked
                      ? '${strings.buyLabel} ${formatCompactNumber(context, cost)}'
                      : strings.lockedLabel,
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
    final canAfford = !state.purchased && controller.state.cash >= upgrade.cost;

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
                  state.purchased
                      ? strings.boughtLabel
                      : '${strings.buyLabel} ${formatCompactNumber(context, upgrade.cost)}',
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
