import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/checklist_template.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/blue_panel.dart';
import '../widgets/screen_header.dart';

class ViewTemplateWidget extends StatelessWidget {
  final ChecklistTemplate template;
  final VoidCallback onBack;

  const ViewTemplateWidget(
      {super.key, required this.template, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ScreenHeader(
          title: template.label,
          icon: const FaIcon(
            FontAwesomeIcons.eye,
            size: AppSizes.iconMedium,
            color: AppColors.light,
          ),
          trailing: IconButton(
            onPressed: onBack,
            icon: const FaIcon(
              FontAwesomeIcons.arrowLeft,
              size: AppSizes.iconMedium,
              color: AppColors.light,
            ),
          ),
        ),
        ...template.stacks.map((stack) => BluePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stack.hasVisibleLabel || stack.isOptional)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              stack.hasVisibleLabel
                                  ? stack.trimmedLabel
                                  : 'Checklist group',
                              style: const TextStyle(
                                color: AppColors.faint,
                                fontSize: AppSizes.textSub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (stack.isOptional)
                            const Text(
                              'Optional',
                              style: TextStyle(
                                color: AppColors.highlight2,
                                fontSize: AppSizes.textSub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ...stack.tasks.map((task) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSizes.xs),
                        child: Text(task.label,
                            style: const TextStyle(
                                color: AppColors.light,
                                fontSize: AppSizes.textSub)),
                      )),
                ],
              ),
            )),
      ],
    );
  }
}
