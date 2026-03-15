import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import 'blue_panel.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget icon;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.trailing,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return BluePanel(
      margin: margin ??
          const EdgeInsets.fromLTRB(AppSizes.s, AppSizes.s, AppSizes.s, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(width: AppSizes.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.light,
                    fontSize: AppSizes.textSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.faint,
                      fontSize: AppSizes.textSub,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSizes.s),
            trailing!,
          ],
        ],
      ),
    );
  }
}
