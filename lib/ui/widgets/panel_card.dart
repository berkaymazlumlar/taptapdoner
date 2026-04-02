import 'package:flutter/material.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

class PanelCard extends StatelessWidget {
  const PanelCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderRadius = RoastedRadii.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final baseColor = backgroundColor ?? RoastedColors.surfaceContainer;
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: RoastedShadows.surface),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          key: const ValueKey('panel-card-fallback-shell'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [baseColor, RoastedColors.surfaceContainerHigh],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 1.0],
            ),
            borderRadius: radius,
            border: Border.all(
              color: RoastedColors.outlineVariant.withValues(
                alpha: RoastedOpacity.ghostEdge,
              ),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const ValueKey('panel-card-inset-glow-shell'),
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        colors: [
                          RoastedColors.primaryFixed.withValues(alpha: 0.14),
                          Colors.transparent,
                          RoastedColors.surfaceContainerLowest.withValues(
                            alpha: 0.16,
                          ),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.44, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
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
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.55],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}
