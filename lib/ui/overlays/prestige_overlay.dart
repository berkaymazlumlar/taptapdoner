import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/layout/responsive_layout_spec.dart';
import 'modal_panel_frame.dart';

class PrestigeOverlay extends StatelessWidget {
  const PrestigeOverlay({
    required this.controller,
    required this.onClose,
    super.key,
  });

  final GameController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: SafeArea(
        key: const ValueKey('prestige-overlay-root'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spec = ResponsiveLayoutSpec.fromSize(
              Size(constraints.maxWidth, constraints.maxHeight),
            );
            final modalConstraints = spec.modalConstraints(
              heightFactor: spec.isCompactHeight ? 0.88 : 0.76,
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
                        key: const ValueKey('prestige-modal-panel'),
                        padding: EdgeInsets.all(spec.modalPadding),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.prestigeTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              SizedBox(height: spec.sectionGap),
                              Text(
                                strings.prestigeConfirm,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                strings.prestigeAvailable(
                                  controller.availablePrestigePoints,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFF8C2F12),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                strings.prestigeHint,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: spec.sectionGap),
                              if (spec.isNarrowWidth)
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    OutlinedButton(
                                      onPressed: onClose,
                                      child: Text(strings.closeLabel),
                                    ),
                                    SizedBox(height: spec.inlineGap),
                                    FilledButton(
                                      onPressed:
                                          controller.availablePrestigePoints > 0
                                          ? () async {
                                              await controller.applyPrestige();
                                              onClose();
                                            }
                                          : null,
                                      child: Text(strings.prestigeNavLabel),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: onClose,
                                        child: Text(strings.closeLabel),
                                      ),
                                    ),
                                    SizedBox(width: spec.inlineGap),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed:
                                            controller.availablePrestigePoints >
                                                0
                                            ? () async {
                                                await controller
                                                    .applyPrestige();
                                                onClose();
                                              }
                                            : null,
                                        child: Text(strings.prestigeNavLabel),
                                      ),
                                    ),
                                  ],
                                ),
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
