import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/ui/layout/responsive_layout_spec.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'modal_panel_frame.dart';

class SettingsOverlay extends StatelessWidget {
  const SettingsOverlay({
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
        key: const ValueKey('settings-overlay-root'),
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
                        key: const ValueKey('settings-modal-panel'),
                        padding: EdgeInsets.all(spec.modalPadding),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.settingsTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              SizedBox(height: spec.sectionGap),
                              Text(
                                strings.languageTitle,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: spec.inlineGap,
                                runSpacing: spec.inlineGap,
                                children: [
                                  ChoiceChip(
                                    label: Text(strings.englishLabel),
                                    selected:
                                        controller.state.localeCode == 'en',
                                    onSelected: (_) =>
                                        controller.setLocaleCode('en'),
                                  ),
                                  ChoiceChip(
                                    label: Text(strings.turkishLabel),
                                    selected:
                                        controller.state.localeCode == 'tr',
                                    onSelected: (_) =>
                                        controller.setLocaleCode('tr'),
                                  ),
                                ],
                              ),
                              SizedBox(height: spec.sectionGap),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const FaIcon(DonerIcons.sound),
                                title: Text(
                                  strings.soundSoonLabel,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const FaIcon(DonerIcons.haptics),
                                title: Text(
                                  strings.hapticsSoonLabel,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: spec.inlineGap),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton(
                                  onPressed: onClose,
                                  child: Text(strings.closeLabel),
                                ),
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
