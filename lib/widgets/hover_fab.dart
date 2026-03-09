import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

class HoverFab extends StatelessWidget {
  final VoidCallback onPressed;

  const HoverFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppSizes.m,
      right: AppSizes.m,
      child: SizedBox(
        width: AppSizes.hoverButton,
        height: AppSizes.hoverButton,
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: AppColors.highlight1,
          elevation: 3,
          child: const FaIcon(FontAwesomeIcons.plus, color: AppColors.white),
        ),
      ),
    );
  }
}
