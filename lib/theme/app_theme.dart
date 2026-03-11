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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.highlight1.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected)
              ? AppColors.highlight1
              : AppColors.faint,
          fontWeight:
              states.contains(WidgetState.selected) ? FontWeight.bold : null,
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
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.light),
      bodyLarge: TextStyle(color: AppColors.light),
    ),
  );
}
