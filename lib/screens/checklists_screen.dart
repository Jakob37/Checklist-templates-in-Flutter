import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/checklist.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/blue_panel.dart';

class ChecklistsScreen extends StatelessWidget {
  const ChecklistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sorted = [...state.checklists]
      ..sort((a, b) => a.timecreated.compareTo(b.timecreated));

    return ListView(
      children: [
        if (sorted.isEmpty)
          BluePanel(
            margin: const EdgeInsets.fromLTRB(
                AppSizes.s, AppSizes.s, AppSizes.s, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Currently no active checklists',
                  style: TextStyle(
                      color: AppColors.light, fontSize: AppSizes.textMajor),
                ),
                const SizedBox(height: AppSizes.s),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.highlight1),
                  onPressed: () => context.go('/templates'),
                  child: const Text('Go to templates',
                      style: TextStyle(color: AppColors.white)),
                ),
              ],
            ),
          ),
        ...sorted.map((checklist) => _ChecklistItem(checklist: checklist)),
        const SizedBox(height: AppSizes.s),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final Checklist checklist;
  const _ChecklistItem({required this.checklist});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDone = state.isChecklistDone(checklist.id);

    return Column(
      children: [
        // Header
        BluePanel(
          margin:
              const EdgeInsets.fromLTRB(AppSizes.s, AppSizes.s, AppSizes.s, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                checklist.template.label,
                style: const TextStyle(
                    color: AppColors.light,
                    fontSize: AppSizes.textMinor,
                    fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => context.push(
                      '/templates/edit?templateId=${checklist.template.id}&isNew=false&syncActiveChecklists=true',
                    ),
                    icon: const FaIcon(
                      FontAwesomeIcons.pen,
                      size: AppSizes.iconMedium,
                      color: AppColors.light,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<AppState>().removeChecklist(checklist.id),
                    icon: const FaIcon(FontAwesomeIcons.trash,
                        size: AppSizes.iconMedium, color: AppColors.light),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Checkboxes
        BluePanel(
          margin:
              const EdgeInsets.fromLTRB(AppSizes.s, AppSizes.xs, AppSizes.s, 0),
          child: Column(
            children: checklist.checkboxes.asMap().entries.map((e) {
              final i = e.key;
              final box = e.value;
              final isChecked = box.checked == CheckboxStatus.checked;
              return Padding(
                padding: EdgeInsets.only(top: i != 0 ? AppSizes.s : 0),
                child: GestureDetector(
                  onTap: () => context
                      .read<AppState>()
                      .toggleCheck(checklist.id, box.id),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      FaIcon(
                        isChecked
                            ? FontAwesomeIcons.solidSquareCheck
                            : FontAwesomeIcons.square,
                        size: AppSizes.iconMedium,
                        color: AppColors.light,
                      ),
                      const SizedBox(width: AppSizes.s),
                      Text(
                        box.label,
                        style: TextStyle(
                          color: isChecked ? AppColors.faint : AppColors.light,
                          fontSize: AppSizes.textSub,
                          decoration:
                              isChecked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Done bar
        if (isDone)
          GestureDetector(
            onTap: () =>
                context.read<AppState>().completeChecklist(checklist.id),
            child: Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSizes.s, AppSizes.s, AppSizes.s, 0),
              padding: const EdgeInsets.symmetric(vertical: AppSizes.s),
              decoration: BoxDecoration(
                color: AppColors.highlight1,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.check,
                      size: AppSizes.iconLarge, color: AppColors.white),
                  SizedBox(width: AppSizes.s),
                  Text(
                    'Done',
                    style: TextStyle(
                        fontSize: AppSizes.textMajor, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
