import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/checklist_template.dart';
import '../models/id_gen.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/blue_panel.dart';

enum _StackMenuAction { moveUp, moveDown, remove }

enum _TaskMenuAction { moveUp, moveDown, remove }

class MakeTemplateScreen extends StatefulWidget {
  final String? templateId;
  final bool isNew;
  final bool syncActiveChecklists;

  const MakeTemplateScreen({
    super.key,
    this.templateId,
    required this.isNew,
    this.syncActiveChecklists = false,
  });

  @override
  State<MakeTemplateScreen> createState() => _MakeTemplateScreenState();
}

class _MakeTemplateScreenState extends State<MakeTemplateScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final Map<String, FocusNode> _stackFocusNodes = {};
  final Map<String, FocusNode> _taskFocusNodes = {};

  late String _templateId;
  bool _isFavorite = false;
  List<TaskStack> _stacks = [];

  @override
  void initState() {
    super.initState();
    _templateId = generateId('template');
    _loadTemplate();
  }

  void _loadTemplate() {
    final id = widget.templateId;
    if (id == null || widget.isNew) {
      _reset();
      return;
    }

    final state = context.read<AppState>();
    final template = state.getTemplateById(id);

    _disposeFocusNodes();
    _templateId = template.id;
    _isFavorite = template.favorite;
    _nameController.text = template.label;
    _stacks = template.stacks
        .map(
          (stack) => TaskStack(
            id: stack.id,
            label: stack.hasVisibleLabel ? stack.trimmedLabel : '',
            tasks: stack.tasks
                .map((task) => Task(id: task.id, label: task.label))
                .toList(),
            isOptional: stack.isOptional,
          ),
        )
        .toList();

    if (_stacks.isEmpty) {
      _stacks = [_buildEmptyStack()];
    }

    for (final stack in _stacks) {
      _stackFocusNodes[stack.id] = FocusNode();
      for (final task in stack.tasks) {
        _taskFocusNodes[task.id] = FocusNode();
      }
    }
  }

  void _reset() {
    _disposeFocusNodes();
    _templateId = generateId('template');
    _isFavorite = false;
    _nameController.clear();
    _stacks = [_buildEmptyStack()];
  }

  TaskStack _buildEmptyStack() => TaskStack(
        id: generateId('stack'),
        label: '',
        tasks: [],
      );

  void _disposeFocusNodes() {
    for (final fn in _stackFocusNodes.values) {
      fn.dispose();
    }
    for (final fn in _taskFocusNodes.values) {
      fn.dispose();
    }
    _stackFocusNodes.clear();
    _taskFocusNodes.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _disposeFocusNodes();
    super.dispose();
  }

  bool get _saveActive =>
      _nameController.text.trim().isNotEmpty &&
      _stacks.any(
        (stack) => stack.tasks.any((task) => task.label.trim().isNotEmpty),
      );

  void _renameStackLabel(String stackId, String label) {
    final index = _stacks.indexWhere((stack) => stack.id == stackId);
    if (index < 0) return;
    setState(() {
      final copy = [..._stacks];
      copy[index] = copy[index].copyWith(label: label);
      _stacks = copy;
    });
  }

  void _moveStack(int index, int offset) {
    final newIndex = index + offset;
    if (newIndex < 0 || newIndex >= _stacks.length) return;
    setState(() {
      final copy = [..._stacks];
      final item = copy.removeAt(index);
      copy.insert(newIndex, item);
      _stacks = copy;
    });
  }

  void _toggleStackOptional(String stackId, bool isOptional) {
    final index = _stacks.indexWhere((stack) => stack.id == stackId);
    if (index < 0) return;
    setState(() {
      final copy = [..._stacks];
      copy[index] = copy[index].copyWith(isOptional: isOptional);
      _stacks = copy;
    });
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _addStack({String? afterStackId}) {
    final newStack = _buildEmptyStack();
    _stackFocusNodes[newStack.id] = FocusNode();

    setState(() {
      final copy = [..._stacks];
      final insertIndex = afterStackId == null
          ? copy.length
          : copy.indexWhere((stack) => stack.id == afterStackId) + 1;
      if (insertIndex <= 0 || insertIndex > copy.length) {
        copy.add(newStack);
      } else {
        copy.insert(insertIndex, newStack);
      }
      _stacks = copy;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stackFocusNodes[newStack.id]?.requestFocus();
    });
  }

  void _removeStack(String stackId) {
    final stackIndex = _stacks.indexWhere((entry) => entry.id == stackId);
    if (stackIndex < 0) return;
    final stack = _stacks[stackIndex];

    _stackFocusNodes.remove(stackId)?.dispose();
    for (final task in stack.tasks) {
      _taskFocusNodes.remove(task.id)?.dispose();
    }

    setState(() {
      final remaining = _stacks.where((entry) => entry.id != stackId).toList();
      _stacks = remaining.isEmpty ? [_buildEmptyStack()] : remaining;
      if (_stacks.length == 1) {
        _stackFocusNodes.putIfAbsent(_stacks.first.id, FocusNode.new);
      }
    });
  }

  void _addTask(String stackId) {
    final taskId = generateId('task');
    _taskFocusNodes[taskId] = FocusNode();

    setState(() {
      _stacks = _stacks.map((stack) {
        if (stack.id != stackId) return stack;
        return stack.copyWith(
          tasks: [...stack.tasks, Task(id: taskId, label: '')],
        );
      }).toList();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskFocusNodes[taskId]?.requestFocus();
    });
  }

  void _renameTask(String stackId, String taskId, String label) {
    final stackIndex = _stacks.indexWhere((stack) => stack.id == stackId);
    if (stackIndex < 0) return;

    final taskIndex =
        _stacks[stackIndex].tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex < 0) return;

    setState(() {
      final updatedStacks = [..._stacks];
      final updatedTasks = [...updatedStacks[stackIndex].tasks];
      updatedTasks[taskIndex] = updatedTasks[taskIndex].copyWith(label: label);
      updatedStacks[stackIndex] =
          updatedStacks[stackIndex].copyWith(tasks: updatedTasks);
      _stacks = updatedStacks;
    });
  }

  void _removeTask(String stackId, String taskId) {
    _taskFocusNodes.remove(taskId)?.dispose();

    setState(() {
      _stacks = _stacks.map((stack) {
        if (stack.id != stackId) return stack;
        return stack.copyWith(
          tasks: stack.tasks.where((task) => task.id != taskId).toList(),
        );
      }).toList();
    });
  }

  void _moveTask(String stackId, int index, int offset) {
    final stackIndex = _stacks.indexWhere((stack) => stack.id == stackId);
    if (stackIndex < 0) return;

    final tasks = _stacks[stackIndex].tasks;
    final newIndex = index + offset;
    if (newIndex < 0 || newIndex >= tasks.length) return;

    setState(() {
      final updatedStacks = [..._stacks];
      final updatedTasks = [...tasks];
      final task = updatedTasks.removeAt(index);
      updatedTasks.insert(newIndex, task);
      updatedStacks[stackIndex] =
          updatedStacks[stackIndex].copyWith(tasks: updatedTasks);
      _stacks = updatedStacks;
    });
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final stacks = _stacks
        .map(
          (stack) => stack.copyWith(
            label: stack.trimmedLabel,
            tasks: stack.tasks
                .where((task) => task.label.trim().isNotEmpty)
                .map((task) => task.copyWith(label: task.label.trim()))
                .toList(),
          ),
        )
        .where((stack) => stack.tasks.isNotEmpty)
        .toList();

    final template = ChecklistTemplate(
      id: _templateId,
      label: _nameController.text.trim(),
      favorite: _isFavorite,
      stacks: stacks,
    );

    await state.saveTemplate(
      template,
      syncActiveChecklists: widget.syncActiveChecklists,
    );

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenTitle = widget.isNew ? 'New template' : 'Edit template';

    return Scaffold(
      body: Column(
        children: [
          BluePanel(
            margin: const EdgeInsets.fromLTRB(
              AppSizes.s,
              AppSizes.s,
              AppSizes.s,
              0,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const FaIcon(
                    FontAwesomeIcons.arrowLeft,
                    size: AppSizes.iconMedium,
                    color: AppColors.light,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          screenTitle,
                          style: const TextStyle(
                            color: AppColors.light,
                            fontSize: AppSizes.textMinor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.syncActiveChecklists)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.s,
                            vertical: AppSizes.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadius,
                            ),
                          ),
                          child: const Text(
                            'Sync active',
                            style: TextStyle(
                              color: AppColors.faint,
                              fontSize: AppSizes.textSub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleFavorite,
                  tooltip: _isFavorite ? 'Remove favorite' : 'Mark as favorite',
                  icon: FaIcon(
                    FontAwesomeIcons.solidStar,
                    size: AppSizes.iconMedium,
                    color: _isFavorite ? AppColors.highlight2 : AppColors.faint,
                  ),
                ),
              ],
            ),
          ),
          BluePanel(
            margin: const EdgeInsets.fromLTRB(
              AppSizes.s,
              AppSizes.s,
              AppSizes.s,
              0,
            ),
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              autofocus: widget.isNew,
              style: const TextStyle(color: AppColors.light),
              decoration: const InputDecoration(
                hintText: 'Template name',
                hintStyle: TextStyle(color: AppColors.faint),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.s,
              AppSizes.s,
              AppSizes.s,
              AppSizes.xs,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Groups',
                    style: TextStyle(
                      color: AppColors.light,
                      fontSize: AppSizes.textMinor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${_stacks.length} ${_stacks.length == 1 ? 'group' : 'groups'}',
                  style: const TextStyle(
                    color: AppColors.faint,
                    fontSize: AppSizes.textSub,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.s),
              children: [
                ..._stacks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stack = entry.value;
                  _stackFocusNodes.putIfAbsent(stack.id, FocusNode.new);
                  for (final task in stack.tasks) {
                    _taskFocusNodes.putIfAbsent(task.id, FocusNode.new);
                  }

                  return _StackEditorCard(
                    key: ValueKey(stack.id),
                    stack: stack,
                    groupNumber: index + 1,
                    stackFocusNode: _stackFocusNodes[stack.id]!,
                    taskFocusNodes: _taskFocusNodes,
                    canMoveUp: index > 0,
                    canMoveDown: index < _stacks.length - 1,
                    canRemove: _stacks.length > 1 ||
                        stack.tasks.isNotEmpty ||
                        stack.trimmedLabel.isNotEmpty,
                    isOptional: stack.isOptional,
                    onLabelChanged: (value) =>
                        _renameStackLabel(stack.id, value),
                    onOptionalChanged: (value) =>
                        _toggleStackOptional(stack.id, value),
                    onMoveUp: () => _moveStack(index, -1),
                    onMoveDown: () => _moveStack(index, 1),
                    onRemove: () => _removeStack(stack.id),
                    onAddTask: () => _addTask(stack.id),
                    onAddGroupAfter: () => _addStack(afterStackId: stack.id),
                    onTaskChanged: (taskId, value) =>
                        _renameTask(stack.id, taskId, value),
                    onTaskRemove: (taskId) => _removeTask(stack.id, taskId),
                    onTaskMoveUp: (taskIndex) =>
                        _moveTask(stack.id, taskIndex, -1),
                    onTaskMoveDown: (taskIndex) =>
                        _moveTask(stack.id, taskIndex, 1),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.s),
                  child: OutlinedButton.icon(
                    onPressed: _addStack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s,
                        vertical: AppSizes.s,
                      ),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
                      ),
                    ),
                    icon: const FaIcon(
                      FontAwesomeIcons.layerGroup,
                      size: AppSizes.iconMedium,
                      color: AppColors.light,
                    ),
                    label: const Text(
                      'Add group',
                      style: TextStyle(
                        color: AppColors.light,
                        fontSize: AppSizes.textSub,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _saveActive ? _save : null,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSizes.s,
                vertical: AppSizes.s,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.s,
                horizontal: AppSizes.s,
              ),
              decoration: BoxDecoration(
                color: _saveActive ? AppColors.highlight2 : AppColors.primary,
                border: Border.all(
                  color: _saveActive ? AppColors.highlight2 : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.floppyDisk,
                    size: AppSizes.iconMedium,
                    color: _saveActive ? AppColors.white : AppColors.faint,
                  ),
                  const SizedBox(width: AppSizes.s),
                  Text(
                    widget.syncActiveChecklists ? 'Save + sync' : 'Save',
                    style: TextStyle(
                      fontSize: AppSizes.textMinor,
                      color: _saveActive ? AppColors.white : AppColors.faint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackEditorCard extends StatelessWidget {
  final TaskStack stack;
  final int groupNumber;
  final FocusNode stackFocusNode;
  final Map<String, FocusNode> taskFocusNodes;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool canRemove;
  final bool isOptional;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<bool> onOptionalChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final VoidCallback onAddTask;
  final VoidCallback onAddGroupAfter;
  final void Function(String taskId, String value) onTaskChanged;
  final ValueChanged<String> onTaskRemove;
  final ValueChanged<int> onTaskMoveUp;
  final ValueChanged<int> onTaskMoveDown;

  const _StackEditorCard({
    super.key,
    required this.stack,
    required this.groupNumber,
    required this.stackFocusNode,
    required this.taskFocusNodes,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canRemove,
    required this.isOptional,
    required this.onLabelChanged,
    required this.onOptionalChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onAddTask,
    required this.onAddGroupAfter,
    required this.onTaskChanged,
    required this.onTaskRemove,
    required this.onTaskMoveUp,
    required this.onTaskMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final taskCountLabel =
        '${stack.tasks.length} ${stack.tasks.length == 1 ? 'task' : 'tasks'}';
    final hasMenuActions = canMoveUp || canMoveDown || canRemove;

    return BluePanel(
      margin: const EdgeInsets.fromLTRB(AppSizes.s, 0, AppSizes.s, AppSizes.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
                alignment: Alignment.center,
                child: const FaIcon(
                  FontAwesomeIcons.layerGroup,
                  size: AppSizes.iconMedium,
                  color: AppColors.light,
                ),
              ),
              const SizedBox(width: AppSizes.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group $groupNumber',
                      style: const TextStyle(
                        color: AppColors.light,
                        fontSize: AppSizes.textSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      taskCountLabel,
                      style: const TextStyle(
                        color: AppColors.faint,
                        fontSize: AppSizes.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasMenuActions)
                PopupMenuButton<_StackMenuAction>(
                  tooltip: 'Group actions',
                  onSelected: (action) {
                    switch (action) {
                      case _StackMenuAction.moveUp:
                        onMoveUp();
                        break;
                      case _StackMenuAction.moveDown:
                        onMoveDown();
                        break;
                      case _StackMenuAction.remove:
                        onRemove();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (canMoveUp)
                      const PopupMenuItem(
                        value: _StackMenuAction.moveUp,
                        child: Text('Move up'),
                      ),
                    if (canMoveDown)
                      const PopupMenuItem(
                        value: _StackMenuAction.moveDown,
                        child: Text('Move down'),
                      ),
                    if (canRemove)
                      const PopupMenuItem(
                        value: _StackMenuAction.remove,
                        child: Text('Delete group'),
                      ),
                  ],
                  icon: const FaIcon(
                    FontAwesomeIcons.ellipsisVertical,
                    size: AppSizes.iconMedium,
                    color: AppColors.light,
                  ),
                )
              else
                const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: AppSizes.s),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s),
            child: TextFormField(
              key: ValueKey('stack-${stack.id}'),
              focusNode: stackFocusNode,
              initialValue: stack.label,
              style: const TextStyle(color: AppColors.light),
              decoration: const InputDecoration(
                hintText: 'Group label (optional)',
                hintStyle: TextStyle(color: AppColors.faint),
                border: InputBorder.none,
              ),
              onChanged: onLabelChanged,
            ),
          ),
          const SizedBox(height: AppSizes.s),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.s),
              value: isOptional,
              activeThumbColor: AppColors.highlight2,
              title: const Text(
                'Optional',
                style: TextStyle(
                  color: AppColors.light,
                  fontSize: AppSizes.textSub,
                ),
              ),
              onChanged: onOptionalChanged,
            ),
          ),
          const SizedBox(height: AppSizes.s),
          ...stack.tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            final focusNode = taskFocusNodes[task.id]!;

            return Padding(
              padding: EdgeInsets.only(
                top: stack.tasks.isEmpty ? 0 : AppSizes.s,
              ),
              child: _TaskRow(
                key: ValueKey(task.id),
                task: task,
                focusNode: focusNode,
                canMoveUp: index > 0,
                canMoveDown: index < stack.tasks.length - 1,
                onChanged: (value) => onTaskChanged(task.id, value),
                onMoveUp: () => onTaskMoveUp(index),
                onMoveDown: () => onTaskMoveDown(index),
                onRemove: () => onTaskRemove(task.id),
              ),
            );
          }),
          const SizedBox(height: AppSizes.s),
          Wrap(
            spacing: AppSizes.s,
            runSpacing: AppSizes.s,
            children: [
              _EditorActionButton(
                icon: FontAwesomeIcons.plus,
                label: 'Add task',
                onPressed: onAddTask,
              ),
              _EditorActionButton(
                icon: FontAwesomeIcons.layerGroup,
                label: 'Add group',
                onPressed: onAddGroupAfter,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorActionButton extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;

  const _EditorActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s,
          vertical: AppSizes.s,
        ),
        side: const BorderSide(color: AppColors.faint),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
      ),
      icon: FaIcon(
        icon,
        size: AppSizes.iconMedium,
        color: AppColors.light,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.light,
          fontSize: AppSizes.textSub,
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final Task task;
  final FocusNode focusNode;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<String> onChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  const _TaskRow({
    super.key,
    required this.task,
    required this.focusNode,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.s),
            child: FaIcon(
              FontAwesomeIcons.squareCheck,
              size: AppSizes.iconMedium,
              color: AppColors.light,
            ),
          ),
          Expanded(
            child: TextFormField(
              key: ValueKey('task-${task.id}'),
              focusNode: focusNode,
              initialValue: task.label,
              style: const TextStyle(color: AppColors.light),
              decoration: const InputDecoration(
                hintText: 'Enter checkbox label',
                hintStyle: TextStyle(color: AppColors.faint),
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
          PopupMenuButton<_TaskMenuAction>(
            tooltip: 'Checkbox actions',
            onSelected: (action) {
              switch (action) {
                case _TaskMenuAction.moveUp:
                  onMoveUp();
                  break;
                case _TaskMenuAction.moveDown:
                  onMoveDown();
                  break;
                case _TaskMenuAction.remove:
                  onRemove();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (canMoveUp)
                const PopupMenuItem(
                  value: _TaskMenuAction.moveUp,
                  child: Text('Move up'),
                ),
              if (canMoveDown)
                const PopupMenuItem(
                  value: _TaskMenuAction.moveDown,
                  child: Text('Move down'),
                ),
              const PopupMenuItem(
                value: _TaskMenuAction.remove,
                child: Text('Delete checkbox'),
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
    );
  }
}
