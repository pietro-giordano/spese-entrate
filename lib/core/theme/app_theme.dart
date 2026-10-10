import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// ThemeData chiaro e scuro costruiti dagli stessi token.
abstract final class AppTheme {
  static const fontFamily = 'Manrope';

  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.neutral.fill,
      onPrimary: c.neutral.onFill,
      secondary: c.income.fill,
      onSecondary: c.income.onFill,
      error: c.danger,
      onError: c.surface,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      surfaceContainerHighest: c.track,
      outline: c.borderStrong,
      outlineVariant: c.border,
      scrim: c.scrim,
      shadow: Colors.black,
    );

    final textTheme = _textTheme(c);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: c.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: textTheme.bodyLarge?.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
        border: _fieldBorder(c.borderStrong),
        enabledBorder: _fieldBorder(c.borderStrong),
        focusedBorder: _fieldBorder(c.text, width: 1.5),
        errorBorder: _fieldBorder(c.danger),
        focusedErrorBorder: _fieldBorder(c.danger, width: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.neutral.fill,
          foregroundColor: c.neutral.onFill,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.text,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: c.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: c.scrim,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.neutral.fill,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.neutral.onFill),
        actionTextColor: c.neutral.onFill,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Scala tipografica ricavata dai mockup (Manrope, pesi 600–800).
  static TextTheme _textTheme(AppColors c) {
    const base = TextTheme(
      displaySmall: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -1.4),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.56),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );
    final themed = base.apply(fontFamily: fontFamily, bodyColor: c.text, displayColor: c.text);
    return themed.copyWith(bodySmall: themed.bodySmall?.copyWith(color: c.textMuted));
  }
}
