import 'package:flutter/material.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

class DonerPanel extends StatelessWidget {
  const DonerPanel({
    required this.child,
    super.key,
    this.padding,
    this.borderRadius,
    this.gradient = DonerGradients.card,
    this.borderColor = DonerColors.borderPrimary,
    this.shadow = DonerShadows.soft,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Gradient gradient;
  final Color borderColor;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(DonerRadius.lg);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ],
        ),
      ),
    );
  }
}

class DonerIconMedallion extends StatelessWidget {
  const DonerIconMedallion({
    required this.icon,
    super.key,
    this.size = 56,
    this.iconSize,
    this.backgroundColor = DonerColors.tealPrimary,
    this.iconColor = DonerColors.goldBright,
    this.borderColor = DonerColors.goldPrimary,
    this.disabled = false,
  });

  final FaIconData icon;
  final double size;
  final double? iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final Color borderColor;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled ? DonerColors.disabledBg : backgroundColor;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.96),
            color.withValues(alpha: 0.58),
          ],
        ),
        border: Border.all(
          color: disabled ? DonerColors.borderSoft : borderColor,
          width: 2,
        ),
        boxShadow: disabled ? null : DonerShadows.tealGlow,
      ),
      child: FaIcon(
        icon,
        size: iconSize ?? size * 0.46,
        color: disabled ? DonerColors.disabledText : iconColor,
      ),
    );
  }
}

class DonerStatCard extends StatelessWidget {
  const DonerStatCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
    this.iconColor = DonerColors.tealPrimary,
    this.minHeight = 62,
    this.compact = false,
  });

  final FaIconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final double minHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 18.0 : 21.0;
    return DonerPanel(
      borderColor: DonerColors.borderSoft,
      shadow: const [
        BoxShadow(
          color: Color(0x3F000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      borderRadius: BorderRadius.circular(DonerRadius.md),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 8 : 10,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Row(
          children: [
            FaIcon(icon, size: iconSize, color: iconColor),
            SizedBox(width: compact ? 6 : 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: RoastedTypography.bodyFontFamily,
                      fontSize: compact ? 9 : 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                      height: 1,
                      color: DonerColors.bodyText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: RoastedTypography.headlineFontFamily,
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        height: 1,
                        color: DonerColors.creamText,
                      ),
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

class DonerSectionTitle extends StatelessWidget {
  const DonerSectionTitle({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lineColor = DonerColors.borderSoft.withValues(alpha: 0.62);
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: lineColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: FaIcon(
            DonerIcons.diamond,
            size: 10,
            color: DonerColors.tealBright,
          ),
        ),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontFamily: RoastedTypography.bodyFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: DonerColors.goldPrimary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: FaIcon(
            DonerIcons.diamond,
            size: 10,
            color: DonerColors.tealBright,
          ),
        ),
        Expanded(child: Container(height: 1, color: lineColor)),
      ],
    );
  }
}

class DonerLevelPill extends StatelessWidget {
  const DonerLevelPill({
    required this.label,
    super.key,
    this.highlighted = false,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted
            ? DonerColors.goldPrimary.withValues(alpha: 0.18)
            : const Color(0xFF6B210E),
        borderRadius: BorderRadius.circular(DonerRadius.pill),
        border: Border.all(color: DonerColors.borderPrimary),
        boxShadow: highlighted ? DonerShadows.goldGlow : null,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontFamily: RoastedTypography.bodyFontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          height: 1,
          color: highlighted ? DonerColors.goldBright : DonerColors.creamText,
        ),
      ),
    );
  }
}

class DonerGameButton extends StatelessWidget {
  const DonerGameButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 52,
    this.pill = false,
    this.highlighted = false,
    this.fontSize,
    this.iconSize,
    this.horizontalPadding,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
  final FaIconData? icon;
  final double height;
  final bool pill;
  final bool highlighted;
  final double? fontSize;
  final double? iconSize;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      pill ? DonerRadius.pill : DonerRadius.md,
    );
    final textColor = enabled
        ? DonerColors.creamText
        : DonerColors.disabledText;
    return Opacity(
      opacity: enabled ? 1 : 0.78,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashFactory: InkRipple.splashFactory,
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              gradient: enabled || highlighted
                  ? DonerGradients.activeButton
                  : DonerGradients.disabledButton,
              borderRadius: radius,
              border: Border.all(
                color: enabled
                    ? DonerColors.goldPrimary
                    : const Color(0xFF6B5447),
                width: enabled ? 1.5 : 1,
              ),
              boxShadow: enabled ? DonerShadows.goldGlow : null,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding ?? 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    FaIcon(
                      icon,
                      size: iconSize ?? 20,
                      color: enabled ? DonerColors.goldBright : textColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontFamily: RoastedTypography.bodyFontFamily,
                        fontSize: fontSize ?? 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        color: textColor,
                      ),
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

class DonerProgressBar extends StatelessWidget {
  const DonerProgressBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFF2A0A08),
        borderRadius: BorderRadius.circular(DonerRadius.pill),
        border: Border.all(color: DonerColors.borderPrimary),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DonerRadius.pill),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0).toDouble(),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [DonerColors.tealPrimary, DonerColors.tealBright],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
