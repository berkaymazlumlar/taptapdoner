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
  final bodyTheme = DonerTypography.bodyTextTheme(
    baseTheme.textTheme.apply(
      bodyColor: RoastedColors.onSurface,
      displayColor: RoastedColors.onSurface,
    ),
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: RoastedColors.background,
    useMaterial3: true,
    fontFamily: DonerTypography.bodyFontFamily,
    textTheme: bodyTheme.copyWith(
      displayLarge: DonerTypography.display(
        bodyTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 0.95,
        ),
      ),
      displayMedium: DonerTypography.display(
        bodyTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 0.98,
        ),
      ),
      displaySmall: DonerTypography.display(
        bodyTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      headlineLarge: DonerTypography.display(
        bodyTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      headlineMedium: DonerTypography.display(
        bodyTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      headlineSmall: DonerTypography.display(
        bodyTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      titleLarge: DonerTypography.body(
        bodyTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      titleMedium: DonerTypography.body(
        bodyTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      titleSmall: DonerTypography.body(
        bodyTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      bodyLarge: DonerTypography.body(
        bodyTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      bodyMedium: DonerTypography.body(
        bodyTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      bodySmall: DonerTypography.body(
        bodyTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      labelLarge: DonerTypography.body(
        bodyTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      labelMedium: DonerTypography.body(
        bodyTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
      labelSmall: DonerTypography.body(
        bodyTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: RoastedColors.surfaceContainerHighest,
      labelStyle: DonerTypography.body(
        const TextStyle(
          color: RoastedColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
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
        textStyle: DonerTypography.body(
          const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: RoastedColors.primary,
        foregroundColor: RoastedColors.onPrimary,
        textStyle: DonerTypography.body(
          const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RoastedColors.onSurface,
        side: BorderSide(
          color: RoastedColors.outlineVariant.withValues(alpha: 0.18),
        ),
        textStyle: DonerTypography.body(
          const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
