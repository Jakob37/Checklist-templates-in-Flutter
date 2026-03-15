import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

Future<void> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.secondary,
      title: Text(title, style: const TextStyle(color: AppColors.light)),
      content: Text(message, style: const TextStyle(color: AppColors.light)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.faint)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
          child: const Text(
            'Confirm',
            style: TextStyle(color: AppColors.highlight1),
          ),
        ),
      ],
    ),
  );
}
