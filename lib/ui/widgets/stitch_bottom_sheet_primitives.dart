import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taptapdoner/l10n/locale_case.dart';
import 'package:taptapdoner/ui/layout/stitch_sheet_metrics.dart';
import 'package:taptapdoner/ui/theme/doner_icons.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

enum StitchSheetActionTone { primary, secondary, subtle }

enum StitchSheetHeaderAlignment { leading, centered }

class StitchBottomSheetSurface extends StatelessWidget {
  const StitchBottomSheetSurface({
    required this.child,
    super.key,
    this.maxWidth,
    this.maxHeight,
    this.margin = EdgeInsets.zero,
    this.backgroundGradient,
    this.shadowColor,
    this.borderRadius,
    this.alignment = Alignment.bottomCenter,
    this.showBorder = true,
    this.showShadow = true,
  });

  final Widget child;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsetsGeometry margin;
  final Gradient? backgroundGradient;
  final Color? shadowColor;
  final BorderRadius? borderRadius;
  final AlignmentGeometry alignment;
  final bool showBorder;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ??
        BorderRadius.vertical(
          top: Radius.circular(StitchSheetMetrics.sheetCornerRadius),
        );

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final sheetConstraints = StitchSheetMetrics.sheetConstraints(
            viewport,
            widthFactor: maxWidth == null
                ? 1
                : math.min(maxWidth! / viewport.width, 1),
            heightFactor: maxHeight == null
                ? 0.95
                : math.min(maxHeight! / viewport.height, 1),
          );
          final effectiveWidth = maxWidth == null
              ? sheetConstraints.maxWidth
              : math.min(maxWidth!, viewport.width);
          final effectiveHeight = maxHeight == null
              ? sheetConstraints.maxHeight
              : math.min(maxHeight!, viewport.height);

