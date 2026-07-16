import 'package:flutter/material.dart';
import 'package:taptapdoner/app/game_controller.dart';
import 'package:taptapdoner/l10n/app_strings.dart';
import 'package:taptapdoner/l10n/locale_case.dart';
import 'package:taptapdoner/ui/layout/responsive_layout_spec.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

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
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: DonerGradients.sheet),
      child: SafeArea(
        key: const ValueKey('settings-overlay-root'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spec = ResponsiveLayoutSpec.fromSize(
              Size(constraints.maxWidth, constraints.maxHeight),
            );
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return _SettingsPanel(
                  spec: spec,
                  strings: strings,
                  localeCode: controller.state.localeCode,
                  onLocaleSelected: controller.setLocaleCode,
                  onClose: onClose,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.spec,
    required this.strings,
    required this.localeCode,
    required this.onLocaleSelected,
    required this.onClose,
  });

  final ResponsiveLayoutSpec spec;
  final AppStrings strings;
  final String localeCode;
  final ValueChanged<String> onLocaleSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('settings-page-root'),
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.center,
                  colors: [
                    DonerColors.goldBright.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: SingleChildScrollView(
            key: const ValueKey('settings-page-scroll'),
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              spec.pagePadding,
              spec.pagePadding + 4,
              spec.pagePadding,
              spec.pagePadding + 20,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                key: const ValueKey('settings-page-content'),
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsHeader(strings: strings, onClose: onClose),
                    SizedBox(height: spec.sectionGap + 4),
                    _SectionLabel(
                      icon: DonerIcons.info,
                      label: strings.languageTitle,
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: _LanguageOption(
                            code: 'TR',
                            label: strings.turkishLabel,
                            selected: localeCode == 'tr',
                            onTap: () => onLocaleSelected('tr'),
                          ),
                        ),
                        SizedBox(width: spec.inlineGap),
                        Expanded(
                          child: _LanguageOption(
                            code: 'EN',
                            label: strings.englishLabel,
                            selected: localeCode == 'en',
                            onTap: () => onLocaleSelected('en'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spec.sectionGap + 6),
                    Divider(
                      height: 1,
                      color: DonerColors.borderSoft.withValues(alpha: 0.7),
                    ),
                    SizedBox(height: spec.sectionGap + 5),
                    _SectionLabel(
                      icon: DonerIcons.settings,
                      label: strings.preferencesTitle,
                    ),
                    const SizedBox(height: 9),
                    _ComingSoonTile(
                      icon: DonerIcons.sound,
                      title: strings.soundTitle,
                      description: strings.soundSoonLabel,
                      badge: strings.comingSoonLabel,
                    ),
                    SizedBox(height: spec.inlineGap),
                    _ComingSoonTile(
                      icon: DonerIcons.haptics,
                      title: strings.hapticsTitle,
                      description: strings.hapticsSoonLabel,
                      badge: strings.comingSoonLabel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.strings, required this.onClose});

  final AppStrings strings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: DonerColors.goldPrimary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(DonerRadius.md),
            border: Border.all(
              color: DonerColors.goldPrimary.withValues(alpha: 0.32),
            ),
          ),
          alignment: Alignment.center,
          child: const FaIcon(
            DonerIcons.settings,
            size: 21,
            color: DonerColors.goldBright,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.settingsTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: DonerColors.creamText,
                  fontWeight: FontWeight.w900,
                  fontFamily: DonerTypography.displayFontFamily,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                strings.settingsSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: DonerColors.mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const ValueKey('settings-header-close-button'),
          onPressed: onClose,
          tooltip: strings.closeLabel,
          style: IconButton.styleFrom(
            backgroundColor: DonerColors.panelDark,
            foregroundColor: DonerColors.bodyText,
            side: const BorderSide(color: DonerColors.borderSoft),
          ),
          icon: const FaIcon(DonerIcons.close, size: 17),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final FaIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, size: 12, color: DonerColors.goldPrimary),
        const SizedBox(width: 7),
        Text(
          label.toLocaleUpperCase(context),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DonerColors.goldBright,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.25,
          ),
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? DonerColors.tealBright
        : DonerColors.borderSoft;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? DonerColors.tealPrimary.withValues(alpha: 0.22)
              : DonerColors.panelDark.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(DonerRadius.md),
          border: Border.all(color: borderColor),
          boxShadow: selected ? DonerShadows.tealGlow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DonerRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected
                          ? DonerColors.tealBright
                          : RoastedColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(DonerRadius.xs),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      code,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected
                            ? DonerColors.panelDark
                            : DonerColors.bodyText,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? DonerColors.creamText
                            : DonerColors.bodyText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 4),
                    const FaIcon(
                      DonerIcons.selected,
                      size: 17,
                      color: DonerColors.tealBright,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
  });

  final FaIconData icon;
  final String title;
  final String description;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(DonerRadius.md),
        border: Border.all(color: DonerColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: DonerColors.panelDark,
                borderRadius: BorderRadius.circular(DonerRadius.sm),
                border: Border.all(
                  color: DonerColors.borderPrimary.withValues(alpha: 0.72),
                ),
              ),
              alignment: Alignment.center,
              child: FaIcon(icon, size: 16, color: DonerColors.mutedText),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: DonerColors.creamText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DonerColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: DonerColors.orangeAccent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(DonerRadius.pill),
                border: Border.all(
                  color: DonerColors.orangeAccent.withValues(alpha: 0.42),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                child: Text(
                  badge.toLocaleUpperCase(context),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DonerColors.goldBright,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
