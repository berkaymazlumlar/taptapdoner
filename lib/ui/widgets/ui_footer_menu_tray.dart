import 'package:flutter/material.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
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
  final FaIconData icon;
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF61150E).withValues(alpha: 0.80),
              const Color(0xFF4B0E0A).withValues(alpha: 0.74),
              const Color(0xFF3A0B08).withValues(alpha: 0.68),
            ],
          ),
          border: Border.all(
            color: DonerColors.borderPrimary.withValues(alpha: 0.58),
            width: 1.35,
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
                            Colors.white.withValues(alpha: 0.05),
                            Colors.transparent,
                            RoastedColors.surfaceContainerLowest.withValues(
                              alpha: 0.08,
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
    final iconColor = enabled
        ? selected
              ? DonerColors.creamText
              : DonerColors.bodyText
        : RoastedColors.onTertiaryFixedVariant.withValues(alpha: 0.82);

    final shellGradient = enabled
        ? selected
              ? [
                  const Color(0xFFB24F1B).withValues(alpha: 0.82),
                  DonerColors.panelSecondary.withValues(alpha: 0.76),
                ]
              : [
                  DonerColors.panelSecondary.withValues(alpha: 0.74),
                  DonerColors.panelPrimary.withValues(alpha: 0.68),
                ]
        : [
            DonerColors.panelDark.withValues(alpha: 0.52),
            DonerColors.disabledBg.withValues(alpha: 0.46),
          ];

    final shellShadow = [
      BoxShadow(
        color: RoastedColors.onSurface.withValues(
          alpha: selected ? 0.10 : 0.06,
        ),
        blurRadius: selected ? 16 : 12,
        offset: const Offset(0, 5),
      ),
      if (selected)
        BoxShadow(
          color: DonerColors.goldPrimary.withValues(alpha: 0.18),
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
      label: item.label,
      selected: item.selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashFactory: InkRipple.splashFactory,
          onTap: item.onPressed,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          customBorder: RoundedRectangleBorder(borderRadius: itemRadius),
          child: AnimatedScale(
            scale: _pressed && enabled ? 0.97 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    key: ValueKey(
                      'ui-footer-menu-tray-segment-shell-${widget.index}',
                    ),
                    decoration: BoxDecoration(
                      borderRadius: itemRadius,
                      gradient: LinearGradient(
                        colors: shellGradient,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: shellShadow,
                      border: Border.all(
                        color: selected
                            ? DonerColors.goldPrimary.withValues(alpha: 0.54)
                            : DonerColors.borderSoft.withValues(alpha: 0.42),
                      ),
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
                            Colors.white.withValues(alpha: 0.05),
                            Colors.transparent,
                            RoastedColors.surfaceContainerLowest.withValues(
                              alpha: 0.08,
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
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _ShinyFooterIconShell(
                        key: ValueKey(
                          'ui-footer-menu-tray-icon-shell-${widget.index}',
                        ),
                        icon: item.icon,
                        iconColor: iconColor,
                        selected: selected,
                        enabled: enabled,
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
                                          DonerColors.goldBright,
                                          DonerColors.orangeAccent,
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
                                    color: RoastedColors.onSurface.withValues(
                                      alpha: 0.12,
                                    ),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  item.badge!,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: enabled
                                            ? Colors.white
                                            : RoastedColors
                                                  .onTertiaryFixedVariant
                                                  .withValues(alpha: 0.88),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.1,
                                        fontFamily:
                                            RoastedTypography.bodyFontFamily,
                                      ),
                                ),
                              ),
                            ),
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
    );
  }
}

class _ShinyFooterIconShell extends StatelessWidget {
  const _ShinyFooterIconShell({
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.enabled,
    super.key,
  });

  static const _ringWidth = 3.5;
  static const _innerSize = RoastedFooterTrayMetrics.itemShellSize;
  static const _outerSize = _innerSize + (_ringWidth * 2);

  final FaIconData icon;
  final Color iconColor;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final innerGradient = selected
        ? const RadialGradient(
            center: Alignment(-0.34, -0.40),
            radius: 1.05,
            colors: [Color(0xFF178F86), Color(0xFF114641), Color(0xFF160605)],
            stops: [0.0, 0.58, 1.0],
          )
        : const RadialGradient(
            center: Alignment(-0.34, -0.40),
            radius: 1.05,
            colors: [Color(0xFF7A2B18), Color(0xFF34100C), Color(0xFF160605)],
            stops: [0.0, 0.62, 1.0],
          );

    return SizedBox.square(
      dimension: _outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  const Color(0xFFFFF3B0).withValues(alpha: enabled ? 1 : 0.46),
                  DonerColors.goldBright.withValues(alpha: enabled ? 1 : 0.50),
                  DonerColors.orangeAccent.withValues(
                    alpha: enabled ? 0.92 : 0.42,
                  ),
                  const Color(
                    0xFF7A3A0B,
                  ).withValues(alpha: enabled ? 0.88 : 0.38),
                  DonerColors.goldPrimary.withValues(
                    alpha: enabled ? 0.96 : 0.44,
                  ),
                  const Color(0xFFFFF3B0).withValues(alpha: enabled ? 1 : 0.46),
                ],
                stops: const [0, 0.18, 0.38, 0.58, 0.78, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: DonerColors.goldPrimary.withValues(
                    alpha: selected ? 0.34 : 0.18,
                  ),
                  blurRadius: selected ? 14 : 9,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: 2,
            left: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: enabled ? 0.58 : 0.18),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: _innerSize,
            height: _innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: innerGradient,
              border: Border.all(
                color: Colors.black.withValues(alpha: selected ? 0.14 : 0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: RoastedColors.onSurface.withValues(
                    alpha: selected ? 0.14 : 0.10,
                  ),
                  blurRadius: selected ? 12 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: FaIcon(
                icon,
                size: RoastedFooterTrayMetrics.itemIconSize,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
