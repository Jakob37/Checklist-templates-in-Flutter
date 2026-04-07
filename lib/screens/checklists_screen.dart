import 'package:flutter/material.dart' hide Checkbox;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/checklist.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/blue_panel.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/screen_header.dart';

enum _ChecklistAction { editTemplate, reset, remove }

class ChecklistsScreen extends StatelessWidget {
  const ChecklistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sorted = [...state.checklists]
      ..sort((a, b) => a.timecreated.compareTo(b.timecreated));

    return ListView(
      children: [
        ScreenHeader(
          title: 'Actions',
          icon: const FaIcon(
            FontAwesomeIcons.squareCheck,
            size: AppSizes.iconMedium,
            color: AppColors.light,
          ),
          trailing: _ChecklistCount(count: sorted.length),
        ),
        if (sorted.isEmpty)
          BluePanel(
            margin: const EdgeInsets.fromLTRB(
                AppSizes.s, AppSizes.s, AppSizes.s, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No active actions',
                  style: TextStyle(
                    color: AppColors.light,
                    fontSize: AppSizes.textMinor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/templates'),
                  child: const Text(
                    'Templates',
                    style: TextStyle(color: AppColors.highlight1),
                  ),
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

class _ChecklistItem extends StatefulWidget {
  final Checklist checklist;
  const _ChecklistItem({required this.checklist});

  @override
  State<_ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<_ChecklistItem> {
  final TextEditingController _temporaryTaskController =
      TextEditingController();
  final FocusNode _temporaryTaskFocusNode = FocusNode();
  bool _isAddingTemporaryTask = false;

  Checklist get checklist => widget.checklist;

  @override
  void dispose() {
    _temporaryTaskController.dispose();
    _temporaryTaskFocusNode.dispose();
    super.dispose();
  }

  List<_ChecklistSection> _buildSections() {
    final checkboxByTaskId = <String, Checkbox>{};
    final temporaryBoxes = <Checkbox>[];
    for (final box in checklist.checkboxes) {
      final taskId = box.taskId;
      if (taskId != null) {
        checkboxByTaskId[taskId] = box;
      } else {
        temporaryBoxes.add(box);
      }
    }

    var fallbackIndex = 0;

    final List<_ChecklistSection> sections = checklist.template.stacks
        .map((stack) {
          final boxes = <Checkbox>[];

          for (final task in stack.tasks) {
            final box = checkboxByTaskId[task.id] ??
                (fallbackIndex < checklist.checkboxes.length
                    ? checklist.checkboxes[fallbackIndex]
                    : null);
            fallbackIndex++;

            if (box != null) {
              boxes.add(box);
            }
          }

          return _ChecklistSection(
            label: stack.hasVisibleLabel ? stack.trimmedLabel : null,
            boxes: boxes,
          );
        })
        .where((section) => section.boxes.isNotEmpty)
        .toList();

    if (temporaryBoxes.isNotEmpty) {
      sections.add(
        _ChecklistSection(
          label: 'Temporary',
          boxes: temporaryBoxes,
        ),
      );
    }

    return sections;
  }

  void _startAddingTemporaryTask() {
    setState(() {
      _isAddingTemporaryTask = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _temporaryTaskFocusNode.requestFocus();
      }
    });
  }

  void _cancelAddingTemporaryTask() {
    setState(() {
      _isAddingTemporaryTask = false;
      _temporaryTaskController.clear();
    });
  }

  Future<void> _saveTemporaryTask() async {
    final String label = _temporaryTaskController.text.trim();
    if (label.isEmpty) {
      return;
    }

    await context.read<AppState>().addTemporaryCheckbox(
          checklist.id,
          label: label,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isAddingTemporaryTask = false;
      _temporaryTaskController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDone = state.isChecklistDone(checklist.id);
    final sections = _buildSections();
    final totalCount = checklist.checkboxes.length;
    final checkedCount = checklist.checkboxes
        .where((box) => box.checked == CheckboxStatus.checked)
        .length;
    final progress = totalCount == 0 ? 0.0 : checkedCount / totalCount;

    return Column(
      children: [
        BluePanel(
          margin:
              const EdgeInsets.fromLTRB(AppSizes.s, AppSizes.s, AppSizes.s, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checklist.template.label,
                          style: const TextStyle(
                              color: AppColors.light,
                              fontSize: AppSizes.textMinor,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          '$checkedCount/$totalCount',
                          style: const TextStyle(
                            color: AppColors.faint,
                            fontSize: AppSizes.textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_ChecklistAction>(
                    tooltip: 'Checklist actions',
                    onSelected: (action) {
                      switch (action) {
                        case _ChecklistAction.editTemplate:
                          context.push(
                            '/templates/edit?templateId=${checklist.template.id}&isNew=false&syncActiveChecklists=true',
                          );
                          break;
                        case _ChecklistAction.reset:
                          context.read<AppState>().resetChecklist(checklist.id);
                          break;
                        case _ChecklistAction.remove:
                          showConfirmDialog(
                            context: context,
                            title: 'Remove checklist',
                            message:
                                'Are you sure you want to remove ${checklist.template.label}?',
                            onConfirm: () => context
                                .read<AppState>()
                                .removeChecklist(checklist.id),
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _ChecklistAction.editTemplate,
                        child: Text('Edit template'),
                      ),
                      PopupMenuItem(
                        value: _ChecklistAction.reset,
                        child: Text('Reset checklist'),
                      ),
                      PopupMenuItem(
                        value: _ChecklistAction.remove,
                        child: Text('Delete checklist'),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.primary,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.highlight1),
                ),
              ),
              if (isDone) ...[
                const SizedBox(height: AppSizes.s),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s,
                    vertical: AppSizes.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.highlight1,
                      fontSize: AppSizes.textSub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        BluePanel(
          margin:
              const EdgeInsets.fromLTRB(AppSizes.s, AppSizes.xs, AppSizes.s, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections.asMap().entries.expand((entry) {
              final sectionIndex = entry.key;
              final section = entry.value;
              final widgets = <Widget>[];

              if (sectionIndex > 0) {
                widgets.add(const SizedBox(height: AppSizes.m));
              }

              if (section.label != null) {
                widgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.xs),
                    child: Text(
                      section.label!,
                      style: const TextStyle(
                        color: AppColors.faint,
                        fontSize: AppSizes.textSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              widgets.addAll(
                section.boxes.asMap().entries.map((boxEntry) {
                  final boxIndex = boxEntry.key;
                  final box = boxEntry.value;
                  final isChecked = box.checked == CheckboxStatus.checked;

                  return Padding(
                    padding:
                        EdgeInsets.only(top: boxIndex != 0 ? AppSizes.s : 0),
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
                          Expanded(
                            child: Text(
                              box.label,
                              style: TextStyle(
                                color: isChecked
                                    ? AppColors.faint
                                    : AppColors.light,
                                fontSize: AppSizes.textSub,
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );

              if (sectionIndex == sections.length - 1) {
                widgets.add(const SizedBox(height: AppSizes.s));
                widgets.add(
                  _TemporaryTaskComposer(
                    controller: _temporaryTaskController,
                    focusNode: _temporaryTaskFocusNode,
                    isEditing: _isAddingTemporaryTask,
                    onStart: _startAddingTemporaryTask,
                    onCancel: _cancelAddingTemporaryTask,
                    onSave: _saveTemporaryTask,
                  ),
                );
              }

              return widgets;
            }).toList(),
          ),
        ),
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
                    'Complete checklist',
                    style: TextStyle(
                      fontSize: AppSizes.textMinor,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ChecklistCount extends StatelessWidget {
  final int count;

  const _ChecklistCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.s,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.light,
          fontSize: AppSizes.textSub,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TemporaryTaskComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  const _TemporaryTaskComposer({
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.onStart,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      return OutlinedButton.icon(
        onPressed: onStart,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.light,
        ),
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Add temporary task'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.s),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(color: AppColors.light),
            decoration: const InputDecoration(
              hintText: 'Temporary task',
              hintStyle: TextStyle(color: AppColors.faint),
              border: InputBorder.none,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSave(),
          ),
          const SizedBox(height: AppSizes.s),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final bool canSave = value.text.trim().isNotEmpty;
              return Row(
                children: [
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.light,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSizes.s),
                  ElevatedButton(
                    onPressed: canSave ? onSave : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.highlight1,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Ok'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChecklistSection {
  final String? label;
  final List<Checkbox> boxes;

  const _ChecklistSection({required this.label, required this.boxes});
}
