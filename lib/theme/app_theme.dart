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
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.primary,
      selectedItemColor: AppColors.highlight1,
      unselectedItemColor: AppColors.faint,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.light),
      bodyLarge: TextStyle(color: AppColors.light),
    ),
  );
}