          return Align(
            alignment: alignment,
            child: Padding(
              padding: margin,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: effectiveWidth,
                  maxHeight: effectiveHeight,
                ),
                child: SizedBox(
                  width: effectiveWidth,
                  height: effectiveHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: backgroundGradient ?? DonerGradients.sheet,
                      border: showBorder
                          ? Border.all(
                              color: DonerColors.borderPrimary.withValues(
                                alpha: 0.78,
                              ),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: showShadow
                          ? [
                              BoxShadow(
                                color: (shadowColor ?? Colors.black).withValues(
                                  alpha: 0.38,
                                ),
                                blurRadius: 32,
                                offset: const Offset(0, -10),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(borderRadius: radius, child: child),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class StitchSheetHandle extends StatelessWidget {
  const StitchSheetHandle({super.key, this.color = DonerColors.goldPrimary});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 16.h, bottom: 10.h),
        child: Container(
          width: StitchSheetMetrics.handleWidth,
          height: StitchSheetMetrics.handleHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
      ),
    );
  }
}

class StitchSheetCloseButton extends StatelessWidget {
  const StitchSheetCloseButton({
    super.key,
    required this.onPressed,
    this.icon = DonerIcons.close,
    this.backgroundColor = RoastedColors.surfaceContainerHigh,
    this.iconColor = RoastedColors.onSurface,
  });

  final VoidCallback onPressed;
  final FaIconData icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          splashFactory: InkRipple.splashFactory,
          onTap: onPressed,
          radius: StitchSheetMetrics.closeButtonSize / 2,
          splashColor: RoastedColors.primary.withValues(alpha: 0.08),
          child: Container(
            width: StitchSheetMetrics.closeButtonSize,
            height: StitchSheetMetrics.closeButtonSize,
            decoration: BoxDecoration(
              color: backgroundColor,
              gradient: DonerGradients.activeButton,
              shape: BoxShape.circle,
              border: Border.all(color: DonerColors.goldPrimary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: DonerColors.orangeAccent.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: FaIcon(icon, size: 22.r, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class StitchSheetHeader extends StatelessWidget {
  const StitchSheetHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
    super.key,
    this.alignment = StitchSheetHeaderAlignment.leading,
    this.titleColor = RoastedColors.primary,
    this.subtitleColor = RoastedColors.secondaryFixedDim,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.centerTitleKey,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;
  final StitchSheetHeaderAlignment alignment;
  final Color titleColor;
  final Color subtitleColor;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final Key? centerTitleKey;

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        titleTextStyle ??
        Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontFamily: RoastedTypography.headlineFontFamily,
          fontWeight: FontWeight.w800,
          letterSpacing: alignment == StitchSheetHeaderAlignment.centered
              ? 0
              : 1.8,
          color: titleColor,
          fontSize: alignment == StitchSheetHeaderAlignment.centered
              ? StitchSheetMetrics.prestigeTitleSize
              : StitchSheetMetrics.headerTitleSize,
        );
    final subtitleStyle =
        subtitleTextStyle ??
        Theme.of(context).textTheme.labelLarge?.copyWith(
          fontFamily: RoastedTypography.bodyFontFamily,
          fontWeight: FontWeight.w700,
          letterSpacing: alignment == StitchSheetHeaderAlignment.centered
              ? 2.0
              : 2.4,
          color: subtitleColor,
          fontSize: StitchSheetMetrics.headerSubtitleSize,
        );

    if (alignment == StitchSheetHeaderAlignment.centered) {
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  key: centerTitleKey,
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                SizedBox(height: StitchSheetMetrics.titleGap),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: StitchSheetCloseButton(onPressed: onClose),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toLocaleUpperCase(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              SizedBox(height: StitchSheetMetrics.titleGap),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: subtitleStyle,
              ),
            ],
          ),
        ),
        SizedBox(width: StitchSheetMetrics.chipGap),
        StitchSheetCloseButton(onPressed: onClose),
      ],
    );
  }
}

class StitchSheetSectionDivider extends StatelessWidget {
  const StitchSheetSectionDivider({
    required this.label,
    super.key,
    this.labelColor = RoastedColors.secondary,
  });

  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final lineColor = DonerColors.borderSoft.withValues(alpha: 0.62);
    return Row(
      children: [
        Expanded(
          child: Container(height: 1.h, color: lineColor),
        ),
        Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  FaIcon(
                    DonerIcons.diamond,
                    size: 9.r,
                    color: DonerColors.tealBright,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    label.toLocaleUpperCase(context),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: RoastedTypography.bodyFontFamily,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                      color: DonerColors.goldPrimary,
                      fontSize: StitchSheetMetrics.sectionLabelSize,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  FaIcon(
                    DonerIcons.diamond,
                    size: 9.r,
                    color: DonerColors.tealBright,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1.h, color: lineColor),
        ),
      ],
    );
  }
}

class StitchStatChip extends StatelessWidget {
  const StitchStatChip({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
    this.iconColor = RoastedColors.primary,
    this.backgroundColor = RoastedColors.surfaceContainerHighest,
    this.valueColor = RoastedColors.onSurface,
  });

  final FaIconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color backgroundColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.72),
        ),
        boxShadow: RoastedShadows.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 20.r, color: iconColor),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toLocaleUpperCase(context),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontFamily: RoastedTypography.bodyFontFamily,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: RoastedColors.onSurfaceVariant.withValues(alpha: 0.72),
                  fontSize: StitchSheetMetrics.chipLabelSize,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontFamily: RoastedTypography.headlineFontFamily,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  fontSize: StitchSheetMetrics.chipValueSize,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StitchSurfaceCard extends StatelessWidget {
  const StitchSurfaceCard({
    required this.child,
    super.key,
    this.backgroundColor = RoastedColors.surfaceContainerHigh,
    this.borderRadius,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final Color backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(RoastedRadii.card.r);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        gradient: DonerGradients.card,
        borderRadius: radius,
        border: Border.all(
          color: DonerColors.borderSoft.withValues(alpha: 0.72),
        ),
        boxShadow: RoastedShadows.surface,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(StitchSheetMetrics.cardPadding),
        child: child,
      ),
    );

    if (onTap == null) {
      return content;
    }

    return _PressableSurface(
      borderRadius: radius,
      onTap: onTap!,
      child: content,
    );
  }
}

