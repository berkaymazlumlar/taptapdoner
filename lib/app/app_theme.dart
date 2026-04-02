import 'package:flutter/material.dart';
import 'package:taptapdoner/ui/theme/roasted_theme_tokens.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.dark().copyWith(
    primary: RoastedColors.primary,
    onPrimary: RoastedColors.onPrimary,
    primaryContainer: RoastedColors.primaryContainer,
    onPrimaryContainer: RoastedColors.onPrimaryContainer,
    primaryFixed: RoastedColors.primaryFixed,
    primaryFixedDim: RoastedColors.primaryFixedDim,
    onPrimaryFixed: RoastedColors.onPrimaryFixed,
    onPrimaryFixedVariant: RoastedColors.onPrimaryFixedVariant,
    secondary: RoastedColors.secondary,
    onSecondary: RoastedColors.onSecondary,
    secondaryContainer: RoastedColors.secondaryContainer,
    onSecondaryContainer: RoastedColors.onSecondaryContainer,
    secondaryFixed: RoastedColors.secondaryFixed,
    secondaryFixedDim: RoastedColors.secondaryFixedDim,
    onSecondaryFixed: RoastedColors.onSecondaryFixed,
    onSecondaryFixedVariant: RoastedColors.onSecondaryFixedVariant,
    tertiary: RoastedColors.tertiary,
    onTertiary: RoastedColors.onTertiary,
    tertiaryContainer: RoastedColors.tertiaryContainer,
    onTertiaryContainer: RoastedColors.onTertiaryContainer,
    tertiaryFixed: RoastedColors.tertiaryFixed,
    tertiaryFixedDim: RoastedColors.tertiaryFixedDim,
    onTertiaryFixed: RoastedColors.onTertiaryFixed,
    onTertiaryFixedVariant: RoastedColors.onTertiaryFixedVariant,
    error: RoastedColors.error,
    onError: RoastedColors.onError,
    errorContainer: RoastedColors.errorContainer,
    onErrorContainer: RoastedColors.onErrorContainer,
    surface: RoastedColors.surface,
    onSurface: RoastedColors.onSurface,
    surfaceDim: RoastedColors.surfaceDim,
    surfaceBright: RoastedColors.surfaceBright,
    surfaceContainerLowest: RoastedColors.surfaceContainerLowest,
    surfaceContainerLow: RoastedColors.surfaceContainerLow,
    surfaceContainer: RoastedColors.surfaceContainer,
    surfaceContainerHigh: RoastedColors.surfaceContainerHigh,
    surfaceContainerHighest: RoastedColors.surfaceContainerHighest,
    outline: RoastedColors.outline,
    outlineVariant: RoastedColors.outlineVariant,
    inverseSurface: RoastedColors.inverseSurface,
    onInverseSurface: RoastedColors.inverseOnSurface,
    inversePrimary: RoastedColors.inversePrimary,
  );

  final baseTheme = ThemeData.dark(useMaterial3: true);
  final bodyTheme = baseTheme.textTheme.apply(
    bodyColor: RoastedColors.onSurface,
    displayColor: RoastedColors.onSurface,
    fontFamily: RoastedTypography.bodyFontFamily,
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: RoastedColors.background,
    useMaterial3: true,
    fontFamily: RoastedTypography.bodyFontFamily,
    textTheme: bodyTheme.copyWith(
      displayLarge: bodyTheme.displayLarge?.copyWith(
        fontFamily: RoastedTypography.headlineFontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        height: 0.95,
      ),
      displayMedium: bodyTheme.displayMedium?.copyWith(
        fontFamily: RoastedTypography.headlineFontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 0.98,
      ),
      displaySmall: bodyTheme.displaySmall?.copyWith(
        fontFamily: RoastedTypography.headlineFontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineLarge: bodyTheme.headlineLarge?.copyWith(
        fontFamily: RoastedTypography.headlineFontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineMedium: bodyTheme.headlineMedium?.copyWith(
        fontFamily: RoastedTypography.headlineFontFamily,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: bodyTheme.headlineSmall?.copyWith(
        fontFamily: RoastedTypography.headlineFontFamily,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: bodyTheme.titleLarge?.copyWith(
        fontFamily: RoastedTypography.bodyFontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      titleMedium: bodyTheme.titleMedium?.copyWith(
        fontFamily: RoastedTypography.bodyFontFamily,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: bodyTheme.titleSmall?.copyWith(
        fontFamily: RoastedTypography.bodyFontFamily,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: bodyTheme.bodyLarge?.copyWith(
        fontFamily: RoastedTypography.bodyFontFamily,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: bodyTheme.bodyMedium?.copyWith(
        fontFamily: RoastedTypography.bodyFontFamily,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: bodyTheme.bodySmall?.copyWith(
        fontFamily: RoastedTypography.bodyFontFamily,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: bodyTheme.labelLarge?.copyWith(
        fontFamily: RoastedTypography.bodyFontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      labelMedium: bodyTheme.labelMedium?.copyWith(
        fontFamily: RoastedTypography.bodyFontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
      labelSmall: bodyTheme.labelSmall?.copyWith(
        fontFamily: RoastedTypography.bodyFontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: RoastedColors.surfaceContainerHighest,
      labelStyle: const TextStyle(
        color: RoastedColors.onSurface,
        fontWeight: FontWeight.w700,
        fontFamily: RoastedTypography.bodyFontFamily,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RoastedRadii.pill),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RoastedColors.secondaryContainer,
        foregroundColor: RoastedColors.onSecondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        elevation: 0,
        shadowColor: Colors.transparent,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          fontFamily: RoastedTypography.bodyFontFamily,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: RoastedColors.primary,
        foregroundColor: RoastedColors.onPrimary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontFamily: RoastedTypography.bodyFontFamily,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RoastedColors.onSurface,
        side: BorderSide(
          color: RoastedColors.outlineVariant.withValues(alpha: 0.18),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontFamily: RoastedTypography.bodyFontFamily,
        ),
      ),
    ),
  );
}
