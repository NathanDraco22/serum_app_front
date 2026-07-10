import 'package:flutter/material.dart';

/// Paleta de colores basada en el diseño "Clinical Precision".
class ColorPalette {
  ColorPalette._();

  static const Color surface = Color(0xFFF7F9FF);
  static const Color surfaceDim = Color(0xFFD7DAE0);
  static const Color surfaceBright = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4FA);
  static const Color surfaceContainer = Color(0xFFEBEEF4);
  static const Color surfaceContainerHigh = Color(0xFFE5E8EE);
  static const Color surfaceContainerHighest = Color(0xFFDFE3E8);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF3F4850);
  static const Color inverseSurface = Color(0xFF2D3135);
  static const Color inverseOnSurface = Color(0xFFEEF1F7);
  static const Color outline = Color(0xFF707881);
  static const Color outlineVariant = Color(0xFFBFC7D2);
  static const Color surfaceTint = Color(0xFF006398);
  static const Color primary = Color(0xFF006194);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF007BB9);
  static const Color onPrimaryContainer = Color(0xFFFDFCFF);
  static const Color inversePrimary = Color(0xFF93CCFF);
  static const Color secondary = Color(0xFF505F76);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD0E1FB);
  static const Color onSecondaryContainer = Color(0xFF54647A);
  static const Color tertiary = Color(0xFF894D00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFAC6200);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color primaryFixed = Color(0xFFCCE5FF);
  static const Color primaryFixedDim = Color(0xFF93CCFF);
  static const Color onPrimaryFixed = Color(0xFF001D31);
  static const Color onPrimaryFixedVariant = Color(0xFF004B73);
  static const Color secondaryFixed = Color(0xFFD3E4FE);
  static const Color secondaryFixedDim = Color(0xFFB7C8E1);
  static const Color onSecondaryFixed = Color(0xFF0B1C30);
  static const Color onSecondaryFixedVariant = Color(0xFF38485D);
  static const Color tertiaryFixed = Color(0xFFFFDCC0);
  static const Color tertiaryFixedDim = Color(0xFFFFB875);
  static const Color onTertiaryFixed = Color(0xFF2D1600);
  static const Color onTertiaryFixedVariant = Color(0xFF6B3B00);
  static const Color background = Color(0xFFF7F9FF);
  static const Color onBackground = Color(0xFF181C20);
  static const Color surfaceVariant = Color(0xFFDFE3E8);
}

/// Configuración de temas claro y oscuro para la aplicación.
class AppTheme {
  AppTheme._();

  /// Configuración del tema claro.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ColorPalette.primary,
        onPrimary: ColorPalette.onPrimary,
        primaryContainer: ColorPalette.primaryContainer,
        onPrimaryContainer: ColorPalette.onPrimaryContainer,
        secondary: ColorPalette.secondary,
        onSecondary: ColorPalette.onSecondary,
        secondaryContainer: ColorPalette.secondaryContainer,
        onSecondaryContainer: ColorPalette.onSecondaryContainer,
        tertiary: ColorPalette.tertiary,
        onTertiary: ColorPalette.onTertiary,
        tertiaryContainer: ColorPalette.tertiaryContainer,
        onTertiaryContainer: ColorPalette.onTertiaryContainer,
        error: ColorPalette.error,
        onError: ColorPalette.onError,
        errorContainer: ColorPalette.errorContainer,
        onErrorContainer: ColorPalette.onErrorContainer,
        // Usamos surface y onSurface de acuerdo con las guías modernas de Material 3
        surface: ColorPalette.surface,
        onSurface: ColorPalette.onSurface,
        onSurfaceVariant: ColorPalette.onSurfaceVariant,
        outline: ColorPalette.outline,
        outlineVariant: ColorPalette.outlineVariant,
        inverseSurface: ColorPalette.inverseSurface,
        onInverseSurface: ColorPalette.inverseOnSurface,
        inversePrimary: ColorPalette.inversePrimary,
        surfaceTint: ColorPalette.surfaceTint,
        surfaceContainerLowest: ColorPalette.surfaceContainerLowest,
        surfaceContainerLow: ColorPalette.surfaceContainerLow,
        surfaceContainer: ColorPalette.surfaceContainer,
        surfaceContainerHigh: ColorPalette.surfaceContainerHigh,
        surfaceContainerHighest: ColorPalette.surfaceContainerHighest,
      ),
    );
  }

  /// Configuración del tema oscuro.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorPalette.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: ColorPalette.inversePrimary,
        surface: ColorPalette.inverseSurface,
        onSurface: ColorPalette.inverseOnSurface,
        onInverseSurface: ColorPalette.onSurface, // Inverso de inverseOnSurface
        surfaceTint: ColorPalette.surfaceTint,
      ),
    );
  }
}
