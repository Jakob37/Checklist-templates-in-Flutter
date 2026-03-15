import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

class BluePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const BluePanel({
    super.key,
    required this.child,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ??
          const EdgeInsets.symmetric(
              horizontal: AppSizes.s, vertical: AppSizes.xs),
      padding: padding ?? const EdgeInsets.all(AppSizes.s),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: child,
    );
  }
}
