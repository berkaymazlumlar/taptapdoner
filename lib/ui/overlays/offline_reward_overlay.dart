import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/services/ads/rewarded_ad_service.dart';
import 'package:taptapdoner/ui/layout/responsive_layout_spec.dart';
import 'package:taptapdoner/ui/widgets/value_formatters.dart';
import 'modal_panel_frame.dart';

class OfflineRewardOverlay extends StatelessWidget {
  const OfflineRewardOverlay({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.5),
      child: SafeArea(
        key: const ValueKey('offline-reward-overlay-root'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spec = ResponsiveLayoutSpec.fromSize(
              Size(constraints.maxWidth, constraints.maxHeight),
            );
            final modalConstraints = spec.modalConstraints(
              heightFactor: spec.isCompactHeight ? 0.9 : 0.78,
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
                        key: const ValueKey('offline-reward-modal-panel'),
                        backgroundColor: const Color(0xFFFFD889),
                        padding: EdgeInsets.all(spec.modalPadding),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.offlineTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              SizedBox(height: spec.sectionGap),
                              Text(
                                strings.offlineSummary(24),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                strings.offlineAmount(
                                  formatCompactNumber(
                                    context,
                                    controller.state.pendingOfflineCash,
                                  ),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: const Color(0xFF8C2F12),
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              if (!controller.canDoubleOfflineReward) ...[
                                const SizedBox(height: 10),
                                Text(
                                  strings.adUnavailable,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              SizedBox(height: spec.sectionGap),
                              if (spec.isNarrowWidth)
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    OutlinedButton(
                                      onPressed:
                                          controller.dismissOfflineReward,
                                      child: Text(strings.dismissLabel),
                                    ),
                                    SizedBox(height: spec.inlineGap),
                                    FilledButton(
                                      onPressed: controller.claimOfflineReward,
                                      child: Text(strings.claimLabel),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed:
                                            controller.dismissOfflineReward,
                                        child: Text(strings.dismissLabel),
                                      ),
                                    ),
                                    SizedBox(width: spec.inlineGap),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed:
                                            controller.claimOfflineReward,
                                        child: Text(strings.claimLabel),
                                      ),
                                    ),
                                  ],
                                ),
                              if (controller.canDoubleOfflineReward) ...[
                                SizedBox(height: spec.inlineGap),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                    onPressed: () async {
                                      final result = await controller
                                          .claimOfflineRewardWithAd();
                                      if (context.mounted &&
                                          result != RewardOutcome.granted &&
                                          result != RewardOutcome.declined) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              strings.adUnavailable,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      strings.claimDoubleLabel,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
