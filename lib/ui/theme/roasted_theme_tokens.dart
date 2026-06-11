import 'package:flutter/material.dart';

abstract final class DonerTypography {
  static const logoFontFamily = 'Plus Jakarta Sans';
  static const displayFontFamily = 'Plus Jakarta Sans';
  static const bodyFontFamily = 'Be Vietnam Pro';

  static TextStyle logo(TextStyle? textStyle) {
    return _withFamily(textStyle, logoFontFamily);
  }

  static TextStyle display(TextStyle? textStyle) {
    return _withFamily(textStyle, displayFontFamily);
  }

  static TextStyle body(TextStyle? textStyle) {
    return _withFamily(textStyle, bodyFontFamily);
  }

  static TextTheme bodyTextTheme(TextTheme textTheme) {
    return textTheme.apply(fontFamily: bodyFontFamily);
  }

  static TextStyle _withFamily(TextStyle? textStyle, String fontFamily) {
    return (textStyle ?? const TextStyle()).copyWith(fontFamily: fontFamily);
  }
}

abstract final class DonerColors {
  static const bgPrimary = Color(0xFF160605);
  static const bgSecondary = Color(0xFF220907);

  static const panelPrimary = Color(0xFF4A0F0B);
  static const panelSecondary = Color(0xFF5C140E);
  static const panelDark = Color(0xFF34100C);

  static const borderPrimary = Color(0xFF8A3A1E);
  static const borderSoft = Color(0xFF6E2617);

  static const goldPrimary = Color(0xFFE8B35A);
  static const goldBright = Color(0xFFF6C66B);

  static const creamText = Color(0xFFF6E6CB);
  static const bodyText = Color(0xFFE2C7A3);
  static const mutedText = Color(0xFFB98E72);

  static const tealPrimary = Color(0xFF138E88);
  static const tealBright = Color(0xFF1EB5AE);

  static const orangeAccent = Color(0xFFD97A24);

  static const disabledBg = Color(0xFF5A4339);
  static const disabledText = Color(0xFFBBA08F);
}

abstract final class DonerGradients {
  static const screen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF240805), Color(0xFF1A0605), Color(0xFF140403)],
  );

  static const header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF61150E), Color(0xFF4B0E0A), Color(0xFF3A0B08)],
  );

  static const card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C140E), Color(0xFF42100B)],
  );

  static const sheet = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5C140E), Color(0xFF34100C), Color(0xFF1A0605)],
  );

  static const activeButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFC56A1D), Color(0xFFA64713), Color(0xFF7F260F)],
  );

  static const disabledButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5C4638), Color(0xFF4A362C)],
  );

  static const turbo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFB5541A), Color(0xFF8A2F12)],
  );
}

abstract final class DonerRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 9999;
}

abstract final class DonerSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class DonerShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x59000000), blurRadius: 14, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> goldGlow = [
    BoxShadow(color: Color(0x2EE8B35A), blurRadius: 10),
  ];

  static const List<BoxShadow> tealGlow = [
    BoxShadow(color: Color(0x2E138E88), blurRadius: 8),
  ];

  static const List<BoxShadow> redGlow = [
    BoxShadow(color: Color(0x40D97A24), blurRadius: 12),
  ];
}

abstract final class RoastedTypography {
  static const headlineFontFamily = DonerTypography.displayFontFamily;
  static const bodyFontFamily = DonerTypography.bodyFontFamily;
}

abstract final class RoastedColors {
  static const background = DonerColors.bgPrimary;
  static const surface = DonerColors.bgPrimary;
  static const surfaceDim = DonerColors.bgSecondary;
  static const surfaceContainerLowest = Color(0xFF250806);
  static const surfaceContainerLow = DonerColors.panelDark;
  static const surfaceContainer = DonerColors.panelPrimary;
  static const surfaceContainerHigh = DonerColors.panelSecondary;
  static const surfaceContainerHighest = Color(0xFF6A1A10);
  static const surfaceBright = Color(0xFF752217);
  static const outline = DonerColors.borderPrimary;
  static const outlineVariant = DonerColors.borderSoft;

  static const primary = DonerColors.goldPrimary;
  static const primaryContainer = DonerColors.orangeAccent;
  static const primaryFixed = DonerColors.goldBright;
  static const primaryFixedDim = DonerColors.goldPrimary;
  static const onPrimary = Color(0xFF34100C);
  static const onPrimaryContainer = DonerColors.creamText;
  static const onPrimaryFixed = Color(0xFF34100C);
  static const onPrimaryFixedVariant = Color(0xFF5A260F);

  static const secondary = DonerColors.orangeAccent;
  static const secondaryContainer = Color(0xFF7A2B18);
  static const secondaryFixed = Color(0xFFFFD0A3);
  static const secondaryFixedDim = DonerColors.goldPrimary;
  static const onSecondary = DonerColors.creamText;
  static const onSecondaryContainer = DonerColors.goldBright;
  static const onSecondaryFixed = DonerColors.creamText;
  static const onSecondaryFixedVariant = DonerColors.bodyText;

  static const tertiary = DonerColors.tealPrimary;
  static const tertiaryContainer = Color(0xFF0B5B58);
  static const tertiaryFixed = DonerColors.tealBright;
  static const tertiaryFixedDim = DonerColors.tealPrimary;
  static const onTertiary = DonerColors.creamText;
  static const onTertiaryContainer = DonerColors.creamText;
  static const onTertiaryFixed = DonerColors.creamText;
  static const onTertiaryFixedVariant = DonerColors.disabledText;

  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);
  static const onError = Color(0xFF690005);
  static const onErrorContainer = Color(0xFFFFDAD6);

  static const inverseSurface = DonerColors.creamText;
  static const inverseOnSurface = DonerColors.panelDark;
  static const inversePrimary = Color(0xFF9A4C17);
  static const onSurface = DonerColors.creamText;
  static const onSurfaceVariant = DonerColors.bodyText;
}

abstract final class RoastedRadii {
  static const double chip = DonerRadius.md;
  static const double card = DonerRadius.lg;
  static const double pill = DonerRadius.pill;
}

abstract final class RoastedShadows {
  static const List<BoxShadow> surface = [
    BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(color: Color(0x2EE8B35A), blurRadius: 18, offset: Offset(0, 4)),
  ];
}

abstract final class RoastedOpacity {
  static const ghostEdge = 0.15;
  static const gloss = 0.10;
  static const ambientShadow = 0.24;
}

abstract final class RoastedFooterTrayMetrics {
  static const double height = 76;
  static const double radius = 24;
  static const double itemShellSize = 42;
  static const double itemIconSize = 22;
  static const double badgeSize = 16;
}
