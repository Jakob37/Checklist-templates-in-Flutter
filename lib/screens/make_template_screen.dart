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
  final Map<String, FocusNode> _taskFocusNodes = {};

  late String _templateId;
  late String _stackId;
  bool _isFavorite = false;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _templateId = generateId('template');
    _stackId = generateId('stack');
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
    _templateId = template.id;
    _stackId = template.stacks.first.id;
    _isFavorite = template.favorite;
    _nameController.text = template.label;
    _tasks = template.stacks.expand((s) => s.tasks).toList();
    for (final task in _tasks) {
      _taskFocusNodes[task.id] = FocusNode();
    }
  }

  void _reset() {
    _templateId = generateId('template');
    _stackId = generateId('stack');
    _isFavorite = false;
    _nameController.clear();
    for (final fn in _taskFocusNodes.values) {
      fn.dispose();
    }
    _taskFocusNodes.clear();
    _tasks = [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    for (final fn in _taskFocusNodes.values) {
      fn.dispose();
    }
    super.dispose();
  }

  bool get _saveActive =>
      _nameController.text.isNotEmpty && _tasks.any((t) => t.label.isNotEmpty);

  void _addTask() {
    final taskId = generateId('task');
    _taskFocusNodes[taskId] = FocusNode();
    setState(() {
      _tasks = [..._tasks, Task(id: taskId, label: '')];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskFocusNodes[taskId]?.requestFocus();
    });
  }

  void _removeTask(String id) {
    _taskFocusNodes[id]?.dispose();
    _taskFocusNodes.remove(id);
    setState(() {
      _tasks = _tasks.where((t) => t.id != id).toList();
    });
  }

  void _renameTask(String id, String label) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final copy = [..._tasks];
    copy[idx] = copy[idx].copyWith(label: label);
    _tasks = copy;
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final tasks = _tasks
        .where((task) => task.label.trim().isNotEmpty)
        .map((task) => task.copyWith(label: task.label.trim()))
        .toList();
    final template = ChecklistTemplate(
      id: _templateId,
      label: _nameController.text.trim(),
      favorite: _isFavorite,
      stacks: [
        TaskStack(
          id: _stackId,
          label: 'default',
          tasks: tasks,
        ),
      ],
    );
    await state.saveTemplate(
      template,
      syncActiveChecklists: widget.syncActiveChecklists,
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Name input
          BluePanel(
            margin: const EdgeInsets.fromLTRB(
                AppSizes.s, AppSizes.s, AppSizes.s, 0),
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              autofocus: widget.isNew,
              style: const TextStyle(color: AppColors.light),
              decoration: const InputDecoration(
                hintText: 'Enter template name',
                hintStyle: TextStyle(color: AppColors.faint),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Task list
          Expanded(
            child: BluePanel(
              margin: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s, vertical: AppSizes.s),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  if (!_taskFocusNodes.containsKey(task.id)) {
                    _taskFocusNodes[task.id] = FocusNode();
                  }
                  return _TaskRow(
                    key: ValueKey(task.id),
                    index: index,
                    task: task,
                    focusNode: _taskFocusNodes[task.id]!,
                    onChanged: (text) => _renameTask(task.id, text),
                    onRemove: () => _removeTask(task.id),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _tasks.removeAt(oldIndex);
                    _tasks.insert(newIndex, item);
                  });
                },
              ),
            ),
          ),

          // Add task
          BluePanel(
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.s),
            child: GestureDetector(
              onTap: _addTask,
              child: const Row(
                children: [
                  FaIcon(FontAwesomeIcons.plus,
                      size: AppSizes.iconMedium, color: AppColors.light),
                  SizedBox(width: AppSizes.s),
                  Text('Add task',
                      style: TextStyle(
                          color: AppColors.light, fontSize: AppSizes.textSub)),
                ],
              ),
            ),
          ),

          // Save button
          GestureDetector(
            onTap: _saveActive ? _save : null,
            child: Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: AppSizes.s, vertical: AppSizes.s),
              padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.s, horizontal: AppSizes.s),
              decoration: BoxDecoration(
                color: _saveActive ? AppColors.highlight2 : AppColors.faint,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.floppyDisk,
                      size: AppSizes.iconMedium,
                      color: _saveActive ? AppColors.white : AppColors.light),
                  const SizedBox(width: AppSizes.s),
                  Text(
                    widget.syncActiveChecklists
                        ? 'Save template and checklist'
                        : 'Save template',
                    style: TextStyle(
                        fontSize: AppSizes.textMajor,
                        color: _saveActive ? AppColors.white : AppColors.light),
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

class _TaskRow extends StatelessWidget {
  final int index;
  final Task task;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  const _TaskRow({
    super.key,
    required this.index,
    required this.task,
    required this.focusNode,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.s),
            child: FaIcon(FontAwesomeIcons.bars,
                size: AppSizes.iconMedium, color: AppColors.light),
          ),
        ),
        Expanded(
          child: TextField(
            focusNode: focusNode,
            controller: TextEditingController(text: task.label)
              ..selection = TextSelection.collapsed(offset: task.label.length),
            style: const TextStyle(color: AppColors.light),
            decoration: const InputDecoration(
              hintText: 'Enter your task...',
              hintStyle: TextStyle(color: AppColors.faint),
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const FaIcon(FontAwesomeIcons.trash,
              size: AppSizes.iconMedium, color: AppColors.light),
        ),
      ],
    );
  }
}
