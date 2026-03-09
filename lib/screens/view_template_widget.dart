import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/checklist_template.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/blue_panel.dart';

class ViewTemplateWidget extends StatelessWidget {
  final ChecklistTemplate template;
  final VoidCallback onBack;

  const ViewTemplateWidget(
      {super.key, required this.template, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BluePanel(
          child: Text(
            template.label,
            style: const TextStyle(
                color: AppColors.light,
                fontSize: AppSizes.textMinor,
                fontWeight: FontWeight.bold),
          ),
        ),
        ...template.stacks.map((stack) => BluePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: stack.tasks
                    .map((task) => Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: AppSizes.xs),
                          child: Text(task.label,
                              style:
                                  const TextStyle(color: AppColors.light)),
                        ))
                    .toList(),
              ),
            )),
        BluePanel(
          child: GestureDetector(
            onTap: onBack,
            child: const Row(
              children: [
                FaIcon(FontAwesomeIcons.arrowLeft,
                    size: AppSizes.iconMedium, color: AppColors.light),
                SizedBox(width: AppSizes.s),
                Text('Back',
                    style: TextStyle(
                        color: AppColors.light,
                        fontSize: AppSizes.textSub)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