class StitchActionButton extends StatelessWidget {
  const StitchActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.tone = StitchSheetActionTone.primary,
    this.icon,
    this.expand = false,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final StitchSheetActionTone tone;
  final FaIconData? icon;
  final bool expand;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? StitchSheetMetrics.buttonHeight;
    final child = _ActionButtonVisual(
      label: label,
      tone: tone,
      icon: icon,
      height: buttonHeight,
    );

    final button = _PressableSurface(
      borderRadius: BorderRadius.circular(StitchSheetMetrics.buttonRadius),
      onTap: onPressed,
      child: child,
    );

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}

class StitchProgressBar extends StatelessWidget {
  const StitchProgressBar({
    required this.labelLeft,
    required this.labelRight,
    required this.value,
    super.key,
    this.backgroundColor = RoastedColors.surfaceContainerLowest,
    this.fillColor = RoastedColors.primary,
    this.secondaryFillColor = RoastedColors.secondary,
  }) : assert(value >= 0 && value <= 1);

  final String labelLeft;
  final String labelRight;
  final double value;
  final Color backgroundColor;
  final Color fillColor;
  final Color secondaryFillColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              labelLeft,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
                color: RoastedColors.outlineVariant,
                fontSize: 10.sp,
              ),
            ),
            Text(
              labelRight,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFamily: RoastedTypography.bodyFontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
                color: RoastedColors.secondary,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          height: 12.h,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: RoastedColors.outlineVariant.withValues(alpha: 0.20),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [fillColor, secondaryFillColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: fillColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 0),
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

class _ActionButtonVisual extends StatelessWidget {
  const _ActionButtonVisual({
    required this.label,
    required this.tone,
    this.icon,
    required this.height,
  });

  final String label;
  final StitchSheetActionTone tone;
  final FaIconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isPrimary = tone == StitchSheetActionTone.primary;
    final isSecondary = tone == StitchSheetActionTone.secondary;
    final background = isPrimary
        ? DonerGradients.activeButton
        : isSecondary
        ? DonerGradients.secondaryAction
        : null;

    final textColor = isPrimary
        ? DonerColors.creamText
        : isSecondary
        ? DonerColors.creamText
        : RoastedColors.onSurface;

    final borderColor = isPrimary
        ? DonerColors.goldPrimary.withValues(alpha: 0.72)
        : isSecondary
        ? DonerColors.goldPrimary.withValues(alpha: 0.46)
        : DonerColors.borderSoft.withValues(alpha: 0.50);

    return Container(
      constraints: BoxConstraints(minHeight: height),
      decoration: BoxDecoration(
        gradient: background,
        color: tone == StitchSheetActionTone.subtle
            ? DonerColors.panelPrimary
            : null,
        borderRadius: BorderRadius.circular(StitchSheetMetrics.buttonRadius),
        border: Border.all(color: borderColor),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: RoastedColors.primary.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : RoastedShadows.surface,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              FaIcon(icon, size: 18.r, color: textColor),
              SizedBox(width: 8.w),
            ],
            Flexible(
              child: Text(
                label.toLocaleUpperCase(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontFamily: RoastedTypography.bodyFontFamily,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: textColor,
                  fontSize: StitchSheetMetrics.actionLabelSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableSurface extends StatefulWidget {
  const _PressableSurface({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  @override
  State<_PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<_PressableSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) {
              setState(() {
                _pressed = true;
              });
            },
      onTapCancel: widget.onTap == null
          ? null
          : () {
              if (mounted) {
                setState(() {
                  _pressed = false;
                });
              }
            },
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              if (mounted) {
                setState(() {
                  _pressed = false;
                });
              }
            },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
