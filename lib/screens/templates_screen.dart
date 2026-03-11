import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/checklist.dart';
import '../models/checklist_template.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/blue_panel.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/hover_fab.dart';
import '../widgets/screen_header.dart';
import 'view_template_widget.dart';

enum _TemplateCardAction { view, edit, remove }

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  ChecklistTemplate? _viewingTemplate;

  List<ChecklistTemplate> _sorted(List<ChecklistTemplate> templates) {
    final favs = templates.where((t) => t.favorite).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    final others = templates.where((t) => !t.favorite).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return [...favs, ...others];
  }

  Future<void> _instantiateTemplate(
    BuildContext context,
    ChecklistTemplate template,
  ) async {
    final optionalStacks =
        template.stacks.where((stack) => stack.isOptional).toList();
    final state = context.read<AppState>();
    Checklist checklist;

    if (optionalStacks.isNotEmpty) {
      final selectedOptionalStackIds = await showDialog<Set<String>>(
        context: context,
        builder: (context) => _OptionalGroupsDialog(
          template: template,
          optionalStacks: optionalStacks,
        ),
      );
      if (!context.mounted) return;
      if (selectedOptionalStackIds == null) return;
      checklist = state.instantiateTemplateWithSelectedOptionalGroups(
        template,
        selectedOptionalStackIds: selectedOptionalStackIds,
      );
    } else {
      checklist = state.instantiateTemplate(template);
    }

    await state.saveChecklist(checklist);
    if (!context.mounted) return;
    context.go('/checklists');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final templateCount = state.templates.length;

    if (_viewingTemplate != null) {
      return ViewTemplateWidget(
        template: _viewingTemplate!,
        onBack: () => setState(() => _viewingTemplate = null),
      );
    }

    return Stack(
      children: [
        ListView(
          padding:
              const EdgeInsets.only(bottom: AppSizes.hoverButton + AppSizes.m),
          children: [
            ScreenHeader(
              title: 'Templates',
              subtitle:
                  'Build reusable checklists and launch them when needed.',
              icon: const FaIcon(
                FontAwesomeIcons.listCheck,
                size: AppSizes.iconMedium,
                color: AppColors.light,
              ),
              trailing: _HeaderCount(count: templateCount, label: 'saved'),
            ),
            if (state.templates.isEmpty)
              BluePanel(
                margin: const EdgeInsets.fromLTRB(
                    AppSizes.s, AppSizes.s, AppSizes.s, AppSizes.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Press "+" to add your first template, or load example templates to see the flow.',
                      style: TextStyle(
                          color: AppColors.light, fontSize: AppSizes.textSub),
                    ),
                    const SizedBox(height: AppSizes.s),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.highlight1),
                      onPressed: () {
                        final s = context.read<AppState>();
                        s.saveNewTemplates([
                          s.makeLeavingHomeTemplate(),
                          s.makeBeforeSleepTemplate(),
                          s.makeBeforeSocialTemplate(),
                        ]);
                      },
                      child: const Text('Add example templates',
                          style: TextStyle(color: AppColors.white)),
                    ),
                  ],
                ),
              )
            else
              ..._sorted(state.templates).map((t) => _TemplateCard(
                    template: t,
                    completionCount: state.completionCountForTemplate(t.id),
                    onInstantiate: () => _instantiateTemplate(context, t),
                    onView: () => setState(() => _viewingTemplate = t),
                    onEdit: () => context
                        .push('/templates/edit?templateId=${t.id}&isNew=false'),
                    onRemove: () => showConfirmDialog(
                      context: context,
                      title: 'Remove template',
                      message: 'Are you sure you want to remove ${t.label}?',
                      onConfirm: () =>
                          context.read<AppState>().removeTemplate(t.id),
                    ),
                    onToggleStar: () {
                      final updated = t.copyWith(favorite: !t.favorite);
                      context.read<AppState>().saveTemplate(updated);
                    },
                  )),
          ],
        ),
        HoverFab(
          onPressed: () => context.push('/templates/edit?isNew=true'),
        ),
      ],
    );
  }
}

