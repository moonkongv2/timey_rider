import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.brown900,
      secondary: AppColors.accentBlue,
      onSecondary: AppColors.brown900,
      secondaryContainer: AppColors.mint,
      onSecondaryContainer: AppColors.brown900,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.sky,
      onTertiaryContainer: AppColors.brown900,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.white,
      onSurface: AppColors.brown900,
      surfaceContainerHighest: AppColors.surfaceSoft,
      onSurfaceVariant: AppColors.brown500,
      outline: AppColors.brown300,
      outlineVariant: AppColors.outlineVariant,
      shadow: AppColors.brown700,
      scrim: AppColors.black,
      inverseSurface: AppColors.brown900,
      onInverseSurface: AppColors.cream,
      inversePrimary: AppColors.primarySoft,
    );

    final baseTheme = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceWarm,
      useMaterial3: true,
    );
    final textTheme = _textTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surfaceWarm,
        foregroundColor: AppColors.brown900,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.brown900,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: const IconThemeData(color: AppColors.brown700),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.brown700.withValues(alpha: 0.12),
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.brown300.withValues(alpha: 0.32),
          disabledForegroundColor: AppColors.brown500.withValues(alpha: 0.56),
          elevation: 0,
          shadowColor: AppColors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: AppColors.brown700,
          side: const BorderSide(color: AppColors.brown300, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: const BorderSide(color: AppColors.brown300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.brown500),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.primarySoft,
        disabledColor: AppColors.creamDark,
        labelStyle: textTheme.titleMedium?.copyWith(
          color: AppColors.brown900,
          fontWeight: FontWeight.w800,
        ),
        secondaryLabelStyle: textTheme.titleMedium?.copyWith(
          color: AppColors.brown900,
          fontWeight: FontWeight.w800,
        ),
        side: const BorderSide(color: AppColors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.brown300;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primarySoft
              : AppColors.creamDark;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    const textColor = AppColors.brown900;
    const bodyColor = AppColors.brown700;

    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          bodyLarge: base.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        )
        .apply(displayColor: textColor, bodyColor: bodyColor);
  }
}
