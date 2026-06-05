import 'package:flutter/material.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

enum UiCircularActionButtonTone { primary, secondary, neutral }

class UiCircularActionButton extends StatefulWidget {
  const UiCircularActionButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.label,
    this.badge,
    this.selected = false,
    this.tone = UiCircularActionButtonTone.neutral,
    this.diameter = 60,
    this.iconSize,
    this.showLabel = true,
  });

  final FaIconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final String? badge;
  final bool selected;
  final UiCircularActionButtonTone tone;
  final double diameter;
  final double? iconSize;
  final bool showLabel;

  @override
  State<UiCircularActionButton> createState() => _UiCircularActionButtonState();
}

class _UiCircularActionButtonState extends State<UiCircularActionButton> {
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
    final enabled = widget.onPressed != null;
    final isPrimaryTone = widget.tone == UiCircularActionButtonTone.primary;
    final isSecondaryTone = widget.tone == UiCircularActionButtonTone.secondary;
    final pressedPrimary = enabled && isPrimaryTone && _pressed;
    final selectedPrimary = enabled && isPrimaryTone && widget.selected;

    final diameter = widget.diameter.clamp(48, 84).toDouble();
    final iconSize = widget.iconSize ?? (diameter * 0.42);

    final colors = enabled
        ? pressedPrimary
              ? const [
                  RoastedColors.primaryFixedDim,
                  RoastedColors.primaryContainer,
                ]
              : selectedPrimary
              ? const [RoastedColors.primary, RoastedColors.primaryContainer]
              : isPrimaryTone
              ? const [RoastedColors.primaryFixed, RoastedColors.primary]
              : isSecondaryTone
              ? const [
                  RoastedColors.secondaryContainer,
                  RoastedColors.secondaryContainer,
                ]
              : const [
                  RoastedColors.surfaceContainerHigh,
                  RoastedColors.surfaceContainerHighest,
                ]
        : const [
            RoastedColors.tertiaryFixedDim,
            RoastedColors.tertiaryContainer,
          ];

    final foregroundColor = enabled
        ? pressedPrimary || selectedPrimary || isPrimaryTone
              ? RoastedColors.onPrimaryFixed
              : isSecondaryTone
              ? RoastedColors.onSecondaryContainer
              : RoastedColors.onSurface
        : RoastedColors.onTertiaryFixedVariant;
    final labelColor = enabled
        ? isPrimaryTone || selectedPrimary
              ? RoastedColors.onPrimaryFixed
              : isSecondaryTone
              ? RoastedColors.onSecondaryContainer
              : RoastedColors.onSurface
        : RoastedColors.onTertiaryFixedVariant.withValues(alpha: 0.78);
    final badgeTextColor = enabled
        ? Colors.white
        : RoastedColors.onTertiaryFixedVariant.withValues(alpha: 0.88);

    final label = widget.label;
    final content = AnimatedScale(
      scale: _pressed && enabled ? 0.95 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: DecoratedBox(
                key: const ValueKey('ui-circular-action-button-fallback-shell'),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: RoastedColors.onSurface.withValues(
                        alpha: enabled ? 0.10 : 0.14,
                      ),
                      blurRadius: pressedPrimary ? 14 : 20,
                      offset: Offset(0, pressedPrimary ? 4 : 10),
                    ),
                    if (enabled && (selectedPrimary || isPrimaryTone))
                      BoxShadow(
                        color: RoastedColors.primary.withValues(alpha: 0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (pressedPrimary)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            key: const ValueKey(
                              'ui-circular-action-button-pressed-inset-shell',
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.04),
                                  Colors.transparent,
                                  RoastedColors.onPrimaryFixedVariant
                                      .withValues(alpha: 0.18),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(
                                  alpha: RoastedOpacity.gloss,
                                ),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: FaIcon(
                        widget.icon,
                        size: iconSize,
                        color: foregroundColor,
                      ),
                    ),
                    if (widget.badge != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: SizedBox(
                          key: const ValueKey(
                            'ui-circular-action-button-badge-shell',
                          ),
                          width: 20,
                          height: 20,
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
                                  color: RoastedColors.onSurface.withValues(
                                    alpha: 0.14,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.badge!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: badgeTextColor,
                                      fontSize: 9,
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
            ),
          ),
          if (widget.showLabel && label != null && label.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                fontFamily: RoastedTypography.bodyFontFamily,
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashFactory: InkRipple.splashFactory,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          child: content,
        ),
      ),
    );
  }
}
