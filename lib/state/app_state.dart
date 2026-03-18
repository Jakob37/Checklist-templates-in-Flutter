import 'package:flutter/foundation.dart';
import '../models/checklist.dart';
import '../models/checklist_history_entry.dart';
import '../models/checklist_template.dart';
import '../models/id_gen.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  List<ChecklistTemplate> _templates = [];
  List<Checklist> _checklists = [];
  List<ChecklistHistoryEntry> _historyEntries = [];

  List<ChecklistTemplate> get templates => List.unmodifiable(_templates);
  List<Checklist> get checklists => List.unmodifiable(_checklists);
  List<ChecklistHistoryEntry> get historyEntries =>
      List.unmodifiable(_historyEntries);
  List<ChecklistTemplate> get sortedTemplates {
    final sorted = [..._templates];
    sorted.sort((a, b) {
      if (a.favorite != b.favorite) {
        return a.favorite ? -1 : 1;
      }
      final usageCompare = b.usageCount.compareTo(a.usageCount);
      if (usageCompare != 0) return usageCompare;
      return a.label.compareTo(b.label);
    });
    return List.unmodifiable(sorted);
  }

  Future<void> init() async {
    _templates = await StorageService.loadTemplates();
    _checklists = await StorageService.loadChecklists();
    _historyEntries = await StorageService.loadHistoryEntries();
  }

  // ── Template mutations ──────────────────────────────────────────────────────

  Future<void> saveTemplate(
    ChecklistTemplate template, {
    bool syncActiveChecklists = false,
  }) async {
    await saveNewTemplates(
      [template],
      syncActiveChecklists: syncActiveChecklists,
    );
  }

  Future<void> saveNewTemplates(
    List<ChecklistTemplate> newTemplates, {
    bool syncActiveChecklists = false,
  }) async {
    final existingById = {
      for (final template in _templates) template.id: template
    };
    final normalizedTemplates = newTemplates.map((template) {
      final existing = existingById[template.id];
      if (existing == null || template.usageCount > 0) return template;
      return template.copyWith(usageCount: existing.usageCount);
    }).toList();
    final newIds = {for (final t in normalizedTemplates) t.id};
    final kept = _templates.where((t) => !newIds.contains(t.id)).toList();
    kept.addAll(normalizedTemplates);
    _templates = kept;
    await StorageService.saveTemplates(_templates);
    if (syncActiveChecklists) {
      for (final template in normalizedTemplates) {
        _syncActiveChecklistsForTemplate(template);
      }
      await StorageService.saveChecklists(_checklists);
    }
    notifyListeners();
  }

  Future<void> removeTemplate(String id) async {
    _templates = _templates.where((t) => t.id != id).toList();
    await StorageService.saveTemplates(_templates);
    notifyListeners();
  }

  // ── Checklist mutations ─────────────────────────────────────────────────────

  Future<void> saveChecklist(Checklist checklist) async {
    final isNewChecklist = !_checklists.any((c) => c.id == checklist.id);
    var storedChecklist = checklist;

    if (isNewChecklist) {
      final templateIndex =
          _templates.indexWhere((t) => t.id == checklist.template.id);
      if (templateIndex >= 0) {
        final updatedTemplate = _templates[templateIndex].copyWith(
          usageCount: _templates[templateIndex].usageCount + 1,
        );
        _templates = _templates.map((template) {
          return template.id == updatedTemplate.id ? updatedTemplate : template;
        }).toList();
        storedChecklist = checklist.copyWith(
          template: checklist.template.copyWith(
            usageCount: updatedTemplate.usageCount,
          ),
        );
        await StorageService.saveTemplates(_templates);
      }
    }

    final without = _checklists.where((c) => c.id != checklist.id).toList();
    _checklists = [...without, storedChecklist];
    await StorageService.saveChecklists(_checklists);
    notifyListeners();
  }

  Future<void> removeChecklist(String id) async {
    _checklists = _checklists.where((c) => c.id != id).toList();
    await StorageService.saveChecklists(_checklists);
    notifyListeners();
  }

  Future<void> completeChecklist(String checklistId) async {
    final checklist = _checklists.firstWhere((c) => c.id == checklistId);
    _historyEntries = [
      ..._historyEntries,
      ChecklistHistoryEntry(
        id: generateId('history'),
        templateId: checklist.template.id,
        templateLabel: checklist.template.label,
        completedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
    _checklists = _checklists.where((c) => c.id != checklistId).toList();
    await StorageService.saveChecklists(_checklists);
    await StorageService.saveHistoryEntries(_historyEntries);
    notifyListeners();
  }

  Future<void> toggleCheck(String checklistId, String checkboxId) async {
    _checklists = _checklists.map((checklist) {
      if (checklist.id != checklistId) return checklist;
      final newBoxes = checklist.checkboxes.map((box) {
        if (box.id != checkboxId) return box;
        final newStatus = box.checked == CheckboxStatus.checked
            ? CheckboxStatus.unchecked
            : CheckboxStatus.checked;
        return box.copyWith(checked: newStatus);
      }).toList();
      return checklist.copyWith(checkboxes: newBoxes);
    }).toList();
    await StorageService.saveChecklists(_checklists);
    notifyListeners();
  }

  Future<void> resetChecklist(String checklistId) async {
    _checklists = _checklists.map((checklist) {
      if (checklist.id != checklistId) return checklist;
      final reset = checklist.checkboxes
          .map((b) => Checkbox(
                id: b.id,
                taskId: b.taskId,
                label: b.label,
                checked: CheckboxStatus.unchecked,
              ))
          .toList();
      return checklist.copyWith(checkboxes: reset);
    }).toList();
    await StorageService.saveChecklists(_checklists);
    notifyListeners();
  }

  // ── Queries ─────────────────────────────────────────────────────────────────

  ChecklistTemplate getTemplateById(String id) =>
      _templates.firstWhere((t) => t.id == id);

  bool getTemplateExists(String id) => _templates.any((t) => t.id == id);

  bool isChecklistDone(String checklistId) {
    final c = _checklists.firstWhere((c) => c.id == checklistId);
    return !c.checkboxes.any((b) => b.checked == CheckboxStatus.unchecked);
  }

  int completionCountForTemplate(String templateId) =>
      _historyEntries.where((entry) => entry.templateId == templateId).length;

  // ── Template factory helpers ─────────────────────────────────────────────────

  ChecklistTemplate buildTemplate({
    required String templateId,
    required String templateName,
    required bool isFavorite,
    required List<String> taskLabels,
  }) {
    final tasks = taskLabels.asMap().entries.map((e) {
      return Task(id: generateId('task-${e.key}'), label: e.value);
    }).toList();

    final stack = TaskStack(
      id: generateId('stack-1'),
      label: '',
      tasks: tasks,
    );

    return ChecklistTemplate(
      id: templateId,
      label: templateName,
      stacks: [stack],
      favorite: isFavorite,
    );
  }

  Checklist instantiateTemplate(ChecklistTemplate template) {
    return instantiateTemplateWithSelectedOptionalGroups(
      template,
      selectedOptionalStackIds: {
        for (final stack in template.stacks.where((stack) => stack.isOptional))
          stack.id,
      },
    );
  }

  Checklist instantiateTemplateWithSelectedOptionalGroups(
    ChecklistTemplate template, {
    required Set<String> selectedOptionalStackIds,
  }) {
    final includedStacks = template.stacks.where((stack) {
      if (!stack.isOptional) return true;
      return selectedOptionalStackIds.contains(stack.id);
    }).toList();

    final instantiatedTemplate = template.copyWith(stacks: includedStacks);

    final checkboxes = includedStacks.expand((stack) {
      return stack.tasks.map((task) {
        return Checkbox(
          id: generateId('checkbox'),
          taskId: task.id,
          label: task.label,
          checked: CheckboxStatus.unchecked,
        );
      });
    }).toList();

    return Checklist(
      id: generateId('checklist'),
      template: instantiatedTemplate,
      checkboxes: checkboxes,
      timecreated: DateTime.now().millisecondsSinceEpoch,
    );
  }

  ChecklistTemplate makeLeavingHomeTemplate() => buildTemplate(
        templateId: generateId('exampletemplate-1'),
        templateName: 'Leaving home (example)',
        isFavorite: false,
        taskLabels: ['Keys', 'Wallet', 'Phone', 'Laptop', 'Gloves'],
      );

  ChecklistTemplate makeBeforeSleepTemplate() => buildTemplate(
        templateId: generateId('exampletemplate-2'),
        templateName: 'Before sleep (example)',
        isFavorite: false,
        taskLabels: [
          'Dim lights',
          'Brush teeth',
          "Pack tomorrow's things",
          'Put aside the phone',
        ],
      );

  ChecklistTemplate makeBeforeSocialTemplate() => buildTemplate(
        templateId: generateId('exampletemplate-3'),
        templateName: 'Before social (example)',
        isFavorite: false,
        taskLabels: [
          'Be mindful for a moment',
          'Relax tensions',
          'Think about the person(s)',
          'Picture them',
          'Find three touching points',
          'Be present',
        ],
      );

  void _syncActiveChecklistsForTemplate(ChecklistTemplate template) {
    _checklists = _checklists.map((checklist) {
      if (checklist.template.id != template.id) return checklist;
      return _syncChecklistToTemplate(checklist, template);
    }).toList();
  }

  Checklist _syncChecklistToTemplate(
    Checklist checklist,
    ChecklistTemplate template,
  ) {
    final activeStackIds = {
      for (final stack in checklist.template.stacks) stack.id,
    };
    final syncedStacks = template.stacks.where((stack) {
      if (!stack.isOptional) return true;
      return activeStackIds.contains(stack.id);
    }).toList();
    final syncedTemplate = template.copyWith(stacks: syncedStacks);
    final checkboxByTaskId = <String, Checkbox>{};
    final previousTasks =
        checklist.template.stacks.expand((stack) => stack.tasks);

    for (final entry in previousTasks.toList().asMap().entries) {
      if (entry.key >= checklist.checkboxes.length) break;
      checkboxByTaskId[entry.value.id] = checklist.checkboxes[entry.key];
    }

    for (final box in checklist.checkboxes) {
      if (box.taskId != null) {
        checkboxByTaskId[box.taskId!] = box;
      }
    }

    final syncedCheckboxes = syncedStacks.expand((stack) => stack.tasks).map((
      task,
    ) {
      final existing = checkboxByTaskId[task.id];
      if (existing != null) {
        return existing.copyWith(taskId: task.id, label: task.label);
      }
      return Checkbox(
        id: generateId('checkbox'),
        taskId: task.id,
        label: task.label,
        checked: CheckboxStatus.unchecked,
      );
    }).toList();

    return checklist.copyWith(
      template: syncedTemplate,
      checkboxes: syncedCheckboxes,
    );
  }
}
