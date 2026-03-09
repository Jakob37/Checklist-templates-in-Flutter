import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.primary,
      primary: AppColors.highlight1,
      secondary: AppColors.secondary,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.secondary,
      selectedItemColor: AppColors.highlight2,
      unselectedItemColor: AppColors.light,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.light),
      bodyLarge: TextStyle(color: AppColors.light),
    ),
  );
}
