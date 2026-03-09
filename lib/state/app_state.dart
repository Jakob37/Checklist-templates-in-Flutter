import 'package:flutter/foundation.dart';
import '../models/checklist.dart';
import '../models/checklist_template.dart';
import '../models/id_gen.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  List<ChecklistTemplate> _templates = [];
  List<Checklist> _checklists = [];

  List<ChecklistTemplate> get templates => List.unmodifiable(_templates);
  List<Checklist> get checklists => List.unmodifiable(_checklists);

  Future<void> init() async {
    _templates = await StorageService.loadTemplates();
    _checklists = await StorageService.loadChecklists();
  }

  // ── Template mutations ──────────────────────────────────────────────────────

  Future<void> saveTemplate(ChecklistTemplate template) async {
    await saveNewTemplates([template]);
  }

  Future<void> saveNewTemplates(List<ChecklistTemplate> newTemplates) async {
    final newIds = {for (final t in newTemplates) t.id};
    final kept = _templates.where((t) => !newIds.contains(t.id)).toList();
    kept.addAll(newTemplates);
    _templates = kept;
    await StorageService.saveTemplates(_templates);
    notifyListeners();
  }

  Future<void> removeTemplate(String id) async {
    _templates = _templates.where((t) => t.id != id).toList();
    await StorageService.saveTemplates(_templates);
    notifyListeners();
  }

  // ── Checklist mutations ─────────────────────────────────────────────────────

  Future<void> saveChecklist(Checklist checklist) async {
    final without = _checklists.where((c) => c.id != checklist.id).toList();
    _checklists = [...without, checklist];
    await StorageService.saveChecklists(_checklists);
    notifyListeners();
  }

  Future<void> removeChecklist(String id) async {
    _checklists = _checklists.where((c) => c.id != id).toList();
    await StorageService.saveChecklists(_checklists);
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
      label: 'default',
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
    final checkboxes = template.stacks.expand((stack) {
      return stack.tasks.asMap().entries.map((e) {
        return Checkbox(
          id: generateId('checkbox-${e.key}'),
          label: e.value.label,
          checked: CheckboxStatus.unchecked,
        );
      });
    }).toList();

    return Checklist(
      id: generateId('checklist'),
      template: template,
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
}
