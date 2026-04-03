import 'package:flutter/material.dart';

abstract final class RoastedTypography {
  static const headlineFontFamily = 'Plus Jakarta Sans';
  static const bodyFontFamily = 'Be Vietnam Pro';
}

abstract final class RoastedColors {
  static const background = Color(0xFF1F0F09);
  static const surface = Color(0xFF1F0F09);
  static const surfaceDim = Color(0xFF1F0F09);
  static const surfaceContainerLowest = Color(0xFF190A05);
  static const surfaceContainerLow = Color(0xFF291710);
  static const surfaceContainer = Color(0xFF2D1B14);
  static const surfaceContainerHigh = Color(0xFF39251E);
  static const surfaceContainerHighest = Color(0xFF453028);
  static const surfaceBright = Color(0xFF49342C);
  static const outline = Color(0xFF9F8E80);
  static const outlineVariant = Color(0xFF524439);

  static const primary = Color(0xFFE9C400);
  static const primaryContainer = Color(0xFFAE9200);
  static const primaryFixed = Color(0xFFFFE16D);
  static const primaryFixedDim = Color(0xFFE9C400);
  static const onPrimary = Color(0xFF3A3000);
  static const onPrimaryContainer = Color(0xFF362C00);
  static const onPrimaryFixed = Color(0xFF221B00);
  static const onPrimaryFixedVariant = Color(0xFF544600);

  static const secondary = Color(0xFFFFB870);
  static const secondaryContainer = Color(0xFF764400);
  static const secondaryFixed = Color(0xFFFFDCBE);
  static const secondaryFixedDim = Color(0xFFFFB870);
  static const onSecondary = Color(0xFF4A2800);
  static const onSecondaryContainer = Color(0xFFFBB46B);
  static const onSecondaryFixed = Color(0xFF2C1600);
  static const onSecondaryFixedVariant = Color(0xFF693C00);

  static const tertiary = Color(0xFFE0C0B4);
  static const tertiaryContainer = Color(0xFFAB8E83);
  static const tertiaryFixed = Color(0xFFFDDBD0);
  static const tertiaryFixedDim = Color(0xFFE0C0B4);
  static const onTertiary = Color(0xFF402C24);
  static const onTertiaryContainer = Color(0xFF3C2821);
  static const onTertiaryFixed = Color(0xFF291710);
  static const onTertiaryFixedVariant = Color(0xFF584239);

  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);
  static const onError = Color(0xFF690005);
  static const onErrorContainer = Color(0xFFFFDAD6);

  static const inverseSurface = Color(0xFFFDDBD0);
  static const inverseOnSurface = Color(0xFF402C24);
  static const inversePrimary = Color(0xFF705D00);
  static const onSurface = Color(0xFFFDDBD0);
  static const onSurfaceVariant = Color(0xFFD6C3B4);
}

abstract final class RoastedRadii {
  static const double chip = 32;
  static const double card = 48;
  static const double pill = 9999;
}

abstract final class RoastedShadows {
  static const List<BoxShadow> surface = [
    BoxShadow(color: Color(0x1AFDDBD0), blurRadius: 24, offset: Offset(0, 12)),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(color: Color(0x22E9C400), blurRadius: 18, offset: Offset(0, 4)),
  ];
}

abstract final class RoastedOpacity {
  static const ghostEdge = 0.15;
  static const gloss = 0.10;
  static const ambientShadow = 0.24;
}

abstract final class RoastedFooterTrayMetrics {
  static const double height = 84;
  static const double radius = 32;
  static const double itemShellSize = 42;
  static const double itemIconSize = 24;
  static const double badgeSize = 18;
}
