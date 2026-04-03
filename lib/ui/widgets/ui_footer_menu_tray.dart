import 'package:flutter/material.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

class UiFooterMenuTrayItem {
  const UiFooterMenuTrayItem({
    this.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge,
    this.selected = false,
    this.enabled = true,
  });

  final Key? key;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? badge;
  final bool selected;
  final bool enabled;
}

class UiFooterMenuTray extends StatelessWidget {
  const UiFooterMenuTray({
    required this.items,
    super.key,
    this.height = RoastedFooterTrayMetrics.height,
  });

  final List<UiFooterMenuTrayItem> items;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RoastedFooterTrayMetrics.radius);
    final hasItems = items.isNotEmpty;

    return Semantics(
      container: true,
      label: 'Footer tray',
      child: DecoratedBox(
        key: const ValueKey('ui-footer-menu-tray-fallback-shell'),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            colors: [
              RoastedColors.surfaceContainerLow,
              RoastedColors.surfaceContainer,
              RoastedColors.surfaceContainerHigh,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.52, 1.0],
          ),
          border: Border.all(
            color: RoastedColors.outlineVariant.withValues(
              alpha: RoastedOpacity.ghostEdge,
            ),
          ),
          boxShadow: RoastedShadows.surface,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(
                              alpha: RoastedOpacity.gloss,
                            ),
                            Colors.transparent,
                            RoastedColors.surfaceContainerLowest.withValues(
                              alpha: 0.12,
                            ),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.42, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          Expanded(
                          child: _UiFooterMenuTraySegment(
                            key: items[index].key,
                            item: items[index],
                            index: index,
                            isLast: index == items.length - 1,
                            ),
                          ),
                          if (index != items.length - 1)
                            _UiFooterMenuTrayDivider(
                              height: height,
                              key: ValueKey(
                                'ui-footer-menu-tray-divider-$index',
                              ),
                            ),
                        ],
                        if (!hasItems) const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UiFooterMenuTrayDivider extends StatelessWidget {
  const _UiFooterMenuTrayDivider({required this.height, super.key});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 1,
        height: height * 0.46,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: RoastedColors.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}

class _UiFooterMenuTraySegment extends StatefulWidget {
  const _UiFooterMenuTraySegment({
    required this.item,
    required this.index,
    required this.isLast,
    super.key,
  });

  final UiFooterMenuTrayItem item;
  final int index;
  final bool isLast;

  @override
  State<_UiFooterMenuTraySegment> createState() =>
      _UiFooterMenuTraySegmentState();
}

class _UiFooterMenuTraySegmentState extends State<_UiFooterMenuTraySegment> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final enabled = item.enabled && item.onPressed != null;
    final selected = enabled && item.selected;
    final labelColor = enabled
        ? selected
              ? RoastedColors.onPrimaryFixed
              : RoastedColors.onSurface
        : RoastedColors.onTertiaryFixedVariant.withValues(alpha: 0.76);
    final iconColor = enabled
        ? selected
              ? RoastedColors.onPrimaryFixed
              : RoastedColors.onSurface
        : RoastedColors.onTertiaryFixedVariant.withValues(alpha: 0.82);

    final shellGradient = enabled
        ? selected
              ? const [
                  RoastedColors.primaryFixed,
                  RoastedColors.primaryContainer,
                ]
              : const [
                  RoastedColors.surfaceContainerHigh,
                  RoastedColors.surfaceContainerHighest,
                ]
        : const [
            RoastedColors.surfaceContainerLow,
            RoastedColors.surfaceContainerHigh,
          ];

    final shellShadow = [
      BoxShadow(
        color: RoastedColors.onSurface.withValues(
          alpha: selected ? 0.12 : 0.08,
        ),
        blurRadius: selected ? 16 : 12,
        offset: const Offset(0, 5),
      ),
      if (selected)
        BoxShadow(
          color: RoastedColors.primary.withValues(alpha: 0.16),
          blurRadius: 18,
          offset: const Offset(0, 3),
        ),
    ];

    final itemRadius = BorderRadius.horizontal(
      left: widget.index == 0
          ? const Radius.circular(RoastedFooterTrayMetrics.radius)
          : Radius.zero,
      right: widget.isLast
          ? const Radius.circular(RoastedFooterTrayMetrics.radius)
          : Radius.zero,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      selected: item.selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onPressed,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          customBorder: RoundedRectangleBorder(borderRadius: itemRadius),
          child: AnimatedScale(
            scale: _pressed && enabled ? 0.97 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: itemRadius,
                        gradient: LinearGradient(
                          colors: shellGradient,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: shellShadow,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: itemRadius,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(
                                alpha: RoastedOpacity.gloss,
                              ),
                              Colors.transparent,
                              RoastedColors.surfaceContainerLowest.withValues(
                                alpha: 0.12,
                              ),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              key: ValueKey(
                                'ui-footer-menu-tray-icon-shell-${widget.index}',
                              ),
                              width: RoastedFooterTrayMetrics.itemShellSize,
                              height: RoastedFooterTrayMetrics.itemShellSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: selected
                                      ? const [
                                          RoastedColors.primary,
                                          RoastedColors.primaryContainer,
                                        ]
                                      : const [
                                          RoastedColors.surfaceContainerHighest,
                                          RoastedColors.surfaceBright,
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: selected
                                      ? RoastedColors.primaryFixed.withValues(
                                          alpha: 0.26,
                                        )
                                      : RoastedColors.outlineVariant.withValues(
                                          alpha: 0.18,
                                        ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: RoastedColors.onSurface.withValues(
                                      alpha: selected ? 0.14 : 0.10,
                                    ),
                                    blurRadius: selected ? 12 : 8,
                                    offset: const Offset(0, 3),
                                  ),
                                  if (selected)
                                    BoxShadow(
                                      color: RoastedColors.primary.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                size: RoastedFooterTrayMetrics.itemIconSize,
                                color: iconColor,
                              ),
                            ),
                            if (item.badge != null)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: SizedBox(
                                  key: ValueKey(
                                    'ui-footer-menu-tray-badge-shell-${widget.index}',
                                  ),
                                  width: RoastedFooterTrayMetrics.badgeSize,
                                  height: RoastedFooterTrayMetrics.badgeSize,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: enabled
                                            ? const [
                                                Color(0xFFFFD77A),
                                                Color(0xFFC46A20),
                                              ]
                                            : const [
                                                RoastedColors.tertiaryFixedDim,
                                                RoastedColors.tertiaryContainer,
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: RoastedColors.onSurface
                                              .withValues(alpha: 0.12),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.badge!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: enabled
                                                  ? Colors.white
                                                  : RoastedColors
                                                        .onTertiaryFixedVariant
                                                        .withValues(
                                                          alpha: 0.88,
                                                        ),
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.1,
                                              fontFamily: RoastedTypography
                                                  .bodyFontFamily,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: labelColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                                fontFamily: RoastedTypography.bodyFontFamily,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
