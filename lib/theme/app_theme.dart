import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      surface: AppColors.primary,
      primary: AppColors.highlight1,
      secondary: AppColors.highlight2,
      onPrimary: AppColors.light,
      onSurface: AppColors.light,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.primary,
      indicatorColor: AppColors.highlight1.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.highlight1
              : AppColors.faint,
          fontWeight:
              states.contains(WidgetState.selected) ? FontWeight.w600 : null,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.highlight1
              : AppColors.faint,
        );
      }),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.highlight1,
        foregroundColor: AppColors.white,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.light,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.highlight1,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.highlight1,
      foregroundColor: AppColors.white,
      elevation: 1,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.light),
      bodyLarge: TextStyle(color: AppColors.light),
    ),
  );
}
