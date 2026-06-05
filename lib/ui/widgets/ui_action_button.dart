import 'package:flutter/material.dart';
import 'package:taptapdoner/ui/layout/responsive_layout_spec.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

enum UiActionButtonTone { primary, secondary }

class UiActionButton extends StatefulWidget {
  const UiActionButton({
    required this.label,
    required this.spec,
    super.key,
    this.icon,
    this.onPressed,
    this.tone = UiActionButtonTone.primary,
    this.badge,
    this.expand = false,
  });

  final String label;
  final FaIconData? icon;
  final VoidCallback? onPressed;
  final UiActionButtonTone tone;
  final String? badge;
  final ResponsiveLayoutSpec spec;
  final bool expand;

  @override
  State<UiActionButton> createState() => _UiActionButtonState();
}

class _UiActionButtonState extends State<UiActionButton> {
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
    final borderRadius = BorderRadius.circular(RoastedRadii.pill);
    final isPrimary = widget.tone == UiActionButtonTone.primary;
    final pressedPrimary = enabled && isPrimary && _pressed;

    final gradientColors = enabled
        ? pressedPrimary
              ? const [
                  RoastedColors.primaryFixedDim,
                  RoastedColors.primaryContainer,
                ]
              : isPrimary
              ? const [RoastedColors.primary, RoastedColors.primaryContainer]
              : const [
                  RoastedColors.secondaryContainer,
                  RoastedColors.secondaryContainer,
                ]
        : const [
            RoastedColors.tertiaryFixedDim,
            RoastedColors.tertiaryContainer,
          ];

    final foregroundColor = enabled
        ? isPrimary
              ? RoastedColors.onPrimaryFixed
              : RoastedColors.onSecondaryContainer
        : RoastedColors.onTertiaryFixedVariant;

    final button = Semantics(
      button: true,
      enabled: enabled,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: AnimatedScale(
          scale: _pressed && enabled ? 0.95 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                key: const ValueKey('ui-action-button-fallback-shell'),
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: enabled
                          ? RoastedColors.onSurface.withValues(
                              alpha: pressedPrimary ? 0.10 : 0.08,
                            )
                          : RoastedColors.surfaceContainerLowest.withValues(
                              alpha: 0.16,
                            ),
                      blurRadius: pressedPrimary ? 16 : 24,
                      offset: Offset(0, pressedPrimary ? 6 : 12),
                    ),
                    if (enabled && isPrimary && !pressedPrimary)
                      BoxShadow(
                        color: RoastedColors.primary.withValues(alpha: 0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashFactory: InkRipple.splashFactory,
                    onTap: widget.onPressed,
                    onTapDown: enabled ? (_) => _setPressed(true) : null,
                    onTapUp: enabled ? (_) => _setPressed(false) : null,
                    onTapCancel: enabled ? () => _setPressed(false) : null,
                    child: Stack(
                      children: [
                        if (pressedPrimary)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                key: const ValueKey(
                                  'ui-action-button-pressed-inset-shell',
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: borderRadius,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.04),
                                      Colors.transparent,
                                      RoastedColors.onPrimaryFixedVariant
                                          .withValues(alpha: 0.16),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.52, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: borderRadius,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: SizedBox(
                            height: widget.spec.actionButtonHeight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                if (widget.icon != null) ...[
                                  FaIcon(
                                    widget.icon,
                                    size: widget.spec.isCompactHeight ? 18 : 20,
                                    color: foregroundColor,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    widget.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: foregroundColor,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.3,
                                          fontFamily: RoastedTypography
                                              .headlineFontFamily,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.badge != null)
                Positioned(
                  top: 6,
                  right: 8,
                  child: SizedBox(
                    key: const ValueKey('ui-action-button-badge-shell'),
                    width: 28,
                    height: 28,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: enabled
                              ? const [Color(0xFFFFD77A), Color(0xFFC46A20)]
                              : const [
                                  RoastedColors.tertiaryFixedDim,
                                  RoastedColors.tertiaryContainer,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: enabled
                              ? const Color(0xFFFFF1C9).withValues(alpha: 0.44)
                              : RoastedColors.outlineVariant.withValues(
                                  alpha: 0.25,
                                ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: RoastedColors.onSurface.withValues(
                              alpha: 0.14,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.badge!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                fontFamily:
                                    RoastedTypography.headlineFontFamily,
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
    );

    if (widget.expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return SizedBox(width: widget.spec.actionButtonWidth, child: button);
  }
}
