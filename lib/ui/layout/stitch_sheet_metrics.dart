import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

abstract final class StitchSheetMetrics {
  static const Size designSize = Size(390, 884);
  static const double designSheetWidth = 390;
  static const double designSheetHeight = 813;

  static double get sheetCornerRadius => RoastedRadii.card.r;
  static double get handleWidth => 48.w;
  static double get handleHeight => 5.h;
  static double get headerHorizontalPadding => 24.w;
  static double get headerTopPadding => 16.h;
  static double get contentHorizontalPadding => 24.w;
  static double get contentBottomPadding => 24.h;
  static double get titleGap => 4.h;
  static double get sectionGap => 16.h;
  static double get blockGap => 24.h;
  static double get chipGap => 12.w;
  static double get cardPadding => 16.w;
  static double get infoCardPadding => 20.w;
  static double get heroCardPadding => 32.w;
  static double get buttonHeight => 48.h;
  static double get buttonHeightLarge => 56.h;
  static double get buttonRadius => RoastedRadii.pill.r;
  static double get sheetMaxHeight => designSheetHeight.h;
  static double get sheetMaxWidth => designSheetWidth.w;
  static double get stationIconSize => 64.w;
  static double get rowIconSize => 56.w;
  static double get closeButtonSize => 40.w;
  static double get sectionLabelSize => 10.sp;
  static double get chipLabelSize => 10.sp;
  static double get chipValueSize => 14.sp;
  static double get headerTitleSize => 30.sp;
  static double get headerSubtitleSize => 12.sp;
  static double get prestigeTitleSize => 36.sp;
  static double get prestigeHeroValueSize => 48.sp;
  static double get infoTitleSize => 18.sp;
  static double get infoBodySize => 14.sp;
  static double get actionLabelSize => 16.sp;
  static double get bodySize => 14.sp;

  static BoxConstraints sheetConstraints(
    Size viewport, {
    double widthFactor = 1,
    double heightFactor = 0.95,
  }) {
    return BoxConstraints(
      maxWidth: math.min(viewport.width * widthFactor, sheetMaxWidth),
      maxHeight: math.min(viewport.height * heightFactor, sheetMaxHeight),
    );
  }

  static EdgeInsets sheetHorizontalInsets() {
    return EdgeInsets.symmetric(horizontal: contentHorizontalPadding);
  }

  static EdgeInsets sheetContentInsets() {
    return EdgeInsets.fromLTRB(
      contentHorizontalPadding,
      0,
      contentHorizontalPadding,
      contentBottomPadding,
    );
  }
}