class _HeaderCount extends StatelessWidget {
  final int count;
  final String label;

  const _HeaderCount({
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(
          color: AppColors.light,
          fontSize: AppSizes.textSub,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _OptionalGroupsDialog extends StatefulWidget {
  final ChecklistTemplate template;
  final List<TaskStack> optionalStacks;

  const _OptionalGroupsDialog({
    required this.template,
    required this.optionalStacks,
  });

  @override
  State<_OptionalGroupsDialog> createState() => _OptionalGroupsDialogState();
}

class _OptionalGroupsDialogState extends State<_OptionalGroupsDialog> {
  late final Set<String> _selectedStackIds = {
    for (final stack in widget.optionalStacks) stack.id,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secondary,
      title: Text(
        widget.template.label,
        style: const TextStyle(color: AppColors.light),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose which optional groups to include.',
              style: TextStyle(
                color: AppColors.faint,
                fontSize: AppSizes.textSub,
              ),
            ),
            const SizedBox(height: AppSizes.s),
            ...widget.optionalStacks.map((stack) {
              final label = stack.hasVisibleLabel
                  ? stack.trimmedLabel
                  : 'Additional group';
              return CheckboxListTile(
                value: _selectedStackIds.contains(stack.id),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.highlight2,
                checkColor: AppColors.white,
                title: Text(
                  label,
                  style: const TextStyle(color: AppColors.light),
                ),
                subtitle: Text(
                  '${stack.tasks.length} ${stack.tasks.length == 1 ? 'checkbox' : 'checkboxes'}',
                  style: const TextStyle(color: AppColors.faint),
                ),
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedStackIds.add(stack.id);
                    } else {
                      _selectedStackIds.remove(stack.id);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.light),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.highlight2,
          ),
          onPressed: () => Navigator.of(context).pop(_selectedStackIds),
          child: const Text(
            'Create checklist',
            style: TextStyle(color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ChecklistTemplate template;
  final int completionCount;
  final VoidCallback onInstantiate;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onToggleStar;

  const _TemplateCard({
    required this.template,
    required this.completionCount,
    required this.onInstantiate,
    required this.onView,
    required this.onEdit,
    required this.onRemove,
    required this.onToggleStar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.s, AppSizes.s, AppSizes.s, 0),
      padding: const EdgeInsets.all(AppSizes.s),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onToggleStar,
                icon: FaIcon(
                  FontAwesomeIcons.solidStar,
                  size: AppSizes.iconMedium,
                  color: template.favorite
                      ? AppColors.highlight2
                      : AppColors.light,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onView,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.label,
                        style: const TextStyle(
                          color: AppColors.light,
                          fontSize: AppSizes.textMinor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        '${template.taskCount} tasks • completed $completionCount ${completionCount == 1 ? 'time' : 'times'}',
                        style: const TextStyle(
                          color: AppColors.faint,
                          fontSize: AppSizes.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<_TemplateCardAction>(
                tooltip: 'Template actions',
                onSelected: (action) {
                  switch (action) {
                    case _TemplateCardAction.view:
                      onView();
                      break;
                    case _TemplateCardAction.edit:
                      onEdit();
                      break;
                    case _TemplateCardAction.remove:
                      onRemove();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _TemplateCardAction.view,
                    child: Text('Preview'),
                  ),
                  PopupMenuItem(
                    value: _TemplateCardAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _TemplateCardAction.remove,
                    child: Text('Delete'),
                  ),
                ],
                icon: const FaIcon(
                  FontAwesomeIcons.ellipsisVertical,
                  size: AppSizes.iconMedium,
                  color: AppColors.light,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.highlight1,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.s),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
              ),
              onPressed: onInstantiate,
              icon: const FaIcon(
                FontAwesomeIcons.play,
                size: AppSizes.iconMedium,
              ),
              label: const Text('Start checklist'),
            ),
          ),
        ],
      ),
    );
  }
}
