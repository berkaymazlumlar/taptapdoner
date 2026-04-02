import 'package:flutter/material.dart';
import 'package:taptapdoner/ui/layout/responsive_layout_spec.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

class UiStatPill extends StatelessWidget {
  const UiStatPill({
    required this.label,
    required this.value,
    required this.spec,
    super.key,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;
  final ResponsiveLayoutSpec spec;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RoastedRadii.chip);
    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        key: const ValueKey('ui-stat-pill-fallback-shell'),
        decoration: BoxDecoration(
          borderRadius: radius,
          color: RoastedColors.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: RoastedColors.onSurface.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: RoastedOpacity.gloss),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0x24E9C400),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: RoastedColors.primaryFixed,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: RoastedColors.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                                fontSize: spec.statLabelSize,
                                letterSpacing: 1.05,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: RoastedColors.tertiary,
                                fontWeight: FontWeight.w900,
                                fontSize: spec.statValueSize,
                                fontFamily:
                                    RoastedTypography.headlineFontFamily,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
