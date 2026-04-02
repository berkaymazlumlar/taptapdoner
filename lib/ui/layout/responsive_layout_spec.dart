import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class ResponsiveLayoutSpec {
  const ResponsiveLayoutSpec({
    required this.viewport,
    required this.pagePadding,
    required this.sectionGap,
    required this.maxContentWidth,
    required this.headerHeight,
    required this.actionDockHeight,
    required this.tapPanelWidth,
    required this.tapMedallionSize,
    required this.tapPanelPadding,
    required this.tapTitleSize,
    required this.tapValueSize,
    required this.actionButtonHeight,
    required this.actionButtonWidth,
    required this.inlineGap,
    required this.statValueSize,
    required this.statLabelSize,
    required this.panelRadius,
    required this.modalWidth,
    required this.modalMaxHeight,
    required this.modalPadding,
    required this.isCompactHeight,
    required this.isNarrowWidth,
  });

  factory ResponsiveLayoutSpec.fromSize(Size size) {
    final width = size.width;
    final height = size.height;
    final shortestSide = math.min(width, height);
    final isCompactHeight = height < 760;
    final isNarrowWidth = width < 380;
    final pagePadding = _clamp(width * 0.082, isCompactHeight ? 24 : 28, 32);
    final sectionGap = _clamp(
      height * 0.01,
      isCompactHeight ? 8 : 10,
      isCompactHeight ? 14 : 16,
    );
    final maxContentWidth = math.min(width - (pagePadding * 2), 326.0);
    final headerHeight = _clamp(height * 0.167, 140, 152);
    final actionDockHeight = _clamp(height * 0.286, 240, 262);
    final tapPanelWidth = math.min(
      maxContentWidth,
      _clamp(width * 0.8, 240, 390),
    );
    final tapMedallionSize = _clamp(
      shortestSide * 0.3,
      isCompactHeight ? 104 : 122,
      198,
    );
    final tapPanelPadding = _clamp(
      shortestSide * 0.045,
      isCompactHeight ? 14 : 18,
      isCompactHeight ? 24 : 28,
    );
    final tapTitleSize = _clamp(
      shortestSide * 0.05,
      isCompactHeight ? 14 : 16,
      24,
    );
    final tapValueSize = _clamp(
      shortestSide * 0.068,
      isCompactHeight ? 22 : 24,
      36,
    );
    final actionButtonHeight = _clamp(
      height * 0.062,
      isCompactHeight ? 42 : 52,
      isCompactHeight ? 56 : 66,
    );
    final actionButtonWidth = isNarrowWidth
        ? math.max(120.0, (maxContentWidth - 12) / 2)
        : math.max(124.0, (maxContentWidth - 16) / 3);
    final inlineGap = isNarrowWidth ? 6.0 : 10.0;
    final statValueSize = _clamp(
      shortestSide * 0.028,
      isCompactHeight ? 11 : 13,
      18,
    );
    final statLabelSize = _clamp(
      shortestSide * 0.023,
      isCompactHeight ? 9 : 10,
      13,
    );
    final panelRadius = _clamp(shortestSide * 0.055, 22, 34);
    final modalWidth = math.min(
      maxContentWidth,
      _clamp(width * 0.92, 280, 540),
    );
    final modalMaxHeight = height * (isCompactHeight ? 0.82 : 0.74);
    final modalPadding = _clamp(
      shortestSide * 0.04,
      isCompactHeight ? 12 : 16,
      24,
    );

    return ResponsiveLayoutSpec(
      viewport: size,
      pagePadding: pagePadding,
      sectionGap: sectionGap,
      maxContentWidth: maxContentWidth,
      headerHeight: headerHeight,
      actionDockHeight: actionDockHeight,
      tapPanelWidth: tapPanelWidth,
      tapMedallionSize: tapMedallionSize,
      tapPanelPadding: tapPanelPadding,
      tapTitleSize: tapTitleSize,
      tapValueSize: tapValueSize,
      actionButtonHeight: actionButtonHeight,
      actionButtonWidth: actionButtonWidth,
      inlineGap: inlineGap,
      statValueSize: statValueSize,
      statLabelSize: statLabelSize,
      panelRadius: panelRadius,
      modalWidth: modalWidth,
      modalMaxHeight: modalMaxHeight,
      modalPadding: modalPadding,
      isCompactHeight: isCompactHeight,
      isNarrowWidth: isNarrowWidth,
    );
  }

  factory ResponsiveLayoutSpec.fromContext(BuildContext context) {
    return ResponsiveLayoutSpec.fromSize(MediaQuery.sizeOf(context));
  }

  final Size viewport;
  final double pagePadding;
  final double sectionGap;
  final double maxContentWidth;
  final double headerHeight;
  final double actionDockHeight;
  final double tapPanelWidth;
  final double tapMedallionSize;
  final double tapPanelPadding;
  final double tapTitleSize;
  final double tapValueSize;
  final double actionButtonHeight;
  final double actionButtonWidth;
  final double inlineGap;
  final double statValueSize;
  final double statLabelSize;
  final double panelRadius;
  final double modalWidth;
  final double modalMaxHeight;
  final double modalPadding;
  final bool isCompactHeight;
  final bool isNarrowWidth;

  BoxConstraints modalConstraints({double? maxWidth, double? heightFactor}) {
    return BoxConstraints(
      maxWidth: maxWidth ?? modalWidth,
      maxHeight: modalMaxHeight * (heightFactor ?? 1),
    );
  }

  static double _clamp(num value, double min, double max) {
    return value.toDouble().clamp(min, max);
  }
}
